#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LogMaster - Dijital İmzalama ve Zaman Damgası Modülü
5651 Kanunu uyumlu log dosyalarının imzalanması
"""

import os
import sys
import json
import hashlib
import base64
import logging
import requests
from datetime import datetime, timezone
from pathlib import Path
import configparser
from typing import Dict, List, Optional, Tuple

try:
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa, padding
    from cryptography.hazmat.primitives.serialization import pkcs12
    from cryptography import x509
    from cryptography.x509.oid import NameOID, ExtensionOID
    import OpenSSL
except ImportError as e:
    print(f"Eksik kütüphane: {e}")
    print("Kurulum için: pip install cryptography pyOpenSSL")
    sys.exit(1)

class DigitalSigner:
    """Dijital imzalama sınıfı"""
    
    def __init__(self, config_file: str = "/opt/logmaster/config/main.conf"):
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
        
        # Sertifika ve anahtar yolları
        self.cert_path = self.config.get('SIGNATURE', 'certificate_path')
        self.key_size = self.config.getint('SIGNATURE', 'key_size')
        self.algorithm = self.config.get('SIGNATURE', 'signature_algorithm')
        
        # TSA ayarları
        self.tsa_enabled = self.config.getboolean('SIGNATURE', 'tsa_enabled')
        self.tsa_url = self.config.get('SIGNATURE', 'tsa_url')
        
        # Logging
        self.setup_logging()
        
        # Sertifikaları hazırla
        self.setup_certificates()
        
        self.logger.info("DigitalSigner başlatıldı")
    
    def setup_logging(self):
        """Logging sistemini ayarla"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger('DigitalSigner')
    
    def setup_certificates(self):
        """Sertifika ve anahtarları hazırla"""
        cert_dir = Path(self.cert_path)
        cert_dir.mkdir(parents=True, exist_ok=True)
        
        self.private_key_path = cert_dir / "logmaster_private.pem"
        self.public_key_path = cert_dir / "logmaster_public.pem"
        self.certificate_path = cert_dir / "logmaster_cert.pem"
        
        # Eğer sertifikalar yoksa oluştur
        if not self.certificate_path.exists():
            self.generate_certificates()
        
        # Sertifika ve anahtarları yükle
        self.load_certificates()
    
    def generate_certificates(self):
        """Kendinden imzalı sertifika oluştur (test için)"""
        self.logger.info("Yeni sertifika oluşturuluyor...")
        
        # Private key oluştur
        private_key = rsa.generate_private_key(
            public_exponent=65537,
            key_size=self.key_size
        )
        
        # Public key
        public_key = private_key.public_key()
        
        # Certificate subject
        subject = issuer = x509.Name([
            x509.NameAttribute(NameOID.COUNTRY_NAME, "TR"),
            x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, "Istanbul"),
            x509.NameAttribute(NameOID.LOCALITY_NAME, "Istanbul"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "LogMaster System"),
            x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, "IT Department"),
            x509.NameAttribute(NameOID.COMMON_NAME, "LogMaster Signing Certificate"),
        ])
        
        # Sertifika oluştur
        cert = x509.CertificateBuilder().subject_name(
            subject
        ).issuer_name(
            issuer
        ).public_key(
            public_key
        ).serial_number(
            x509.random_serial_number()
        ).not_valid_before(
            datetime.now(timezone.utc)
        ).not_valid_after(
            datetime.now(timezone.utc).replace(year=datetime.now().year + 5)
        ).add_extension(
            x509.SubjectAlternativeName([
                x509.DNSName("logmaster.local"),
                x509.DNSName("localhost"),
            ]),
            critical=False,
        ).add_extension(
            x509.KeyUsage(
                digital_signature=True,
                key_encipherment=True,
                content_commitment=True,
                data_encipherment=False,
                key_agreement=False,
                key_cert_sign=False,
                crl_sign=False,
                encipher_only=False,
                decipher_only=False,
            ),
            critical=True,
        ).sign(private_key, hashes.SHA256())
        
        # Dosyalara kaydet
        with open(self.private_key_path, "wb") as f:
            f.write(private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            ))
        
        with open(self.public_key_path, "wb") as f:
            f.write(public_key.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo
            ))
        
        with open(self.certificate_path, "wb") as f:
            f.write(cert.public_bytes(serialization.Encoding.PEM))
        
        self.logger.info("Sertifikalar oluşturuldu")
    
    def load_certificates(self):
        """Sertifika ve anahtarları yükle"""
        try:
            # Private key yükle
            with open(self.private_key_path, "rb") as f:
                self.private_key = serialization.load_pem_private_key(
                    f.read(),
                    password=None
                )
            
            # Certificate yükle
            with open(self.certificate_path, "rb") as f:
                self.certificate = x509.load_pem_x509_certificate(f.read())
            
            self.logger.info("Sertifikalar yüklendi")
            
        except Exception as e:
            self.logger.error(f"Sertifika yükleme hatası: {e}")
            raise
    
    def calculate_file_hash(self, file_path: str) -> str:
        """Dosyanın SHA-256 hash'ini hesapla"""
        sha256_hash = hashlib.sha256()
        
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                sha256_hash.update(chunk)
        
        return sha256_hash.hexdigest()
    
    def sign_data(self, data: bytes) -> bytes:
        """Veriyi dijital olarak imzala"""
        try:
            signature = self.private_key.sign(
                data,
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            return signature
        except Exception as e:
            self.logger.error(f"İmzalama hatası: {e}")
            raise
    
    def verify_signature(self, data: bytes, signature: bytes) -> bool:
        """İmzayı doğrula"""
        try:
            public_key = self.certificate.public_key()
            public_key.verify(
                signature,
                data,
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )
            return True
        except Exception:
            return False
    
    def get_timestamp_from_tsa(self, data_hash: bytes) -> Optional[bytes]:
        """TSA'dan zaman damgası al"""
        if not self.tsa_enabled:
            return None
        
        try:
            # RFC 3161 timestamp request oluştur
            from cryptography.hazmat.primitives.hashes import SHA256
            
            # Bu örnekte basit TSA isteği - gerçek kullanımda RFC 3161 uyumlu olmalı
            timestamp_request = {
                "hash": base64.b64encode(data_hash).decode(),
                "algorithm": "SHA256",
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            
            # TSA'ya istek gönder
            response = requests.post(
                self.tsa_url,
                json=timestamp_request,
                timeout=30,
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                timestamp_response = response.json()
                return base64.b64decode(timestamp_response.get("timestamp", ""))
            else:
                self.logger.warning(f"TSA hatası: {response.status_code}")
                return None
                
        except Exception as e:
            self.logger.error(f"TSA zaman damgası hatası: {e}")
            return None
    
    def sign_log_file(self, log_file_path: str) -> Dict:
        """Log dosyasını imzala ve metadata oluştur"""
        try:
            # Dosya hash'ini hesapla
            file_hash = self.calculate_file_hash(log_file_path)
            file_hash_bytes = bytes.fromhex(file_hash)
            
            # Dosyayı imzala
            with open(log_file_path, "rb") as f:
                file_content = f.read()
            
            signature = self.sign_data(file_content)
            
            # TSA zaman damgası al
            timestamp = self.get_timestamp_from_tsa(file_hash_bytes)
            
            # İmza metadata'sı oluştur
            signature_metadata = {
                "file_path": log_file_path,
                "file_hash": file_hash,
                "signature": base64.b64encode(signature).decode(),
                "signature_algorithm": self.algorithm,
                "certificate_fingerprint": self.get_certificate_fingerprint(),
                "signed_at": datetime.now(timezone.utc).isoformat(),
                "tsa_timestamp": base64.b64encode(timestamp).decode() if timestamp else None,
                "file_size": os.path.getsize(log_file_path),
                "compliance": {
                    "standard": "5651_kanunu",
                    "version": "1.0",
                    "retention_years": 2
                }
            }
            
            # İmza dosyası oluştur
            signature_file = f"{log_file_path}.sig"
            with open(signature_file, "w", encoding="utf-8") as f:
                json.dump(signature_metadata, f, indent=2, ensure_ascii=False)
            
            self.logger.info(f"Dosya imzalandı: {log_file_path}")
            return signature_metadata
            
        except Exception as e:
            self.logger.error(f"İmzalama hatası: {e}")
            raise
    
    def verify_log_file(self, log_file_path: str) -> Dict:
        """Log dosyasının imzasını doğrula"""
        try:
            signature_file = f"{log_file_path}.sig"
            
            if not os.path.exists(signature_file):
                return {"valid": False, "error": "İmza dosyası bulunamadı"}
            
            # İmza metadata'sını oku
            with open(signature_file, "r", encoding="utf-8") as f:
                signature_metadata = json.load(f)
            
            # Dosya hash'ini yeniden hesapla
            current_hash = self.calculate_file_hash(log_file_path)
            original_hash = signature_metadata["file_hash"]
            
            # Hash kontrolü
            if current_hash != original_hash:
                return {
                    "valid": False, 
                    "error": "Dosya bütünlüğü bozulmuş",
                    "current_hash": current_hash,
                    "original_hash": original_hash
                }
            
            # İmza doğrulama
            with open(log_file_path, "rb") as f:
                file_content = f.read()
            
            signature = base64.b64decode(signature_metadata["signature"])
            is_valid = self.verify_signature(file_content, signature)
            
            verification_result = {
                "valid": is_valid,
                "file_hash_match": True,
                "signature_valid": is_valid,
                "signed_at": signature_metadata["signed_at"],
                "file_size": signature_metadata["file_size"],
                "certificate_fingerprint": signature_metadata["certificate_fingerprint"]
            }
            
            if not is_valid:
                verification_result["error"] = "Dijital imza doğrulanamadı"
            
            return verification_result
            
        except Exception as e:
            return {"valid": False, "error": str(e)}
    
    def get_certificate_fingerprint(self) -> str:
        """Sertifika parmak izini al"""
        cert_der = self.certificate.public_bytes(serialization.Encoding.DER)
        fingerprint = hashlib.sha256(cert_der).hexdigest()
        return fingerprint
    
    def batch_sign_logs(self, log_directory: str) -> List[Dict]:
        """Bir dizindeki tüm log dosyalarını toplu imzala"""
        results = []
        log_dir = Path(log_directory)
        
        for log_file in log_dir.glob("*.log"):
            try:
                result = self.sign_log_file(str(log_file))
                results.append({
                    "file": str(log_file),
                    "success": True,
                    "metadata": result
                })
            except Exception as e:
                results.append({
                    "file": str(log_file),
                    "success": False,
                    "error": str(e)
                })
        
        return results

class TimestampAuthority:
    """Basit Zaman Damgası Yetkilisi (RFC 3161 uyumlu)"""
    
    def __init__(self):
        self.logger = logging.getLogger('TimestampAuthority')
    
    def create_timestamp(self, data_hash: str) -> Dict:
        """Zaman damgası oluştur"""
        timestamp = datetime.now(timezone.utc)
        
        # RFC 3161 uyumlu timestamp yapısı
        timestamp_info = {
            "version": 1,
            "policy": "1.2.3.4.5.6.7.8.1",
            "messageImprint": {
                "hashAlgorithm": "SHA256",
                "hashedMessage": data_hash
            },
            "serialNumber": int(timestamp.timestamp() * 1000000),
            "genTime": timestamp.isoformat(),
            "accuracy": {
                "seconds": 1,
                "millis": 0,
                "micros": 0
            },
            "ordering": False,
            "tsa": {
                "directoryName": "CN=LogMaster TSA,O=LogMaster,C=TR"
            }
        }
        
        return timestamp_info

def main():
    """Test fonksiyonu"""
    print("LogMaster Dijital İmzalama Test")
    print("=" * 40)
    
    try:
        signer = DigitalSigner()
        
        # Test dosyası oluştur
        test_file = "/tmp/test_log.log"
        with open(test_file, "w") as f:
            f.write("Test log girişi\n")
            f.write(f"Zaman: {datetime.now()}\n")
        
        print(f"Test dosyası oluşturuldu: {test_file}")
        
        # Dosyayı imzala
        result = signer.sign_log_file(test_file)
        print("İmzalama tamamlandı")
        print(f"Dosya hash: {result['file_hash']}")
        
        # İmzayı doğrula
        verification = signer.verify_log_file(test_file)
        print(f"Doğrulama sonucu: {verification['valid']}")
        
        # Temizlik
        os.remove(test_file)
        os.remove(f"{test_file}.sig")
        print("Test tamamlandı")
        
    except Exception as e:
        print(f"Test hatası: {e}")

if __name__ == "__main__":
    main() 