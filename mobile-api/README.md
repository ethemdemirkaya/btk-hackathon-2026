# Paranette Mobile API

Laravel Sanctum tabanlı, Flutter mobil uygulaması için REST API.

**Base URL:** `http://<host>/api/v1`  
**Auth:** `Authorization: Bearer <token>`  
**Format:** JSON (`Content-Type: application/json`)

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

**Response `201`:**
```json
{
  "token": "1|abc123...",
  "user": {
    "id": 1,
    "name": "Ethem Demirkaya",
    "email": "ethem@example.com",
    "monthly_income": 45000.0,
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

**Response `200`:** — `register` ile aynı yapı.

---

### Profil Görüntüle

```http
GET /api/v1/auth/me
Authorization: Bearer <token>
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

---

### Çıkış

```http
DELETE /api/v1/auth/logout
DELETE /api/v1/auth/logout-all   ← Tüm cihazlardan çıkış
```

---

## Dashboard

### Finansal Özet

```http
GET /api/v1/dashboard
Authorization: Bearer <token>
```

**Response:**
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
    { "month": "Ara", "income": 45000, "expense": 32000 }
  ],
  "category_spend": [
    { "category": "Market", "total": 8400.00 }
  ],
  "personal_inflation": {
    "personal_rate": 42.8,
    "tufe_rate": 37.9,
    "diff": 4.9,
    "breakdown": [
      { "category": "Konut", "weight_pct": 35, "tuik_rate": 59.1 }
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
    { "name": "Market", "amount": 5000, "spent": 4250, "pct": 85, "over_budget": false }
  ],
  "health_score": {
    "score": 74,
    "debt_ratio_score": 65,
    "savings_rate_score": 80,
    "emergency_fund_score": 70,
    "expense_consistency_score": 82,
    "calculated_at": "2026-05-11T09:00:00"
  },
  "macro_indicators": []
}
```

---

## Banka Bağlantıları

### Listele

```http
GET /api/v1/bank-connections
```

**Response:**
```json
{
  "connections": [
    {
      "id": 1,
      "bank": { "id": 1, "name": "Ziraat Bankası", "slug": "ziraat", "logo": "banks/ziraat.svg" },
      "status": "active",
      "last_sync_at": "2026-05-11T08:00:00+03:00",
      "accounts": [
        {
          "id": 1,
          "account_type": "checking",
          "iban": "TR33****1234",
          "currency": "TRY",
          "balance": 15200.00,
          "available_balance": 14800.00
        }
      ]
    }
  ]
}
```

---

### Banka Bağla

```http
POST /api/v1/bank-connections
```

**Body (Ziraat için):**
```json
{
  "bank_slug": "ziraat",
  "credentials": {
    "username": "kullanici",
    "password": "sifre"
  }
}
```

**Desteklenen `bank_slug` değerleri:** `ziraat`, `garanti`, `isbank`, `akbank`

---

### Senkronize Et

```http
POST /api/v1/bank-connections/{id}/sync
```

---

### Bağlantıyı Sil

```http
DELETE /api/v1/bank-connections/{id}
```

---

## İşlemler

### Listele (Filtrelenebilir)

```http
GET /api/v1/transactions?type=expense&from=2026-04-01&to=2026-04-30&per_page=20
```

**Query parametreleri:**

| Param     | Tip    | Açıklama                     |
|-----------|--------|------------------------------|
| `type`    | string | `income` veya `expense`      |
| `from`    | date   | Başlangıç tarihi `YYYY-MM-DD`|
| `to`      | date   | Bitiş tarihi `YYYY-MM-DD`    |
| `per_page`| int    | Sayfa başına kayıt (1–100)   |

**Response:**
```json
{
  "data": [
    {
      "id": "uuid-...",
      "posted_at": "2026-04-15T14:22:00",
      "amount": -245.50,
      "currency": "TRY",
      "description": "Migros Market",
      "merchant_name": "Migros",
      "merchant_category": "Grocery",
      "channel": "pos",
      "is_recurring": false,
      "anomaly_score": null
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

---

### Detay

```http
GET /api/v1/transactions/{id}
```

---

## Kredi Kartları

```http
GET /api/v1/cards
```

**Response:**
```json
{
  "cards": [
    {
      "id": 1,
      "type": "credit",
      "masked_number": "**** **** **** 4521",
      "holder_name": "ETHEM DEMIRKAYA",
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

---

## Krediler

```http
GET /api/v1/loans
```

**Response:**
```json
{
  "loans": [
    {
      "id": 1,
      "type": "mortgage",
      "principal": 800000.00,
      "current_balance": 720000.00,
      "interest_rate": 3.49,
      "total_installments": 120,
      "paid_installments": 12,
      "remaining_installments": 108,
      "progress_pct": 10.0,
      "next_payment_date": "2026-06-01",
      "next_payment_amount": 9800.00
    }
  ],
  "total_balance": 720000.00,
  "due_next_30_days": 9800.00
}
```

---

## Faturalar

### Listele

```http
GET /api/v1/bills
```

### Ekle

```http
POST /api/v1/bills
```

```json
{
  "name": "Doğalgaz",
  "type": "gas",
  "provider": "İGDAŞ",
  "account_number": "123456789",
  "average_amount": 800,
  "due_day": 20,
  "is_autopay": false
}
```

### Güncelle / Sil

```http
PATCH /api/v1/bills/{id}
DELETE /api/v1/bills/{id}
```

---

## Abonelikler

### Listele

```http
GET /api/v1/subscriptions
```

**Response:**
```json
{
  "subscriptions": [
    {
      "id": 1,
      "name": "Netflix",
      "amount": 149.99,
      "currency": "TRY",
      "billing_cycle": "monthly",
      "monthly_equivalent": 149.99,
      "next_billing_date": "2026-06-01",
      "auto_detected": true,
      "status": "active"
    }
  ],
  "total_monthly": 549.97,
  "candidates": [
    { "merchant_name": "Spotify", "avg_amount": 59.99, "occurrences": 4 }
  ]
}
```

### Ekle

```http
POST /api/v1/subscriptions
```

```json
{
  "name": "Spotify",
  "amount": 59.99,
  "billing_cycle": "monthly",
  "next_billing_date": "2026-06-05"
}
```

### İptal Et

```http
DELETE /api/v1/subscriptions/{id}
```

---

## Bütçeler

### Listele (aya göre)

```http
GET /api/v1/budgets?period=2026-05
```

### Oluştur / Güncelle

```http
POST /api/v1/budgets
```

```json
{
  "category_id": 3,
  "amount": 5000,
  "alert_threshold": 80,
  "period": "2026-05"
}
```

> `period` yoksa mevcut ay kullanılır. Aynı kategori+dönem varsa güncellenir.

### Sil

```http
DELETE /api/v1/budgets/{id}
```

---

## Hedefler

### Listele

```http
GET /api/v1/goals
```

**Response:**
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

### Oluştur

```http
POST /api/v1/goals
```

```json
{
  "name": "Tatil Fonu",
  "target_amount": 20000,
  "current_amount": 500,
  "target_date": "2026-08-01",
  "monthly_contribution": 2000
}
```

### Para Ekle

```http
POST /api/v1/goals/{id}/add-funds
```

```json
{ "amount": 500 }
```

### Sil

```http
DELETE /api/v1/goals/{id}
```

---

## Kişisel Enflasyon

```http
GET /api/v1/inflation
```

**Response:**
```json
{
  "personal_rate": 42.8,
  "tufe_rate": 37.9,
  "diff": 4.9,
  "breakdown": [
    { "category": "Konut & Kira", "weight_pct": 35.2, "tuik_rate": 59.1 }
  ],
  "period": "2026-04",
  "tufe_history": [
    { "period": "2026-04", "annual_rate": 37.9, "monthly_rate": 2.1 }
  ],
  "category_rates": [
    { "category": "Eğitim", "rate": 75.3, "period": "2026-04" }
  ]
}
```

---

## AI Ajan Asistan

### Mesaj Gönder

```http
POST /api/v1/agent/send
```

```json
{
  "message": "Bu ay ne kadar harcadım?",
  "session_id": "flutter-session-001"
}
```

**Response:**
```json
{
  "reply": "Nisan ayında toplam ₺18.420 harcama yaptınız. En yüksek kategori Market: ₺4.200.",
  "agents_used": ["BudgetAdvisorAgent", "TransactionClassifierAgent"],
  "session_id": "flutter-session-001",
  "run_id": 42
}
```

---

### Geçmiş Konuşmalar

```http
GET /api/v1/agent/history?session_id=flutter-session-001
```

---

### AI Öngörüleri

```http
GET /api/v1/agent/insights
```

---

### Öngörü Kapat

```http
PATCH /api/v1/agent/insights/{id}/dismiss
```

---

## Fişler & OCR

### Listele

```http
GET /api/v1/receipts
```

### Fiş Yükle (OCR)

```http
POST /api/v1/receipts
Content-Type: multipart/form-data
```

| Alan    | Tip   | Açıklama                 |
|---------|-------|--------------------------|
| `image` | file  | JPEG/PNG, maks 10 MB     |

**Response `201`:**
```json
{
  "receipt": {
    "id": 5,
    "merchant_name": "Migros",
    "total_amount": 245.50,
    "currency": "TRY",
    "purchased_at": "2026-05-10T15:30:00+03:00",
    "category": "Market",
    "items": [
      { "name": "Süt 1L", "qty": 2, "price": 34.90 }
    ]
  }
}
```

### Sil

```http
DELETE /api/v1/receipts/{id}
```

---

## Hata Yanıtları

| HTTP | Durum            | Açıklama                            |
|------|------------------|-------------------------------------|
| 401  | Unauthenticated  | Token eksik veya geçersiz           |
| 403  | Forbidden        | Kaynak başka kullanıcıya ait        |
| 404  | Not Found        | Kayıt bulunamadı                    |
| 422  | Unprocessable    | Validasyon hatası                   |
| 500  | Server Error     | Sunucu hatası (AI/OCR servisi fail) |

**422 örnek:**
```json
{
  "message": "The email field must be a valid email address.",
  "errors": {
    "email": ["The email field must be a valid email address."]
  }
}
```

---

## Token Yönetimi

- Token süresi: **30 gün**
- Token geçersiz olduğunda `401` döner → yeniden login gerekir
- `DELETE /api/v1/auth/logout` mevcut token'ı siler
- `DELETE /api/v1/auth/logout-all` tüm cihazlardan çıkış yapar

---

## Flutter Örnek Kullanım

```dart
// login
final res = await dio.post('/api/v1/auth/login', data: {
  'email': email,
  'password': password,
  'device_name': 'Flutter App',
});
final token = res.data['token'];

// authenticated request
dio.options.headers['Authorization'] = 'Bearer $token';
final dashboard = await dio.get('/api/v1/dashboard');

// AI mesaj gönder
final chat = await dio.post('/api/v1/agent/send', data: {
  'message': 'Birikim önerilerin neler?',
  'session_id': 'session-${userId}',
});
print(chat.data['reply']);
```

---

## Endpoint Özeti

| Method | Endpoint                              | Açıklama                  |
|--------|---------------------------------------|---------------------------|
| POST   | /auth/register                        | Kayıt                     |
| POST   | /auth/login                           | Giriş                     |
| GET    | /auth/me                              | Profil görüntüle          |
| PATCH  | /auth/me                              | Profil güncelle           |
| DELETE | /auth/logout                          | Çıkış                     |
| DELETE | /auth/logout-all                      | Tüm cihazlardan çıkış     |
| GET    | /dashboard                            | Finansal özet             |
| GET    | /bank-connections                     | Banka bağlantıları        |
| POST   | /bank-connections                     | Banka bağla               |
| POST   | /bank-connections/{id}/sync           | Senkronize et             |
| DELETE | /bank-connections/{id}                | Bağlantıyı sil            |
| GET    | /transactions                         | İşlem listesi             |
| GET    | /transactions/{id}                    | İşlem detayı              |
| GET    | /cards                                | Kredi kartları            |
| GET    | /loans                                | Krediler                  |
| GET    | /bills                                | Faturalar                 |
| POST   | /bills                                | Fatura ekle               |
| PATCH  | /bills/{id}                           | Fatura güncelle           |
| DELETE | /bills/{id}                           | Fatura sil                |
| GET    | /subscriptions                        | Abonelikler               |
| POST   | /subscriptions                        | Abonelik ekle             |
| DELETE | /subscriptions/{id}                   | Abonelik iptal            |
| GET    | /budgets                              | Bütçeler                  |
| POST   | /budgets                              | Bütçe oluştur             |
| DELETE | /budgets/{id}                         | Bütçe sil                 |
| GET    | /goals                                | Hedefler                  |
| POST   | /goals                                | Hedef oluştur             |
| POST   | /goals/{id}/add-funds                 | Para ekle                 |
| DELETE | /goals/{id}                           | Hedef sil                 |
| GET    | /inflation                            | Kişisel enflasyon         |
| POST   | /agent/send                           | AI ajan mesajı            |
| GET    | /agent/history                        | Konuşma geçmişi           |
| GET    | /agent/insights                       | AI öngörüleri             |
| PATCH  | /agent/insights/{id}/dismiss          | Öngörü kapat              |
| GET    | /receipts                             | Fiş listesi               |
| POST   | /receipts                             | Fiş yükle (OCR)           |
| DELETE | /receipts/{id}                        | Fiş sil                   |
