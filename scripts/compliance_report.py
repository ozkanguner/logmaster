#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LogMaster - 5651 Kanunu Uyumluluk Raporları
Kanuni gerekliliklere uygun raporlama sistemi
"""

import os
import sys
import json
import logging
from datetime import datetime, timedelta, date
from pathlib import Path
import configparser
from typing import Dict, List, Optional
import psycopg2
from psycopg2.extras import RealDictCursor

try:
    from reportlab.lib.pagesizes import A4, letter
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib import colors
    from reportlab.lib.units import inch
    from reportlab.pdfgen import canvas
    import pandas as pd
    import matplotlib.pyplot as plt
    import seaborn as sns
except ImportError as e:
    print(f"Eksik kütüphane: {e}")
    print("Kurulum için: pip install reportlab pandas matplotlib seaborn")
    sys.exit(1)

class ComplianceReporter:
    """5651 Kanunu uyumluluk raporlama sınıfı"""
    
    def __init__(self, config_file: str = "/opt/logmaster/config/main.conf"):
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
        
        # Ayarları al
        self.report_path = Path("/opt/logmaster/reports")
        self.retention_days = self.config.getint('COMPLIANCE', 'retention_period')
        
        # Dizin oluştur
        self.report_path.mkdir(exist_ok=True)
        
        # Logging
        self.setup_logging()
        
        # Veritabanı bağlantısı
        self.setup_database()
        
        self.logger.info("ComplianceReporter başlatıldı")
    
    def setup_logging(self):
        """Logging sistemini ayarla"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger('ComplianceReporter')
    
    def setup_database(self):
        """Veritabanı bağlantısını kur"""
        try:
            self.db_conn = psycopg2.connect(
                host=self.config.get('DATABASE', 'db_host'),
                port=self.config.get('DATABASE', 'db_port'),
                database=self.config.get('DATABASE', 'db_name'),
                user=self.config.get('DATABASE', 'db_user'),
                password=self.config.get('DATABASE', 'db_password'),
                cursor_factory=RealDictCursor
            )
            self.logger.info("Veritabanı bağlantısı kuruldu")
        except Exception as e:
            self.logger.error(f"Veritabanı bağlantı hatası: {e}")
            self.db_conn = None
    
    def get_log_statistics(self, start_date: date, end_date: date) -> Dict:
        """Belirtilen tarih aralığında log istatistiklerini al"""
        cursor = self.db_conn.cursor()
        
        # Toplam log sayısı
        cursor.execute("""
            SELECT COUNT(*) as total_logs,
                   COUNT(DISTINCT device_id) as active_devices,
                   SUM(size) as total_size
            FROM log_entries 
            WHERE DATE(timestamp) BETWEEN %s AND %s
        """, (start_date, end_date))
        
        basic_stats = cursor.fetchone()
        
        # Günlük dağılım
        cursor.execute("""
            SELECT DATE(timestamp) as log_date,
                   COUNT(*) as daily_count,
                   COUNT(DISTINCT device_id) as daily_devices
            FROM log_entries 
            WHERE DATE(timestamp) BETWEEN %s AND %s
            GROUP BY DATE(timestamp)
            ORDER BY log_date
        """, (start_date, end_date))
        
        daily_stats = cursor.fetchall()
        
        # Cihaz bazlı istatistikler
        cursor.execute("""
            SELECT device_id,
                   COUNT(*) as log_count,
                   MIN(timestamp) as first_log,
                   MAX(timestamp) as last_log
            FROM log_entries 
            WHERE DATE(timestamp) BETWEEN %s AND %s
            GROUP BY device_id
            ORDER BY log_count DESC
            LIMIT 20
        """, (start_date, end_date))
        
        device_stats = cursor.fetchall()
        
        cursor.close()
        
        return {
            'basic': dict(basic_stats),
            'daily': [dict(row) for row in daily_stats],
            'devices': [dict(row) for row in device_stats]
        }
    
    def get_signature_statistics(self, start_date: date, end_date: date) -> Dict:
        """Dijital imza istatistiklerini al"""
        cursor = self.db_conn.cursor()
        
        # İmza durumu özeti
        cursor.execute("""
            SELECT verification_status,
                   COUNT(*) as count,
                   ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
            FROM digital_signatures 
            WHERE DATE(signed_at) BETWEEN %s AND %s
            GROUP BY verification_status
        """, (start_date, end_date))
        
        signature_status = cursor.fetchall()
        
        # Günlük imzalama istatistikleri
        cursor.execute("""
            SELECT DATE(signed_at) as sign_date,
                   COUNT(*) as signed_files,
                   AVG(file_size) as avg_file_size
            FROM digital_signatures 
            WHERE DATE(signed_at) BETWEEN %s AND %s
            GROUP BY DATE(signed_at)
            ORDER BY sign_date
        """, (start_date, end_date))
        
        daily_signatures = cursor.fetchall()
        
        # TSA başarı oranı
        cursor.execute("""
            SELECT 
                COUNT(*) as total_signatures,
                COUNT(CASE WHEN tsa_timestamp IS NOT NULL THEN 1 END) as tsa_signed,
                ROUND(COUNT(CASE WHEN tsa_timestamp IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as tsa_success_rate
            FROM digital_signatures 
            WHERE DATE(signed_at) BETWEEN %s AND %s
        """, (start_date, end_date))
        
        tsa_stats = cursor.fetchone()
        
        cursor.close()
        
        return {
            'status': [dict(row) for row in signature_status],
            'daily': [dict(row) for row in daily_signatures],
            'tsa': dict(tsa_stats)
        }
    
    def get_archive_statistics(self, start_date: date, end_date: date) -> Dict:
        """Arşivleme istatistiklerini al"""
        cursor = self.db_conn.cursor()
        
        # Arşiv özeti
        cursor.execute("""
            SELECT COUNT(*) as total_archived,
                   SUM(original_size) as total_original_size,
                   SUM(compressed_size) as total_compressed_size,
                   ROUND(AVG((1 - compressed_size::float / original_size) * 100), 2) as avg_compression_ratio
            FROM archive_records 
            WHERE DATE(archived_at) BETWEEN %s AND %s
        """, (start_date, end_date))
        
        archive_summary = cursor.fetchone()
        
        # Günlük arşivleme
        cursor.execute("""
            SELECT DATE(archived_at) as archive_date,
                   COUNT(*) as files_archived,
                   SUM(original_size) as daily_original_size,
                   SUM(compressed_size) as daily_compressed_size
            FROM archive_records 
            WHERE DATE(archived_at) BETWEEN %s AND %s
            GROUP BY DATE(archived_at)
            ORDER BY archive_date
        """, (start_date, end_date))
        
        daily_archives = cursor.fetchall()
        
        cursor.close()
        
        return {
            'summary': dict(archive_summary),
            'daily': [dict(row) for row in daily_archives]
        }
    
    def get_access_log_statistics(self, start_date: date, end_date: date) -> Dict:
        """Erişim logları istatistiklerini al"""
        cursor = self.db_conn.cursor()
        
        # Erişim özeti
        cursor.execute("""
            SELECT action,
                   COUNT(*) as count,
                   COUNT(CASE WHEN success THEN 1 END) as successful,
                   COUNT(CASE WHEN NOT success THEN 1 END) as failed
            FROM access_logs 
            WHERE DATE(accessed_at) BETWEEN %s AND %s
            GROUP BY action
            ORDER BY count DESC
        """, (start_date, end_date))
        
        access_summary = cursor.fetchall()
        
        # Kullanıcı bazlı erişim
        cursor.execute("""
            SELECT user_id,
                   user_name,
                   COUNT(*) as access_count,
                   COUNT(DISTINCT action) as action_types
            FROM access_logs 
            WHERE DATE(accessed_at) BETWEEN %s AND %s
            GROUP BY user_id, user_name
            ORDER BY access_count DESC
            LIMIT 20
        """, (start_date, end_date))
        
        user_access = cursor.fetchall()
        
        cursor.close()
        
        return {
            'summary': [dict(row) for row in access_summary],
            'users': [dict(row) for row in user_access]
        }
    
    def generate_compliance_score(self, stats: Dict) -> float:
        """Uyumluluk skorunu hesapla (0-100)"""
        score = 100.0
        
        # İmza başarı oranı (40% ağırlık)
        signature_stats = stats.get('signatures', {})
        if signature_stats.get('status'):
            valid_sigs = sum(s['count'] for s in signature_stats['status'] if s['verification_status'] == 'valid')
            total_sigs = sum(s['count'] for s in signature_stats['status'])
            if total_sigs > 0:
                signature_ratio = valid_sigs / total_sigs
                score -= (1 - signature_ratio) * 40
        
        # TSA başarı oranı (20% ağırlık)
        tsa_stats = signature_stats.get('tsa', {})
        if tsa_stats.get('tsa_success_rate') is not None:
            tsa_ratio = tsa_stats['tsa_success_rate'] / 100
            score -= (1 - tsa_ratio) * 20
        
        # Arşivleme başarısı (20% ağırlık)
        archive_stats = stats.get('archives', {})
        if archive_stats.get('summary', {}).get('total_archived', 0) > 0:
            # Arşivleme başarılı
            pass
        else:
            score -= 20  # Arşivleme yapılmamış
        
        # Erişim logları (20% ağırlık)
        access_stats = stats.get('access', {})
        if access_stats.get('summary'):
            total_access = sum(s['count'] for s in access_stats['summary'])
            successful_access = sum(s['successful'] for s in access_stats['summary'])
            if total_access > 0:
                access_ratio = successful_access / total_access
                score -= (1 - access_ratio) * 20
        
        return max(0, min(100, score))
    
    def create_pdf_report(self, report_data: Dict, output_file: Path):
        """PDF raporu oluştur"""
        doc = SimpleDocTemplate(str(output_file), pagesize=A4)
        styles = getSampleStyleSheet()
        story = []
        
        # Başlık
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=16,
            spaceAfter=30,
            textColor=colors.darkblue
        )
        
        title = Paragraph("5651 Sayılı Kanun Uyumluluk Raporu", title_style)
        story.append(title)
        
        # Rapor bilgileri
        report_info = f"""
        <b>Rapor Türü:</b> {report_data['type']}<br/>
        <b>Dönem:</b> {report_data['period_start']} - {report_data['period_end']}<br/>
        <b>Oluşturulma:</b> {report_data['generated_at']}<br/>
        <b>Uyumluluk Skoru:</b> {report_data['compliance_score']:.2f}/100
        """
        
        story.append(Paragraph(report_info, styles['Normal']))
        story.append(Spacer(1, 20))
        
        # Özet istatistikler
        story.append(Paragraph("Özet İstatistikler", styles['Heading2']))
        
        log_stats = report_data['data']['logs']['basic']
        summary_data = [
            ['Metrik', 'Değer'],
            ['Toplam Log Girişi', f"{log_stats['total_logs']:,}"],
            ['Aktif Cihaz Sayısı', f"{log_stats['active_devices']:,}"],
            ['Toplam Veri Boyutu', f"{log_stats['total_size'] / (1024*1024*1024):.2f} GB"],
            ['İmzalanan Dosya', f"{sum(s['count'] for s in report_data['data']['signatures']['status'])}"],
            ['Arşivlenen Dosya', f"{report_data['data']['archives']['summary']['total_archived'] or 0}"]
        ]
        
        summary_table = Table(summary_data)
        summary_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 14),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(summary_table)
        story.append(Spacer(1, 20))
        
        # İmza durumu
        story.append(Paragraph("Dijital İmza Durumu", styles['Heading2']))
        
        sig_data = [['Durum', 'Sayı', 'Yüzde']]
        for status in report_data['data']['signatures']['status']:
            sig_data.append([
                status['verification_status'].title(),
                str(status['count']),
                f"{status['percentage']:.1f}%"
            ])
        
        sig_table = Table(sig_data)
        sig_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.grey),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('GRID', (0, 0), (-1, -1), 1, colors.black)
        ]))
        
        story.append(sig_table)
        story.append(Spacer(1, 20))
        
        # Kanuni gereklilikler
        story.append(Paragraph("5651 Sayılı Kanun Gereklilikleri", styles['Heading2']))
        
        compliance_text = f"""
        <b>1. Veri Saklama:</b> Loglar {self.retention_days} gün süreyle saklanmaktadır.<br/>
        <b>2. Dijital İmzalama:</b> Tüm log dosyaları dijital olarak imzalanmaktadır.<br/>
        <b>3. Zaman Damgası:</b> RFC 3161 uyumlu zaman damgası eklenmektedir.<br/>
        <b>4. Erişim Kontrolü:</b> Tüm erişimler loglanmaktadır.<br/>
        <b>5. Bütünlük Kontrolü:</b> SHA-256 hash ile dosya bütünlüğü korunmaktadır.
        """
        
        story.append(Paragraph(compliance_text, styles['Normal']))
        
        # PDF'i oluştur
        doc.build(story)
        self.logger.info(f"PDF raporu oluşturuldu: {output_file}")
    
    def create_json_report(self, report_data: Dict, output_file: Path):
        """JSON raporu oluştur"""
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False, default=str)
        
        self.logger.info(f"JSON raporu oluşturuldu: {output_file}")
    
    def save_report_to_db(self, report_data: Dict):
        """Raporu veritabanına kaydet"""
        if not self.db_conn:
            return
        
        try:
            cursor = self.db_conn.cursor()
            
            query = """
                INSERT INTO compliance_reports 
                (report_type, period_start, period_end, total_logs, signed_logs, 
                 verified_logs, archived_logs, compliance_score, report_data, generated_by)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            log_stats = report_data['data']['logs']['basic']
            sig_stats = report_data['data']['signatures']['status']
            archive_stats = report_data['data']['archives']['summary']
            
            total_signed = sum(s['count'] for s in sig_stats)
            verified_logs = sum(s['count'] for s in sig_stats if s['verification_status'] == 'valid')
            
            cursor.execute(query, (
                report_data['type'],
                report_data['period_start'],
                report_data['period_end'],
                log_stats['total_logs'],
                total_signed,
                verified_logs,
                archive_stats.get('total_archived', 0),
                report_data['compliance_score'],
                json.dumps(report_data['data'], default=str),
                'system'
            ))
            
            self.db_conn.commit()
            cursor.close()
            
            self.logger.info("Rapor veritabanına kaydedildi")
            
        except Exception as e:
            self.logger.error(f"Rapor kaydetme hatası: {e}")
    
    def generate_report(self, report_type: str, start_date: date, end_date: date) -> Dict:
        """Tam rapor oluştur"""
        self.logger.info(f"{report_type} raporu oluşturuluyor: {start_date} - {end_date}")
        
        # Verileri topla
        log_stats = self.get_log_statistics(start_date, end_date)
        signature_stats = self.get_signature_statistics(start_date, end_date)
        archive_stats = self.get_archive_statistics(start_date, end_date)
        access_stats = self.get_access_log_statistics(start_date, end_date)
        
        stats = {
            'logs': log_stats,
            'signatures': signature_stats,
            'archives': archive_stats,
            'access': access_stats
        }
        
        # Uyumluluk skorunu hesapla
        compliance_score = self.generate_compliance_score(stats)
        
        # Rapor verisi
        report_data = {
            'type': report_type,
            'period_start': start_date,
            'period_end': end_date,
            'generated_at': datetime.now(),
            'compliance_score': compliance_score,
            'data': stats
        }
        
        # Dosya adları
        date_str = f"{start_date}_{end_date}"
        pdf_file = self.report_path / f"compliance_{report_type}_{date_str}.pdf"
        json_file = self.report_path / f"compliance_{report_type}_{date_str}.json"
        
        # Raporları oluştur
        self.create_pdf_report(report_data, pdf_file)
        self.create_json_report(report_data, json_file)
        
        # Veritabanına kaydet
        self.save_report_to_db(report_data)
        
        self.logger.info(f"Rapor oluşturma tamamlandı - Skor: {compliance_score:.2f}")
        
        return report_data

def main():
    """Ana fonksiyon"""
    import argparse
    
    parser = argparse.ArgumentParser(description='LogMaster Uyumluluk Raporları')
    parser.add_argument('--type', choices=['daily', 'weekly', 'monthly', 'annual'], 
                       default='monthly', help='Rapor türü')
    parser.add_argument('--start-date', type=str, help='Başlangıç tarihi (YYYY-MM-DD)')
    parser.add_argument('--end-date', type=str, help='Bitiş tarihi (YYYY-MM-DD)')
    
    args = parser.parse_args()
    
    # Tarih aralığını belirle
    if args.start_date and args.end_date:
        start_date = datetime.strptime(args.start_date, '%Y-%m-%d').date()
        end_date = datetime.strptime(args.end_date, '%Y-%m-%d').date()
    else:
        # Varsayılan: Son ay
        end_date = date.today()
        start_date = end_date.replace(day=1) - timedelta(days=1)
        start_date = start_date.replace(day=1)
    
    try:
        reporter = ComplianceReporter()
        report = reporter.generate_report(args.type, start_date, end_date)
        
        print(f"Rapor oluşturuldu:")
        print(f"  Tür: {report['type']}")
        print(f"  Dönem: {report['period_start']} - {report['period_end']}")
        print(f"  Uyumluluk Skoru: {report['compliance_score']:.2f}/100")
        
    except Exception as e:
        logging.error(f"Rapor oluşturma hatası: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 