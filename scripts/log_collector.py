#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LogMaster - 5651 Kanunu Uyumlu Log Toplama Sistemi
Ana log toplama ve işleme modülü
"""

import os
import sys
import json
import logging
import socket
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path
import configparser
import hashlib
import gzip
from typing import Dict, List, Optional
import asyncio
import aiofiles

# Gerekli kütüphaneler için import
try:
    import socketserver
    import signal
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa, padding
    from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
    import psycopg2
    from psycopg2.extras import RealDictCursor
except ImportError as e:
    print(f"Eksik kütüphane: {e}")
    print("Kurulum için: pip install -r requirements.txt")
    sys.exit(1)

class LogMasterCollector:
    """Ana log toplama sınıfı"""
    
    def __init__(self, config_file: str = "/opt/logmaster/config/main.conf"):
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
        
        # Temel ayarları al
        self.log_base_path = self.config.get('SYSTEM', 'log_base_path')
        self.device_count = self.config.getint('SYSTEM', 'device_count')
        self.syslog_port = self.config.getint('NETWORK', 'syslog_port')
        
        # Cihaz eşleştirme dosyasını yükle
        mapping_file = self.config.get('NETWORK', 'device_mapping_file')
        with open(mapping_file, 'r', encoding='utf-8') as f:
            self.device_mapping = json.load(f)
        
        # Logging ayarları
        self.setup_logging()
        
        # Veritabanı bağlantısı
        self.setup_database()
        
        # Dizinleri oluştur
        self.create_directories()
        
        # İstatistikler
        self.stats = {
            'logs_received': 0,
            'logs_processed': 0,
            'errors': 0,
            'start_time': datetime.now()
        }
        
        self.logger.info("LogMaster Collector başlatıldı")
    
    def setup_logging(self):
        """Logging sistemini ayarla"""
        log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        logging.basicConfig(
            level=logging.INFO,
            format=log_format,
            handlers=[
                logging.FileHandler('/var/log/logmaster/collector.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger('LogMasterCollector')
    
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
    
    def create_directories(self):
        """Gerekli dizinleri oluştur"""
        base_dirs = [
            self.log_base_path,
            self.config.get('SYSTEM', 'signed_path'),
            self.config.get('SYSTEM', 'archived_path'),
            self.config.get('SYSTEM', 'temp_path'),
            '/var/log/logmaster'
        ]
        
        for directory in base_dirs:
            Path(directory).mkdir(parents=True, exist_ok=True)
        
        # Cihaz bazlı klasörler oluştur
        for i in range(1, self.device_count + 1):
            device_dir = f"{self.log_base_path}/device-{i:03d}"
            Path(device_dir).mkdir(parents=True, exist_ok=True)
        
        self.logger.info(f"{self.device_count} cihaz klasörü oluşturuldu")
    
    def identify_device(self, source_ip: str) -> Optional[str]:
        """IP adresinden cihaz ID'sini belirle"""
        # Doğrudan eşleştirme
        if source_ip in self.device_mapping['devices']:
            return self.device_mapping['devices'][source_ip]['device_id']
        
        # IP aralığı kontrolü
        import ipaddress
        source_addr = ipaddress.ip_address(source_ip)
        
        for network, config in self.device_mapping['ip_ranges'].items():
            if source_addr in ipaddress.ip_network(network):
                if config.get('auto_assign', False):
                    # Otomatik cihaz ID ataması
                    device_id = f"{config['device_prefix']}{source_ip.replace('.', '-')}"
                    return device_id
        
        return None
    
    def parse_syslog_message(self, data: bytes, addr: tuple) -> Dict:
        """Syslog mesajını parse et"""
        try:
            message = data.decode('utf-8', errors='ignore').strip()
            timestamp = datetime.now()
            source_ip = addr[0]
            
            # Cihaz kimliğini belirle
            device_id = self.identify_device(source_ip)
            if not device_id:
                device_id = f"unknown-{source_ip.replace('.', '-')}"
            
            return {
                'timestamp': timestamp,
                'source_ip': source_ip,
                'device_id': device_id,
                'raw_message': message,
                'size': len(data)
            }
        except Exception as e:
            self.logger.error(f"Mesaj parse hatası: {e}")
            return None
    
    def get_daily_log_file(self, device_id: str, date: datetime = None) -> str:
        """Günlük log dosyası yolunu al"""
        if date is None:
            date = datetime.now()
        
        date_str = date.strftime('%Y-%m-%d')
        return f"{self.log_base_path}/{device_id}/{date_str}.log"
    
    async def write_log_entry(self, log_data: Dict):
        """Log girişini dosyaya yaz"""
        try:
            device_id = log_data['device_id']
            log_file = self.get_daily_log_file(device_id)
            
            # Günlük format
            timestamp_str = log_data['timestamp'].strftime('%Y-%m-%d %H:%M:%S.%f')
            log_line = f"{timestamp_str} | {log_data['source_ip']} | {log_data['raw_message']}\n"
            
            # Asenkron dosya yazma
            async with aiofiles.open(log_file, 'a', encoding='utf-8') as f:
                await f.write(log_line)
            
            # Veritabanına metadata kaydet
            if self.db_conn:
                await self.save_log_metadata(log_data)
            
            self.stats['logs_processed'] += 1
            
        except Exception as e:
            self.logger.error(f"Log yazma hatası: {e}")
            self.stats['errors'] += 1
    
    async def save_log_metadata(self, log_data: Dict):
        """Log metadata'sını veritabanına kaydet"""
        try:
            cursor = self.db_conn.cursor()
            
            query = """
                INSERT INTO log_entries 
                (timestamp, device_id, source_ip, message_hash, file_path, size)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            
            # Mesaj hash'i oluştur
            message_hash = hashlib.sha256(
                log_data['raw_message'].encode('utf-8')
            ).hexdigest()
            
            file_path = self.get_daily_log_file(log_data['device_id'])
            
            cursor.execute(query, (
                log_data['timestamp'],
                log_data['device_id'],
                log_data['source_ip'],
                message_hash,
                file_path,
                log_data['size']
            ))
            
            self.db_conn.commit()
            cursor.close()
            
        except Exception as e:
            self.logger.error(f"Metadata kaydetme hatası: {e}")
    
    def print_stats(self):
        """İstatistikleri yazdır"""
        uptime = datetime.now() - self.stats['start_time']
        print(f"\n--- LogMaster İstatistikleri ---")
        print(f"Çalışma süresi: {uptime}")
        print(f"Alınan loglar: {self.stats['logs_received']}")
        print(f"İşlenen loglar: {self.stats['logs_processed']}")
        print(f"Hatalar: {self.stats['errors']}")
        
        if self.stats['logs_processed'] > 0:
            rate = self.stats['logs_processed'] / uptime.total_seconds()
            print(f"İşleme hızı: {rate:.2f} log/saniye")

class SyslogHandler(socketserver.BaseRequestHandler):
    """Syslog mesajlarını işleyen handler"""
    
    def __init__(self, request, client_address, server, collector):
        self.collector = collector
        super().__init__(request, client_address, server)
    
    def handle(self):
        """Gelen syslog mesajını işle"""
        try:
            data = self.request[0]
            socket = self.request[1]
            
            # Log verisini parse et
            log_data = self.collector.parse_syslog_message(data, self.client_address)
            
            if log_data:
                # Asenkron olarak işle
                asyncio.create_task(self.collector.write_log_entry(log_data))
                self.collector.stats['logs_received'] += 1
            
        except Exception as e:
            self.collector.logger.error(f"Handler hatası: {e}")

def signal_handler(signum, frame):
    """Sistem sinyallerini işle"""
    print("\nLogMaster kapatılıyor...")
    sys.exit(0)

def main():
    """Ana fonksiyon"""
    print("LogMaster - 5651 Kanunu Uyumlu Log Toplama Sistemi")
    print("=" * 50)
    
    # Sinyal işleyicileri
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        # Collector oluştur
        collector = LogMasterCollector()
        
        # Syslog server oluştur
        class SyslogServer(socketserver.ThreadingUDPServer):
            def __init__(self, server_address, handler_class, collector):
                self.collector = collector
                super().__init__(server_address, handler_class)
            
            def finish_request(self, request, client_address):
                self.RequestHandlerClass(request, client_address, self, self.collector)
        
        server = SyslogServer(
            ('0.0.0.0', collector.syslog_port),
            SyslogHandler,
            collector
        )
        
        print(f"Syslog server {collector.syslog_port} portunda dinleniyor...")
        
        # İstatistik yazdırma thread'i
        def stats_printer():
            while True:
                time.sleep(300)  # 5 dakikada bir
                collector.print_stats()
        
        stats_thread = threading.Thread(target=stats_printer, daemon=True)
        stats_thread.start()
        
        # Server'ı başlat
        server.serve_forever()
        
    except KeyboardInterrupt:
        print("\nLogMaster kapatılıyor...")
    except Exception as e:
        print(f"Kritik hata: {e}")
        sys.exit(1)
    finally:
        if 'server' in locals():
            server.shutdown()
        print("LogMaster kapatıldı.")

if __name__ == "__main__":
    main() 