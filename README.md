<div align="center">

# Paranette

### Yapay Zeka Destekli Kişisel Finans Asistanı

[![Laravel](https://img.shields.io/badge/Laravel-13.7-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)](https://laravel.com)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Gemini](https://img.shields.io/badge/Gemini_AI-2.5_Pro-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://mysql.com)

**BTK Akademi Hackathon 2026**

Türk bankalarından veri çeken, harcamalarını analiz eden, bütçe/hedef/yatırım takibi yapan ve 11 uzman AI ajanıyla sohbet eden kişisel finans asistanı.

</div>

---

## Mobil Uygulama Ekran Görüntüleri

<div align="center">
<table>
  <tr>
    <td align="center"><img src="docs/screenshots/01-dashboard.png" width="180"/><br/><sub><b>Dashboard</b></sub></td>
    <td align="center"><img src="docs/screenshots/02-ai-chat.png" width="180"/><br/><sub><b>AI Finans Asistanı</b></sub></td>
    <td align="center"><img src="docs/screenshots/03-transactions.png" width="180"/><br/><sub><b>İşlemler</b></sub></td>
    <td align="center"><img src="docs/screenshots/04-budget.png" width="180"/><br/><sub><b>Bütçe & Hedefler</b></sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/05-investments.png" width="180"/><br/><sub><b>Yatırım Portföyü</b></sub></td>
    <td align="center"><img src="docs/screenshots/06-negotiation.png" width="180"/><br/><sub><b>Müzakere Ajanı</b></sub></td>
    <td align="center"><img src="docs/screenshots/07-simulator.png" width="180"/><br/><sub><b>Karar Simülatörü</b></sub></td>
    <td align="center"><img src="docs/screenshots/08-reports.png" width="180"/><br/><sub><b>Raporlar</b></sub></td>
  </tr>
</table>
</div>

---

## Özellikler

<div align="center">

| Modül | Açıklama |
|:---|:---|
| **Banka Bağlantıları** | 4 Türk bankası (Ziraat, Garanti, İşbank, Akbank) simülasyonu, otomatik senkronizasyon |
| **Dashboard** | Bakiye özeti, harcama kategorileri, AI önerileri, finansal sağlık skoru |
| **İşlemler & Fiş OCR** | Çok para birimli, anomali skoru, kamera ile fiş okuma, otomatik kategori |
| **Bütçe & Hedefler** | AI destekli bütçe önerisi, tasarruf hedefi takibi |
| **AI Finans Asistanı** | 11 uzman ajanla (BudgetAdvisor, AnomalyDetector, Negotiation vb.) doğal dil sohbet |
| **Karar Simülatörü** | 3–12 aylık projeksiyon, reel/nominal bakiye karşılaştırması |
| **Enflasyon Takibi** | Kişisel enflasyon endeksi vs. resmi TÜFE |
| **Müzakere Ajanı** | Faiz indirimi ve borç yeniden yapılandırma için AI mektubu üretici |
| **Yatırım Portföyü** | Altın, döviz, kripto, BIST, fon — canlı fiyatlarla |
| **Kur & Altın Alarmları** | Eşik tabanlı anlık uyarılar |
| **Faturalar & Abonelikler** | 8 fatura türü, otomatik abonelik tespiti |
| **Raporlar** | Aylık özet JSON + PDF |
| **Finansal Takvim** | Ödeme, taksit, kart ekstresi tek görünümde |

</div>

---

## Teknik Altyapı

<div align="center">

| Katman | Teknoloji |
|:---:|:---:|
| Backend | Laravel 13.7 · PHP 8.3 |
| Veritabanı | MySQL 8 |
| Yapay Zeka | Google Gemini 1.5 Pro / Flash / Vision |
| Mobil | Flutter 3.x · Riverpod · GoRouter · Dio |
| Launcher | Go 1.22 (Windows / Linux / macOS) |
| Kimlik Doğrulama | Laravel Sanctum Bearer Token |

</div>

---

## Kurulum

### Gereksinimler

| Araç | Versiyon | İndir |
|:---|:---:|:---|
| WAMP64 (Windows) / LAMP (Linux/macOS) | PHP 8.2+ · MySQL 8 | [wampserver.com](https://www.wampserver.com) |
| Flutter SDK | 3.19+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Android Studio + AVD | Ladybug+ | [developer.android.com](https://developer.android.com/studio) |
| Go *(sadece launcher derlemek için)* | 1.22+ | [go.dev](https://go.dev/dl) |

---

### Otomatik Kurulum (Önerilen)

`launcher/build/` dizininden platformunuza uygun binary'yi çalıştırın:

| Platform | Dosya |
|:---|:---|
| Windows 64-bit | `paranette-windows-amd64.exe` |
| Linux x86-64 | `paranette-linux-amd64` |
| Linux ARM64 | `paranette-linux-arm64` |
| macOS Intel | `paranette-macos-intel` |
| macOS Apple Silicon | `paranette-macos-arm64` |

Launcher tek seferde şunları yapar:

```
1. PHP / MySQL / Flutter / ADB yollarını otomatik bulur
2. MySQL hazır değilse WAMP'ı başlatır ve bekler
3. php artisan serve ile Laravel'i http://127.0.0.1:8000 adresinde başlatır
4. API bağlantı modunu sorar  →  emülatör / gerçek cihaz / manuel IP
5. Mevcut AVD listesini gösterir, seçilen emülatörü başlatır ve boot'u bekler
6. --dart-define=API_HOST ile Flutter uygulamasını çalıştırır
```

---

### Manuel Kurulum

<details>
<summary><strong>1. Web (Laravel)</strong></summary>

```bash
cd web
cp .env.example .env
# .env içinde DB_DATABASE, DB_USERNAME, DB_PASSWORD, GEMINI_API_KEY değerlerini doldurun
composer install
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=127.0.0.1 --port=8000
```

</details>

<details>
<summary><strong>2. Mobil (Flutter)</strong></summary>

```bash
cd mobile
flutter pub get

# Emülatör için (varsayılan):
flutter run --dart-define=API_HOST=10.0.2.2

# Gerçek cihaz için (PC'nin yerel IP'si):
flutter run --dart-define=API_HOST=192.168.x.x
```

</details>

<details>
<summary><strong>3. .env Zorunlu Değerler</strong></summary>

```env
DB_DATABASE=paranette
DB_USERNAME=root
DB_PASSWORD=              # WAMP varsayılan: boş
GEMINI_API_KEY=           # Google AI Studio'dan alın: aistudio.google.com
# Birden fazla key için (round-robin):
GEMINI_API_KEYS=key1,key2,key3
```

</details>

---

## Test Rehberi

<details>
<summary><strong>Hızlı Test Akışı — adım adım aç</strong></summary>

**1 · Kayıt & Giriş**
- Uygulamayı aç → "Kayıt Ol" → ad, e-posta, şifre gir
- Giriş yap → Dashboard'a yönlendirme kontrol et

**2 · Banka Bağlantısı**
- Sol menü → "Banka Bağlantıları" → "Banka Ekle"
- Ziraat / Garanti / İşbank / Akbank seç (herhangi bir kimlik bilgisi — simülasyon)
- "Senkronize Et" → işlemlerin listelendiğini gör

**3 · Dashboard**
- Bakiye kartları ve harcama grafiği görünüyor mu?
- AI Önerisi kartları dolu mu? (boşsa 10–15 sn bekle, otomatik yüklenir)
- Finansal Sağlık Skoru görünüyor mu?

**4 · İşlemler + Fiş OCR**
- Sol menü → "İşlemler" → liste yüklendi mi?
- Sağ üst "+" → fotoğraf seç → OCR'ın kategori ve tutarı okuduğunu kontrol et

**5 · AI Finans Asistanı**
- Sol menü → "Finans Asistanı"
- Yaz: *"Bu ay en çok nereye harcadım ve ne yapmalıyım?"*
- 10–20 saniye içinde detaylı yanıt gelmeli

**6 · Bütçe & Hedefler**
- "Bütçe" → "AI Öner" butonuna bas → öneriyi kabul et
- "Hedefler" → "Hedef Ekle" → ilerleme yüzdesi görünüyor mu?

**7 · Müzakere Ajanı**
- "Müzakere" → "Kredi Faizi İndirimi" seç → "Mektup Oluştur"
- AI'nin oluşturduğu resmi mektubu gör

**8 · Yatırımlar & Kur Alarmları**
- "Yatırımlar" → portföy sayfası açılıyor mu?
- "Kur Alarmları" → dolar için eşik değer gir, alarm kaydedildi mi?

**9 · Raporlar**
- "Raporlar" → aylık özet yüklendi mi?
- "PDF İndir" → dosya geldi mi?

**10 · Profil**
- Sağ üst avatar → "Profil" → bilgi güncelle → kaydet
- Geri çık, tekrar gir → değişiklik kaydedilmiş mi?

</details>

---

## Proje Yapısı

```
btk-hackathon-2026/
├── web/                        # Laravel 13.7 backend
│   ├── app/
│   │   ├── Http/Controllers/Api/    # 19 REST API controller
│   │   └── Services/Agents/         # 11 AI ajan servisi
│   ├── database/migrations/
│   └── routes/api.php
├── mobile/                     # Flutter uygulaması
│   └── lib/
│       ├── core/                    # API, router, tema, widget'lar
│       └── features/                # 22 özellik modülü
├── launcher/                   # Go cross-platform başlatıcı
│   ├── main.go
│   ├── platform_windows.go
│   ├── platform_unix.go
│   └── build/                       # Derlenmiş binary'ler (5 platform)
└── docs/
    └── screenshots/                 # Uygulama ekran görüntüleri
```

---

## Takım

<div align="center">

| | Kişi | Rol |
|:---:|:---|:---|
| | **Ethem Demirkaya** | Backend · Laravel · AI Ajanlar |
| | **Sinem** | Mobil · Flutter |

</div>

---

<div align="center">

**BTK Akademi Hackathon 2026 — Paranette**

*Finansal özgürlüğün yapay zeka ile buluştuğu yer.*

</div>
