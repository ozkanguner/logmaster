# Log Yönetim Arayüzü Proje Planı

## 1. Teknoloji Seçimi

- **Backend:** Python (FastAPI)
  - Hızlı geliştirme, kolay bakım, güçlü API desteği.
- **Frontend:** React
  - Modern, bileşen tabanlı, geniş topluluk ve bol kaynak.
- **Veritabanı:** Elasticsearch
  - Büyük miktarda log verisi için hızlı arama ve filtreleme.
- **Kurulum:** Docker
  - Kolay dağıtım ve taşınabilirlik.

---

## 2. Genel Mimari

```
Cihazlar (rsyslog) → Ubuntu Sunucu (Loglar klasörlerde) → FastAPI (Backend/API) → Elasticsearch
                                                                                 ↓
                                                                       React (Frontend)
```

---

## 3. Adım Adım Yol Haritası

### 3.1. Backend (FastAPI)
- Log klasörlerini ve dosyalarını okuyan API endpointleri oluşturulacak.
- Elasticsearch ile entegrasyon: Loglar indekslenecek ve API üzerinden sorgulanabilecek.
- Kimlik doğrulama (JWT) eklenecek.
- Log filtreleme, arama, indirme ve silme işlemleri için endpointler hazırlanacak.

### 3.2. Frontend (React)
- Giriş ekranı (kullanıcı adı/şifre ile).
- Cihaz listesi ve log dosyası görüntüleme.
- Tarih, cihaz, anahtar kelime ile filtreleme ve arama.
- Log detaylarını gösterme, indirme ve silme butonları.
- Hata/uyarı bildirimleri için arayüzde uyarı alanı.

### 3.3. Veritabanı (Elasticsearch)
- Loglar günlük olarak otomatik indekslenecek.
- Hızlı arama ve filtreleme için uygun mapping yapılacak.

### 3.4. Dağıtım ve Kurulum
- Tüm bileşenler için Dockerfile hazırlanacak.
- docker-compose ile tek komutla kurulum sağlanacak.
- Gerekirse Nginx ile frontend ve backend yönlendirmesi yapılacak.

---

## 4. Güvenlik ve Ekstra Özellikler
- HTTPS ile güvenli bağlantı.
- Rol bazlı yetkilendirme (admin/kullanıcı).
- Performans için log rotasyonu ve arşivleme.
- (Opsiyonel) Gerçek zamanlı log güncelleme için WebSocket desteği.

---

## 5. Geliştirme Sırası (Öneri)
1. Backend API temel fonksiyonları (log okuma, listeleme, arama)
2. Elasticsearch entegrasyonu
3. Frontend temel arayüz (cihaz ve log listesi)
4. Kimlik doğrulama ve yetkilendirme
5. Log indirme/silme ve bildirimler
6. Docker ile dağıtım
7. Ekstra özellikler ve testler

---

Her adımda örnek kod veya detaylı açıklama istersen, ayrıca yardımcı olabilirim. 