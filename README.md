# Paranette

**Yapay Zeka Destekli Kişisel Finans Asistanı**

BTK Akademi Hackathon 2026 — Agentic Fintech uygulaması. Türk bankalarından veri çeker, harcama kalıplarını analiz eder, bütçe/hedef/yatırım takibi yapar ve 11 uzman AI ajanıyla sohbet eden bir finans asistanı sunar.

---

## Özellikler

| Modül | Açıklama |
|---|---|
| Banka Bağlantıları | 4 Türk bankası (Ziraat, Garanti, İşbank, Akbank) simülasyonu, otomatik senkronizasyon |
| Dashboard | Bakiye özeti, harcama kategorileri, AI önerileri, finansal sağlık skoru |
| İşlemler | Çok para birimli, anomali skoru, OCR fiş okuma, otomatik kategori |
| Bütçe & Hedefler | AI destekli bütçe önerisi, tasarruf hedefi takibi |
| AI Finans Asistanı | 11 uzman ajanla (BudgetAdvisor, AnomalyDetector, Negotiation vb.) doğal dil sohbet |
| Karar Simülatörü | 3–12 aylık projeksiyon, reel/nominal bakiye karşılaştırması |
| Enflasyon Takibi | Kişisel enflasyon endeksi vs. resmi TÜFE |
| Müzakere Ajanı | Faiz indirimi ve borç yeniden yapılandırma için AI mektubu üretici |
| Yatırım Portföyü | Altın, döviz, kripto, BIST, fon — canlı fiyatlarla |
| Kur & Altın Alarmları | Eşik tabanlı anlık uyarılar |
| Faturalar & Abonelikler | 8 fatura türü, otomatik abonelik tespiti |
| Raporlar | Aylık özet JSON + PDF |
| Finansal Takvim | Ödeme, taksit, kart ekstresi tek görünümde |

---

## Teknik Altyapı

| Katman | Teknoloji |
|---|---|
| Backend | Laravel 13.7, PHP 8.3 |
| Veritabanı | MySQL 8 |
| AI | Google Gemini 1.5 Pro / Flash / Vision |
| Mobil | Flutter 3.x, Riverpod, GoRouter, Dio |
| Launcher | Go 1.22 (cross-platform) |
| Kimlik Doğrulama | Laravel Sanctum (Bearer Token) |

---

## Kurulum

### Gereksinimler

| Araç | Minimum Versiyon | İndir |
|---|---|---|
| WAMP64 (Windows) / LAMP (Linux) | PHP 8.2+, MySQL 8 | [wampserver.com](https://www.wampserver.com) |
| Flutter SDK | 3.19+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Android Studio | Ladybug+ | [developer.android.com](https://developer.android.com/studio) |
| Go | 1.22+ (sadece launcher derlemek için) | [go.dev](https://go.dev/dl) |

---

### Otomatik Kurulum (Önerilen)

`launcher/build/` dizininden platformunuza uygun binary'yi çalıştırın:

| Platform | Dosya |
|---|---|
| Windows 64-bit | `paranette-windows-amd64.exe` |
| Linux x86-64 | `paranette-linux-amd64` |
| Linux ARM64 | `paranette-linux-arm64` |
| macOS Intel | `paranette-macos-intel` |
| macOS Apple Silicon | `paranette-macos-arm64` |

Launcher şunları otomatik yapar:
1. PHP / MySQL / Flutter / ADB yollarını otomatik bulur
2. MySQL hazır değilse WAMP'ı başlatır ve bekler
3. `php artisan serve` ile Laravel'i başlatır
4. API bağlantı modunu sorar (emülatör / gerçek cihaz / manuel IP)
5. Mevcut AVD listesini gösterir, seçilen emülatörü başlatır ve boot'u bekler
6. `--dart-define=API_HOST=<seçilen_ip>` ile Flutter uygulamasını başlatır

---

### Manuel Kurulum

#### 1. Web (Laravel)

```bash
cd web
cp .env.example .env
# .env içinde DB_DATABASE, DB_USERNAME, DB_PASSWORD, GEMINI_API_KEY değerlerini doldurun
composer install
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=127.0.0.1 --port=8000
```

#### 2. Mobil (Flutter)

```bash
cd mobile
flutter pub get
# Emülatör için (varsayılan):
flutter run --dart-define=API_HOST=10.0.2.2
# Gerçek cihaz için (PC'nin yerel IP'si):
flutter run --dart-define=API_HOST=192.168.x.x
```

#### 3. `.env` Zorunlu Değerler

```env
DB_DATABASE=paranette
DB_USERNAME=root
DB_PASSWORD=          # WAMP varsayılan: boş
GEMINI_API_KEY=       # Google AI Studio'dan alın
# veya birden fazla key için:
GEMINI_API_KEYS=key1,key2,key3
```

---

## Test Rehberi

### Hızlı Test Akışı (Sırayla)

**1. Kayıt & Giriş**
- Uygulamayı aç → "Kayıt Ol" → ad, e-posta, şifre gir
- Giriş yap → Dashboard'a yönlendirme kontrol et

**2. Banka Bağlantısı**
- Sol menü → "Banka Bağlantıları" → "Banka Ekle"
- Ziraat / Garanti / İşbank / Akbank seç
- Test kimlik bilgileri: herhangi bir kullanıcı adı/şifre (simülasyon)
- "Senkronize Et" — işlemlerin yüklendiğini kontrol et

**3. Dashboard**
- Bakiye kartları, harcama grafiği görünür mü?
- AI Önerisi kartları dolu mu? (boşsa 10–15 sn bekle, otomatik yüklenir)
- Finansal Sağlık Skoru görünüyor mu?

**4. İşlemler**
- Sol menü → "İşlemler" → liste geldi mi?
- Fiş yükle: sağ üst "+" → kamera/galeri → fotoğraf seç → OCR sonucunu kontrol et

**5. AI Finans Asistanı**
- Sol menü → "Finans Asistanı"
- Örnek soru: *"Bu ay en çok nereye harcadım?"*
- Örnek soru: *"Bütçemi nasıl optimize edebilirim?"*
- Yanıt 10–20 saniye içinde gelmeli

**6. Bütçe & Hedefler**
- Sol menü → "Bütçe" → "AI Öner" butonuna bas → öneri kabul et
- Sol menü → "Hedefler" → "Hedef Ekle" → ilerleme takibi

**7. Müzakere Ajanı**
- Sol menü → "Müzakere" → senaryo seç (örn: kredi faizi indirimi)
- "Mektup Oluştur" → AI mektubunu kontrol et

**8. Yatırımlar & Kur Alarmları**
- Sol menü → "Yatırımlar" → portföy gör
- Sol menü → "Kur Alarmları" → alarm ekle

**9. Raporlar**
- Sol menü → "Raporlar" → aylık özet
- "PDF İndir" → dosya geldi mi kontrol et

**10. Profil**
- Sağ üst avatar → "Profil" → bilgi güncelle → kaydet

---

## Proje Yapısı

```
btk-hackathon-2026/
├── web/                    # Laravel 13.7 backend
│   ├── app/
│   │   ├── Http/Controllers/Api/   # REST API controller'ları
│   │   └── Services/Agents/        # AI ajan altyapısı
│   ├── database/migrations/
│   └── routes/api.php
├── mobile/                 # Flutter uygulaması
│   └── lib/
│       ├── core/           # API, router, tema, widget'lar
│       └── features/       # 22 özellik modülü
├── launcher/               # Go cross-platform başlatıcı
│   ├── main.go
│   ├── platform_windows.go
│   ├── platform_unix.go
│   └── build/              # Derlenmiş binary'ler
└── docs/                   # Ek belgeler
```

---

## Takım

| Kişi | Rol |
|---|---|
| Ethem Demirkaya | Backend (Laravel, AI Ajanlar) |
| Sinem | Mobil (Flutter) |

---

## Lisans

Bu proje BTK Akademi Hackathon 2026 kapsamında geliştirilmiştir.
