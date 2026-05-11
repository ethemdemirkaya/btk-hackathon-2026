# Paranette Mobile API

Laravel Sanctum tabanlı, Flutter mobil uygulaması için REST API.

**Base URL:** `http://<host>/api/v1`  
**Auth:** `Authorization: Bearer <token>`  
**Format:** `Content-Type: application/json` (dosya yüklemelerde `multipart/form-data`)  
**Token süresi:** 30 gün — süresi dolan token `401` döner, yeniden login gerekir.

---

## Endpoint Hızlı Başvuru

| Method | Endpoint | Auth | Açıklama |
|--------|----------|------|----------|
| POST | `/auth/register` | — | Kayıt |
| POST | `/auth/login` | — | Giriş |
| GET | `/auth/me` | ✓ | Profil görüntüle |
| PATCH | `/auth/me` | ✓ | Profil güncelle |
| DELETE | `/auth/logout` | ✓ | Çıkış (mevcut token) |
| DELETE | `/auth/logout-all` | ✓ | Tüm cihazlardan çıkış |
| GET | `/dashboard` | ✓ | Finansal genel bakış |
| GET | `/bank-connections` | ✓ | Banka bağlantıları |
| POST | `/bank-connections` | ✓ | Banka bağla |
| POST | `/bank-connections/{id}/sync` | ✓ | Senkronize et |
| DELETE | `/bank-connections/{id}` | ✓ | Bağlantıyı sil |
| GET | `/transactions` | ✓ | İşlem listesi (filtreli, sayfalı) |
| GET | `/transactions/{id}` | ✓ | İşlem detayı |
| GET | `/cards` | ✓ | Kart listesi + özet |
| GET | `/loans` | ✓ | Krediler |
| GET | `/bills` | ✓ | Faturalar |
| POST | `/bills` | ✓ | Fatura ekle |
| PATCH | `/bills/{id}` | ✓ | Fatura güncelle |
| DELETE | `/bills/{id}` | ✓ | Fatura sil |
| GET | `/subscriptions` | ✓ | Abonelikler + adaylar |
| POST | `/subscriptions` | ✓ | Abonelik ekle |
| DELETE | `/subscriptions/{id}` | ✓ | Abonelik iptal |
| GET | `/budgets` | ✓ | Bütçeler (aylık) |
| POST | `/budgets` | ✓ | Bütçe oluştur / güncelle |
| DELETE | `/budgets/{id}` | ✓ | Bütçe sil |
| POST | `/budgets/ai-suggest` | ✓ | AI bütçe önerisi al |
| POST | `/budgets/ai-apply` | ✓ | AI önerilerini toplu uygula |
| GET | `/goals` | ✓ | Hedefler |
| POST | `/goals` | ✓ | Hedef oluştur |
| POST | `/goals/{id}/add-funds` | ✓ | Hedefe para ekle |
| GET | `/goals/{id}/suggest` | ✓ | Aylık katkı önerisi al |
| DELETE | `/goals/{id}` | ✓ | Hedef sil |
| GET | `/inflation` | ✓ | Kişisel + resmi enflasyon |
| GET | `/personal-debts` | ✓ | Kişisel borç listesi |
| POST | `/personal-debts` | ✓ | Borç ekle |
| PATCH | `/personal-debts/{id}/settle` | ✓ | Borcu kapat |
| DELETE | `/personal-debts/{id}` | ✓ | Borç sil |
| GET | `/investments` | ✓ | Yatırım portföyü |
| POST | `/investments` | ✓ | Varlık ekle |
| DELETE | `/investments/{id}` | ✓ | Varlık sil |
| GET | `/fx-alerts` | ✓ | Kur alarmları + anlık kurlar |
| POST | `/fx-alerts` | ✓ | Alarm oluştur |
| DELETE | `/fx-alerts/{id}` | ✓ | Alarm sil |
| GET | `/fx-alerts/rates` | ✓ | Canlı kur/altın verileri |
| GET | `/negotiation` | ✓ | Müzakere taslakları |
| POST | `/negotiation/generate` | ✓ | AI mektubu oluştur |
| PATCH | `/negotiation/{id}/status` | ✓ | Taslak durumunu güncelle |
| DELETE | `/negotiation/{id}` | ✓ | Taslak sil |
| GET | `/simulator` | ✓ | Mevcut finansal durum |
| POST | `/simulator/calculate` | ✓ | Senaryo hesapla |
| GET | `/calendar` | ✓ | Aylık finansal takvim |
| GET | `/report/summary` | ✓ | Aylık rapor özeti (JSON) |
| GET | `/report/pdf` | ✓ | PDF rapor indir |
| POST | `/agent/send` | ✓ | AI ajan mesajı gönder |
| GET | `/agent/history` | ✓ | Konuşma geçmişi |
| GET | `/agent/insights` | ✓ | AI öngörüleri |
| PATCH | `/agent/insights/{id}/dismiss` | ✓ | Öngörü kapat |
| GET | `/receipts` | ✓ | Fiş listesi |
| POST | `/receipts` | ✓ | Fiş yükle (OCR) |
| DELETE | `/receipts/{id}` | ✓ | Fiş sil |

---

## Hata Yanıtları

| HTTP | Durum | Açıklama |
|------|-------|----------|
| `401` | Unauthenticated | Token eksik veya geçersiz — yeniden login |
| `403` | Forbidden | Kaynak başka kullanıcıya ait |
| `404` | Not Found | Kayıt bulunamadı |
| `422` | Unprocessable | Validasyon hatası — `errors` alanına bak |
| `500` | Server Error | AI/OCR servis hatası |

**Validasyon hatası (`422`) örneği:**
```json
{
  "message": "The email field must be a valid email address.",
  "errors": {
    "email": ["The email field must be a valid email address."],
    "password": ["The password field must be at least 8 characters."]
  }
}
```

---

## Kimlik Doğrulama

### Kayıt

```http
POST /api/v1/auth/register
```

**Body:**
```json
{
  "name": "Ethem Demirkaya",
  "email": "ethem@example.com",
  "password": "şifre1234",
  "password_confirmation": "şifre1234",
  "monthly_income": 45000,
  "phone": "05XX XXX XX XX"
}
```

**Validasyon kuralları:**

| Alan | Kural |
|------|-------|
| `name` | zorunlu, max 255 |
| `email` | zorunlu, geçerli email, unique |
| `password` | zorunlu, min 8, `password_confirmation` ile eşleşmeli |
| `monthly_income` | opsiyonel, sayısal, min 0 |
| `phone` | opsiyonel, max 20 |

**Response `201`:**
```json
{
  "token": "1|abc123...",
  "user": {
    "id": 1,
    "name": "Ethem Demirkaya",
    "email": "ethem@example.com",
    "phone": "05XX XXX XX XX",
    "birth_date": null,
    "monthly_income": 45000.00,
    "created_at": "2026-05-11T10:00:00+03:00"
  }
}
```

---

### Giriş

```http
POST /api/v1/auth/login
```

**Body:**
```json
{
  "email": "ethem@example.com",
  "password": "şifre1234",
  "device_name": "iPhone 15"
}
```

`device_name` opsiyonel, varsayılan `"mobile"`. Sanctum token bu isme atanır.

**Response `200`:** — `register` ile aynı yapı.

---

### Profil Görüntüle

```http
GET /api/v1/auth/me
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "user": {
    "id": 1,
    "name": "Ethem Demirkaya",
    "email": "ethem@example.com",
    "phone": "05XX XXX XX XX",
    "birth_date": "1995-03-15",
    "monthly_income": 45000.00,
    "created_at": "2026-05-11T10:00:00+03:00"
  }
}
```

---

### Profil Güncelle

```http
PATCH /api/v1/auth/me
Authorization: Bearer <token>
```

**Body (tümü opsiyonel):**
```json
{
  "name": "Yeni Ad",
  "monthly_income": 50000,
  "phone": "05XX XXX XX XX",
  "birth_date": "1995-03-15"
}
```

**Response `200`:** — güncel `user` objesi.

---

### Çıkış

```http
DELETE /api/v1/auth/logout          ← Mevcut token
DELETE /api/v1/auth/logout-all      ← Tüm cihazlar
```

**Response `200`:**
```json
{ "message": "Çıkış yapıldı." }
```

---

## Dashboard

### Finansal Genel Bakış

```http
GET /api/v1/dashboard
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "summary": {
    "total_balance": 48240.50,
    "total_card_debt": 3200.00,
    "total_loan": 120000.00,
    "net_worth": 31540.00,
    "health_score": 74
  },
  "cash_flow": [
    {
      "period": "2026-04",
      "income": 45000.00,
      "expenses": 32000.00,
      "net": 13000.00
    }
  ],
  "category_spend": [
    {
      "category": "Market",
      "amount": 8400.00,
      "percentage": 26.3
    }
  ],
  "personal_inflation": {
    "personal_rate": 42.8,
    "tufe_rate": 37.9,
    "diff": 4.9,
    "breakdown": [
      { "category": "Konut & Kira", "weight_pct": 35.2, "tuik_rate": 59.1 }
    ],
    "period": "2026-04"
  },
  "smart_alerts": [
    {
      "type": "warning",
      "title": "Bütçe Uyarısı",
      "body": "Market bütçenizin %85'ini kullandınız.",
      "icon": "tabler-alert-triangle",
      "link": "/budgets"
    }
  ],
  "budget_summary": [
    {
      "category": "Market",
      "budgeted": 5000.00,
      "spent": 4250.00,
      "remaining": 750.00,
      "pct": 85.0,
      "over_budget": false
    }
  ],
  "health_score": {
    "score": 74,
    "debt_ratio_score": 65,
    "savings_rate_score": 80,
    "emergency_fund_score": 70,
    "expense_consistency_score": 82,
    "calculated_at": "2026-05-11T09:00:00+03:00"
  },
  "macro_indicators": [
    {
      "type": "policy_rate",
      "value": 45.0,
      "fetched_at": "2026-05-11T00:00:00+03:00"
    }
  ]
}
```

> `health_score` ve `personal_inflation` null olabilir (henüz veri yoksa).  
> `cash_flow` son 6 ayı döner, `category_spend` mevcut ayı döner.

---

## Banka Bağlantıları

### Listele

```http
GET /api/v1/bank-connections
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "connections": [
    {
      "id": 1,
      "bank": {
        "id": 1,
        "name": "Ziraat Bankası",
        "slug": "ziraat",
        "logo": "banks/ziraat.svg"
      },
      "status": "active",
      "last_sync_at": "2026-05-11T08:00:00+03:00",
      "accounts": [
        {
          "id": 1,
          "external_id": "ACC-001",
          "account_type": "checking",
          "iban": "TR33****1234",
          "currency": "TRY",
          "balance": 15200.00,
          "available_balance": 14800.00,
          "nickname": null,
          "bank": {
            "name": "Ziraat Bankası",
            "slug": "ziraat",
            "logo": "banks/ziraat.svg"
          },
          "created_at": "2026-05-10T10:00:00+03:00"
        }
      ]
    }
  ]
}
```

**`status` değerleri:** `pending` · `active` · `error` · `inactive`

---

### Banka Bağla

```http
POST /api/v1/bank-connections
Authorization: Bearer <token>
```

**Body (Ziraat — TCKN/şifre):**
```json
{
  "bank_slug": "ziraat",
  "credentials": {
    "username": "kullanici_adi",
    "password": "sifre"
  }
}
```

**Body (Garanti — OAuth):**
```json
{
  "bank_slug": "garanti",
  "credentials": {
    "access_token": "oauth_token_buraya",
    "refresh_token": "refresh_token_buraya"
  }
}
```

**Body (Akbank — API key):**
```json
{
  "bank_slug": "akbank",
  "credentials": {
    "api_key": "key_buraya",
    "client_id": "client_id_buraya"
  }
}
```

**Desteklenen `bank_slug` değerleri:** `ziraat` · `garanti` · `isbank` · `akbank`

**Response `201`:**
```json
{
  "id": 2,
  "bank": { "name": "Garanti BBVA", "slug": "garanti" },
  "status": "pending",
  "last_sync_at": null,
  "accounts": []
}
```

> Bağlantı oluşturulunca arka planda `SyncBankConnectionJob` tetiklenir, hesaplar kısa süre içinde dolar.

---

### Senkronize Et

```http
POST /api/v1/bank-connections/{id}/sync
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "status": "active",
  "last_sync_at": "2026-05-12T10:30:00+03:00",
  "accounts": [ /* güncel hesap listesi */ ]
}
```

---

### Banka Bağlantısını Sil

```http
DELETE /api/v1/bank-connections/{id}
Authorization: Bearer <token>
```

**Response `200`:**
```json
{ "message": "Banka bağlantısı silindi." }
```

---

## İşlemler

### Listele (Filtrelenebilir & Sayfalı)

```http
GET /api/v1/transactions
Authorization: Bearer <token>
```

**Query parametreleri:**

| Param | Tip | Zorunlu | Açıklama |
|-------|-----|---------|----------|
| `type` | string | — | `income` veya `expense` |
| `from` | date | — | Başlangıç tarihi `YYYY-MM-DD` |
| `to` | date | — | Bitiş tarihi `YYYY-MM-DD` |
| `category` | string | — | Kategori adıyla filtrele |
| `per_page` | int | — | Sayfa başına kayıt (1–100, varsayılan 20) |

**Örnek:**
```
GET /api/v1/transactions?type=expense&from=2026-04-01&to=2026-04-30&per_page=50
```

**Response `200`:**
```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "external_id": "TXN-2026-001",
      "posted_at": "2026-04-15T14:22:00+03:00",
      "amount": -245.50,
      "currency": "TRY",
      "try_amount": -245.50,
      "description": "Migros Market - Beşiktaş",
      "merchant_name": "Migros",
      "merchant_category": "Grocery",
      "category": {
        "id": 2,
        "name": "Market",
        "icon": "tabler-shopping-cart"
      },
      "channel": "pos",
      "is_recurring": false,
      "installment_no": null,
      "installment_total": null,
      "anomaly_score": null
    },
    {
      "id": "661f9511-...",
      "posted_at": "2026-04-10T09:00:00+03:00",
      "amount": -4800.00,
      "currency": "TRY",
      "try_amount": -4800.00,
      "description": "iPhone 14 - 12/24",
      "merchant_name": "Apple Store",
      "merchant_category": "Electronics",
      "category": {
        "id": 31,
        "name": "Elektronik",
        "icon": "tabler-device-laptop"
      },
      "channel": "pos",
      "is_recurring": false,
      "installment_no": 12,
      "installment_total": 24,
      "anomaly_score": 0.12
    }
  ],
  "pagination": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 20,
    "total": 98
  }
}
```

**`channel` değerleri:** `pos` · `atm` · `online` · `transfer`  
**`amount`:** negatif = gider, pozitif = gelir  
**`try_amount`:** yabancı para biriminde gerçekleşen işlemlerin TRY karşılığı  
**`anomaly_score`:** `0.0–1.0` arası — null = analiz edilmemiş, yüksek değer = olağandışı

---

### İşlem Detayı

```http
GET /api/v1/transactions/{id}
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "transaction": { /* GET /transactions dizisiyle aynı nesne yapısı */ }
}
```

---

## Kredi Kartları

```http
GET /api/v1/cards
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "cards": [
    {
      "id": 1,
      "type": "credit",
      "masked_number": "**** **** **** 4521",
      "holder_name": "ETHEM DEMIRKAYA",
      "expiry_month": 9,
      "expiry_year": 2028,
      "credit_limit": 30000.00,
      "current_debt": 3200.00,
      "available_limit": 26800.00,
      "utilization_pct": 10.7,
      "statement_day": 15,
      "due_day": 3
    }
  ],
  "total_debt": 3200.00,
  "total_limit": 30000.00,
  "utilization": 10.7
}
```

**`type` değerleri:** `credit` · `debit` · `prepaid`

---

## Krediler

```http
GET /api/v1/loans
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "loans": [
    {
      "id": 1,
      "external_id": "LOAN-2025-001",
      "type": "mortgage",
      "principal": 800000.00,
      "current_balance": 720000.00,
      "interest_rate": 3.49,
      "total_installments": 120,
      "paid_installments": 12,
      "remaining_installments": 108,
      "progress_pct": 10.0,
      "next_payment_date": "2026-06-01",
      "next_payment_amount": 9800.00,
      "started_at": "2025-06-01",
      "ends_at": "2035-06-01",
      "bank": {
        "name": "Ziraat Bankası",
        "slug": "ziraat"
      }
    }
  ],
  "total_balance": 720000.00,
  "due_next_30_days": 9800.00
}
```

**`type` değerleri:** `personal` · `mortgage` · `vehicle` · `commercial`

---

## Faturalar

### Listele

```http
GET /api/v1/bills
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "bills": [
    {
      "id": 1,
      "name": "Elektrik",
      "type": "electricity",
      "type_label": "Elektrik",
      "provider": "BEDAŞ",
      "account_number": "123456789",
      "average_amount": 1200.00,
      "due_day": 15,
      "is_autopay": true,
      "last_paid_at": "2026-05-15T00:00:00+03:00",
      "last_amount": 1150.00
    }
  ],
  "total_monthly_est": 4800.00
}
```

**`type` değerleri:** `electricity` · `water` · `gas` · `internet` · `phone` · `rent` · `insurance` · `other`

---

### Fatura Ekle

```http
POST /api/v1/bills
Authorization: Bearer <token>
```

**Body:**
```json
{
  "name": "Doğalgaz",
  "type": "gas",
  "provider": "İGDAŞ",
  "account_number": "987654321",
  "average_amount": 800,
  "due_day": 20,
  "is_autopay": false
}
```

**Validasyon:**

| Alan | Kural |
|------|-------|
| `name` | zorunlu, max 255 |
| `type` | zorunlu, geçerli değer |
| `provider` | opsiyonel, max 255 |
| `account_number` | opsiyonel, max 100 |
| `average_amount` | zorunlu, sayısal, min 0 |
| `due_day` | opsiyonel, 1–31 |
| `is_autopay` | opsiyonel, boolean |

**Response `201`:** — `{ "bill": { ... } }` nesne.

---

### Fatura Güncelle / Sil

```http
PATCH /api/v1/bills/{id}     ← Tüm alanlar opsiyonel
DELETE /api/v1/bills/{id}
```

---

## Abonelikler

### Listele

```http
GET /api/v1/subscriptions
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "subscriptions": [
    {
      "id": 1,
      "name": "Netflix",
      "merchant_name": "NETFLIX.COM",
      "amount": 149.99,
      "currency": "TRY",
      "billing_cycle": "monthly",
      "monthly_equivalent": 149.99,
      "next_billing_date": "2026-06-01",
      "started_at": "2024-01-01",
      "auto_detected": true,
      "status": "active",
      "category": {
        "id": 24,
        "name": "Dijital Abonelik"
      }
    }
  ],
  "total_monthly": 549.97,
  "candidates": [
    {
      "merchant_name": "Spotify",
      "avg_amount": 59.99,
      "occurrences": 5
    }
  ]
}
```

> **`candidates`**: Henüz abonelik olarak eklenmemiş, ama tekrarlayan işlem örüntüsünden tespit edilen adaylar. Kullanıcıya "Şunu ekleyeyim mi?" olarak sunulabilir.

**`billing_cycle` değerleri:** `weekly` · `monthly` · `quarterly` · `yearly`  
**`monthly_equivalent`:** Tüm döngüler bu alanda aylık eşdeğere dönüştürülür (yıllık ÷ 12, haftalık × 4.33).

---

### Abonelik Ekle

```http
POST /api/v1/subscriptions
Authorization: Bearer <token>
```

**Body:**
```json
{
  "name": "Spotify",
  "merchant_name": "SPOTIFY AB",
  "amount": 59.99,
  "currency": "TRY",
  "billing_cycle": "monthly",
  "next_billing_date": "2026-06-05",
  "started_at": "2026-01-05",
  "category_id": 24
}
```

**Response `201`:** — `{ "subscription": { ... } }` nesne.

---

### Abonelik İptal Et

```http
DELETE /api/v1/subscriptions/{id}
Authorization: Bearer <token>
```

Kayıt silinmez, `status: "cancelled"` olarak işaretlenir.

---

## Bütçeler

### Listele (Aylık)

```http
GET /api/v1/budgets?period=2026-05
Authorization: Bearer <token>
```

`period` belirtilmezse mevcut ay kullanılır. Format: `YYYY-MM`.

**Response `200`:**
```json
{
  "period": "2026-05",
  "budgets": [
    {
      "id": 3,
      "period": "2026-05",
      "amount": 5000.00,
      "alert_threshold": 80.0,
      "spent": 4250.00,
      "remaining": 750.00,
      "pct": 85.0,
      "over_budget": false,
      "category": {
        "id": 2,
        "name": "Market",
        "icon": "tabler-shopping-cart"
      }
    }
  ]
}
```

---

### Bütçe Oluştur / Güncelle

```http
POST /api/v1/budgets
Authorization: Bearer <token>
```

**Body:**
```json
{
  "category_id": 3,
  "amount": 5000,
  "alert_threshold": 80,
  "period": "2026-05"
}
```

> `period` yoksa mevcut ay kullanılır.  
> Aynı `user_id + category_id + period` kombinasyonu varsa **güncellenir** (updateOrCreate).

**Response `201`:** — `{ "budget": { ... } }` nesne.

---

### Bütçe Sil

```http
DELETE /api/v1/budgets/{id}
Authorization: Bearer <token>
```

---

## Hedefler

### Listele

```http
GET /api/v1/goals
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "goals": [
    {
      "id": 1,
      "name": "Tatil Fonu",
      "target_amount": 20000.00,
      "current_amount": 8500.00,
      "remaining_amount": 11500.00,
      "progress_pct": 42.5,
      "target_date": "2026-08-01",
      "monthly_contribution": 2000.00,
      "status": "active",
      "months_to_goal": 6
    }
  ],
  "total_saved": 8500.00,
  "total_target": 20000.00
}
```

**`status` değerleri:** `active` · `completed`  
**`months_to_goal`:** `monthly_contribution > 0` ise hesaplanır, aksi takdirde `null`.

---

### Hedef Oluştur

```http
POST /api/v1/goals
Authorization: Bearer <token>
```

**Body:**
```json
{
  "name": "Tatil Fonu",
  "target_amount": 20000,
  "current_amount": 500,
  "target_date": "2026-08-01",
  "monthly_contribution": 2000
}
```

**Validasyon:**

| Alan | Kural |
|------|-------|
| `name` | zorunlu, max 255 |
| `target_amount` | zorunlu, sayısal, min 1 |
| `current_amount` | opsiyonel, sayısal, min 0 |
| `target_date` | opsiyonel, tarih, bugünden sonra |
| `monthly_contribution` | opsiyonel, sayısal, min 0 |

**Response `201`:** — `{ "goal": { ... } }` nesne.

---

### Hedefe Para Ekle

```http
POST /api/v1/goals/{id}/add-funds
Authorization: Bearer <token>
```

**Body:**
```json
{ "amount": 500 }
```

**Response `200`:** — güncel `{ "goal": { ... } }` nesne.  
> `current_amount`, `target_amount`'a ulaşırsa `status` otomatik `"completed"` olur.

---

### Hedef Sil

```http
DELETE /api/v1/goals/{id}
Authorization: Bearer <token>
```

---

## Kişisel Enflasyon

```http
GET /api/v1/inflation
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "personal_rate": 42.8,
  "tufe_rate": 37.9,
  "diff": 4.9,
  "breakdown": [
    {
      "category": "Konut & Kira",
      "weight_pct": 35.2,
      "tuik_rate": 59.1
    },
    {
      "category": "Gıda & İçecek",
      "weight_pct": 28.4,
      "tuik_rate": 43.2
    }
  ],
  "period": "2026-04",
  "tufe_history": [
    {
      "period": "2026-04",
      "annual_rate": 37.9,
      "monthly_rate": 2.1
    },
    {
      "period": "2026-03",
      "annual_rate": 39.1,
      "monthly_rate": 2.6
    }
  ],
  "category_rates": [
    { "category": "Eğitim", "rate": 75.3, "period": "2026-04" },
    { "category": "Ulaşım", "rate": 31.2, "period": "2026-04" }
  ]
}
```

> `personal_rate` null olabilir — kullanıcının o ay için işlem verisi yoksa hesaplanamaz.  
> `tufe_history` son 12 ay, `category_rates` TÜİK'in 14 kategorisinin son değerleri.

---

## AI Ajan Asistan

### Mesaj Gönder

```http
POST /api/v1/agent/send
Authorization: Bearer <token>
```

**Body:**
```json
{
  "message": "Bu ay ne kadar harcadım? Bütçemi aştım mı?",
  "session_id": "flutter-session-abc123"
}
```

`session_id` opsiyonel — verilmezse otomatik UUID oluşturulur ve response'da döner.

**Response `200`:**
```json
{
  "reply": "Nisan ayında toplam ₺18.420 harcama yaptınız...\n\n**Kategoriler:**\n- Market: ₺4.200 (bütçenizin %84'ü)\n- Ulaşım: ₺2.100\n\nMarket bütçenize yaklaşıyorsunuz.",
  "agents_used": ["BudgetAdvisorAgent", "TransactionClassifierAgent"],
  "session_id": "flutter-session-abc123",
  "run_id": 42
}
```

> `reply` alanı **Markdown formatında** gelir. Flutter'da `flutter_markdown` paketi ile render edilmesi önerilir.

**Hata `500`:**
```json
{
  "error": "Ajan yanıt veremedi.",
  "details": "timeout after 300s"
}
```

---

### Konuşma Geçmişi

```http
GET /api/v1/agent/history?session_id=flutter-session-abc123
Authorization: Bearer <token>
```

`session_id` opsiyonel — verilmezse son 20 çalışma döner.

**Response `200`:**
```json
{
  "runs": [
    {
      "run_id": 42,
      "session_id": "flutter-session-abc123",
      "status": "completed",
      "started_at": "2026-05-12T10:00:00+03:00",
      "messages": [
        {
          "role": "user",
          "content": "Bu ay ne kadar harcadım?",
          "at": "2026-05-12T10:00:00+03:00"
        },
        {
          "role": "assistant",
          "content": "Nisan ayında toplam ₺18.420...",
          "at": "2026-05-12T10:00:15+03:00"
        }
      ]
    }
  ]
}
```

**`status` değerleri:** `running` · `completed` · `failed`

---

### AI Öngörüleri

```http
GET /api/v1/agent/insights
Authorization: Bearer <token>
```

Son 10 kapatılmamış öngörü döner.

**Response `200`:**
```json
{
  "insights": [
    {
      "id": 7,
      "type": "warning",
      "title": "Market harcamaları artıyor",
      "body": "Son 3 ayda market harcamalarınız ortalama %18 arttı.",
      "action_link": "/budgets",
      "importance": "high",
      "created_at": "2026-05-11T08:30:00+03:00"
    }
  ]
}
```

**`type` değerleri:** `warning` · `opportunity` · `tip` · `anomaly`  
**`importance` değerleri:** `low` · `medium` · `high` · `critical`

---

### Öngörü Kapat

```http
PATCH /api/v1/agent/insights/{id}/dismiss
Authorization: Bearer <token>
```

**Response `200`:**
```json
{ "message": "Öngörü kapatıldı." }
```

---

## Fişler & OCR

### Listele

```http
GET /api/v1/receipts
Authorization: Bearer <token>
```

Son 50 fiş döner.

**Response `200`:**
```json
{
  "receipts": [
    {
      "id": 5,
      "merchant_name": "Migros",
      "total_amount": 245.50,
      "currency": "TRY",
      "purchased_at": "2026-05-10T15:30:00+03:00",
      "category": "Market",
      "items_count": 8
    }
  ]
}
```

---

### Fiş Yükle (OCR)

```http
POST /api/v1/receipts
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

| Alan | Tip | Kural |
|------|-----|-------|
| `image` | file | zorunlu · JPEG/PNG/GIF/WEBP/PDF · maks 10 MB |

**Response `201`:**
```json
{
  "receipt": {
    "id": 5,
    "merchant_name": "Migros",
    "total_amount": 245.50,
    "currency": "TRY",
    "purchased_at": "2026-05-10T15:30:00+03:00",
    "warranty_until": null,
    "category": "Market",
    "items": [
      { "name": "Süt 1L", "qty": 2, "unit_price": 34.90, "total": 69.80 },
      { "name": "Ekmek", "qty": 1, "unit_price": 15.00, "total": 15.00 }
    ]
  }
}
```

> OCR başarısız olsa bile fiş kaydedilir, `items` boş array döner.

**Hata `500`:**
```json
{
  "error": "OCR işlemi başarısız.",
  "details": "Gemini Vision timeout"
}
```

---

### Fiş Sil

```http
DELETE /api/v1/receipts/{id}
Authorization: Bearer <token>
```

---

## Bütçe — AI Önerileri

### AI Bütçe Önerisi Al

Son 3 ayın harcama örüntüsüne göre kategori bazlı bütçe önerileri üretir.

```http
POST /api/v1/budgets/ai-suggest
Authorization: Bearer <token>
```

Body gönderilmez. Kullanıcının işlem geçmişi otomatik analiz edilir.

**Response `200`:**
```json
{
  "suggestions": [
    {
      "category_id": 2,
      "category_name": "Market",
      "monthly_avg": 4250.00,
      "suggested": 4500.00
    },
    {
      "category_id": 3,
      "category_name": "Restoran & Kafe",
      "monthly_avg": 1820.00,
      "suggested": 2000.00
    }
  ]
}
```

> `suggested` = son 3 aylık ortalama × 1.05 (küçük tampon bırakılır).

---

### AI Önerilerini Toplu Uygula

```http
POST /api/v1/budgets/ai-apply
Authorization: Bearer <token>
```

**Body:**
```json
{
  "suggestions": [
    { "category_id": 2, "amount": 4500 },
    { "category_id": 3, "amount": 2000 }
  ]
}
```

**Response `200`:**
```json
{
  "created": 3,
  "message": "AI önerisi ile 3 bütçe kategorisi oluşturuldu."
}
```

Mevcut aynı ay + kategori kombinasyonu varsa **güncellenir** (upsert).

---

## Hedefler — Katkı Önerisi

```http
GET /api/v1/goals/{id}/suggest
Authorization: Bearer <token>
```

Kullanıcının ortalama aylık tasarrufuna ve hedefe kalan süreye göre öneri hesaplar.

**Response `200`:**
```json
{
  "suggested": 2000.00,
  "affordable": 1600.00,
  "avg_savings": 4000.00,
  "months_left": 24,
  "remaining": 48000.00
}
```

| Alan | Açıklama |
|------|----------|
| `suggested` | Hedefe zamanında ulaşmak için gereken aylık katkı |
| `affordable` | Ortalama aylık tasarrufun %40'ı (gerçekçi öneri) |
| `avg_savings` | Son 3 ayın ortalama net tasarrufu |
| `months_left` | `target_date` varsa kalan ay sayısı, yoksa `null` |
| `remaining` | `target_amount - current_amount` |

---

## Kişisel Borçlar

### Listele

```http
GET /api/v1/personal-debts
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "given": [
    {
      "id": 1,
      "contact_name": "Ahmet Yılmaz",
      "amount": 500.00,
      "direction": "given",
      "note": "Akşam yemeği borcu",
      "is_settled": false,
      "settled_at": null,
      "transaction_id": null,
      "created_at": "2026-05-01T10:00:00+03:00"
    }
  ],
  "received": [
    {
      "id": 2,
      "contact_name": "Zeynep Kaya",
      "amount": 200.00,
      "direction": "received",
      "note": null,
      "is_settled": false,
      "settled_at": null,
      "transaction_id": "uuid-...",
      "created_at": "2026-04-28T14:00:00+03:00"
    }
  ],
  "stats": {
    "given_active": 1500.00,
    "received_active": 800.00,
    "net_position": 700.00,
    "settled_count": 3
  }
}
```

**`direction` değerleri:** `given` (verilen) · `received` (alınan)  
**`net_position`:** pozitif = net alacaklısın, negatif = net borçlusun

---

### Borç Ekle

```http
POST /api/v1/personal-debts
Authorization: Bearer <token>
```

**Body:**
```json
{
  "contact_name": "Ahmet Yılmaz",
  "amount": 500,
  "direction": "given",
  "note": "Akşam yemeği"
}
```

**Validasyon:**

| Alan | Kural |
|------|-------|
| `contact_name` | zorunlu, max 120 |
| `amount` | zorunlu, sayısal, min 0.01 |
| `direction` | zorunlu, `given` veya `received` |
| `note` | opsiyonel, max 500 |

**Response `201`:**
```json
{ "debt": { /* borç nesnesi */ } }
```

---

### Borcu Kapat

```http
PATCH /api/v1/personal-debts/{id}/settle
Authorization: Bearer <token>
```

Body gönderilmez. `is_settled = true`, `settled_at = now()` olarak işaretlenir.

**Response `200`:**
```json
{ "debt": { /* güncel borç nesnesi, is_settled: true */ } }
```

---

### Borç Sil

```http
DELETE /api/v1/personal-debts/{id}
Authorization: Bearer <token>
```

---

## Yatırım Portföyü

### Portföy Listesi (Canlı Fiyatlı)

```http
GET /api/v1/investments
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "assets": [
    {
      "id": 1,
      "asset_type": "usd",
      "name": "Amerikan Doları",
      "quantity": 1000.00,
      "buy_price_try": 30.50,
      "buy_value_try": 30500.00,
      "current_price_try": 32.25,
      "current_value_try": 32250.00,
      "gain_loss_try": 1750.00,
      "gain_loss_pct": 5.74,
      "buy_date": "2025-11-15",
      "notes": null,
      "type_label": "Amerikan Doları (USD)",
      "type_icon": "tabler-currency-dollar",
      "type_color": "success"
    },
    {
      "id": 2,
      "asset_type": "gold_gram",
      "name": "Gram Altın",
      "quantity": 50.00,
      "buy_price_try": 2800.00,
      "buy_value_try": 140000.00,
      "current_price_try": 3150.00,
      "current_value_try": 157500.00,
      "gain_loss_try": 17500.00,
      "gain_loss_pct": 12.50,
      "buy_date": "2025-09-01",
      "notes": null,
      "type_label": "Gram Altın",
      "type_icon": "tabler-coin",
      "type_color": "warning"
    }
  ],
  "totals": {
    "current_value": 189750.00,
    "buy_value": 170500.00,
    "gain_loss": 19250.00,
    "gain_loss_pct": 11.29
  }
}
```

> `current_price_try` ve `current_value_try` canlı kur/altın verilerinden hesaplanır. Veri alınamazsa `null` olabilir.

**`asset_type` değerleri:**

| Değer | Açıklama |
|-------|----------|
| `gold_gram` | Gram altın |
| `gold_quarter` | Çeyrek altın |
| `gold_republic` | Cumhuriyet altını |
| `usd` | Amerikan Doları |
| `eur` | Euro |
| `gbp` | İngiliz Sterlini |
| `btc` | Bitcoin |
| `eth` | Ethereum |
| `bist` | BIST hisse senedi |
| `fund` | Yatırım fonu |
| `mevduat` | Vadeli mevduat |
| `other` | Diğer |

---

### Varlık Ekle

```http
POST /api/v1/investments
Authorization: Bearer <token>
```

**Body:**
```json
{
  "asset_type": "usd",
  "name": "Amerikan Doları",
  "quantity": 1000,
  "buy_price_try": 30.50,
  "buy_date": "2025-11-15",
  "notes": "Birikim hesabından"
}
```

**Validasyon:**

| Alan | Kural |
|------|-------|
| `asset_type` | zorunlu, geçerli değer (yukarıdaki liste) |
| `name` | zorunlu, max 120 |
| `quantity` | zorunlu, sayısal, min 0.0001 (kripto için 8 ondalık hassasiyet) |
| `buy_price_try` | zorunlu, sayısal, min 0.01 |
| `buy_date` | zorunlu, geçerli tarih |
| `notes` | opsiyonel, max 1000 |

**Response `201`:**
```json
{ "asset": { /* varlık nesnesi */ } }
```

---

### Varlık Sil

```http
DELETE /api/v1/investments/{id}
Authorization: Bearer <token>
```

---

## Kur & Altın Alarmları

### Alarmlar + Anlık Kurlar

```http
GET /api/v1/fx-alerts
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "alerts": [
    {
      "id": 1,
      "currency": "USD",
      "condition": "above",
      "threshold": 33.00,
      "is_active": true,
      "triggered_at": null,
      "current_rate": 32.25,
      "is_triggered": false
    }
  ],
  "rates": {
    "USD": {
      "currency": "USD",
      "name": "Amerikan Doları",
      "symbol": "$",
      "rate": 32.25,
      "change": 0.15,
      "change_pct": 0.47,
      "date": "2026-05-12"
    },
    "EUR": {
      "currency": "EUR",
      "name": "Euro",
      "symbol": "€",
      "rate": 34.80,
      "change": -0.10,
      "change_pct": -0.29,
      "date": "2026-05-12"
    },
    "GOLD": {
      "currency": "GOLD",
      "name": "Gram Altın",
      "symbol": "₺",
      "rate": 3150.00,
      "change": 25.00,
      "change_pct": 0.80,
      "date": "2026-05-12"
    }
  }
}
```

**`condition` değerleri:** `above` (üstüne çıkınca tetikle) · `below` (altına düşünce tetikle)

---

### Canlı Kur/Altın Verileri

```http
GET /api/v1/fx-alerts/rates
Authorization: Bearer <token>
```

Alarm olmadan sadece güncel kur verilerini döner. 55 saniye cache'lenir.

**Response `200`:**
```json
{
  "source": "yahoo",
  "at": "14:32:15",
  "date": "12.05.2026",
  "rates": {
    "USD": { "currency": "USD", "rate": 32.25, "change": 0.15, "change_pct": 0.47 },
    "EUR": { "currency": "EUR", "rate": 34.80, "change": -0.10, "change_pct": -0.29 },
    "GBP": { "currency": "GBP", "rate": 41.20, "change": 0.30, "change_pct": 0.73 },
    "GOLD": { "currency": "GOLD", "rate": 3150.00, "change": 25.00, "change_pct": 0.80 }
  }
}
```

---

### Alarm Oluştur

```http
POST /api/v1/fx-alerts
Authorization: Bearer <token>
```

**Body:**
```json
{
  "currency": "USD",
  "condition": "above",
  "threshold": 33.00
}
```

**Validasyon:**

| Alan | Kural |
|------|-------|
| `currency` | zorunlu, max 10 (USD, EUR, GBP, GOLD, BTC...) |
| `condition` | zorunlu, `above` veya `below` |
| `threshold` | zorunlu, sayısal, min 0.01 |

**Response `201`:**
```json
{ "alert": { /* alarm nesnesi */ } }
```

---

### Alarm Sil

```http
DELETE /api/v1/fx-alerts/{id}
Authorization: Bearer <token>
```

---

## Müzakere Ajanı

### Taslak Listesi

```http
GET /api/v1/negotiation
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "drafts": [
    {
      "id": 1,
      "target": "card_interest",
      "target_label": "Kredi Kartı Faiz İndirimi",
      "recipient_name": "Müşteri Hizmetleri",
      "subject": "Kredi Kartı Faiz Oranı İndirimi Talebim",
      "body": "Sayın yetkili...",
      "status": "sent",
      "created_at": "2026-05-01T10:00:00+03:00"
    }
  ]
}
```

**`target` değerleri:**

| Değer | Açıklama |
|-------|----------|
| `card_interest` | Kredi kartı faiz indirimi |
| `loan_restructure` | Kredi yeniden yapılandırma |
| `bank_fee_waiver` | Banka ücreti muafiyeti |
| `subscription_cancel` | Abonelik iptali müzakeresi |
| `insurance_discount` | Sigorta indirimi |
| `salary_raise` | Maaş artışı talebi |
| `other` | Diğer |

**`status` değerleri:** `draft` · `sent` · `accepted` · `rejected`

---

### AI Mektubu Oluştur

```http
POST /api/v1/negotiation/generate
Authorization: Bearer <token>
```

**Body:**
```json
{
  "target": "card_interest",
  "recipient_name": "Garanti BBVA Müşteri Hizmetleri",
  "extra_context": "5 yıldır müşteriyim, son 6 ayda hiç gecikme yaşamadım."
}
```

**Validasyon:**

| Alan | Kural |
|------|-------|
| `target` | zorunlu, geçerli değer |
| `recipient_name` | opsiyonel, max 200 |
| `extra_context` | opsiyonel, max 1000 — AI'ya ek bağlam verir |

**Response `200`:**
```json
{
  "draft": {
    "id": 3,
    "target": "card_interest",
    "target_label": "Kredi Kartı Faiz İndirimi",
    "recipient_name": "Garanti BBVA Müşteri Hizmetleri",
    "subject": "Kredi Kartı Faiz Oranı İndirimi Talebim",
    "body": "Sayın Yetkili,\n\nGaranti BBVA'nın değerli bir müşterisi olarak...",
    "status": "draft",
    "created_at": "2026-05-12T11:00:00+03:00"
  },
  "key_arguments": [
    "5 yıllık müşteri sadakati",
    "Düzenli ödeme geçmişi (0 gecikme)",
    "Rakip bankaların daha düşük faiz oranları"
  ],
  "success_tips": [
    "Sabah 09:00-11:00 saatleri arasında arayın",
    "Nezaket ve sakinlik üslubunu koruyun"
  ],
  "estimated_chance": 72.5
}
```

> `body` alanı kullanıcının gerçek finansal verileriyle kişiselleştirilmiş, Türkçe Gemini Pro çıktısıdır.

---

### Taslak Durumunu Güncelle

```http
PATCH /api/v1/negotiation/{id}/status
Authorization: Bearer <token>
```

**Body:**
```json
{ "status": "sent" }
```

Geçerli geçişler: `draft → sent → accepted` veya `draft → sent → rejected`

**Response `200`:**
```json
{ "draft": { /* güncel taslak */ } }
```

---

### Taslak Sil

```http
DELETE /api/v1/negotiation/{id}
Authorization: Bearer <token>
```

---

## Karar Simülatörü

### Mevcut Finansal Durum

Simülatör için ön yükleme verisi — kullanıcının güncel rakamları.

```http
GET /api/v1/simulator
Authorization: Bearer <token>
```

**Response `200`:**
```json
{
  "monthly_income": 45000.00,
  "avg_monthly_expense": 32000.00,
  "total_balance": 48240.00,
  "total_card_debt": 3200.00,
  "health_score": 74,
  "inflation_rate": 37.9
}
```

---

### Senaryo Hesapla

```http
POST /api/v1/simulator/calculate
Authorization: Bearer <token>
```

**Body:**
```json
{
  "income_change_pct": 10,
  "expense_change_pct": -5,
  "inflation_rate": 38,
  "months_horizon": 12,
  "monthly_income": 45000,
  "avg_monthly_expense": 32000,
  "total_balance": 48240,
  "total_card_debt": 3200
}
```

**Validasyon:**

| Alan | Kural | Açıklama |
|------|-------|----------|
| `income_change_pct` | sayısal, -50 ile 200 arası | Gelir değişim yüzdesi |
| `expense_change_pct` | sayısal, -50 ile 100 arası | Gider değişim yüzdesi |
| `inflation_rate` | sayısal, 0 ile 100 arası | Yıllık enflasyon varsayımı |
| `months_horizon` | tam sayı, 1 ile 60 arası | Projeksiyon süresi (ay) |
| `monthly_income` | sayısal, min 0 | Aylık net gelir |
| `avg_monthly_expense` | sayısal, min 0 | Aylık ortalama gider |
| `total_balance` | sayısal | Toplam mevcut bakiye |
| `total_card_debt` | sayısal, min 0 | Toplam kart borcu |

**Response `200`:**
```json
{
  "projections": [
    { "month": 1,  "balance": 61240.00, "real_balance": 59842.00, "card_debt": 0.00 },
    { "month": 6,  "balance": 121240.00, "real_balance": 113520.00, "card_debt": 0.00 },
    { "month": 12, "balance": 191240.00, "real_balance": 172350.00, "card_debt": 0.00 }
  ],
  "new_income": 49500.00,
  "new_expense": 30400.00,
  "new_savings": 19100.00,
  "savings_rate_pct": 38.6,
  "estimated_score": 82,
  "final_balance": 191240.00,
  "real_final_balance": 172350.00,
  "inflation_loss": 18890.00,
  "months_emergency": 5.97
}
```

| Alan | Açıklama |
|------|----------|
| `projections` | Her ay için nominal ve reel bakiye (tüm aylar veya önemli noktalar) |
| `real_balance` | Enflasyona göre düzeltilmiş satın alma gücü |
| `inflation_loss` | Enflasyon nedeniyle eriyen değer |
| `months_emergency` | Son bakiyeyle kaç aylık gideri karşılayabilirsin |
| `estimated_score` | Projeksiyon sonunda tahmini finansal sağlık skoru |

---

## Finansal Takvim

```http
GET /api/v1/calendar?month=2026-05
Authorization: Bearer <token>
```

**Query parametreleri:**

| Param | Tip | Açıklama |
|-------|-----|----------|
| `month` | string | `YYYY-MM` formatı, varsayılan mevcut ay |

**Response `200`:**
```json
{
  "month": "2026-05",
  "prev_month": "2026-04",
  "next_month": "2026-06",
  "total_monthly_payments": 4850.00,
  "event_count": 8,
  "events": {
    "3": [
      {
        "type": "card_due",
        "title": "Garanti Kredi Kartı — Son Ödeme",
        "amount": 3200.00,
        "color": "danger",
        "icon": "tabler-credit-card",
        "link": "/cards"
      }
    ],
    "15": [
      {
        "type": "bill",
        "title": "Elektrik (BEDAŞ)",
        "amount": 1150.00,
        "color": "warning",
        "icon": "tabler-bolt",
        "link": "/bills"
      },
      {
        "type": "subscription",
        "title": "Netflix",
        "amount": 149.99,
        "color": "info",
        "icon": "tabler-device-tv",
        "link": "/subscriptions"
      }
    ],
    "20": [
      {
        "type": "bill",
        "title": "Doğalgaz (İGDAŞ)",
        "amount": 800.00,
        "color": "warning",
        "icon": "tabler-flame",
        "link": "/bills"
      },
      {
        "type": "loan",
        "title": "Konut Kredisi Taksiti",
        "amount": 9800.00,
        "color": "primary",
        "icon": "tabler-home",
        "link": "/loans"
      }
    ]
  }
}
```

> `events` objesi anahtar olarak ayın günü (string), değer olarak o günün etkinlik dizisini içerir.

**`type` değerleri:**

| Değer | Açıklama |
|-------|----------|
| `bill` | Fatura vade günü |
| `subscription` | Abonelik yenileme |
| `loan` | Kredi taksit günü |
| `card_due` | Kredi kartı son ödeme günü |
| `card_statement` | Kredi kartı ekstre günü |

---

## Aylık Rapor

### Rapor Özeti (JSON)

```http
GET /api/v1/report/summary?month=2026-04
Authorization: Bearer <token>
```

**Query parametreleri:**

| Param | Tip | Açıklama |
|-------|-----|----------|
| `month` | string | `YYYY-MM` formatı, varsayılan mevcut ay |

**Response `200`:**
```json
{
  "period": "2026-04",
  "period_label": "Nisan 2026",
  "income": {
    "total": 45000.00,
    "transactions": 3
  },
  "expenses": {
    "total": 31420.00,
    "transactions": 87
  },
  "net_savings": 13580.00,
  "savings_rate_pct": 30.2,
  "top_categories": [
    { "name": "Market", "amount": 4250.00, "pct": 13.5, "icon": "tabler-shopping-cart" },
    { "name": "Restoran & Kafe", "amount": 2800.00, "pct": 8.9, "icon": "tabler-knife" },
    { "name": "Ulaşım", "amount": 2100.00, "pct": 6.7, "icon": "tabler-car" }
  ],
  "health_score": {
    "score": 74,
    "change": 2
  },
  "personal_inflation": {
    "rate": 42.8,
    "vs_official": 4.9
  },
  "available_months": ["2026-05", "2026-04", "2026-03", "2026-02", "2026-01", "2025-12"]
}
```

---

### PDF Rapor İndir

```http
GET /api/v1/report/pdf?month=2026-04
Authorization: Bearer <token>
```

**Response:** Binary PDF dosyası  
**Content-Type:** `application/pdf`  
**Content-Disposition:** `attachment; filename="paranette-rapor-2026-04.pdf"`

> Flutter'da `dio` ile indirme:
> ```dart
> final response = await dio.get(
>   '/report/pdf',
>   queryParameters: {'month': '2026-04'},
>   options: Options(responseType: ResponseType.bytes),
> );
> // response.data → Uint8List (PDF bytes)
> ```

---

## Flutter Örnek Kullanım

```dart
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'http://paranette.local:8000/api/v1',
  headers: {'Accept': 'application/json'},
));

// Token'ı interceptor ile ekle
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    final token = AuthStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  },
  onError: (error, handler) {
    if (error.response?.statusCode == 401) {
      // Token süresi doldu → login sayfasına yönlendir
      AuthStorage.clearToken();
      NavigationService.pushReplace('/login');
    }
    handler.next(error);
  },
));

// Kayıt / Giriş
final loginRes = await dio.post('/auth/login', data: {
  'email': email,
  'password': password,
  'device_name': 'Flutter App',
});
AuthStorage.saveToken(loginRes.data['token']);

// Dashboard
final dashboard = await dio.get('/dashboard');
final balance = dashboard.data['summary']['total_balance'];

// İşlem listesi
final txRes = await dio.get('/transactions', queryParameters: {
  'type': 'expense',
  'from': '2026-05-01',
  'per_page': 30,
});

// AI ajan mesajı
final chat = await dio.post('/agent/send', data: {
  'message': 'Bütçemi nasıl optimize edebilirim?',
  'session_id': 'session-$userId',
});
print(chat.data['reply']); // Markdown string

// Fiş yükle (OCR)
final formData = FormData.fromMap({
  'image': await MultipartFile.fromFile('/path/to/receipt.jpg'),
});
final receipt = await dio.post('/receipts', data: formData);

// Hedefe para ekle
await dio.post('/goals/1/add-funds', data: {'amount': 500});
```

---

## Notlar

- **Timestamps:** Tüm tarih/saat alanları ISO 8601 formatında (`2026-05-12T10:30:00+03:00`)
- **Para birimleri:** Tüm tutarlar float, 2 ondalık hassasiyet (`decimal:2`)
- **Soft delete:** Fatura, abonelik, hedef, kredi, hesap, işlem, fiş kayıtları silinmez — soft delete uygulanır
- **Sahiplik kontrolü:** Her endpoint kullanıcı sahipliğini doğrular — başka kullanıcının kaydına erişim `403` döner
- **Para birimi dönüşümü:** İşlemlerde hem orijinal `amount/currency` hem TRY karşılığı `try_amount` bulunur
- **Markdown:** `/agent/send` yanıtındaki `reply` alanı Markdown formatındadır
