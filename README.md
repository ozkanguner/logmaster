# LogMaster - 5651 Kanunu Uyumlu Log Yönetim Sistemi

## Genel Bakış

Bu sistem Ubuntu sunucuda 400 adet firewall cihazından gelen logları 5651 sayılı kanuna uygun şekilde toplar, imzalar ve arşivler.

## Sistem Mimarisi

```
/opt/logmaster/
├── config/                 # Konfigürasyon dosyaları
├── scripts/                # Ana işlem scriptleri
├── logs/                   # Ham log dosyaları
│   ├── device-001/         # Cihaz bazlı klasörler
│   │   ├── 2024-01-15.log
│   │   └── 2024-01-16.log
│   └── device-400/
├── signed/                 # İmzalanmış log dosyaları
├── archived/               # Arşivlenmiş dosyalar
├── certs/                  # Dijital sertifikalar
└── reports/                # Uyumluluk raporları
```

## Ana Özellikler

### 1. Log Toplama
- **Syslog Entegrasyonu**: rsyslog ile otomatik log toplama
- **Cihaz Tanıma**: IP/MAC adres bazlı cihaz kimliklemdirme
- **Real-time Processing**: Anlık log işleme

### 2. Dosya Organizasyonu
- **Cihaz Bazlı Klasörleme**: Her firewall için ayrı dizin
- **Günlük Dosyalar**: YYYY-MM-DD.log formatında
- **Otomatik Temizlik**: Eski dosyaların arşivlenmesi

### 3. 5651 Kanunu Uyumluluğu
- **Dijital İmzalama**: GPG/X.509 sertifika ile imzalama
- **Zaman Damgası**: RFC 3161 uyumlu timestamp
- **Bütünlük Kontrolü**: SHA-256 hash kontrolü
- **Erişim Logları**: Kimin ne zaman eriştiğinin kaydı

### 4. Güvenlik
- **Şifreleme**: AES-256 ile dosya şifreleme
- **Erişim Kontrolü**: RBAC tabanlı yetkilendirme
- **Audit Trail**: Tüm işlemlerin detaylı kaydı

## Kurulum Gereksinimleri

- Ubuntu 20.04+ LTS
- Python 3.8+
- rsyslog/syslog-ng
- GnuPG 2.x
- OpenSSL 1.1.1+
- PostgreSQL 12+ (log metadata için)

## Hukuki Uyumluluk

5651 sayılı kanun gereği:
- Loglar minimum 2 yıl saklanır
- Değiştirilemez formatta arşivlenir
- Dijital imza ile bütünlük korunur
- Erişim kayıtları tutulur
- Resmi makam taleplerine uygun format

## Performans Hedefleri

- **İşlem Kapasitesi**: Saniyede 10,000+ log girişi
- **Depolama**: Günlük 100GB+ log işleme
- **Gecikme**: <5 saniye log işleme süresi
- **Kullanılabilirlik**: %99.9 uptime

## Lisans

Bu proje 5651 sayılı kanun uyumluluk gereksinimleri için geliştirilmiştir. 