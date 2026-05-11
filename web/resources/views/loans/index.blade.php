<x-app-layout>
  <x-slot name="title">Krediler</x-slot>

  <x-slot name="pageCss">
  <style>
    /* ── Bank logo box ─────────────────────────────────────────────────────── */
    .bank-logo-box {
      background: #fff;
      border-radius: 6px;
      padding: 4px 8px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 72px;
      height: 48px;
      border: 1px solid rgba(0,0,0,.08);
      flex-shrink: 0;
    }
    [data-bs-theme="dark"] .bank-logo-box {
      background: rgba(255,255,255,.1);
      border-color: rgba(255,255,255,.1);
    }
    .bank-logo-box img {
      max-height: 32px;
      width: auto;
      object-fit: contain;
    }
    .bank-logo-box .bank-initials {
      font-size: .8rem;
      font-weight: 700;
      letter-spacing: .04em;
      color: #7367F0;
      line-height: 1;
    }

    /* ── Urgency left-border system ────────────────────────────────────────── */
    .loan-card-urgent { border-left: 4px solid #EA5455 !important; }
    .loan-card-warn   { border-left: 4px solid #FF9F43 !important; }
    .loan-card-mid    { border-left: 4px solid #7367F0 !important; }
    .loan-card-ok     { border-left: 4px solid #28C76F !important; }

    /* ── Card gradient hero section ────────────────────────────────────────── */
    .loan-hero {
      background: linear-gradient(135deg, rgba(115,103,240,.08) 0%, rgba(115,103,240,.03) 100%);
      border-radius: 0 8px 8px 0;
      padding: 1rem 1.1rem .9rem;
      margin: -1rem -1rem .75rem;
      border-bottom: 1px solid var(--bs-border-color);
      position: relative;
    }
    .loan-card-urgent  .loan-hero { background: linear-gradient(135deg, rgba(234,84,85,.09) 0%, rgba(234,84,85,.03) 100%); }
    .loan-card-warn    .loan-hero { background: linear-gradient(135deg, rgba(255,159,67,.09) 0%, rgba(255,159,67,.03) 100%); }
    .loan-card-mid     .loan-hero { background: linear-gradient(135deg, rgba(115,103,240,.09) 0%, rgba(115,103,240,.03) 100%); }
    .loan-card-ok      .loan-hero { background: linear-gradient(135deg, rgba(40,199,111,.09) 0%, rgba(40,199,111,.03) 100%); }

    /* ── Circular progress ring ────────────────────────────────────────────── */
    .loan-ring { flex-shrink: 0; }
    .loan-ring svg { display: block; }
    .loan-ring .ring-track {
      fill: none;
      stroke: var(--bs-border-color);
      stroke-width: 3.5;
    }
    .loan-ring .ring-fill {
      fill: none;
      stroke-width: 3.5;
      stroke-linecap: round;
      transform: rotate(-90deg);
      transform-origin: 50% 50%;
      transition: stroke-dashoffset .6s ease;
    }
    .loan-ring .ring-text {
      font-size: 9px;
      font-weight: 700;
      fill: var(--bs-heading-color);
      font-family: 'Public Sans', sans-serif;
      dominant-baseline: middle;
      text-anchor: middle;
    }
    .loan-ring .ring-sub {
      font-size: 5.5px;
      fill: var(--bs-secondary-color);
      font-family: 'Public Sans', sans-serif;
      dominant-baseline: middle;
      text-anchor: middle;
    }

    /* ── Detail chips ──────────────────────────────────────────────────────── */
    .detail-chip {
      background: var(--bs-secondary-bg);
      border: 1px solid var(--bs-border-color);
      border-radius: 8px;
      padding: .45rem .75rem;
      min-width: 0;
    }
    .detail-chip .chip-label {
      font-size: .68rem;
      color: var(--bs-secondary-color);
      line-height: 1.2;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .detail-chip .chip-value {
      font-size: .8rem;
      font-weight: 600;
      color: var(--bs-heading-color);
      line-height: 1.3;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    /* ── Installment timeline ──────────────────────────────────────────────── */
    .install-timeline {
      display: flex;
      flex-wrap: wrap;
      gap: 3px;
      align-items: center;
    }
    .install-dot {
      width: 9px;
      height: 9px;
      border-radius: 50%;
      flex-shrink: 0;
    }
    .install-dot.paid      { background: #28C76F; }
    .install-dot.remaining { background: var(--bs-border-color); }
    .install-dot.next      { background: #FF9F43; box-shadow: 0 0 0 2px rgba(255,159,67,.3); }

    /* ── Progress bar ──────────────────────────────────────────────────────── */
    .loan-progress {
      height: 5px;
      border-radius: 8px;
      background: var(--bs-secondary-bg);
      overflow: hidden;
      border: 1px solid var(--bs-border-color);
    }
    .loan-progress-bar {
      height: 100%;
      border-radius: 8px;
      background: linear-gradient(90deg, #7367F0, #9e95f5);
      transition: width .5s ease;
    }
    .loan-card-urgent .loan-progress-bar  { background: linear-gradient(90deg, #EA5455, #f0797a); }
    .loan-card-warn   .loan-progress-bar  { background: linear-gradient(90deg, #FF9F43, #ffb470); }
    .loan-card-ok     .loan-progress-bar  { background: linear-gradient(90deg, #28C76F, #55d98d); }

    /* ── Remaining total chip ──────────────────────────────────────────────── */
    .remaining-chip {
      background: linear-gradient(135deg, rgba(115,103,240,.1), rgba(115,103,240,.04));
      border: 1px solid rgba(115,103,240,.2);
      border-radius: 8px;
      padding: .45rem .85rem;
    }
    .loan-card-urgent .remaining-chip { background: linear-gradient(135deg, rgba(234,84,85,.1), rgba(234,84,85,.04)); border-color: rgba(234,84,85,.2); }
    .loan-card-warn   .remaining-chip { background: linear-gradient(135deg, rgba(255,159,67,.1), rgba(255,159,67,.04)); border-color: rgba(255,159,67,.2); }
    .loan-card-ok     .remaining-chip { background: linear-gradient(135deg, rgba(40,199,111,.1), rgba(40,199,111,.04)); border-color: rgba(40,199,111,.2); }

    /* ── Hover lift ────────────────────────────────────────────────────────── */
    .loan-card {
      transition: transform .18s ease, box-shadow .18s ease;
    }
    .loan-card:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 24px rgba(0,0,0,.1) !important;
    }

    /* ── Empty state ───────────────────────────────────────────────────────── */
    .empty-icon-wrap {
      width: 80px;
      height: 80px;
      border-radius: 50%;
      background: var(--bs-secondary-bg);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      border: 2px dashed var(--bs-border-color);
    }
  </style>
  </x-slot>

  {{-- ══ Page header ════════════════════════════════════════════════════════════ --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Krediler</h4>
      <p class="text-muted small mb-0">{{ $loans->count() }} aktif kredi · taksit takibi</p>
    </div>
    <a href="{{ route('negotiation.index') }}" class="btn btn-primary">
      <i class="icon-base ti tabler-message-2-dollar me-1"></i>Yeniden Yapılandır
    </a>
  </div>

  {{-- ══ Stat cards ══════════════════════════════════════════════════════════════ --}}
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
              <div class="h5 fw-bold mt-1 mb-0 text-danger">₺{{ number_format($totalBalance, 0, ',', '.') }}</div>
              <span class="small text-muted">{{ $loans->count() }} kredi</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-danger">
                <i class="icon-base ti tabler-file-invoice icon-22px"></i>
              </span>
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
              <div class="h5 fw-bold mt-1 mb-0 text-warning">₺{{ number_format($totalNextPayment, 0, ',', '.') }}</div>
              <span class="small text-muted">toplam taksit</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-warning">
                <i class="icon-base ti tabler-calendar-due icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- En Yakın Vade --}}
    <div class="col-sm-6 col-xl-3">
      @php
        $daysLeft = $nextDue
          ? (int) round(now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($nextDue->next_payment_date)->startOfDay(), false))
          : null;
        $dueColor = $daysLeft !== null
          ? ($daysLeft <= 3 ? 'danger' : ($daysLeft <= 7 ? 'warning' : 'success'))
          : 'secondary';
      @endphp
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-{{ $dueColor }}"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">En Yakın Vade</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">
                @if($nextDue)
                  {{ \Carbon\Carbon::parse($nextDue->next_payment_date)->format('d.m.Y') }}
                @else —
                @endif
              </div>
              @if($daysLeft !== null)
                <span class="badge bg-label-{{ $dueColor }}" style="font-size:.7rem;">
                  {{ $daysLeft === 0 ? 'Bugün!' : "{$daysLeft} gün kaldı" }}
                </span>
              @else
                <span class="small text-muted">vade yok</span>
              @endif
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $dueColor }}">
                <i class="icon-base ti tabler-clock icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Toplam Kalan Taksit --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-info"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Kalan Taksit</span>
              <div class="h5 fw-bold mt-1 mb-0 text-info">{{ number_format($totalRemainingInstallments, 0, ',', '.') }}</div>
              <span class="small text-muted">tüm krediler</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-info">
                <i class="icon-base ti tabler-list-numbers icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>

  {{-- ══ Loan cards ══════════════════════════════════════════════════════════════ --}}
  <div class="row g-5">
    @forelse($loans as $loan)
    @php
      // Left-border accent class based on remaining installments ratio
      $remPct = $loan->total_installments > 0
        ? ($loan->remaining_installments / $loan->total_installments) * 100
        : 0;
      $accentClass = $remPct <= 20 ? 'loan-card-ok'
        : ($remPct <= 40 ? 'loan-card-mid'
          : ($remPct <= 70 ? 'loan-card-warn' : 'loan-card-urgent'));

      // Next payment urgency
      $loanDaysLeft = $loan->next_payment_date
        ? (int) round(now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($loan->next_payment_date)->startOfDay(), false))
        : null;
      $isUrgent = $loanDaysLeft !== null && $loanDaysLeft <= 7;

      // Total remaining cost
      $remainingTotal = $loan->remaining_installments * $loan->next_payment_amount;

      // Timeline dots — cap at 30
      $maxDots  = min($loan->total_installments, 30);
      $paidDots = $loan->total_installments > 0
        ? (int) round(($loan->paid_installments / $loan->total_installments) * $maxDots)
        : 0;

      // Circular progress — circumference for r=22 circle
      $radius    = 22;
      $circum    = round(2 * M_PI * $radius, 2); // ≈ 138.23
      $paidPct   = min(100, max(0, (float) $loan->paid_pct));
      $dashOffset = round($circum * (1 - $paidPct / 100), 2);

      // Ring stroke colour
      $ringStroke = $accentClass === 'loan-card-ok'     ? '#28C76F'
        : ($accentClass === 'loan-card-warn'   ? '#FF9F43'
          : ($accentClass === 'loan-card-mid'  ? '#7367F0' : '#EA5455'));

      // Next-payment date color
      $nextDateClass = $isUrgent ? 'text-danger' : 'text-heading';
    @endphp

    <div class="col-md-6">
      <div class="card h-100 shadow-sm {{ $accentClass }} loan-card">
        <div class="card-body p-0">

          {{-- ── Hero section ─────────────────────────────────────────────── --}}
          <div class="loan-hero p-3 pb-2">
            <div class="d-flex align-items-start gap-3">

              {{-- Bank logo --}}
              <div class="bank-logo-box">
                @if($loan->bank_logo)
                  <img src="{{ asset($loan->bank_logo) }}" alt="{{ $loan->bank_name }}">
                @else
                  <span class="bank-initials">{{ strtoupper(substr($loan->bank_slug ?? $loan->bank_name, 0, 3)) }}</span>
                @endif
              </div>

              {{-- Bank name + type + urgency badge --}}
              <div class="flex-grow-1 min-width-0 pt-1">
                <div class="d-flex align-items-center gap-2 flex-wrap">
                  <span class="fw-bold text-heading" style="font-size:.95rem;">{{ $loan->bank_name }}</span>
                  @if($isUrgent)
                    <span class="badge bg-danger" style="font-size:.65rem; padding:.25em .55em;">
                      <i class="icon-base ti tabler-bell-ringing icon-10px me-1"></i>Yaklaşıyor
                    </span>
                  @endif
                </div>
                <div class="text-muted" style="font-size:.78rem;">
                  {{ ucfirst($loan->type ?? 'Bireysel') }} Kredi
                  @if($loan->ends_at)
                    · Bitiş <span class="fw-medium">{{ \Carbon\Carbon::parse($loan->ends_at)->format('M Y') }}</span>
                  @endif
                </div>
              </div>

              {{-- Circular ring + balance --}}
              <div class="d-flex flex-column align-items-end gap-1 flex-shrink-0">
                <div class="loan-ring" title="{{ $paidPct }}% ödendi">
                  <svg width="60" height="60" viewBox="0 0 56 56">
                    <circle class="ring-track" cx="28" cy="28" r="{{ $radius }}"/>
                    <circle
                      class="ring-fill"
                      cx="28" cy="28" r="{{ $radius }}"
                      stroke="{{ $ringStroke }}"
                      stroke-dasharray="{{ $circum }}"
                      stroke-dashoffset="{{ $dashOffset }}"
                    />
                    <text class="ring-text" x="28" y="26">{{ round($paidPct) }}%</text>
                    <text class="ring-sub"  x="28" y="33">ödendi</text>
                  </svg>
                </div>
              </div>

            </div>

            {{-- Remaining balance prominence --}}
            <div class="mt-2 d-flex align-items-baseline gap-2">
              <span class="text-muted" style="font-size:.75rem;">Kalan Bakiye</span>
              <span class="fw-bold text-danger" style="font-size:1.25rem; letter-spacing:-.01em;">
                ₺{{ number_format($loan->current_balance, 0, ',', '.') }}
              </span>
              @if($loan->principal > 0)
                <span class="text-muted" style="font-size:.72rem;">
                  / ₺{{ number_format($loan->principal, 0, ',', '.') }} anapara
                </span>
              @endif
            </div>

          </div>{{-- /loan-hero --}}

          {{-- ── Body ─────────────────────────────────────────────────────── --}}
          <div class="px-3 pb-3 pt-2">

            {{-- Progress bar --}}
            <div class="mb-2">
              <div class="d-flex justify-content-between align-items-center mb-1">
                <span class="text-muted" style="font-size:.72rem;">Ödeme ilerleme</span>
                <span class="fw-semibold" style="font-size:.75rem;">
                  {{ $loan->paid_installments }} / {{ $loan->total_installments }} taksit
                </span>
              </div>
              <div class="loan-progress mb-2">
                <div class="loan-progress-bar" style="width:{{ $paidPct }}%;"></div>
              </div>

              {{-- Dot timeline --}}
              <div class="install-timeline mb-1">
                @for($d = 0; $d < $maxDots; $d++)
                  @if($d < $paidDots)
                    <div class="install-dot paid" title="Ödendi ({{ $d + 1 }})"></div>
                  @elseif($d === $paidDots)
                    <div class="install-dot next" title="Sıradaki ödeme ({{ $d + 1 }})"></div>
                  @else
                    <div class="install-dot remaining" title="Kalan ({{ $d + 1 }})"></div>
                  @endif
                @endfor
              </div>
              @if($loan->total_installments > $maxDots)
                <div class="text-muted" style="font-size:.68rem;">
                  <i class="icon-base ti tabler-dots icon-10px me-1"></i>+{{ $loan->total_installments - $maxDots }} daha gösterilmiyor
                </div>
              @else
                <div class="text-muted" style="font-size:.68rem;">{{ $loan->remaining_installments }} taksit kaldı</div>
              @endif
            </div>

            {{-- Detail chips 2×2 --}}
            <div class="row g-2 mb-2">
              <div class="col-6">
                <div class="detail-chip">
                  <div class="chip-label">Anapara</div>
                  <div class="chip-value">₺{{ number_format($loan->principal, 0, ',', '.') }}</div>
                </div>
              </div>
              <div class="col-6">
                <div class="detail-chip">
                  <div class="chip-label">Faiz Oranı (aylık)</div>
                  <div class="chip-value">%{{ $loan->interest_rate }}</div>
                </div>
              </div>
              <div class="col-6">
                <div class="detail-chip">
                  <div class="chip-label">Aylık Taksit</div>
                  <div class="chip-value text-warning">₺{{ number_format($loan->next_payment_amount, 0, ',', '.') }}</div>
                </div>
              </div>
              <div class="col-6">
                <div class="detail-chip">
                  <div class="chip-label">Sonraki Ödeme</div>
                  <div class="chip-value {{ $nextDateClass }}">
                    @if($loan->next_payment_date)
                      {{ \Carbon\Carbon::parse($loan->next_payment_date)->format('d.m.Y') }}
                      @if($loanDaysLeft !== null)
                        <span class="d-block fw-normal text-muted" style="font-size:.66rem;">
                          {{ $loanDaysLeft === 0 ? 'Bugün!' : "{$loanDaysLeft} gün" }}
                        </span>
                      @endif
                    @else —
                    @endif
                  </div>
                </div>
              </div>
            </div>

            {{-- Remaining total + CTA --}}
            <div class="d-flex align-items-center gap-2 mt-3">
              <div class="remaining-chip flex-grow-1">
                <div class="chip-label" style="font-size:.68rem;">Kalan Ödeme Toplamı</div>
                <div class="chip-value fw-bold" style="font-size:.88rem; color:#7367F0;">
                  ₺{{ number_format($remainingTotal, 0, ',', '.') }}
                </div>
              </div>
              <a href="{{ route('negotiation.index') }}"
                 class="btn btn-sm btn-outline-primary flex-shrink-0 d-flex align-items-center gap-1"
                 title="Yeniden Yapılandır">
                <i class="icon-base ti tabler-message-2-dollar icon-16px"></i>
                <span class="d-none d-sm-inline">Yapılandır</span>
              </a>
            </div>

          </div>{{-- /body --}}
        </div>
      </div>
    </div>

    @empty

    {{-- ── Empty state ──────────────────────────────────────────────────────── --}}
    <div class="col-12">
      <div class="card">
        <div class="card-body text-center py-8">
          <div class="d-flex justify-content-center mb-4">
            <div class="empty-icon-wrap">
              <i class="icon-base ti tabler-file-invoice icon-48px text-muted"></i>
            </div>
          </div>
          <h5 class="fw-bold mb-2">Aktif krediniz bulunmuyor</h5>
          <p class="text-muted mb-5 mx-auto" style="max-width:380px;">
            Banka hesabınızı bağladıktan sonra kredileriniz otomatik olarak listelenir ve taksit takibiniz başlar.
          </p>
          <a href="{{ route('bank-connections.create') }}" class="btn btn-primary">
            <i class="icon-base ti tabler-building-bank me-1"></i>Banka Bağla
          </a>
        </div>
      </div>
    </div>

    @endforelse
  </div>

</x-app-layout>
