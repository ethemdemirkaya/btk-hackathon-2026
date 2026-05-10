<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>Paranette Aylık Rapor – {{ $periodLabel }}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: DejaVu Sans, Arial, sans-serif; font-size: 10px; color: #1e293b; line-height: 1.5; }

    /* ── Layout ── */
    .page { padding: 28px 32px; }

    /* ── Header ── */
    .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #1A56DB; padding-bottom: 14px; margin-bottom: 20px; }
    .logo-area h1 { font-size: 22px; color: #1A56DB; font-weight: 700; letter-spacing: -.3px; }
    .logo-area p  { font-size: 9px; color: #64748b; margin-top: 2px; }
    .header-meta  { text-align: right; font-size: 9px; color: #64748b; }
    .header-meta strong { font-size: 11px; color: #1e293b; display: block; }

    /* ── Section title ── */
    .section-title { font-size: 11px; font-weight: 700; color: #1A56DB; text-transform: uppercase; letter-spacing: .5px; border-bottom: 1px solid #e2e8f0; padding-bottom: 5px; margin-bottom: 10px; margin-top: 18px; }

    /* ── Summary row of 4 cards ── */
    .kpi-row { display: flex; gap: 10px; margin-bottom: 4px; }
    .kpi-card { flex: 1; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px 12px; }
    .kpi-card .label { font-size: 8.5px; color: #64748b; text-transform: uppercase; letter-spacing: .3px; }
    .kpi-card .value { font-size: 14px; font-weight: 700; margin-top: 2px; }
    .kpi-card .sub   { font-size: 8px; color: #94a3b8; margin-top: 1px; }
    .green  { color: #16a34a; }
    .red    { color: #dc2626; }
    .blue   { color: #1A56DB; }
    .orange { color: #d97706; }

    /* ── Tables ── */
    table { width: 100%; border-collapse: collapse; margin-top: 6px; }
    thead th { background: #f8fafc; font-size: 8.5px; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: .3px; padding: 6px 8px; border-bottom: 1px solid #e2e8f0; }
    tbody td { padding: 5px 8px; border-bottom: 1px solid #f1f5f9; font-size: 9px; }
    tbody tr:last-child td { border-bottom: none; }
    .text-right { text-align: right; }
    .text-center { text-align: center; }
    .fw-bold { font-weight: 700; }

    /* ── Score bar ── */
    .score-section { display: flex; align-items: center; gap: 16px; }
    .score-circle { width: 52px; height: 52px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; font-weight: 700; border: 3px solid; flex-shrink: 0; }
    .score-bar-bg { flex: 1; height: 8px; background: #e2e8f0; border-radius: 4px; }
    .score-bar-fill { height: 8px; border-radius: 4px; }

    /* ── Category bars ── */
    .cat-row { margin-bottom: 6px; }
    .cat-row .cat-label { display: flex; justify-content: space-between; font-size: 9px; margin-bottom: 2px; }
    .cat-bar-bg  { background: #f1f5f9; border-radius: 3px; height: 7px; }
    .cat-bar-fill { height: 7px; border-radius: 3px; background: #1A56DB; }

    /* ── Footer ── */
    .footer { margin-top: 28px; border-top: 1px solid #e2e8f0; padding-top: 10px; display: flex; justify-content: space-between; font-size: 8px; color: #94a3b8; }

    /* ── 2-col layout ── */
    .two-col { display: flex; gap: 20px; }
    .two-col .col-left  { flex: 1; }
    .two-col .col-right { flex: 1; }

    /* ── Badge ── */
    .badge { display: inline-block; padding: 1px 6px; border-radius: 10px; font-size: 8px; font-weight: 600; }
    .badge-success { background: #dcfce7; color: #16a34a; }
    .badge-warning { background: #fef9c3; color: #a16207; }
    .badge-danger  { background: #fee2e2; color: #dc2626; }
    .badge-info    { background: #dbeafe; color: #1d4ed8; }
  </style>
</head>
<body>
<div class="page">

  {{-- ══ HEADER ══ --}}
  <div class="header">
    <div class="logo-area">
      <h1>Paranette</h1>
      <p>Kişisel Finans Asistanı &mdash; Aylık Rapor</p>
    </div>
    <div class="header-meta">
      <strong>{{ $periodLabel }}</strong>
      {{ $user->name }}<br>
      Oluşturulma: {{ now()->format('d.m.Y H:i') }}
    </div>
  </div>

  {{-- ══ KPI CARDS ══ --}}
  <div class="kpi-row">
    <div class="kpi-card">
      <div class="label">Toplam Bakiye</div>
      <div class="value blue">₺{{ number_format($totalBalance, 0, ',', '.') }}</div>
      <div class="sub">{{ $accounts->count() }} hesap</div>
    </div>
    <div class="kpi-card">
      <div class="label">Dönem Geliri</div>
      <div class="value green">₺{{ number_format($income, 0, ',', '.') }}</div>
      <div class="sub">{{ $periodLabel }}</div>
    </div>
    <div class="kpi-card">
      <div class="label">Dönem Gideri</div>
      <div class="value red">₺{{ number_format(abs($expense), 0, ',', '.') }}</div>
      <div class="sub">{{ $transactions->where('amount', '<', 0)->count() }} işlem</div>
    </div>
    <div class="kpi-card">
      <div class="label">Net Nakit Akışı</div>
      <div class="value {{ $netFlow >= 0 ? 'green' : 'red' }}">
        {{ $netFlow >= 0 ? '+' : '' }}₺{{ number_format($netFlow, 0, ',', '.') }}
      </div>
      <div class="sub">{{ $netFlow >= 0 ? 'Tasarruf' : 'Açık' }}</div>
    </div>
  </div>

  {{-- ══ TWO COLUMNS ══ --}}
  <div class="two-col" style="margin-top:18px;">

    {{-- LEFT ──────────────────────────────────────────── --}}
    <div class="col-left">

      {{-- Financial Health Score --}}
      <div class="section-title">Finansal Sağlık Skoru</div>
      @php
        $score = $healthScore?->score ?? 0;
        $scoreColor = $score >= 70 ? '#16a34a' : ($score >= 40 ? '#d97706' : '#dc2626');
      @endphp
      <div class="score-section">
        <div class="score-circle" style="color:{{ $scoreColor }};border-color:{{ $scoreColor }};">
          {{ $score }}
        </div>
        <div style="flex:1;">
          <div style="font-size:9px;color:#64748b;margin-bottom:4px;">
            {{ $score >= 70 ? 'İyi seviyede' : ($score >= 40 ? 'Orta seviyede' : 'Geliştirilmeli') }}
          </div>
          <div class="score-bar-bg">
            <div class="score-bar-fill" style="width:{{ $score }}%;background:{{ $scoreColor }};"></div>
          </div>
          <div style="font-size:8px;color:#94a3b8;margin-top:3px;">Kişisel Enflasyon: %{{ $personalInflation }}</div>
        </div>
      </div>

      {{-- Accounts --}}
      <div class="section-title">Hesaplar</div>
      <table>
        <thead><tr>
          <th>Banka</th>
          <th>IBAN</th>
          <th class="text-right">Bakiye</th>
        </tr></thead>
        <tbody>
          @foreach($accounts as $acct)
          <tr>
            <td>{{ $acct->bank_name }}</td>
            <td style="color:#64748b;">{{ substr($acct->iban, -8) ? '****' . substr($acct->iban, -4) : '—' }}</td>
            <td class="text-right fw-bold {{ $acct->balance >= 0 ? 'green' : 'red' }}">
              ₺{{ number_format($acct->balance, 2, ',', '.') }}
            </td>
          </tr>
          @endforeach
        </tbody>
      </table>

      {{-- Cards & Debt --}}
      @if($cards->count())
      <div class="section-title">Kredi Kartları</div>
      <table>
        <thead><tr>
          <th>Kart</th>
          <th class="text-right">Limit</th>
          <th class="text-right">Borç</th>
          <th class="text-right">Kullanım</th>
        </tr></thead>
        <tbody>
          @foreach($cards as $card)
          @php $usage = $card->credit_limit > 0 ? round($card->current_debt / $card->credit_limit * 100) : 0; @endphp
          <tr>
            <td>****{{ substr($card->masked_number, -4) }}</td>
            <td class="text-right">₺{{ number_format($card->credit_limit, 0, ',', '.') }}</td>
            <td class="text-right {{ $card->current_debt > 0 ? 'red' : '' }}">₺{{ number_format($card->current_debt, 0, ',', '.') }}</td>
            <td class="text-right">
              <span class="badge {{ $usage > 70 ? 'badge-danger' : ($usage > 40 ? 'badge-warning' : 'badge-success') }}">
                %{{ $usage }}
              </span>
            </td>
          </tr>
          @endforeach
        </tbody>
      </table>
      @endif

      {{-- Loans --}}
      @if($loans->count())
      <div class="section-title">Krediler</div>
      <table>
        <thead><tr>
          <th>Tür</th>
          <th class="text-right">Kalan Borç</th>
          <th class="text-right">Faiz</th>
          <th>Son Ödeme</th>
        </tr></thead>
        <tbody>
          @foreach($loans as $loan)
          <tr>
            <td>{{ ucfirst($loan->type ?? 'Kredi') }}</td>
            <td class="text-right red">₺{{ number_format($loan->current_balance, 0, ',', '.') }}</td>
            <td class="text-right">%{{ $loan->interest_rate }}</td>
            <td>{{ $loan->next_payment_date ? \Carbon\Carbon::parse($loan->next_payment_date)->format('d.m.Y') : '—' }}</td>
          </tr>
          @endforeach
        </tbody>
      </table>
      @endif

    </div>

    {{-- RIGHT ─────────────────────────────────────────── --}}
    <div class="col-right">

      {{-- Category Breakdown --}}
      <div class="section-title">Harcama Kategorileri</div>
      @php $maxCat = $categoryBreakdown->max('total') ?: 1; @endphp
      @foreach($categoryBreakdown as $cat)
      <div class="cat-row">
        <div class="cat-label">
          <span>{{ $cat->merchant_category ?: 'Diğer' }}</span>
          <span class="fw-bold">₺{{ number_format($cat->total, 0, ',', '.') }}</span>
        </div>
        <div class="cat-bar-bg">
          <div class="cat-bar-fill" style="width:{{ round($cat->total / $maxCat * 100) }}%;"></div>
        </div>
      </div>
      @endforeach

      {{-- Top Merchants --}}
      @if($topMerchants->count())
      <div class="section-title">En Çok Harcanan Yerler</div>
      <table>
        <thead><tr>
          <th>Mağaza</th>
          <th class="text-right">İşlem</th>
          <th class="text-right">Toplam</th>
        </tr></thead>
        <tbody>
          @foreach($topMerchants as $m)
          <tr>
            <td>{{ $m->merchant_name }}</td>
            <td class="text-center">{{ $m->cnt }}</td>
            <td class="text-right fw-bold red">₺{{ number_format($m->total, 0, ',', '.') }}</td>
          </tr>
          @endforeach
        </tbody>
      </table>
      @endif

      {{-- Recent Transactions --}}
      <div class="section-title">Son İşlemler</div>
      <table>
        <thead><tr>
          <th>Tarih</th>
          <th>Açıklama</th>
          <th class="text-right">Tutar</th>
        </tr></thead>
        <tbody>
          @foreach($transactions->take(15) as $tx)
          <tr>
            <td style="white-space:nowrap;color:#64748b;">{{ \Carbon\Carbon::parse($tx->posted_at)->format('d.m') }}</td>
            <td style="max-width:120px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">
              {{ $tx->merchant_name ?: mb_substr($tx->description ?? '', 0, 28) }}
            </td>
            <td class="text-right fw-bold {{ $tx->amount >= 0 ? 'green' : 'red' }}">
              {{ $tx->amount >= 0 ? '+' : '' }}₺{{ number_format(abs($tx->amount), 2, ',', '.') }}
            </td>
          </tr>
          @endforeach
        </tbody>
      </table>

    </div>
  </div>

  {{-- ══ FOOTER ══ --}}
  <div class="footer">
    <span>Paranette &mdash; TEKNOFEST Hackathon 2026 &mdash; paranette.local</span>
    <span>Bu rapor {{ now()->format('d.m.Y H:i') }} tarihinde oluşturulmuştur. Yatırım tavsiyesi değildir.</span>
  </div>

</div>
</body>
</html>
