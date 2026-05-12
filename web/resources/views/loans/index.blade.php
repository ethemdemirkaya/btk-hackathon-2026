<x-app-layout>
  <x-slot name="title">Krediler</x-slot>

  {{-- ══ Page CSS ════════════════════════════════════════════════════════════════ --}}
  <x-slot name="pageCss">
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/apex-charts/apex-charts.css') }}">
    <style>
      /* ── Stat cards ────────────────────────────────────────────────────────── */
      .stat-card { transition: transform .18s ease, box-shadow .18s ease; }
      .stat-card:hover { transform: translateY(-3px); box-shadow: 0 8px 24px rgba(115,103,240,.15) !important; }
      .stat-card .accent-bar {
        height: 3px;
        border-radius: 3px 3px 0 0;
        position: absolute;
        top: 0; left: 0; right: 0;
      }

      /* ── Stat icon gradient wrappers ───────────────────────────────────────── */
      .stat-icon-wrap {
        width: 46px; height: 46px;
        border-radius: 10px;
        display: flex; align-items: center; justify-content: center;
        flex-shrink: 0;
      }
      .stat-icon-wrap.gradient-danger  { background: linear-gradient(135deg, #EA5455, #f0797a); }
      .stat-icon-wrap.gradient-warning { background: linear-gradient(135deg, #FF9F43, #ffb470); }
      .stat-icon-wrap.gradient-primary { background: linear-gradient(135deg, #7367F0, #9e95f5); }
      .stat-icon-wrap.gradient-info    { background: linear-gradient(135deg, #00CFE8, #33d9f4); }
      .stat-icon-wrap.gradient-success { background: linear-gradient(135deg, #28C76F, #55d98d); }

      /* ── Loan card accent system ────────────────────────────────────────────── */
      .loan-card {
        transition: transform .18s ease, box-shadow .18s ease;
        border-left: 4px solid transparent !important;
      }
      .loan-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 28px rgba(0,0,0,.12) !important;
      }
      .loan-card.accent-danger  { border-left-color: #EA5455 !important; }
      .loan-card.accent-warning { border-left-color: #FF9F43 !important; }
      .loan-card.accent-primary { border-left-color: #7367F0 !important; }
      .loan-card.accent-success { border-left-color: #28C76F !important; }

      /* ── Loan type badge overrides ──────────────────────────────────────────── */
      .badge-type-mortgage { background: rgba(115,103,240,.15); color: #7367F0; }
      .badge-type-vehicle  { background: rgba(0,207,232,.15);   color: #00CFE8; }
      .badge-type-personal { background: rgba(255,159,67,.15);  color: #FF9F43; }
      .badge-type-other    { background: rgba(108,117,125,.15); color: #6c757d; }
      [data-bs-theme="dark"] .badge-type-mortgage { background: rgba(115,103,240,.25); }
      [data-bs-theme="dark"] .badge-type-vehicle  { background: rgba(0,207,232,.25); }
      [data-bs-theme="dark"] .badge-type-personal { background: rgba(255,159,67,.25); }
      [data-bs-theme="dark"] .badge-type-other    { background: rgba(108,117,125,.25); }

      /* ── Bank logo box ──────────────────────────────────────────────────────── */
      .bank-logo-box {
        width: 52px; height: 52px;
        border-radius: 12px;
        display: flex; align-items: center; justify-content: center;
        flex-shrink: 0;
        background: #fff;
        border: 1px solid rgba(0,0,0,.08);
        overflow: hidden;
      }
      [data-bs-theme="dark"] .bank-logo-box {
        background: rgba(255,255,255,.08);
        border-color: rgba(255,255,255,.1);
      }
      .bank-logo-box img { max-width: 36px; max-height: 36px; object-fit: contain; }
      .bank-logo-box .bank-initials {
        font-size: .72rem; font-weight: 800;
        letter-spacing: .04em; color: #7367F0; line-height: 1;
        text-align: center;
      }

      /* ── Progress bar ────────────────────────────────────────────────────────── */
      .loan-progress {
        height: 6px; border-radius: 8px;
        background: var(--bs-secondary-bg);
        overflow: hidden;
      }
      .loan-progress .bar-fill {
        height: 100%; border-radius: 8px;
        transition: width .5s ease;
      }
      .accent-danger  .bar-fill { background: linear-gradient(90deg, #EA5455, #f0797a); }
      .accent-warning .bar-fill { background: linear-gradient(90deg, #FF9F43, #ffb470); }
      .accent-primary .bar-fill { background: linear-gradient(90deg, #7367F0, #9e95f5); }
      .accent-success .bar-fill { background: linear-gradient(90deg, #28C76F, #55d98d); }

      /* ── Circular ring ───────────────────────────────────────────────────────── */
      .ring-svg { display: block; }
      .ring-track { fill: none; stroke: var(--bs-border-color); stroke-width: 4; }
      .ring-fill  {
        fill: none; stroke-width: 4; stroke-linecap: round;
        transform: rotate(-90deg); transform-origin: 50% 50%;
        transition: stroke-dashoffset .6s ease;
      }
      .ring-label-pct  {
        font-size: 9.5px; font-weight: 700;
        fill: var(--bs-heading-color);
        dominant-baseline: middle; text-anchor: middle;
        font-family: 'Public Sans', sans-serif;
      }
      .ring-label-sub  {
        font-size: 6px; fill: var(--bs-secondary-color);
        dominant-baseline: middle; text-anchor: middle;
        font-family: 'Public Sans', sans-serif;
      }

      /* ── Detail chips ────────────────────────────────────────────────────────── */
      .info-chip {
        background: var(--bs-secondary-bg);
        border: 1px solid var(--bs-border-color);
        border-radius: 10px;
        padding: .5rem .75rem;
        min-width: 0;
      }
      .info-chip .chip-label {
        font-size: .66rem; color: var(--bs-secondary-color);
        line-height: 1.2; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        text-transform: uppercase; letter-spacing: .04em;
      }
      .info-chip .chip-value {
        font-size: .82rem; font-weight: 600;
        color: var(--bs-heading-color); line-height: 1.3;
        white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
      }

      /* ── Urgency dot pulse ───────────────────────────────────────────────────── */
      .pulse-dot {
        display: inline-block;
        width: 8px; height: 8px; border-radius: 50%;
        background: #EA5455;
        animation: pulse-anim 1.4s ease infinite;
        flex-shrink: 0;
      }
      @keyframes pulse-anim {
        0%, 100% { box-shadow: 0 0 0 0 rgba(234,84,85,.5); }
        50%       { box-shadow: 0 0 0 5px rgba(234,84,85,0); }
      }

      /* ── Accordion amortization chart ───────────────────────────────────────── */
      .chart-accordion .accordion-button {
        font-size: .82rem; font-weight: 600; padding: .6rem 1rem;
        background: var(--bs-secondary-bg);
        color: var(--bs-heading-color);
      }
      .chart-accordion .accordion-button:not(.collapsed) {
        background: rgba(115,103,240,.06);
        color: #7367F0;
        box-shadow: none;
      }
      .chart-accordion .accordion-button::after {
        filter: none;
      }
      .chart-accordion .accordion-body { padding: .75rem 1rem 1rem; }

      /* ── Empty state ──────────────────────────────────────────────────────────── */
      .empty-state-card {
        background: linear-gradient(135deg,
          rgba(115,103,240,.06) 0%,
          rgba(115,103,240,.02) 100%);
        border: 2px dashed rgba(115,103,240,.2) !important;
      }
      .empty-icon-ring {
        width: 96px; height: 96px; border-radius: 50%;
        background: rgba(115,103,240,.1);
        display: flex; align-items: center; justify-content: center;
        border: 2px dashed rgba(115,103,240,.3);
      }

      /* ── Summary hero banner ──────────────────────────────────────────────────── */
      .loans-hero-banner {
        background: linear-gradient(135deg, #7367F0 0%, #9e95f5 60%, #CE9FFC 100%);
        border-radius: .75rem;
        color: #fff;
        position: relative;
        overflow: hidden;
      }
      .loans-hero-banner::before {
        content: '';
        position: absolute; top: -50px; right: -50px;
        width: 200px; height: 200px;
        background: rgba(255,255,255,.07); border-radius: 50%;
        pointer-events: none;
      }
      .loans-hero-banner::after {
        content: '';
        position: absolute; bottom: -70px; left: 30%;
        width: 240px; height: 240px;
        background: rgba(255,255,255,.04); border-radius: 50%;
        pointer-events: none;
      }
      .loans-hero-banner .hero-divider {
        width: 1px; background: rgba(255,255,255,.25);
        align-self: stretch;
      }

      /* ── Installment dot strip ────────────────────────────────────────────────── */
      .dot-strip { display: flex; flex-wrap: wrap; gap: 3px; align-items: center; }
      .inst-dot {
        width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0;
      }
      .inst-dot.paid      { background: #28C76F; }
      .inst-dot.next-due  { background: #FF9F43; box-shadow: 0 0 0 2px rgba(255,159,67,.35); }
      .inst-dot.remaining { background: var(--bs-border-color); }
    </style>
  </x-slot>

  {{-- ══ Page header ════════════════════════════════════════════════════════════ --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Krediler</h4>
      <p class="text-muted small mb-0">
        <i class="icon-base ti tabler-building-bank icon-14px me-1"></i>
        {{ $loans->count() }} aktif kredi &middot; taksit takibi ve geri ödeme planı
      </p>
    </div>
    <div class="d-flex gap-2">
      <a href="{{ route('negotiation.index') }}" class="btn btn-primary">
        <i class="icon-base ti tabler-message-2-dollar me-1"></i>Yeniden Yapılandır
      </a>
    </div>
  </div>

  @if($loans->isNotEmpty())

  {{-- ══ Hero summary banner ════════════════════════════════════════════════════ --}}
  @php
    $avgRate = $loans->count() > 0 ? round($loans->avg('interest_rate'), 2) : 0;
    $totalCount = $loans->count();
    $daysLeft = $nextDue
      ? (int) round(now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($nextDue->next_payment_date)->startOfDay(), false))
      : null;
  @endphp
  <div class="loans-hero-banner p-4 p-md-5 mb-6">
    <div class="row g-4 align-items-center">
      {{-- Toplam Kalan Borç --}}
      <div class="col-6 col-md-3 text-center text-md-start">
        <div class="small opacity-75 mb-1">
          <i class="icon-base ti tabler-file-invoice icon-14px me-1"></i>Toplam Kalan Borç
        </div>
        <div class="h3 fw-bold mb-0">₺{{ number_format($totalBalance, 0, ',', '.') }}</div>
        <div class="small opacity-75 mt-1">{{ $totalCount }} aktif kredi</div>
      </div>

      <div class="hero-divider d-none d-md-flex"></div>

      {{-- Bu Ay Ödenecek --}}
      <div class="col-6 col-md-3 text-center">
        <div class="small opacity-75 mb-1">
          <i class="icon-base ti tabler-calendar-due icon-14px me-1"></i>Bu Ay Ödenecek
        </div>
        <div class="h3 fw-bold mb-0">₺{{ number_format($totalNextPayment, 0, ',', '.') }}</div>
        <div class="small opacity-75 mt-1">toplam taksit</div>
      </div>

      <div class="hero-divider d-none d-md-flex"></div>

      {{-- En Yakın Vade --}}
      <div class="col-6 col-md-3 text-center">
        <div class="small opacity-75 mb-1">
          <i class="icon-base ti tabler-clock-hour-4 icon-14px me-1"></i>En Yakın Vade
        </div>
        @if($nextDue && $nextDue->next_payment_date)
          <div class="h3 fw-bold mb-0">{{ \Carbon\Carbon::parse($nextDue->next_payment_date)->format('d.m.Y') }}</div>
          <div class="mt-1">
            @if($daysLeft === 0)
              <span class="badge" style="background:rgba(255,255,255,.25);font-size:.72rem;">Bugün!</span>
            @elseif($daysLeft <= 3)
              <span class="badge" style="background:rgba(234,84,85,.4);font-size:.72rem;">{{ $daysLeft }} gün kaldı</span>
            @elseif($daysLeft <= 7)
              <span class="badge" style="background:rgba(255,159,67,.35);font-size:.72rem;">{{ $daysLeft }} gün kaldı</span>
            @else
              <span class="small opacity-75">{{ $daysLeft }} gün kaldı</span>
            @endif
          </div>
        @else
          <div class="h3 fw-bold mb-0">—</div>
          <div class="small opacity-75 mt-1">vade yok</div>
        @endif
      </div>

      <div class="hero-divider d-none d-md-flex"></div>

      {{-- Ortalama Faiz --}}
      <div class="col-6 col-md-3 text-center text-md-end">
        <div class="small opacity-75 mb-1">
          <i class="icon-base ti tabler-percentage icon-14px me-1"></i>Ortalama Faiz (yıllık)
        </div>
        <div class="h3 fw-bold mb-0">%{{ $avgRate }}</div>
        <div class="small opacity-75 mt-1">tüm krediler</div>
      </div>
    </div>
  </div>

  {{-- ══ Stat cards row ═════════════════════════════════════════════════════════ --}}
  @php $totalRemainingInstallments = $loans->sum('remaining_installments'); @endphp
  <div class="row g-4 mb-6">

    {{-- Toplam Kalan Borç --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-danger"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Kalan Borç</span>
              <div class="h5 fw-bold mt-1 mb-1 text-danger">₺{{ number_format($totalBalance, 0, ',', '.') }}</div>
              <div class="d-flex align-items-center gap-1">
                <i class="icon-base ti tabler-credit-card icon-14px text-muted"></i>
                <span class="small text-muted">{{ $totalCount }} kredi</span>
              </div>
            </div>
            <div class="stat-icon-wrap gradient-danger">
              <i class="icon-base ti tabler-file-invoice icon-22px text-white"></i>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Bu Ay Ödenecek --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-warning"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Bu Ay Ödenecek</span>
              <div class="h5 fw-bold mt-1 mb-1 text-warning">₺{{ number_format($totalNextPayment, 0, ',', '.') }}</div>
              <div class="d-flex align-items-center gap-1">
                <i class="icon-base ti tabler-calendar-due icon-14px text-muted"></i>
                <span class="small text-muted">aylık toplam taksit</span>
              </div>
            </div>
            <div class="stat-icon-wrap gradient-warning">
              <i class="icon-base ti tabler-calendar-due icon-22px text-white"></i>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Toplam Kalan Taksit --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-primary"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Kalan Taksit Sayısı</span>
              <div class="h5 fw-bold mt-1 mb-1 text-heading">{{ number_format($totalRemainingInstallments, 0, ',', '.') }}</div>
              <div class="d-flex align-items-center gap-1">
                <i class="icon-base ti tabler-list-numbers icon-14px text-muted"></i>
                <span class="small text-muted">tüm krediler toplamı</span>
              </div>
            </div>
            <div class="stat-icon-wrap gradient-primary">
              <i class="icon-base ti tabler-list-numbers icon-22px text-white"></i>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Ortalama Faiz Oranı --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-info"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Ortalama Faiz Oranı</span>
              <div class="h5 fw-bold mt-1 mb-1 text-heading">%{{ $avgRate }}</div>
              <div class="d-flex align-items-center gap-1">
                <i class="icon-base ti tabler-percentage icon-14px text-muted"></i>
                <span class="small text-muted">yıllık ağırlıklı ort.</span>
              </div>
            </div>
            <div class="stat-icon-wrap gradient-info">
              <i class="icon-base ti tabler-percentage icon-22px text-white"></i>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>

  {{-- ══ Loan cards ══════════════════════════════════════════════════════════════ --}}
  <div class="row g-5 mb-5">
    @foreach($loans as $loopIndex => $loan)
    @php
      // ── Accent class based on % remaining ────────────────────────────────
      $remPct = $loan->total_installments > 0
        ? ($loan->remaining_installments / $loan->total_installments) * 100
        : 0;
      $accentClass = $remPct <= 20 ? 'accent-success'
        : ($remPct <= 45 ? 'accent-primary'
          : ($remPct <= 75 ? 'accent-warning' : 'accent-danger'));

      // ── Ring stroke colour ────────────────────────────────────────────────
      $ringColor = match($accentClass) {
        'accent-success' => '#28C76F',
        'accent-primary' => '#7367F0',
        'accent-warning' => '#FF9F43',
        default          => '#EA5455',
      };

      // ── Next payment urgency ──────────────────────────────────────────────
      $loanDaysLeft = $loan->next_payment_date
        ? (int) round(now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($loan->next_payment_date)->startOfDay(), false))
        : null;
      $isUrgent = $loanDaysLeft !== null && $loanDaysLeft <= 7;

      // ── Loan type label & badge class ─────────────────────────────────────
      $typeLabel = match(strtolower($loan->type ?? '')) {
        'mortgage'           => 'Konut Kredisi',
        'vehicle', 'auto'   => 'Araç Kredisi',
        'personal'           => 'İhtiyaç Kredisi',
        'commercial'         => 'Ticari Kredi',
        default              => ucfirst($loan->type ?? 'Bireysel') . ' Kredi',
      };
      $typeBadgeClass = match(strtolower($loan->type ?? '')) {
        'mortgage'           => 'badge-type-mortgage',
        'vehicle', 'auto'   => 'badge-type-vehicle',
        'personal'           => 'badge-type-personal',
        default              => 'badge-type-other',
      };
      $typeIcon = match(strtolower($loan->type ?? '')) {
        'mortgage'           => 'tabler-home-2',
        'vehicle', 'auto'   => 'tabler-car',
        'personal'           => 'tabler-user',
        'commercial'         => 'tabler-building-store',
        default              => 'tabler-file-invoice',
      };

      // ── Circular progress ─────────────────────────────────────────────────
      $radius    = 22;
      $circum    = round(2 * M_PI * $radius, 2);  // ≈138.23
      $paidPct   = min(100, max(0, (float)$loan->paid_pct));
      $dashOffset = round($circum * (1 - $paidPct / 100), 2);

      // ── Remaining total cost ──────────────────────────────────────────────
      $remainingTotal = $loan->remaining_installments * ($loan->next_payment_amount ?? 0);

      // ── Installment dot strip (capped at 36) ─────────────────────────────
      $maxDots  = min($loan->total_installments, 36);
      $paidDots = $loan->total_installments > 0
        ? (int) round(($loan->paid_installments / $loan->total_installments) * $maxDots)
        : 0;

      // ── Amortization chart data: simple straight-line estimate ───────────
      $chartId = 'chart-loan-' . $loan->id;
      $amortMonths = [];
      $amortBalances = [];
      if ($loan->remaining_installments > 0 && $loan->next_payment_amount > 0) {
        $bal = (float)$loan->current_balance;
        $monthlyRate = (float)$loan->interest_rate / 100 / 12;
        $baseDate = $loan->next_payment_date
          ? \Carbon\Carbon::parse($loan->next_payment_date)
          : now();
        for ($m = 0; $m <= min($loan->remaining_installments, 60); $m++) {
          $amortMonths[] = $baseDate->copy()->addMonths($m)->format('M Y');
          $amortBalances[] = round(max(0, $bal), 0);
          if ($monthlyRate > 0) {
            $interest = $bal * $monthlyRate;
            $principal = (float)$loan->next_payment_amount - $interest;
            $bal -= max(0, $principal);
          } else {
            $bal -= (float)$loan->next_payment_amount;
          }
        }
        if (end($amortBalances) > 0) {
          $amortBalances[count($amortBalances) - 1] = 0;
        }
      }
    @endphp

    <div class="col-md-6 col-xl-6">
      <div class="card h-100 shadow-sm loan-card {{ $accentClass }}">
        <div class="card-body p-0">

          {{-- ── Card header: bank logo + type + urgency + ring ─────────────── --}}
          <div class="p-4 pb-3 border-bottom">
            <div class="d-flex align-items-start gap-3">

              {{-- Bank logo --}}
              <div class="bank-logo-box">
                @if($loan->bank_logo)
                  <img src="{{ asset($loan->bank_logo) }}" alt="{{ $loan->bank_name }}">
                @else
                  <span class="bank-initials">{{ strtoupper(substr($loan->bank_slug ?? $loan->bank_name, 0, 3)) }}</span>
                @endif
              </div>

              {{-- Bank name + loan type + urgency --}}
              <div class="flex-grow-1 min-width-0">
                <div class="d-flex align-items-center flex-wrap gap-2 mb-1">
                  <span class="fw-bold text-heading" style="font-size:.98rem;">{{ $loan->bank_name }}</span>
                  @if($isUrgent)
                    <span class="d-inline-flex align-items-center gap-1" style="font-size:.72rem; color:#EA5455; font-weight:600;">
                      <span class="pulse-dot"></span>Yaklaşıyor
                    </span>
                  @endif
                </div>
                <div class="d-flex align-items-center gap-2 flex-wrap">
                  <span class="badge {{ $typeBadgeClass }} d-inline-flex align-items-center gap-1" style="font-size:.72rem; font-weight:600; padding:.3em .65em; border-radius:6px;">
                    <i class="icon-base ti {{ $typeIcon }} icon-12px"></i>{{ $typeLabel }}
                  </span>
                  <span class="badge bg-label-secondary" style="font-size:.68rem; font-weight:600;">
                    %{{ $loan->interest_rate }}&nbsp;yıllık
                  </span>
                  @if($loan->ends_at)
                    <span class="text-muted" style="font-size:.71rem;">
                      <i class="icon-base ti tabler-calendar-x icon-11px me-1"></i>{{ \Carbon\Carbon::parse($loan->ends_at)->format('M Y') }}
                    </span>
                  @endif
                </div>
              </div>

              {{-- SVG ring --}}
              <div class="flex-shrink-0" title="{{ round($paidPct) }}% ödendi">
                <svg class="ring-svg" width="60" height="60" viewBox="0 0 56 56">
                  <circle class="ring-track" cx="28" cy="28" r="{{ $radius }}"/>
                  <circle
                    class="ring-fill"
                    cx="28" cy="28" r="{{ $radius }}"
                    stroke="{{ $ringColor }}"
                    stroke-dasharray="{{ $circum }}"
                    stroke-dashoffset="{{ $dashOffset }}"
                  />
                  <text class="ring-label-pct" x="28" y="26">{{ round($paidPct) }}%</text>
                  <text class="ring-label-sub"  x="28" y="34">ödendi</text>
                </svg>
              </div>

            </div>
          </div>{{-- /card header --}}

          {{-- ── Balance + progress ──────────────────────────────────────────── --}}
          <div class="px-4 pt-3 pb-2">

            {{-- Balance row --}}
            <div class="d-flex align-items-baseline gap-2 mb-3">
              <span class="text-muted" style="font-size:.75rem;">Kalan:</span>
              <span class="fw-bold text-danger" style="font-size:1.3rem; letter-spacing:-.01em;">
                ₺{{ number_format($loan->current_balance, 0, ',', '.') }}
              </span>
              @if($loan->principal > 0)
                <span class="text-muted" style="font-size:.72rem;">
                  / ₺{{ number_format($loan->principal, 0, ',', '.') }} anapara
                </span>
              @endif
            </div>

            {{-- Progress bar + labels --}}
            <div class="d-flex justify-content-between align-items-center mb-1">
              <span class="text-muted" style="font-size:.7rem;">Ödeme İlerlemesi</span>
              <span class="fw-semibold" style="font-size:.73rem;">
                {{ $loan->paid_installments }} / {{ $loan->total_installments }} taksit
              </span>
            </div>
            <div class="loan-progress mb-2">
              <div class="bar-fill" style="width:{{ $paidPct }}%;"></div>
            </div>

            {{-- Dot strip --}}
            <div class="dot-strip mb-1">
              @for($d = 0; $d < $maxDots; $d++)
                @if($d < $paidDots)
                  <div class="inst-dot paid" title="Ödendi ({{ $d + 1 }})"></div>
                @elseif($d === $paidDots)
                  <div class="inst-dot next-due" title="Sıradaki ({{ $d + 1 }})"></div>
                @else
                  <div class="inst-dot remaining" title="Kalan ({{ $d + 1 }})"></div>
                @endif
              @endfor
            </div>
            <div class="text-muted mb-3" style="font-size:.67rem;">
              @if($loan->total_installments > $maxDots)
                <i class="icon-base ti tabler-dots icon-10px me-1"></i>+{{ $loan->total_installments - $maxDots }} taksit gösterilmiyor &middot;
              @endif
              <strong class="text-heading">{{ $loan->remaining_installments }}</strong> taksit kaldı
            </div>

            {{-- 2×2 Info chips --}}
            <div class="row g-2 mb-3">
              {{-- Anapara --}}
              <div class="col-6">
                <div class="info-chip">
                  <div class="chip-label">Anapara</div>
                  <div class="chip-value">₺{{ number_format($loan->principal, 0, ',', '.') }}</div>
                </div>
              </div>
              {{-- Aylık Taksit --}}
              <div class="col-6">
                <div class="info-chip">
                  <div class="chip-label">Aylık Taksit</div>
                  <div class="chip-value text-warning fw-bold">₺{{ number_format($loan->next_payment_amount, 0, ',', '.') }}</div>
                </div>
              </div>
              {{-- Sonraki Ödeme --}}
              <div class="col-6">
                <div class="info-chip">
                  <div class="chip-label">Sonraki Ödeme</div>
                  <div class="chip-value {{ $isUrgent ? 'text-danger' : '' }}">
                    @if($loan->next_payment_date)
                      {{ \Carbon\Carbon::parse($loan->next_payment_date)->format('d.m.Y') }}
                      @if($loanDaysLeft !== null)
                        <span class="d-block fw-normal text-muted" style="font-size:.63rem;">
                          {{ $loanDaysLeft === 0 ? 'Bugün!' : "{$loanDaysLeft} gün" }}
                        </span>
                      @endif
                    @else
                      <span class="text-muted">—</span>
                    @endif
                  </div>
                </div>
              </div>
              {{-- Toplam Kalan Maliyet --}}
              <div class="col-6">
                <div class="info-chip" style="border-color:rgba(115,103,240,.2); background:rgba(115,103,240,.05);">
                  <div class="chip-label">Kalan Toplam</div>
                  <div class="chip-value" style="color:#7367F0; font-size:.86rem;">₺{{ number_format($remainingTotal, 0, ',', '.') }}</div>
                </div>
              </div>
            </div>

            {{-- Action buttons --}}
            <div class="d-flex align-items-center gap-2">
              <a href="{{ route('negotiation.index') }}"
                 class="btn btn-sm btn-primary flex-grow-1">
                <i class="icon-base ti tabler-message-2-dollar me-1"></i>Yapılandır
              </a>
              @if(count($amortMonths) > 0)
              <button class="btn btn-sm btn-outline-secondary flex-shrink-0"
                      type="button"
                      data-bs-toggle="collapse"
                      data-bs-target="#amort-{{ $loan->id }}"
                      aria-expanded="false"
                      title="Amortisman Grafiği">
                <i class="icon-base ti tabler-chart-area-line icon-16px"></i>
              </button>
              @endif
            </div>

          </div>{{-- /card body --}}

          {{-- ── Amortization chart (collapse) ──────────────────────────────── --}}
          @if(count($amortMonths) > 0)
          <div class="collapse" id="amort-{{ $loan->id }}">
            <div class="border-top px-4 py-3">
              <div class="d-flex align-items-center gap-2 mb-2">
                <i class="icon-base ti tabler-chart-area-line icon-14px text-primary"></i>
                <span class="fw-semibold small text-heading">Kalan Bakiye Gidişatı</span>
                <span class="badge bg-label-primary ms-1" style="font-size:.65rem;">{{ count($amortMonths) - 1 }} ay</span>
              </div>
              <div id="{{ $chartId }}" style="min-height:160px;"></div>
            </div>
          </div>
          @endif

        </div>{{-- /card-body --}}
      </div>
    </div>

    @endforeach
  </div>{{-- /row --}}

  {{-- ══ Full amortization table toggle ════════════════════════════════════════ --}}
  @if($loans->count() > 0)
  <div class="card shadow-sm mb-5">
    <div class="card-header d-flex align-items-center justify-content-between py-3">
      <div>
        <h5 class="card-title mb-0">
          <i class="icon-base ti tabler-table me-2 text-primary"></i>Tüm Krediler Özeti
        </h5>
        <small class="text-muted">Tablo görünümü</small>
      </div>
      <button class="btn btn-sm btn-outline-secondary" type="button"
              data-bs-toggle="collapse" data-bs-target="#loanSummaryTable">
        <i class="icon-base ti tabler-chevron-down icon-14px me-1"></i>Göster / Gizle
      </button>
    </div>
    <div class="collapse" id="loanSummaryTable">
      <div class="table-responsive">
        <table class="table table-hover mb-0">
          <thead class="paranette-thead">
            <tr>
              <th class="ps-4 py-3">Banka / Tür</th>
              <th class="py-3 text-end">Anapara</th>
              <th class="py-3 text-end">Kalan Bakiye</th>
              <th class="py-3 text-end d-none d-md-table-cell">Taksit</th>
              <th class="py-3 text-end d-none d-lg-table-cell">Faiz</th>
              <th class="py-3 text-end d-none d-sm-table-cell">İlerleme</th>
              <th class="py-3 text-end pe-4">Sonraki Ödeme</th>
            </tr>
          </thead>
          <tbody>
            @foreach($loans as $loan)
            @php
              $lDaysLeft = $loan->next_payment_date
                ? (int) round(now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($loan->next_payment_date)->startOfDay(), false))
                : null;
            @endphp
            <tr>
              <td class="ps-4 py-3">
                <div class="d-flex align-items-center gap-3">
                  <div class="avatar avatar-sm flex-shrink-0">
                    @if($loan->bank_logo)
                      <img src="{{ asset($loan->bank_logo) }}" alt="{{ $loan->bank_name }}" class="rounded" style="width:32px;height:32px;object-fit:contain;background:#fff;border:1px solid var(--bs-border-color);">
                    @else
                      <span class="avatar-initial rounded bg-label-primary" style="font-size:.65rem;font-weight:700;">
                        {{ strtoupper(substr($loan->bank_slug ?? $loan->bank_name, 0, 2)) }}
                      </span>
                    @endif
                  </div>
                  <div>
                    <div class="fw-semibold small">{{ $loan->bank_name }}</div>
                    <div class="text-muted" style="font-size:.72rem;">{{ $typeLabel ?? ucfirst($loan->type ?? '—') }}</div>
                  </div>
                </div>
              </td>
              <td class="py-3 text-end">
                <span class="small fw-medium">₺{{ number_format($loan->principal, 0, ',', '.') }}</span>
              </td>
              <td class="py-3 text-end">
                <span class="fw-bold text-danger small">₺{{ number_format($loan->current_balance, 0, ',', '.') }}</span>
              </td>
              <td class="py-3 text-end d-none d-md-table-cell">
                <div class="small fw-medium">₺{{ number_format($loan->next_payment_amount, 0, ',', '.') }}</div>
                <div class="text-muted" style="font-size:.7rem;">{{ $loan->paid_installments }}/{{ $loan->total_installments }}</div>
              </td>
              <td class="py-3 text-end d-none d-lg-table-cell">
                <span class="badge bg-label-secondary">%{{ $loan->interest_rate }}</span>
              </td>
              <td class="py-3 d-none d-sm-table-cell">
                <div class="d-flex align-items-center gap-2">
                  <div class="flex-grow-1 progress" style="height:5px;border-radius:5px;background:var(--bs-secondary-bg);min-width:60px;">
                    <div class="progress-bar bg-primary" style="width:{{ $loan->paid_pct }}%;border-radius:5px;background:linear-gradient(90deg,#7367F0,#9e95f5);"></div>
                  </div>
                  <span class="text-muted" style="font-size:.7rem;white-space:nowrap;">{{ $loan->paid_pct }}%</span>
                </div>
              </td>
              <td class="py-3 pe-4 text-end">
                @if($loan->next_payment_date)
                  <div class="small fw-medium {{ $lDaysLeft !== null && $lDaysLeft <= 7 ? 'text-danger' : '' }}">
                    {{ \Carbon\Carbon::parse($loan->next_payment_date)->format('d.m.Y') }}
                  </div>
                  @if($lDaysLeft !== null && $lDaysLeft <= 7)
                    <div style="font-size:.68rem;color:#EA5455;">
                      {{ $lDaysLeft === 0 ? 'Bugün!' : "{$lDaysLeft} gün kaldı" }}
                    </div>
                  @endif
                @else
                  <span class="text-muted small">—</span>
                @endif
              </td>
            </tr>
            @endforeach
          </tbody>
          <tfoot style="background:var(--bs-secondary-bg);">
            <tr>
              <td class="ps-4 py-2 fw-bold small text-heading">Toplam</td>
              <td class="py-2 text-end fw-bold small">₺{{ number_format($loans->sum('principal'), 0, ',', '.') }}</td>
              <td class="py-2 text-end fw-bold text-danger small">₺{{ number_format($totalBalance, 0, ',', '.') }}</td>
              <td class="py-2 text-end fw-bold text-warning small d-none d-md-table-cell">₺{{ number_format($totalNextPayment, 0, ',', '.') }}</td>
              <td class="py-2 d-none d-lg-table-cell"></td>
              <td class="py-2 d-none d-sm-table-cell"></td>
              <td class="py-2 pe-4"></td>
            </tr>
          </tfoot>
        </table>
      </div>
    </div>
  </div>
  @endif

  @else

  {{-- ══ Empty state ════════════════════════════════════════════════════════════ --}}
  <div class="row justify-content-center">
    <div class="col-md-7 col-lg-5">
      <div class="card empty-state-card text-center py-8 px-4">
        <div class="card-body">
          <div class="d-flex justify-content-center mb-5">
            <div class="empty-icon-ring">
              <i class="icon-base ti tabler-file-invoice icon-48px" style="color:#7367F0;"></i>
            </div>
          </div>
          <h4 class="fw-bold mb-2">Aktif krediniz bulunmuyor</h4>
          <p class="text-muted mb-2" style="max-width:340px; margin: 0 auto;">
            Banka hesabınızı bağladıktan sonra kredileriniz otomatik olarak listelenir.
          </p>
          <p class="text-muted small mb-6" style="max-width:340px; margin: 0 auto;">
            Taksit takibi, geri ödeme planı ve erken kapama hesaplamaları hemen devreye girer.
          </p>
          <div class="d-flex justify-content-center gap-3 flex-wrap">
            <a href="{{ route('bank-connections.create') }}" class="btn btn-primary px-5">
              <i class="icon-base ti tabler-building-bank me-1"></i>Banka Bağla
            </a>
            <a href="{{ route('negotiation.index') }}" class="btn btn-outline-secondary">
              <i class="icon-base ti tabler-message-2-dollar me-1"></i>Yapılandırma Talebi
            </a>
          </div>
          <div class="mt-6 pt-4 border-top">
            <div class="row g-3 text-start">
              <div class="col-4">
                <div class="d-flex align-items-center gap-2">
                  <div class="avatar avatar-sm flex-shrink-0">
                    <span class="avatar-initial rounded bg-label-primary">
                      <i class="icon-base ti tabler-chart-area-line icon-14px"></i>
                    </span>
                  </div>
                  <span class="text-muted" style="font-size:.72rem;">Amortisman Planı</span>
                </div>
              </div>
              <div class="col-4">
                <div class="d-flex align-items-center gap-2">
                  <div class="avatar avatar-sm flex-shrink-0">
                    <span class="avatar-initial rounded bg-label-warning">
                      <i class="icon-base ti tabler-bell-ringing icon-14px"></i>
                    </span>
                  </div>
                  <span class="text-muted" style="font-size:.72rem;">Vade Uyarıları</span>
                </div>
              </div>
              <div class="col-4">
                <div class="d-flex align-items-center gap-2">
                  <div class="avatar avatar-sm flex-shrink-0">
                    <span class="avatar-initial rounded bg-label-success">
                      <i class="icon-base ti tabler-calculator icon-14px"></i>
                    </span>
                  </div>
                  <span class="text-muted" style="font-size:.72rem;">Yapılandırma</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  @endif

  {{-- ══ Page JavaScript ════════════════════════════════════════════════════════ --}}
  <x-slot name="pageJs">
    <script src="{{ asset('assets/vendor/libs/apex-charts/apexcharts.js') }}"></script>
    <script>
    (function () {
      'use strict';

      const isDark    = document.documentElement.getAttribute('data-bs-theme') === 'dark';
      const fontFam   = "'Public Sans', sans-serif";
      const textColor = isDark ? '#b4b7bd' : '#6e6b7b';
      const gridColor = isDark ? 'rgba(255,255,255,.06)' : 'rgba(0,0,0,.04)';

      // ── Amortization area charts ────────────────────────────────────────────
      const charts = @json(
        $loans->map(function ($loan) {
          $months   = [];
          $balances = [];
          if ($loan->remaining_installments > 0 && $loan->next_payment_amount > 0) {
            $bal  = (float)$loan->current_balance;
            $rate = (float)$loan->interest_rate / 100 / 12;
            $base = $loan->next_payment_date
              ? \Carbon\Carbon::parse($loan->next_payment_date)
              : now();
            $cap = min($loan->remaining_installments, 60);
            for ($m = 0; $m <= $cap; $m++) {
              $months[]   = $base->copy()->addMonths($m)->format('M Y');
              $balances[] = round(max(0, $bal), 0);
              if ($rate > 0) {
                $interest  = $bal * $rate;
                $principal = (float)$loan->next_payment_amount - $interest;
                $bal      -= max(0, $principal);
              } else {
                $bal -= (float)$loan->next_payment_amount;
              }
            }
            if (count($balances) > 0) {
              $balances[count($balances) - 1] = 0;
            }
          }
          return [
            'id'       => $loan->id,
            'months'   => $months,
            'balances' => $balances,
          ];
        })->values()
      );

      // Colour per accent class
      const accentColors = {
        'accent-danger':  '#EA5455',
        'accent-warning': '#FF9F43',
        'accent-primary': '#7367F0',
        'accent-success': '#28C76F',
      };

      charts.forEach(function (data) {
        if (!data.months.length) return;

        const el = document.getElementById('chart-loan-' + data.id);
        if (!el) return;

        // Derive colour from the card's accent class
        const card = el.closest('.loan-card');
        let seriesColor = '#7367F0';
        if (card) {
          for (const [cls, col] of Object.entries(accentColors)) {
            if (card.classList.contains(cls)) { seriesColor = col; break; }
          }
        }

        // Only render when the collapse is opened (lazy)
        const collapseEl = document.getElementById('amort-' + data.id);
        let rendered = false;

        function renderChart() {
          if (rendered) return;
          rendered = true;
          new ApexCharts(el, {
            chart: {
              type: 'area',
              height: 160,
              toolbar: { show: false },
              fontFamily: fontFam,
              background: 'transparent',
              sparkline: { enabled: false },
              animations: { enabled: true, speed: 600 },
            },
            series: [{ name: 'Kalan Bakiye', data: data.balances }],
            colors: [seriesColor],
            fill: {
              type: 'gradient',
              gradient: {
                shadeIntensity: 1,
                opacityFrom: isDark ? .35 : .25,
                opacityTo: .02,
                stops: [0, 100],
              },
            },
            stroke: { curve: 'smooth', width: 2 },
            xaxis: {
              categories: data.months,
              tickAmount: Math.min(data.months.length - 1, 6),
              labels: {
                rotate: 0,
                style: { colors: textColor, fontFamily: fontFam, fontSize: '10px' },
              },
              axisBorder: { show: false },
              axisTicks: { show: false },
            },
            yaxis: {
              labels: {
                formatter: function (v) {
                  return v >= 1000000
                    ? '₺' + (v / 1000000).toFixed(1) + 'M'
                    : v >= 1000
                      ? '₺' + (v / 1000).toFixed(0) + 'B'
                      : '₺' + v;
                },
                style: { colors: textColor, fontFamily: fontFam, fontSize: '10px' },
              },
            },
            grid: {
              borderColor: gridColor,
              strokeDashArray: 4,
              padding: { top: -10, right: 4, left: 4, bottom: 0 },
            },
            dataLabels: { enabled: false },
            markers: { size: 0 },
            tooltip: {
              theme: isDark ? 'dark' : 'light',
              y: {
                formatter: function (v) {
                  return '₺ ' + parseFloat(v).toLocaleString('tr-TR', { maximumFractionDigits: 0 });
                },
              },
            },
          }).render();
        }

        if (collapseEl) {
          collapseEl.addEventListener('show.bs.collapse', renderChart);
        }
      });

    }());
    </script>
  </x-slot>

</x-app-layout>
