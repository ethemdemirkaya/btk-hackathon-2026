<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <title>Paranette Aylık Rapor – {{ $periodLabel }}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: DejaVu Sans, Arial, sans-serif; font-size: 10px; color: #1e293b; line-height: 1.5; background: #fff; }

    /* ── Layout ── */
    .page { padding: 26px 30px; }

    /* ── Page break ── */
    .page-break { page-break-before: always; margin-top: 28px; }
    .no-break   { page-break-inside: avoid; }

    /* ── Header ── */
    .header { border-bottom: 2px solid #1A56DB; padding-bottom: 12px; margin-bottom: 18px; }
    .header-inner { display: table; width: 100%; }
    .header-left  { display: table-cell; vertical-align: top; }
    .header-right { display: table-cell; vertical-align: top; text-align: right; }
    .logo-area h1 { font-size: 22px; color: #1A56DB; font-weight: 700; letter-spacing: -.3px; }
    .logo-area p  { font-size: 9px; color: #64748b; margin-top: 2px; }
    .header-meta  { font-size: 9px; color: #64748b; }
    .header-meta strong { font-size: 11px; color: #1e293b; display: block; }

    /* ── Section title ── */
    .section-title { font-size: 10.5px; font-weight: 700; color: #1A56DB; text-transform: uppercase; letter-spacing: .5px; border-bottom: 1px solid #e2e8f0; padding-bottom: 4px; margin-bottom: 9px; margin-top: 16px; }

    /* ── KPI cards (table-based) ── */
    .kpi-table { width: 100%; border-collapse: separate; border-spacing: 8px 0; margin-bottom: 4px; display: table; }
    .kpi-cell  { display: table-cell; width: 25%; border: 1px solid #e2e8f0; border-radius: 8px; padding: 9px 11px; vertical-align: top; }
    .kpi-label { font-size: 8px; color: #64748b; text-transform: uppercase; letter-spacing: .3px; }
    .kpi-value { font-size: 14px; font-weight: 700; margin-top: 2px; line-height: 1.1; }
    .kpi-sub   { font-size: 8px; color: #94a3b8; margin-top: 1px; }

    /* ── Color helpers ── */
    .green  { color: #16a34a; }
    .red    { color: #dc2626; }
    .blue   { color: #1A56DB; }
    .orange { color: #d97706; }

    /* ── Health score ── */
    .score-wrap { display: table; width: 100%; }
    .score-left  { display: table-cell; width: 58px; vertical-align: middle; }
    .score-right { display: table-cell; vertical-align: middle; padding-left: 12px; }
    .score-circle { width: 50px; height: 50px; border-radius: 50%; text-align: center; line-height: 50px; font-size: 15px; font-weight: 700; border: 3px solid; }
    .score-bar-bg   { background: #e2e8f0; border-radius: 4px; height: 8px; }
    .score-bar-fill { height: 8px; border-radius: 4px; }

    /* ── Two-column layout (table-based) ── */
    .two-col-wrap { display: table; width: 100%; border-collapse: separate; border-spacing: 16px 0; margin-top: 16px; }
    .col-l { display: table-cell; width: 50%; vertical-align: top; }
    .col-r { display: table-cell; width: 50%; vertical-align: top; }

    /* ── Tables ── */
    table.data { width: 100%; border-collapse: collapse; margin-top: 5px; }
    table.data thead th { background: #f1f5f9; font-size: 8px; font-weight: 600; color: #475569; text-transform: uppercase; letter-spacing: .3px; padding: 5px 7px; border-bottom: 1px solid #e2e8f0; }
    table.data tbody td { padding: 4px 7px; border-bottom: 1px solid #f1f5f9; font-size: 9px; }
    table.data tbody tr:nth-child(even) td { background: #f8fafc; }
    table.data tbody tr:last-child td { border-bottom: none; }
    .text-right  { text-align: right; }
    .text-center { text-align: center; }
    .fw-bold     { font-weight: 700; }

    /* ── Category bars ── */
    .cat-row { margin-bottom: 5px; }
    .cat-label-row { display: table; width: 100%; margin-bottom: 2px; }
    .cat-lbl-l { display: table-cell; font-size: 9px; }
    .cat-lbl-r { display: table-cell; font-size: 9px; text-align: right; font-weight: 700; }
    .cat-bar-bg   { background: #f1f5f9; border-radius: 3px; height: 6px; }
    .cat-bar-fill { height: 6px; border-radius: 3px; background: #1A56DB; }

    /* ── Badge ── */
    .badge { display: inline-block; padding: 1px 6px; border-radius: 10px; font-size: 8px; font-weight: 600; }
    .badge-success { background: #dcfce7; color: #16a34a; }
    .badge-warning { background: #fef9c3; color: #a16207; }
    .badge-danger  { background: #fee2e2; color: #dc2626; }
    .badge-info    { background: #dbeafe; color: #1d4ed8; }

    /* ── Goals progress bar ── */
    .goal-bar-bg   { background: #e2e8f0; border-radius: 3px; height: 7px; margin-top: 3px; }
    .goal-bar-fill { height: 7px; border-radius: 3px; background: #1A56DB; }

    /* ── Budget bar ── */
    .budget-bar-bg   { background: #e2e8f0; border-radius: 3px; height: 6px; margin-top: 2px; }
    .budget-bar-fill { height: 6px; border-radius: 3px; }

    /* ── Summary stats box ── */
    .stats-box { border: 1px solid #e2e8f0; border-radius: 6px; padding: 10px 14px; background: #f8fafc; margin-bottom: 14px; }
    .stats-box-row { display: table; width: 100%; }
    .stats-box-cell { display: table-cell; width: 25%; text-align: center; vertical-align: middle; padding: 4px 0; }
    .stats-box-cell + .stats-box-cell { border-left: 1px solid #e2e8f0; }
    .stats-box .sb-label { font-size: 8px; color: #64748b; text-transform: uppercase; }
    .stats-box .sb-val   { font-size: 13px; font-weight: 700; }

    /* ── Footer ── */
    .footer { margin-top: 24px; border-top: 1px solid #e2e8f0; padding-top: 8px; display: table; width: 100%; font-size: 8px; color: #94a3b8; }
    .footer-l { display: table-cell; }
    .footer-r { display: table-cell; text-align: right; }
  </style>
</head>
<body>
<div class="page">

  {{-- ══════════════════════════════════ PAGE 1 ══════════════════════════════════ --}}

  {{-- ── HEADER ── --}}
  <div class="header no-break">
    <div class="header-inner">
      <div class="header-left">
        <div class="logo-area">
          <h1>Paranette</h1>
          <p>Kişisel Finans Asistanı &mdash; Aylık Rapor</p>
        </div>
      </div>
      <div class="header-right">
        <div class="header-meta">
          <strong>{{ $periodLabel }}</strong>
          {{ $user->name }}<br>
          Oluşturulma: {{ now()->format('d.m.Y H:i') }}
        </div>
      </div>
    </div>
  </div>

  {{-- ── KPI CARDS (4 in a row) ── --}}
  <div class="no-break">
    <div class="kpi-table">
      <div class="kpi-cell">
        <div class="kpi-label">Toplam Bakiye</div>
        <div class="kpi-value blue">₺{{ number_format($totalBalance, 0, ',', '.') }}</div>
        <div class="kpi-sub">{{ $accounts->count() }} hesap</div>
      </div>
      <div class="kpi-cell">
        <div class="kpi-label">Dönem Geliri</div>
        <div class="kpi-value green">₺{{ number_format($income, 0, ',', '.') }}</div>
        <div class="kpi-sub">{{ $periodLabel }}</div>
      </div>
      <div class="kpi-cell">
        <div class="kpi-label">Dönem Gideri</div>
        <div class="kpi-value red">₺{{ number_format(abs($expense), 0, ',', '.') }}</div>
        <div class="kpi-sub">{{ $transactions->where('amount', '<', 0)->count() }} işlem</div>
      </div>
      <div class="kpi-cell">
        <div class="kpi-label">Net Nakit Akışı</div>
        <div class="kpi-value {{ $netFlow >= 0 ? 'green' : 'red' }}">
          {{ $netFlow >= 0 ? '+' : '' }}₺{{ number_format($netFlow, 0, ',', '.') }}
        </div>
        <div class="kpi-sub">{{ $netFlow >= 0 ? 'Tasarruf' : 'Açık' }}</div>
      </div>
    </div>
  </div>

  {{-- ── FINANCIAL HEALTH SCORE ── --}}
  @php
    $score = $healthScore?->score ?? 0;
    $scoreColor = $score >= 70 ? '#16a34a' : ($score >= 40 ? '#d97706' : '#dc2626');
    $scoreLabel = $score >= 70 ? 'İyi seviyede' : ($score >= 40 ? 'Orta seviyede' : 'Geliştirilmeli');
  @endphp
  <div class="no-break">
    <div class="section-title">Finansal Sağlık Skoru</div>
    <div class="score-wrap">
      <div class="score-left">
        <div class="score-circle" style="color:{{ $scoreColor }};border-color:{{ $scoreColor }};">{{ $score }}</div>
      </div>
      <div class="score-right">
        <div style="font-size:9px;color:#64748b;margin-bottom:4px;">{{ $scoreLabel }}</div>
        <div class="score-bar-bg">
          <div class="score-bar-fill" style="width:{{ $score }}%;background:{{ $scoreColor }};"></div>
        </div>
        <div style="font-size:8px;color:#94a3b8;margin-top:3px;">Kişisel Enflasyon: %{{ $personalInflation }}</div>
      </div>
    </div>
  </div>

  {{-- ── TWO-COLUMN LAYOUT ── --}}
  <div class="two-col-wrap">

    {{-- ════ LEFT COLUMN ════ --}}
    <div class="col-l">

      {{-- Accounts --}}
      <div class="section-title">Hesaplar</div>
      <table class="data">
        <thead><tr>
          <th>Banka</th>
          <th>IBAN</th>
          <th class="text-right">Bakiye</th>
        </tr></thead>
        <tbody>
          @foreach($accounts as $acct)
          <tr>
            <td>{{ $acct->bank_name }}</td>
            <td style="color:#64748b;">****{{ substr($acct->iban, -4) ?: '—' }}</td>
            <td class="text-right fw-bold {{ $acct->balance >= 0 ? 'green' : 'red' }}">
              ₺{{ number_format($acct->balance, 2, ',', '.') }}
            </td>
          </tr>
          @endforeach
        </tbody>
      </table>

      {{-- Credit Cards --}}
      @if($cards->count())
      <div class="section-title">Kredi Kartları</div>
      <table class="data">
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
            <td>****{{ substr($card->masked_number ?? '', -4) }}</td>
            <td class="text-right">₺{{ number_format($card->credit_limit, 0, ',', '.') }}</td>
            <td class="text-right {{ $card->current_debt > 0 ? 'red' : '' }}">₺{{ number_format($card->current_debt, 0, ',', '.') }}</td>
            <td class="text-right">
              <span class="badge {{ $usage > 70 ? 'badge-danger' : ($usage > 40 ? 'badge-warning' : 'badge-success') }}">%{{ $usage }}</span>
            </td>
          </tr>
          @endforeach
        </tbody>
      </table>
      @endif

      {{-- Loans --}}
      @if($loans->count())
      <div class="section-title">Krediler</div>
      <table class="data">
        <thead><tr>
          <th>Tür</th>
          <th class="text-right">Kalan</th>
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

    {{-- ════ RIGHT COLUMN ════ --}}
    <div class="col-r">

      {{-- Category Breakdown --}}
      <div class="section-title">Harcama Kategorileri</div>
      @php $maxCat = $categoryBreakdown->max('total') ?: 1; @endphp
      @foreach($categoryBreakdown as $cat)
      <div class="cat-row">
        <div class="cat-label-row">
          <span class="cat-lbl-l">{{ $cat->merchant_category ?: 'Diğer' }}</span>
          <span class="cat-lbl-r">₺{{ number_format($cat->total, 0, ',', '.') }}</span>
        </div>
        <div class="cat-bar-bg">
          <div class="cat-bar-fill" style="width:{{ round($cat->total / $maxCat * 100) }}%;"></div>
        </div>
      </div>
      @endforeach

      {{-- Top Merchants --}}
      @if($topMerchants->count())
      <div class="section-title">En Çok Harcanan Yerler</div>
      <table class="data">
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

    </div>
  </div>

  {{-- ── FOOTER PAGE 1 ── --}}
  <div class="footer">
    <div class="footer-l">Paranette &mdash; BTK Akademi Hackathon 2026 &mdash; paranette.local</div>
    <div class="footer-r">Bu rapor {{ now()->format('d.m.Y H:i') }} tarihinde oluşturulmuştur. Yatırım tavsiyesi değildir.</div>
  </div>

  {{-- ══════════════════════════════════ PAGE 2 ══════════════════════════════════ --}}
  <div class="page-break">

    {{-- ── PAGE 2 HEADER ── --}}
    <div class="header no-break">
      <div class="header-inner">
        <div class="header-left">
          <div class="logo-area">
            <h1>Paranette</h1>
            <p>Kişisel Finans Asistanı &mdash; Aylık Rapor</p>
          </div>
        </div>
        <div class="header-right">
          <div class="header-meta">
            <strong>{{ $periodLabel }} — Sayfa 2</strong>
            {{ $user->name }}<br>
            Oluşturulma: {{ now()->format('d.m.Y H:i') }}
          </div>
        </div>
      </div>
    </div>

    {{-- ── SUMMARY STATISTICS BOX ── --}}
    @php
      $txTotal  = $transactions->count();
      $txIncome = $transactions->where('amount', '>', 0)->count();
      $txExpense = $transactions->where('amount', '<', 0)->count();
      $avgTx    = $txExpense > 0 ? abs($expense) / $txExpense : 0;
      $savingsRate = $income > 0 ? round($netFlow / $income * 100, 1) : 0;
    @endphp
    <div class="no-break">
      <div class="section-title">Dönem Özeti</div>
      <div class="stats-box">
        <div class="stats-box-row">
          <div class="stats-box-cell">
            <div class="sb-label">Toplam İşlem</div>
            <div class="sb-val blue">{{ $txTotal }}</div>
          </div>
          <div class="stats-box-cell">
            <div class="sb-label">Ortalama Gider</div>
            <div class="sb-val red">₺{{ number_format($avgTx, 0, ',', '.') }}</div>
          </div>
          <div class="stats-box-cell">
            <div class="sb-label">Tasarruf Oranı</div>
            <div class="sb-val {{ $savingsRate >= 0 ? 'green' : 'red' }}">%{{ $savingsRate }}</div>
          </div>
          <div class="stats-box-cell">
            <div class="sb-label">Kredi Kartı Borcu</div>
            <div class="sb-val {{ $totalCardDebt > 0 ? 'red' : 'green' }}">₺{{ number_format($totalCardDebt, 0, ',', '.') }}</div>
          </div>
        </div>
      </div>
    </div>

    {{-- ── ACTIVE GOALS ── --}}
    @if(isset($goals) && $goals->count())
    <div class="no-break">
      <div class="section-title">Aktif Hedefler</div>
      <table class="data">
        <thead><tr>
          <th>Hedef</th>
          <th class="text-right">Mevcut</th>
          <th class="text-right">Hedef</th>
          <th class="text-right">İlerleme</th>
          <th>Bitiş</th>
        </tr></thead>
        <tbody>
          @foreach($goals as $goal)
          @php
            $gPct   = $goal->target_amount > 0 ? min(100, round($goal->current_amount / $goal->target_amount * 100, 1)) : 0;
            $gColor = $gPct >= 75 ? '#16a34a' : ($gPct >= 40 ? '#d97706' : '#1A56DB');
          @endphp
          <tr>
            <td class="fw-bold">{{ $goal->name }}</td>
            <td class="text-right green">₺{{ number_format($goal->current_amount, 0, ',', '.') }}</td>
            <td class="text-right">₺{{ number_format($goal->target_amount, 0, ',', '.') }}</td>
            <td class="text-right" style="width:80px;">
              <div style="font-size:8px;text-align:right;margin-bottom:1px;font-weight:700;color:{{ $gColor }}">%{{ $gPct }}</div>
              <div class="goal-bar-bg">
                <div class="goal-bar-fill" style="width:{{ $gPct }}%;background:{{ $gColor }};"></div>
              </div>
            </td>
            <td>{{ $goal->target_date ? \Carbon\Carbon::parse($goal->target_date)->format('d.m.Y') : '—' }}</td>
          </tr>
          @endforeach
        </tbody>
      </table>
    </div>
    @endif

    {{-- ── ACTIVE BUDGETS ── --}}
    @if(isset($budgets) && $budgets->count())
    <div class="no-break">
      <div class="section-title">Aktif Bütçeler</div>
      <table class="data">
        <thead><tr>
          <th>Kategori</th>
          <th class="text-right">Limit</th>
          <th class="text-right">Harcanan</th>
          <th class="text-right">Kalan</th>
          <th class="text-right">Kullanım</th>
          <th>Durum</th>
        </tr></thead>
        <tbody>
          @foreach($budgets as $bgt)
          @php
            $bSpent  = $bgt->spent ?? 0;
            $bLimit  = (float) $bgt->amount;
            $bPct    = $bLimit > 0 ? min(100, round($bSpent / $bLimit * 100)) : 0;
            $bLeft   = max(0, $bLimit - $bSpent);
            $bOver   = $bSpent > $bLimit;
            $bBarClr = $bOver ? '#dc2626' : ($bPct >= 80 ? '#d97706' : '#16a34a');
          @endphp
          <tr>
            <td class="fw-bold">{{ $bgt->category_name ?? ($bgt->category ?? 'Kategori') }}</td>
            <td class="text-right">₺{{ number_format($bLimit, 0, ',', '.') }}</td>
            <td class="text-right {{ $bOver ? 'red' : '' }}">₺{{ number_format($bSpent, 0, ',', '.') }}</td>
            <td class="text-right {{ $bOver ? 'red' : 'green' }}">{{ $bOver ? '—' : '₺' . number_format($bLeft, 0, ',', '.') }}</td>
            <td class="text-right" style="width:70px;">
              <div style="font-size:8px;text-align:right;margin-bottom:1px;font-weight:700;color:{{ $bBarClr }}">%{{ $bPct }}</div>
              <div class="budget-bar-bg">
                <div class="budget-bar-fill" style="width:{{ $bPct }}%;background:{{ $bBarClr }};"></div>
              </div>
            </td>
            <td>
              @if($bOver)
                <span class="badge badge-danger">Aşıldı</span>
              @elseif($bPct >= 80)
                <span class="badge badge-warning">Uyarı</span>
              @else
                <span class="badge badge-success">Normal</span>
              @endif
            </td>
          </tr>
          @endforeach
        </tbody>
      </table>
    </div>
    @endif

    {{-- ── ACTIVE SUBSCRIPTIONS ── --}}
    @if(isset($subscriptions) && $subscriptions->count())
    <div class="no-break">
      <div class="section-title">Aktif Abonelikler</div>
      <table class="data">
        <thead><tr>
          <th>Abonelik</th>
          <th class="text-right">Tutar</th>
          <th>Dönem</th>
          <th>Sonraki Ödeme</th>
          <th class="text-right">Aylık Karşılık</th>
        </tr></thead>
        <tbody>
          @foreach($subscriptions as $sub)
          @php
            $cycleLabels = ['weekly'=>'Haftalık','monthly'=>'Aylık','quarterly'=>'3 Aylık','yearly'=>'Yıllık'];
            $cycleLabel  = $cycleLabels[$sub->billing_cycle] ?? ucfirst($sub->billing_cycle ?? '—');
            $monthlyEq   = match($sub->billing_cycle ?? 'monthly') {
              'weekly'    => (float)$sub->amount * 4.33,
              'monthly'   => (float)$sub->amount,
              'quarterly' => (float)$sub->amount / 3,
              'yearly'    => (float)$sub->amount / 12,
              default     => (float)$sub->amount,
            };
          @endphp
          <tr>
            <td class="fw-bold">{{ $sub->name }}</td>
            <td class="text-right">₺{{ number_format($sub->amount, 2, ',', '.') }}</td>
            <td>{{ $cycleLabel }}</td>
            <td>{{ $sub->next_billing_date ? \Carbon\Carbon::parse($sub->next_billing_date)->format('d.m.Y') : '—' }}</td>
            <td class="text-right orange">₺{{ number_format($monthlyEq, 2, ',', '.') }}</td>
          </tr>
          @endforeach
        </tbody>
      </table>
    </div>
    @endif

    {{-- ── FULL TRANSACTIONS TABLE ── --}}
    <div class="no-break">
      <div class="section-title">İşlem Hareketleri &mdash; {{ $periodLabel }}</div>
    </div>
    <table class="data">
      <thead><tr>
        <th style="width:48px;">Tarih</th>
        <th>Açıklama / Mağaza</th>
        <th>Kategori</th>
        <th class="text-right">Tutar</th>
      </tr></thead>
      <tbody>
        @foreach($transactions as $tx)
        <tr>
          <td style="white-space:nowrap;color:#64748b;">{{ \Carbon\Carbon::parse($tx->posted_at)->format('d.m') }}</td>
          <td style="max-width:140px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">
            {{ $tx->merchant_name ?: mb_substr($tx->description ?? '', 0, 35) }}
          </td>
          <td style="color:#64748b;font-size:8.5px;">{{ $tx->merchant_category ?: '—' }}</td>
          <td class="text-right fw-bold {{ $tx->amount >= 0 ? 'green' : 'red' }}">
            {{ $tx->amount >= 0 ? '+' : '' }}₺{{ number_format(abs($tx->amount), 2, ',', '.') }}
          </td>
        </tr>
        @endforeach
      </tbody>
    </table>

    {{-- ── FOOTER PAGE 2 ── --}}
    <div class="footer">
      <div class="footer-l">Paranette &mdash; BTK Akademi Hackathon 2026 &mdash; paranette.local</div>
      <div class="footer-r">Bu rapor {{ now()->format('d.m.Y H:i') }} tarihinde oluşturulmuştur. Yatırım tavsiyesi değildir.</div>
    </div>

  </div>{{-- end page-break --}}

</div>
</body>
</html>
