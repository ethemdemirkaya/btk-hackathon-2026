# Paranette — 2 Dakikalık Tanıtım Video Senaryosu

> **Toplam süre:** 2:00  
> **Format:** Telefon ekran kaydı (dikey, 1080×2340) + senkronize konuşma  
> **Gerekli araç:** Android ekran kaydı (Ayarlar → Ekran Kaydı) veya AZ Screen Recorder  
> **Öneri:** Sesi sonradan dublaj olarak ekle — böylece çekim sırasında hata yaparsan sesi kaybetmezsin.

---

## Hazırlık (Çekimden önce)

- [ ] Backend çalışıyor: `php artisan serve --host=0.0.0.0 --port=8000`
- [ ] Demo hesabı oluşturulmuş ve banka bağlantıları senkronize edilmiş
- [ ] Uygulamada oturum açık, Dashboard'da
- [ ] Telefon: bildirimler kapalı, pil > %50, Wi-Fi bağlı
- [ ] Ekran parlaklığı tam açık
- [ ] Demo verileri dolu: işlemler, bütçeler, hedefler, yatırımlar hazır

---

## Sahne Sahne Senaryo

### 🎬 0:00 – 0:08 | Açılış + Splash

**Ekranda:** Paranette splash animasyonu (logo pulse, pulsing dots, particle efekti)

**Ne yaparsın:** Uygulamayı sıfırdan aç. Splash animasyonunun tam oynamasını bekle.

**Söylenecek:**
> *"Paranette — Türkiye'nin yapay zeka destekli kişisel finans asistanı."*

---

### 🎬 0:08 – 0:22 | Dashboard Genel Bakış

**Ekranda:** Dashboard — bakiye kartları, haftalık harcama bar grafiği, AI insight kartları, Finansal Sağlık Skoru

**Ne yaparsın:**
1. Dashboard'u göster, yukarıdan aşağı yavaşça scroll et
2. Finansal Sağlık Skoru kartına bir saniye odaklan
3. Harcama grafiğini kısa göster

**Söylenecek:**
> *"Dashboard'da tüm bankalardan çekilen bakiyeler, harcama analizi ve yapay zeka önerileri anlık görünüyor."*

**Dikkat:** AI insight kartları dolduysa harika — dolmadıysa 10 sn bekle, otomatik gelir.

---

### 🎬 0:22 – 0:40 | Banka Bağlantısı + İşlemler

**Ekranda:** Hamburger menü → Banka Bağlantıları → Ziraat kartı → İşlemler listesi

**Ne yaparsın:**
1. Sol hamburgeri aç
2. "Banka Bağlantıları"na tap
3. Ziraat/Garanti kartını göster (senkronize durumu, son senkronizasyon tarihi)
4. Geri dön → "İşlemler"e git
5. Liste yüklendi — bir işleme tap et, detay sayfasını göster (kategori, anomali skoru)

**Söylenecek:**
> *"Dört Türk bankasına bağlanıyor. İşlemler otomatik kategorize ediliyor — her işlemin bir anomali skoru var, olağandışı harcamalar anında tespit ediliyor."*

---

### 🎬 0:40 – 1:05 | AI Finans Asistanı ⭐ (En Güçlü Özellik)

**Ekranda:** Hamburger menü → AI Finans Asistanı → sohbet başlıyor

**Ne yaparsın:**
1. Chat ekranını aç
2. Hazırda kopyalı olan soruyu yapıştır (veya yaz):
   > `"Bu ay bütçemi aşıyor muyum, en büyük risk nerede ve ne yapmalıyım?"`
3. Gönder — yanıt gelene kadar bekle (10–20 sn)
4. Yanıt gelince yavaşça scroll ederek göster

**Söylenecek:**
> *"11 uzman AI ajanı aynı anda çalışıyor — bütçe danışmanı, anomali dedektörü, yatırım danışmanı... Tek soruda hepsinden gerçek zamanlı analiz."*

**İpucu:** Yanıt gelmeden konuşmayı bitirme. Bu sahne en etkileyici kısım — yeterli süre ver.

---

### 🎬 1:05 – 1:22 | Bütçe & Hedefler

**Ekranda:** Hamburger → Bütçeler → "AI Öner" butonu → onay → Hedefler sayfası

**Ne yaparsın:**
1. Bütçeler sayfasını aç
2. "AI Öner" ya da "Yapay Zeka Önerisi" butonuna bas
3. AI önerilerinin geldiğini göster (kategori + tutar)
4. "Uygula" / "Kabul Et"e bas
5. Hızlıca Hedefler sayfasına geç, ilerleme barını göster

**Söylenecek:**
> *"Yapay zeka gelir-gider analizine göre bütçe öneriyor, tek tıkla uygulanıyor. Hedeflerde tasarruf ilerlemesi anlık takip ediliyor."*

---

### 🎬 1:22 – 1:38 | Müzakere Ajanı (Unique Özellik)

**Ekranda:** Hamburger → Müzakere Mektupları → Kredi Faizi İndirimi → Mektup Oluştur → AI mektubu

**Ne yaparsın:**
1. "Müzakere Mektupları" sayfasını aç
2. "Kredi Faizi İndirimi" veya mevcut bir seçeneği seç
3. "Mektup Oluştur"a bas
4. Oluşturulan resmi AI mektubunu göster (kısa scroll)

**Söylenecek:**
> *"Türkiye'ye özgü bir özellik: müzakere ajanı, bankaya göndermek için hukuki dil ve kişisel verilerle resmi faiz indirimi mektubu yazıyor."*

---

### 🎬 1:38 – 1:52 | Yatırımlar + Güvenlik

**Ekranda:** Hamburger → Yatırımlar (canlı fiyatlar) → Geri → Profil → PIN ekranı (kısa)

**Ne yaparsın:**
1. Yatırımlar sayfasını aç — altın/döviz/kripto/BIST canlı fiyatları göster (3 sn)
2. Geri çık
3. Uygulamayı arka plana at ve tekrar aç → PIN giriş ekranı gelsin
4. PIN gir → uygulama açılsın
5. (Varsa) Parmak izi ikonu görünsün

**Söylenecek:**
> *"Canlı yatırım portföyü takibinin yanı sıra uygulama her açılışta PIN veya biyometrik doğrulama istiyor — güvenlik ödünsüz."*

---

### 🎬 1:52 – 2:00 | Kapanış

**Ekranda:** Dashboard veya Splash

**Ne yaparsın:** Dashboard'a dön, birkaç saniyeliğine görüntüle. Son 3 saniyede siyah ekrana fade out.

**Söylenecek:**
> *"Paranette — BTK Akademi Hackathon 2026. Finansal özgürlüğün yapay zeka ile buluştuğu yer."*

---

## Zaman Çizelgesi Özeti

| Zaman | Sahne | Süre |
|:---:|:---|:---:|
| 0:00 – 0:08 | Splash açılışı | 8 sn |
| 0:08 – 0:22 | Dashboard genel bakış | 14 sn |
| 0:22 – 0:40 | Banka + İşlemler | 18 sn |
| 0:40 – 1:05 | AI Finans Asistanı ⭐ | 25 sn |
| 1:05 – 1:22 | Bütçe & Hedefler | 17 sn |
| 1:22 – 1:38 | Müzakere Ajanı | 16 sn |
| 1:38 – 1:52 | Yatırımlar + Güvenlik | 14 sn |
| 1:52 – 2:00 | Kapanış | 8 sn |

---

## Çekim İpuçları

### Hız & Geçişler
- Her sayfaya geçişte **1–2 saniye bekle** — editörde hızlandırabilirsin, yavaş çekmek daha iyidir
- Hamburger menüyü açarken **yavaş ve kasıtlı** hareket et — hızlı geçişler jüri için kafa karıştırıcı
- AI yanıtı beklenirken ekranı sabit tut, beklerken konuşmaya devam et

### Veri Hazırlığı
- Banka bağlantısı önceden senkronize edilmiş olmalı — canlı senkronizasyon çok zaman alır
- AI chat sorusunu patlamalı yapıştırabilmek için panoya kopyala
- Müzakere mektubu için banka/kredi bilgileri önceden doldurulmuş olmalı
- Dashboard AI kartları dolu değilse: önce bir API çağrısı yap, dolduktan sonra çek

### Ses
- Arka plan müziği: yumuşak, dikkat dağıtmayan enstrümental (30–60 BPM civarı)
- Konuşma hızı: normal konuşmanın %80'i — yavaş ama doğal
- Türkçe teknik terimleri (AI, dashboard, sync) İngilizce telaffuzla oku

### Editing
- Başlangıç ve bitiş: 0.5 saniyelik siyah ekrana fade in/out
- Geçişler: cross-fade veya cut — morph/zoom geçişi dikkat dağıtır
- Alt yazı ekle: her sahnede uygulama adı veya özellik adı (beyaz, yarı şeffaf arka plan)
- Çözünürlük: en az 1080p, 60fps tercih edilir

### Yedek Plan
- **AI yanıtı 20 sn'yi geçerse:** Kuru bir "AI analiz yapıyor…" state'ini göster ve kurgu ile kes
- **Veri yüklenmediyse:** Sayfayı pull-to-refresh ile yenile, bu hareket de doğal görünür
- **Bağlantı kopuksa:** Offline state'i göstermek yerine WiFi bağlantısını önceden test et

---

## Önerilen Çekim Sırası

Sürekli bir akış yerine **bölüm bölüm çek**, sonra birleştir:

1. Splash + kapanış (en kolay, önce halvet)
2. Dashboard scroll
3. Banka + işlemler
4. AI chat (en uzun bekleme süresi — sabırlı ol)
5. Bütçe + hedefler
6. Müzakere
7. Yatırım + PIN

Her bölümü **2–3 kez çek**, en iyi alımı seç.
