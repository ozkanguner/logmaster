#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LogMaster Web Arayüzü - Ana Uygulama
5651 Kanunu Uyumlu Log Yönetim Sistemi Web Dashboard
"""

import os
import sys
import json
import logging
from datetime import datetime, timedelta, date
from pathlib import Path
from typing import Dict, List, Optional
import configparser

from fastapi import FastAPI, Request, HTTPException, Depends, status, Form, File, UploadFile
from fastapi.responses import HTMLResponse, JSONResponse, FileResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

import psycopg2
from psycopg2.extras import RealDictCursor
import asyncio
import aiofiles

# LogMaster modüllerini import et
sys.path.append('/opt/logmaster')
try:
    from scripts.digital_signer import DigitalSigner
    from scripts.archiver import LogArchiver
    from scripts.compliance_report import ComplianceReporter
except ImportError:
    # Development ortamı için
    pass

# FastAPI uygulaması
app = FastAPI(
    title="LogMaster Web Arayüzü",
    description="5651 Kanunu Uyumlu Log Yönetim Sistemi",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files ve templates
app.mount("/static", StaticFiles(directory="web/static"), name="static")
templates = Jinja2Templates(directory="web/templates")

# Security
security = HTTPBasic()

# Global değişkenler
config = None
db_pool = None

def load_config():
    """Konfigürasyonu yükle"""
    global config
    config = configparser.ConfigParser()
    
    # Farklı konumları dene
    config_paths = [
        "/opt/logmaster/config/main.conf",
        "config/main.conf",
        "web/../config/main.conf"
    ]
    
    for path in config_paths:
        if os.path.exists(path):
            config.read(path)
            break
    else:
        raise FileNotFoundError("Konfigürasyon dosyası bulunamadı")

def get_db_connection():
    """Veritabanı bağlantısı al"""
    try:
        return psycopg2.connect(
            host=config.get('DATABASE', 'db_host'),
            port=config.get('DATABASE', 'db_port'),
            database=config.get('DATABASE', 'db_name'),
            user=config.get('DATABASE', 'db_user'),
            password=config.get('DATABASE', 'db_password'),
            cursor_factory=RealDictCursor
        )
    except Exception as e:
        logging.error(f"Veritabanı bağlantı hatası: {e}")
        return None

def verify_credentials(credentials: HTTPBasicCredentials = Depends(security)):
    """Basit kimlik doğrulama"""
    # Gerçek uygulamada veritabanından kontrol edilmeli
    correct_username = "admin"
    correct_password = "logmaster2024"
    
    if credentials.username != correct_username or credentials.password != correct_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Yanlış kullanıcı adı veya şifre",
            headers={"WWW-Authenticate": "Basic"},
        )
    return credentials.username

# Ana sayfa
@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request, username: str = Depends(verify_credentials)):
    """Ana dashboard sayfası"""
    return templates.TemplateResponse("dashboard.html", {
        "request": request,
        "username": username,
        "title": "LogMaster Dashboard"
    })

# API Endpoints

@app.get("/api/stats/overview")
async def get_overview_stats(username: str = Depends(verify_credentials)):
    """Genel istatistikleri getir"""
    db = get_db_connection()
    if not db:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantı hatası")
    
    try:
        cursor = db.cursor()
        
        # Son 24 saat istatistikleri
        yesterday = datetime.now() - timedelta(days=1)
        
        # Toplam log sayısı
        cursor.execute("SELECT COUNT(*) as total FROM log_entries WHERE timestamp >= %s", (yesterday,))
        total_logs = cursor.fetchone()['total']
        
        # Aktif cihaz sayısı
        cursor.execute("SELECT COUNT(DISTINCT device_id) as count FROM log_entries WHERE timestamp >= %s", (yesterday,))
        active_devices = cursor.fetchone()['count']
        
        # İmzalanan dosya sayısı
        cursor.execute("SELECT COUNT(*) as count FROM digital_signatures WHERE signed_at >= %s", (yesterday,))
        signed_files = cursor.fetchone()['count']
        
        # Arşivlenen dosya sayısı
        cursor.execute("SELECT COUNT(*) as count FROM archive_records WHERE archived_at >= %s", (yesterday,))
        archived_files = cursor.fetchone()['count']
        
        # Hata sayısı
        cursor.execute("SELECT COUNT(*) as count FROM access_logs WHERE accessed_at >= %s AND success = false", (yesterday,))
        error_count = cursor.fetchone()['count']
        
        # Disk kullanımı
        log_path = config.get('SYSTEM', 'log_base_path', fallback='/opt/logmaster/logs')
        disk_usage = get_disk_usage(log_path)
        
        cursor.close()
        db.close()
        
        return {
            "total_logs": total_logs,
            "active_devices": active_devices,
            "signed_files": signed_files,
            "archived_files": archived_files,
            "error_count": error_count,
            "disk_usage": disk_usage,
            "last_updated": datetime.now().isoformat()
        }
        
    except Exception as e:
        logging.error(f"İstatistik alma hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/logs/recent")
async def get_recent_logs(limit: int = 100, device_id: Optional[str] = None, username: str = Depends(verify_credentials)):
    """Son log girişlerini getir"""
    db = get_db_connection()
    if not db:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantı hatası")
    
    try:
        cursor = db.cursor()
        
        query = """
            SELECT le.timestamp, le.device_id, le.source_ip, 
                   LEFT(le.raw_message, 100) as message_preview,
                   d.name as device_name
            FROM log_entries le
            LEFT JOIN devices d ON le.device_id = d.device_id
        """
        
        params = []
        if device_id:
            query += " WHERE le.device_id = %s"
            params.append(device_id)
        
        query += " ORDER BY le.timestamp DESC LIMIT %s"
        params.append(limit)
        
        cursor.execute(query, params)
        logs = cursor.fetchall()
        
        cursor.close()
        db.close()
        
        return [dict(log) for log in logs]
        
    except Exception as e:
        logging.error(f"Log getirme hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/devices")
async def get_devices(username: str = Depends(verify_credentials)):
    """Cihaz listesini getir"""
    db = get_db_connection()
    if not db:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantı hatası")
    
    try:
        cursor = db.cursor()
        
        cursor.execute("""
            SELECT d.device_id, d.name, d.ip_address, d.location, d.status,
                   COUNT(le.id) as log_count,
                   MAX(le.timestamp) as last_log
            FROM devices d
            LEFT JOIN log_entries le ON d.device_id = le.device_id
            GROUP BY d.device_id, d.name, d.ip_address, d.location, d.status
            ORDER BY log_count DESC
        """)
        
        devices = cursor.fetchall()
        cursor.close()
        db.close()
        
        return [dict(device) for device in devices]
        
    except Exception as e:
        logging.error(f"Cihaz listesi hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/signatures/status")
async def get_signature_status(days: int = 7, username: str = Depends(verify_credentials)):
    """İmza durumu istatistiklerini getir"""
    db = get_db_connection()
    if not db:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantı hatası")
    
    try:
        cursor = db.cursor()
        start_date = datetime.now() - timedelta(days=days)
        
        cursor.execute("""
            SELECT verification_status,
                   COUNT(*) as count,
                   ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
            FROM digital_signatures 
            WHERE signed_at >= %s
            GROUP BY verification_status
        """, (start_date,))
        
        status_data = cursor.fetchall()
        
        # Günlük imza sayıları
        cursor.execute("""
            SELECT DATE(signed_at) as date,
                   COUNT(*) as count
            FROM digital_signatures 
            WHERE signed_at >= %s
            GROUP BY DATE(signed_at)
            ORDER BY date
        """, (start_date,))
        
        daily_data = cursor.fetchall()
        
        cursor.close()
        db.close()
        
        return {
            "status_breakdown": [dict(row) for row in status_data],
            "daily_counts": [dict(row) for row in daily_data]
        }
        
    except Exception as e:
        logging.error(f"İmza durumu hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/signature/verify")
async def verify_signature(file_path: str = Form(...), username: str = Depends(verify_credentials)):
    """Dosya imzasını doğrula"""
    try:
        signer = DigitalSigner()
        result = signer.verify_log_file(file_path)
        
        return {
            "file_path": file_path,
            "verification_result": result,
            "verified_at": datetime.now().isoformat()
        }
        
    except Exception as e:
        logging.error(f"İmza doğrulama hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/archives")
async def get_archive_info(username: str = Depends(verify_credentials)):
    """Arşiv bilgilerini getir"""
    db = get_db_connection()
    if not db:
        raise HTTPException(status_code=500, detail="Veritabanı bağlantı hatası")
    
    try:
        cursor = db.cursor()
        
        # Arşiv özeti
        cursor.execute("""
            SELECT COUNT(*) as total_files,
                   SUM(original_size) as total_original_size,
                   SUM(compressed_size) as total_compressed_size,
                   ROUND(AVG((1 - compressed_size::float / original_size) * 100), 2) as avg_compression_ratio
            FROM archive_records
        """)
        
        summary = cursor.fetchone()
        
        # Son arşivlenen dosyalar
        cursor.execute("""
            SELECT original_file_path, archive_file_path, archived_at,
                   original_size, compressed_size, compression_type
            FROM archive_records
            ORDER BY archived_at DESC
            LIMIT 20
        """)
        
        recent_archives = cursor.fetchall()
        
        cursor.close()
        db.close()
        
        return {
            "summary": dict(summary),
            "recent_archives": [dict(row) for row in recent_archives]
        }
        
    except Exception as e:
        logging.error(f"Arşiv bilgisi hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/compliance/score")
async def get_compliance_score(days: int = 30, username: str = Depends(verify_credentials)):
    """Uyumluluk skorunu hesapla"""
    try:
        reporter = ComplianceReporter()
        end_date = date.today()
        start_date = end_date - timedelta(days=days)
        
        # İstatistikleri al
        log_stats = reporter.get_log_statistics(start_date, end_date)
        signature_stats = reporter.get_signature_statistics(start_date, end_date)
        archive_stats = reporter.get_archive_statistics(start_date, end_date)
        access_stats = reporter.get_access_log_statistics(start_date, end_date)
        
        stats = {
            'logs': log_stats,
            'signatures': signature_stats,
            'archives': archive_stats,
            'access': access_stats
        }
        
        # Uyumluluk skorunu hesapla
        score = reporter.generate_compliance_score(stats)
        
        return {
            "compliance_score": score,
            "period_days": days,
            "calculated_at": datetime.now().isoformat(),
            "details": stats
        }
        
    except Exception as e:
        logging.error(f"Uyumluluk skoru hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/reports/generate")
async def generate_report(
    report_type: str = Form(...),
    start_date: str = Form(...),
    end_date: str = Form(...),
    username: str = Depends(verify_credentials)
):
    """Uyumluluk raporu oluştur"""
    try:
        reporter = ComplianceReporter()
        
        start_dt = datetime.strptime(start_date, '%Y-%m-%d').date()
        end_dt = datetime.strptime(end_date, '%Y-%m-%d').date()
        
        report = reporter.generate_report(report_type, start_dt, end_dt)
        
        return {
            "success": True,
            "report_type": report_type,
            "period": f"{start_date} - {end_date}",
            "compliance_score": report["compliance_score"],
            "generated_at": report["generated_at"]
        }
        
    except Exception as e:
        logging.error(f"Rapor oluşturma hatası: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Utility functions

def get_disk_usage(path: str) -> Dict:
    """Disk kullanım bilgilerini al"""
    try:
        import shutil
        total, used, free = shutil.disk_usage(path)
        
        return {
            "total": total,
            "used": used,
            "free": free,
            "usage_percent": round((used / total) * 100, 2)
        }
    except Exception:
        return {
            "total": 0,
            "used": 0,
            "free": 0,
            "usage_percent": 0
        }

# Sistem yönetimi endpoints

@app.get("/api/system/status")
async def get_system_status(username: str = Depends(verify_credentials)):
    """Sistem durumunu kontrol et"""
    status = {}
    
    # Veritabanı durumu
    db = get_db_connection()
    status["database"] = "healthy" if db else "error"
    if db:
        db.close()
    
    # Log dizini durumu
    log_path = config.get('SYSTEM', 'log_base_path', fallback='/opt/logmaster/logs')
    status["log_directory"] = "healthy" if os.path.exists(log_path) else "error"
    
    # Servis durumları (Linux'ta)
    try:
        import subprocess
        services = ['postgresql', 'rsyslog', 'nginx']
        for service in services:
            try:
                result = subprocess.run(['systemctl', 'is-active', service], 
                                      capture_output=True, text=True)
                status[f"service_{service}"] = result.stdout.strip()
            except:
                status[f"service_{service}"] = "unknown"
    except:
        pass
    
    return status

@app.post("/api/system/restart-service")
async def restart_service(service_name: str = Form(...), username: str = Depends(verify_credentials)):
    """Servisi yeniden başlat"""
    try:
        import subprocess
        allowed_services = ['logmaster-collector', 'logmaster-signer']
        
        if service_name not in allowed_services:
            raise HTTPException(status_code=400, detail="İzin verilmeyen servis")
        
        result = subprocess.run(['sudo', 'supervisorctl', 'restart', service_name], 
                              capture_output=True, text=True)
        
        return {
            "success": result.returncode == 0,
            "output": result.stdout,
            "error": result.stderr
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Başlangıç fonksiyonu
@app.on_event("startup")
async def startup_event():
    """Uygulama başlangıcında çalışacak fonksiyonlar"""
    try:
        load_config()
        logging.info("LogMaster Web Arayüzü başlatıldı")
    except Exception as e:
        logging.error(f"Başlangıç hatası: {e}")

# Ana çalıştırma
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="0.0.0.0", help="Host adresi")
    parser.add_argument("--port", type=int, default=8000, help="Port numarası")
    parser.add_argument("--debug", action="store_true", help="Debug modu")
    
    args = parser.parse_args()
    
    logging.basicConfig(
        level=logging.DEBUG if args.debug else logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    uvicorn.run(
        "app:app",
        host=args.host,
        port=args.port,
        reload=args.debug,
        log_level="debug" if args.debug else "info"
    ) 