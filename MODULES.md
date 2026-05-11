# Paranette — Modül & Özellik Kataloğu

> **Stack:** Laravel 13.7 · Google Gemini Pro/Flash/Vision · MySQL · Bootstrap 5 (Vuexy)  
> **Hedef kitle:** Türk bireysel kullanıcılar · **Hackathon:** TEKNOFEST 2026

---

## İçindekiler

1. [Kimlik Doğrulama & Profil](#1-kimlik-doğrulama--profil)
2. [Dashboard](#2-dashboard)
3. [Banka Bağlantıları](#3-banka-bağlantıları)
4. [Kartlar](#4-kartlar)
5. [Krediler](#5-krediler)
6. [İşlemler](#6-i̇şlemler)
7. [Kategoriler & Bütçe](#7-kategoriler--bütçe)
8. [Abonelikler](#8-abonelikler)
9. [Faturalar](#9-faturalar)
10. [Hedefler](#10-hedefler)
11. [Kişisel Borçlar (IOU)](#11-kişisel-borçlar-iou)
12. [Fişler & OCR](#12-fişler--ocr)
13. [Finansal Zeka Merkezi (AI Chat)](#13-finansal-zeka-merkezi-ai-chat)
14. [Uzman Ajanlar](#14-uzman-ajanlar)
15. [Karar Simülatörü](#15-karar-simülatörü)
16. [Enflasyon Takibi](#16-enflasyon-takibi)
17. [Finansal Sağlık Skoru](#17-finansal-sağlık-skoru)
18. [Raporlar](#18-raporlar)
19. [Müzakere Ajanı](#19-müzakere-ajanı)
20. [Yatırım Portföyü](#20-yatırım-portföyü)
21. [Kur & Altın Alarmları](#21-kur--altın-alarmları)
22. [Finansal Takvim](#22-finansal-takvim)

---

## 1. Kimlik Doğrulama & Profil

Kayıt, giriş, e-posta doğrulama, şifre sıfırlama, profil düzenleme/silme.

**Önemli alan:** `users.monthly_income` — tüm finansal hesaplamaların (sağlık skoru, simülatör, bütçe önerisi) temel girdisi.

**Teknoloji:** Laravel Breeze · Sanctum API token · Şifreli kimlik bilgisi saklama

---

## 2. Dashboard

Kullanıcının finansal tablosunu tek ekranda sunar.

| Widget | İçerik |
|--------|--------|
| Özet kartları | Net varlık · Kart borcu · Toplam kredi · Nakit akışı |
| Nakit akışı grafiği | Aylık gelir vs. gider (son 6 ay) |
| Kategori dağılımı | Harcamanın pasta grafiği |
| Bütçe özeti | Aylık limitler ve doluluk oranları |
| Aktif hedefler | İlerleme çubukları |
| Enflasyon karşılaştırması | Kişisel enflasyon vs. resmi TÜFE |
| AI öngörüleri | Ajan tarafından üretilen öneriler (dismiss edilebilir) |
| Finansal sağlık skoru | 0–100, bileşen detaylarıyla |

**Teknoloji:** `DashboardService` · `FinancialHealthScoreService` · 24 saatlik cache

---

## 3. Banka Bağlantıları

Çoklu banka entegrasyonu: hesap, kart, kredi ve işlemleri gerçek zamanlı senkronize eder.

**Desteklenen bankalar:** Ziraat · Garanti · İşbank · Akbank *(hackathon için FakeBank simülasyonu)*

**Özellikler:**
- Kimlik bilgileri Laravel `encrypt()` ile şifreli saklanıyor
- Her banka farklı auth yöntemi (OAuth token, TCKN+şifre, API key)
- `SyncBankConnectionJob` — asenkron arka plan senkronizasyonu
- Webhook desteği (anlık güncelleme)
- Soft delete ile güvenli bağlantı kesme

---

## 4. Kartlar

Kredi ve banka kartlarının limit, borç ve ödeme döngüsü takibi.

**Temel alanlar:** `credit_limit` · `current_debt` · `available_limit` · `statement_day` · `due_day`

Her kart bir hesaba, işlemler de bir karta bağlı.

---

## 5. Krediler

Konut, taşıt, ihtiyaç, ticari kredi takibi.

**Temel alanlar:** `type` · `principal` · `current_balance` · `interest_rate` · `total_installments` · `paid_installments` · `next_payment_date` · `next_payment_amount`

Ondalık hassasiyet: tutarlar `15,2` · faiz oranı `8,4` formatında.

---

## 6. İşlemler

Uygulamanın ana veri kaynağı.

**Özellikler:**
- UUID birincil anahtar (dağıtık sistem uyumlu)
- Çoklu para birimi — TRY eşdeğeri `try_amount` alanında otomatik saklanır
- Taksitli işlem takibi (`parent_transaction_id` + `installment_no` / `installment_total`)
- Kanal sınıflandırması: POS · ATM · Online · Transfer
- Tekrarlayan işlem bayrağı (`is_recurring`)
- Anomali skoru `0–100` (ajan tarafından doldurulur)
- Ajan sınıflandırma zaman damgası (`classified_by_agent_at`)
- Ham veri saklama (`raw_payload`) — denetim izi için

**CSV Import/Export** — toplu işlem yükleme ve indirme

---

## 7. Kategoriler & Bütçe

**Kategoriler:** İki seviyeli hiyerarşi (`parent_id`). TÜİK'in 14 ana kategorisiyle eşleştirilmiş (`tuik_category_slug`) — enflasyon hesabında kullanılıyor.

**Bütçeler:**
- Aylık kategori bazlı limit
- Harcama vs. bütçe karşılaştırması
- Uyarı eşiği (varsayılan %80)
- `POST /budgets/ai-suggest` — Gemini destekli öneri
- `POST /budgets/ai-apply` — önerilen bütçeyi tek tıkla uygula
- AI Chat'ten direkt bütçe oluşturma (ajan önerisi formu)

---

## 8. Abonelikler

Netflix, Spotify, YouTube Premium gibi tekrarlayan dijital ödemelerin yönetimi.

**Özellikler:**
- Fatura döngüsü: `weekly` · `monthly` · `quarterly` · `yearly`
- Tüm döngüler aylık eşdeğere dönüştürülüyor (toplam maliyet hesabı)
- İşlem örüntülerinden **otomatik algılama** (`auto_detected` bayrağı)
- Sonraki fatura tarihi tahmini
- Durum takibi: `active` / `cancelled`

---

## 9. Faturalar

Elektrik, su, doğalgaz, internet, telefon, kira, sigorta gibi sabit giderlerin takibi.

**Özellikler:**
- Aylık ödeme günü takibi (`due_day`: 1–31)
- Otomatik ödeme hesap bağlantısı (`autopay_account_id`)
- Son ödeme tutarı ve tarihi geçmişi
- Tip bazlı ikon + renk kodlaması

---

## 10. Hedefler

Birikim hedefi oluşturma ve izleme.

**Temel alanlar:** `name` · `target_amount` · `current_amount` · `target_date` · `monthly_contribution` · `status`

**Özellikler:**
- İlerleme yüzdesi ve kalan tutar otomatik hesaplanıyor
- `POST /goals/{id}/funds` — manuel birikim ekleme
- `GET /goals/{id}/suggest` — AI katkı önerisi
- **AI Chat'ten tek tıkla oluşturma** (ajan önerisi inline formu)
- Hedefe ulaşınca otomatik `completed` durumu

---

## 11. Kişisel Borçlar (IOU)

Arkadaş/aile arasındaki borç takibi.

**Özellikler:**
- Yön: `given` (verilen) · `received` (alınan)
- İşlemle isteğe bağlı ilişkilendirme
- Kapatma tarihi ve kişi adı kaydı
- Soft tracking — işlem silmeden bağlantı kesilebilir

---

## 12. Fişler & OCR

Fiş görselini yükle → yapay zeka içeriği çıkarsın → harcama kaydına dönüştür.

**Desteklenen formatlar:** JPG · PNG · GIF · WEBP · PDF (maks. 10 MB)

**Çıkarılan veriler:**
- Satır kalemleri (ürün adı + fiyat)
- Toplam tutar ve KDV
- Mağaza adı ve tarihi
- Garanti bitiş tarihi (`warranty_until`)

**Teknoloji:** `ReceiptOCRAgent` · Gemini Vision API · `ocr_extracted` JSON alanı  
OCR başarısız olsa bile fiş kaydediliyor (kısmi başarı).

---

## 13. Finansal Zeka Merkezi (AI Chat)

Uygulamanın kalbi. Kullanıcı bir soru/komut gönderir, 11 uzman ajan arka planda çalışır, sonuç markdown kart olarak render edilir.

### Mimari

```
Kullanıcı mesajı
    ↓
ProcessAgentJob kuyruğa alınır (non-blocking, UI hemen açılır)
    ↓
OrchestratorAgent → ilgili uzmanları çağırır
    ↓
CriticAgent → çıktı kalite kontrolü
    ↓
Gemini Pro → nihai sentez yanıtı
    ↓
AgentMessage güncellenir (status: completed)
    ↓
Frontend 2.5sn'de bir poll eder → skeleton → analiz kartı
```

### Endpoint'ler

| Method | URL | Açıklama |
|--------|-----|----------|
| `GET` | `/chat` | Chat arayüzü |
| `POST` | `/chat/send` | Mesaj gönder (anında `{status:'pending', message_id}` döner) |
| `GET` | `/chat/poll/{id}` | Yanıt hazır mı kontrol et |
| `POST` | `/chat/quick-analyze` | Hızlı bütçe + anomali analizi |
| `GET` | `/chat/history` | Oturum geçmişi |
| `GET` | `/chat/runs` | Son ajan çalışmaları |
| `POST` | `/chat/action` | Ajan önerisini gerçekleştir (`create_goal` / `create_budget`) |
| `PATCH` | `/chat/insights/{id}/dismiss` | Öngörüyü kapat |

### Agentic Action Sistemi

AI yanıtında "hedef oluşturayım" / "bütçe belirleyelim" gibi ifadeler tespit edildiğinde:
1. Kart altında **"Ajan önerisi"** bölümü açılır
2. Kullanıcı butona tıklar → inline form genişler
3. Alanlar doldurulur (önerilen tutar otomatik gelir) → **Oluştur**
4. AJAX ile `POST /chat/action` → kayıt veritabanına yazılır
5. Başarı mesajı + "Görüntüle →" linki inline gösterilir

### Veritabanı Tabloları

| Tablo | Amaç |
|-------|------|
| `agent_messages` | Oturum bazlı mesaj geçmişi (user/assistant/system) |
| `agent_runs` | Her ajan çalışmasının kaydı (token, süre, model, hata) |
| `agent_insights` | Proaktif öngörüler (dismiss edilebilir, önem sırası) |
| `agent_memories` | Kullanıcı bağlamı hafıza deposu |

---

## 14. Uzman Ajanlar

`OrchestratorAgent` tarafından yönetilen 11 adet uzman:

| Ajan | Görev |
|------|-------|
| `BudgetAdvisorAgent` | Harcama örüntüsü analizi, bütçe önerisi, aşım riski |
| `AnomalyDetectorAgent` | İstatistiksel veya Gemini tabanlı anormal işlem tespiti |
| `TransactionClassifierAgent` | Merchant adı + tutara göre otomatik kategori atama |
| `ReceiptOCRAgent` | Fiş görseli analizi, kalem-kalem çıkarım (Gemini Vision) |
| `SubscriptionHunterAgent` | İşlem örüntülerinden abonelik tespiti |
| `DebtOptimizerAgent` | Borç yapısı analizi, en hızlı kapatma stratejisi |
| `InflationAwareAgent` | Harcamaları TÜFE bağlamında yorumlama |
| `ForecasterAgent` | Nakit akışı ve birikim tahmini (6–12 ay) |
| `PurchasePlannerAgent` | Büyük alımlar için zamanlama ve bütçe önerisi |
| `CriticAgent` | Uzman çıktılarını filtreler, düşük kaliteliyi eler |
| `NegotiationAgent` | Müzakere ve ikna mektubu üretimi |

**Ortak altyapı:** `AbstractAgent` base class · `GeminiClient` (Pro / Flash / Vision) · Her çalışma `agent_runs`'a loglanıyor · Ajan başarısız olsa diğerleri devam ediyor.

---

## 15. Karar Simülatörü

"Ya şunu yapsaydım?" finansal senaryo aracı.

**Girdiler:**
- Gelir değişim yüzdesi
- Gider değişim yüzdesi
- Varsayılan enflasyon oranı
- Projeksiyon süresi (ay)

**Çıktılar:**
- İlerideki tahmini bakiye
- Birikmiş tasarruf
- Kalan borç
- Yeni finansal sağlık skoru

Baz değerler son 3 ayın gerçek ortalamasından alınıyor. Bileşik faiz/enflasyon formülü kullanılıyor.

---

## 16. Enflasyon Takibi

**Resmi veri:** TÜİK API entegrasyonu — aylık TÜFE ve 14 kategori bazlı enflasyon oranları

**Kişisel Enflasyon İndeksi:**
- Kullanıcının harcama dağılımı × ilgili kategori enflasyon oranı = kişisel ağırlıklı enflasyon
- Dashboard'da "Sen %X.X · Resmi %Y.Y" olarak karşılaştırılıyor

Tablolar: `inflation_rates` · `inflation_category_rates` · `economic_indicators`

---

## 17. Finansal Sağlık Skoru

0–100 arası bileşik skor.

| Bileşen | Ağırlık | Hesaplama |
|---------|---------|-----------|
| Borç oranı | %30 | Toplam borç / Yıllık gelir |
| Birikim oranı | %30 | (Gelir − Gider) / Gelir |
| Acil fon | %25 | Toplam bakiye / Aylık gider |
| Tutarlılık | %15 | Aylık gider standart sapması |

- 24 saatte bir yeniden hesaplanıyor (cache + `CalculateHealthScoreJob`)
- Her bileşen ayrı ayrı saklanıyor (detay gösterimi için)
- Simülatörde gelecek skor projeksiyonu da yapılıyor

---

## 18. Raporlar

Aylık finansal özet:
- Toplam gelir / gider
- Kategori bazlı harcama dağılımı
- Geçen aya göre değişim
- Tasarruf oranı

---

## 19. Müzakere Ajanı

AI destekli ikna mektubu üretimi.

**Desteklenen senaryolar:**
- Kredi kartı faiz indirimi
- Kredi yeniden yapılandırma
- Banka ücreti muafiyeti
- Abonelik iptali
- Sigorta indirimi
- Maaş artışı talebi

**Durum takibi:** `draft` → `sent` → `accepted` / `rejected`

Tüm mektuplar Türkçe, kullanıcının gerçek finansal verileriyle kişiselleştirilmiş.

---

## 20. Yatırım Portföyü

Çoklu varlık sınıfı takibi.

| Tür | Örnekler |
|-----|---------|
| Altın | Gram · Çeyrek · Cumhuriyet altını |
| Döviz | USD · EUR · GBP |
| Kripto | BTC · ETH |
| Hisse | BIST hisseleri |
| Fon | Yatırım fonları |
| Diğer | Mevduat, diğer |

Alış fiyatı (TRY), alış tarihi, miktar kaydediliyor. Kripto için 8 ondalık hassasiyet.

---

## 21. Kur & Altın Alarmları

Döviz ve altın fiyatları için eşik bazlı alarm sistemi.

**Özellikler:**
- `above` / `below` koşul tipi
- Aktif/pasif toggle
- Tetiklenme tarihi kaydı
- Canlı kur API entegrasyonu
- `/fx-alerts/market` — tarihsel market verileri

---

## 22. Finansal Takvim

Tüm ödeme ve vadeleri tek takvimde birleştiren görünüm:

- 📄 Fatura vade günleri
- 💳 Kredi taksit tarihleri
- 🔁 Abonelik yenileme tarihleri
- 🏦 Hesap ekstre ve ödeme günleri

---

## Teknik Özet

| Konu | Detay |
|------|-------|
| **Backend** | Laravel 13.7, PHP 8.3 |
| **AI modelleri** | Gemini 1.5 Pro · Gemini 1.5 Flash · Gemini Vision |
| **Async işlem** | Laravel Queue — database driver · `queue:work` |
| **UI** | Vuexy Admin (Bootstrap 5) · Tabler Icons |
| **Veritabanı** | MySQL · 30+ tablo |
| **OCR** | Gemini Vision API |
| **Banka entegrasyonu** | FakeBank OAuth simülasyonu (4 banka) |
| **Enflasyon verisi** | TÜİK API entegrasyonu |
| **Güvenlik** | Laravel `encrypt()` · Sanctum · CSRF · Soft delete |
| **Markdown render** | Inline JS parser (CDN bağımlılığı yok) |

---

## Proje Yapısı

```
btk-hackathon-2026/
├── web/                        # Laravel uygulaması
│   ├── app/
│   │   ├── Http/Controllers/   # 25+ controller
│   │   ├── Models/             # 30+ model
│   │   ├── Services/
│   │   │   ├── Agents/         # OrchestratorAgent + 11 uzman ajan
│   │   │   ├── Bank/           # Banka entegrasyon servisleri
│   │   │   └── ...             # Enflasyon, sağlık skoru, raporlar
│   │   └── Jobs/               # ProcessAgentJob · SyncBankConnectionJob · CalculateHealthScoreJob
│   ├── database/
│   │   ├── migrations/         # 30+ migration
│   │   └── seeders/            # Demo veri seeders
│   └── resources/views/        # Blade template'ler (modül başına)
└── mobile-api/                 # (planlanan) Mobil API katmanı
```
