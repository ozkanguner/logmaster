#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LogMaster - Arşivleme Modülü
Eski log dosyalarını sıkıştırıp arşivleme
"""

import os
import sys
import gzip
import shutil
import hashlib
import logging
from datetime import datetime, timedelta
from pathlib import Path
import configparser
import json
from typing import List, Dict
import psycopg2

class LogArchiver:
    """Log arşivleme sınıfı"""
    
    def __init__(self, config_file: str = "/opt/logmaster/config/main.conf"):
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
        
        # Ayarları al
        self.log_base_path = self.config.get('SYSTEM', 'log_base_path')
        self.archive_path = self.config.get('SYSTEM', 'archived_path')
        self.archive_after_days = self.config.getint('ARCHIVAL', 'archive_after_days')
        self.compression_type = self.config.get('ARCHIVAL', 'compression_type')
        self.retention_days = self.config.getint('COMPLIANCE', 'retention_period')
        
        # Logging
        self.setup_logging()
        
        # Veritabanı bağlantısı
        self.setup_database()
        
        self.logger.info("LogArchiver başlatıldı")
    
    def setup_logging(self):
        """Logging sistemini ayarla"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/var/log/logmaster/archiver.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger('LogArchiver')
    
    def setup_database(self):
        """Veritabanı bağlantısını kur"""
        try:
            self.db_conn = psycopg2.connect(
                host=self.config.get('DATABASE', 'db_host'),
                port=self.config.get('DATABASE', 'db_port'),
                database=self.config.get('DATABASE', 'db_name'),
                user=self.config.get('DATABASE', 'db_user'),
                password=self.config.get('DATABASE', 'db_password')
            )
            self.logger.info("Veritabanı bağlantısı kuruldu")
        except Exception as e:
            self.logger.error(f"Veritabanı bağlantı hatası: {e}")
            self.db_conn = None
    
    def find_files_to_archive(self) -> List[Path]:
        """Arşivlenecek dosyaları bul"""
        cutoff_date = datetime.now() - timedelta(days=self.archive_after_days)
        files_to_archive = []
        
        log_dir = Path(self.log_base_path)
        
        for device_dir in log_dir.iterdir():
            if device_dir.is_dir():
                for log_file in device_dir.glob("*.log"):
                    # Dosya tarihi kontrolü
                    file_time = datetime.fromtimestamp(log_file.stat().st_mtime)
                    
                    if file_time < cutoff_date:
                        files_to_archive.append(log_file)
        
        self.logger.info(f"{len(files_to_archive)} dosya arşivlenecek")
        return files_to_archive
    
    def compress_file(self, source_file: Path) -> Path:
        """Dosyayı sıkıştır"""
        archive_dir = Path(self.archive_path) / source_file.parent.name
        archive_dir.mkdir(parents=True, exist_ok=True)
        
        # Arşiv dosya adı: YYYY-MM-DD.log.gz
        archive_file = archive_dir / f"{source_file.name}.gz"
        
        try:
            with open(source_file, 'rb') as f_in:
                with gzip.open(archive_file, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            
            self.logger.info(f"Dosya sıkıştırıldı: {source_file} -> {archive_file}")
            return archive_file
            
        except Exception as e:
            self.logger.error(f"Sıkıştırma hatası {source_file}: {e}")
            raise
    
    def calculate_hash(self, file_path: Path) -> str:
        """Dosya hash'ini hesapla"""
        hash_md5 = hashlib.md5()
        
        if file_path.suffix == '.gz':
            # Gzip dosyası için
            with gzip.open(file_path, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_md5.update(chunk)
        else:
            # Normal dosya için
            with open(file_path, 'rb') as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_md5.update(chunk)
        
        return hash_md5.hexdigest()
    
    def record_archive(self, original_file: Path, archive_file: Path):
        """Arşiv kaydını veritabanına ekle"""
        if not self.db_conn:
            return
        
        try:
            cursor = self.db_conn.cursor()
            
            original_size = original_file.stat().st_size
            compressed_size = archive_file.stat().st_size
            archive_hash = self.calculate_hash(archive_file)
            retention_until = datetime.now().date() + timedelta(days=self.retention_days)
            
            query = """
                INSERT INTO archive_records 
                (original_file_path, archive_file_path, compression_type, 
                 original_size, compressed_size, archive_hash, retention_until)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """
            
            cursor.execute(query, (
                str(original_file),
                str(archive_file),
                self.compression_type,
                original_size,
                compressed_size,
                archive_hash,
                retention_until
            ))
            
            self.db_conn.commit()
            cursor.close()
            
            compression_ratio = (1 - compressed_size / original_size) * 100
            self.logger.info(f"Arşiv kaydedildi: {compression_ratio:.1f}% sıkıştırma")
            
        except Exception as e:
            self.logger.error(f"Arşiv kayıt hatası: {e}")
    
    def verify_archive(self, original_file: Path, archive_file: Path) -> bool:
        """Arşiv dosyasını doğrula"""
        try:
            # Orijinal dosya hash'i
            original_hash = self.calculate_hash(original_file)
            
            # Arşiv dosyasından açılmış veri hash'i
            archive_hash = self.calculate_hash(archive_file)
            
            return original_hash == archive_hash
            
        except Exception as e:
            self.logger.error(f"Arşiv doğrulama hatası: {e}")
            return False
    
    def remove_original_file(self, file_path: Path):
        """Orijinal dosyayı sil"""
        try:
            file_path.unlink()
            self.logger.info(f"Orijinal dosya silindi: {file_path}")
            
            # İmza dosyasını da sil
            sig_file = Path(f"{file_path}.sig")
            if sig_file.exists():
                sig_file.unlink()
                self.logger.info(f"İmza dosyası silindi: {sig_file}")
                
        except Exception as e:
            self.logger.error(f"Dosya silme hatası {file_path}: {e}")
    
    def archive_files(self, files: List[Path]) -> Dict:
        """Dosyaları arşivle"""
        stats = {
            'processed': 0,
            'archived': 0,
            'errors': 0,
            'total_original_size': 0,
            'total_compressed_size': 0
        }
        
        for file_path in files:
            try:
                original_size = file_path.stat().st_size
                
                # Dosyayı sıkıştır
                archive_file = self.compress_file(file_path)
                compressed_size = archive_file.stat().st_size
                
                # Doğrula
                if self.verify_archive(file_path, archive_file):
                    # Veritabanına kaydet
                    self.record_archive(file_path, archive_file)
                    
                    # Orijinal dosyayı sil
                    self.remove_original_file(file_path)
                    
                    stats['archived'] += 1
                    stats['total_original_size'] += original_size
                    stats['total_compressed_size'] += compressed_size
                    
                else:
                    self.logger.error(f"Arşiv doğrulama başarısız: {file_path}")
                    archive_file.unlink()  # Hatalı arşiv dosyasını sil
                    stats['errors'] += 1
                
                stats['processed'] += 1
                
            except Exception as e:
                self.logger.error(f"Arşivleme hatası {file_path}: {e}")
                stats['errors'] += 1
        
        return stats
    
    def cleanup_old_archives(self):
        """Eski arşivleri temizle"""
        if not self.db_conn:
            return
        
        try:
            cursor = self.db_conn.cursor()
            
            # Süresi dolan arşivleri bul
            query = """
                SELECT archive_file_path FROM archive_records 
                WHERE retention_until < %s
            """
            
            cursor.execute(query, (datetime.now().date(),))
            expired_archives = cursor.fetchall()
            
            deleted_count = 0
            for (archive_path,) in expired_archives:
                try:
                    Path(archive_path).unlink()
                    deleted_count += 1
                    self.logger.info(f"Eski arşiv silindi: {archive_path}")
                except Exception as e:
                    self.logger.error(f"Arşiv silme hatası {archive_path}: {e}")
            
            # Veritabanından kayıtları sil
            if deleted_count > 0:
                delete_query = """
                    DELETE FROM archive_records 
                    WHERE retention_until < %s
                """
                cursor.execute(delete_query, (datetime.now().date(),))
                self.db_conn.commit()
            
            cursor.close()
            self.logger.info(f"{deleted_count} eski arşiv temizlendi")
            
        except Exception as e:
            self.logger.error(f"Arşiv temizleme hatası: {e}")
    
    def run_archival(self):
        """Arşivleme işlemini çalıştır"""
        self.logger.info("Arşivleme işlemi başlatıldı")
        
        # Arşivlenecek dosyaları bul
        files_to_archive = self.find_files_to_archive()
        
        if not files_to_archive:
            self.logger.info("Arşivlenecek dosya bulunamadı")
            return
        
        # Dosyaları arşivle
        stats = self.archive_files(files_to_archive)
        
        # İstatistikleri yazdır
        compression_ratio = 0
        if stats['total_original_size'] > 0:
            compression_ratio = (1 - stats['total_compressed_size'] / stats['total_original_size']) * 100
        
        self.logger.info(f"Arşivleme tamamlandı:")
        self.logger.info(f"  İşlenen: {stats['processed']}")
        self.logger.info(f"  Arşivlenen: {stats['archived']}")
        self.logger.info(f"  Hata: {stats['errors']}")
        self.logger.info(f"  Sıkıştırma oranı: {compression_ratio:.1f}%")
        
        # Eski arşivleri temizle
        self.cleanup_old_archives()
        
        self.logger.info("Arşivleme işlemi tamamlandı")

def main():
    """Ana fonksiyon"""
    import argparse
    
    parser = argparse.ArgumentParser(description='LogMaster Arşivleme Sistemi')
    parser.add_argument('--dry-run', action='store_true', 
                       help='Sadece simülasyon, gerçek arşivleme yapma')
    parser.add_argument('--force', action='store_true',
                       help='Zorla arşivle (tarih kontrolü yapma)')
    
    args = parser.parse_args()
    
    try:
        archiver = LogArchiver()
        
        if args.dry_run:
            files = archiver.find_files_to_archive()
            print(f"Arşivlenecek dosya sayısı: {len(files)}")
            for file in files[:10]:  # İlk 10'unu göster
                print(f"  {file}")
            if len(files) > 10:
                print(f"  ... ve {len(files) - 10} dosya daha")
        else:
            archiver.run_archival()
    
    except Exception as e:
        logging.error(f"Arşivleme hatası: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 