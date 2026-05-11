<x-app-layout>
  <x-slot name="title">Krediler</x-slot>

  <x-slot name="pageCss">
  <style>
    .bank-logo-box { background:#fff; border-radius:6px; padding:4px 8px; display:inline-flex; align-items:center; justify-content:center; min-width:60px; height:36px; border:1px solid rgba(0,0,0,.08); }
    [data-bs-theme="dark"] .bank-logo-box { background:rgba(255,255,255,.1); border-color:rgba(255,255,255,.1); }
    .bank-logo-box img { max-height:24px; width:auto; object-fit:contain; }
    .detail-box { background:var(--bs-secondary-bg); border:1px solid var(--bs-border-color); border-radius:8px; padding:.5rem .75rem; }
    /* Loan card left-border accent based on remaining installments */
    .loan-card-urgent   { border-left: 4px solid #EA5455 !important; }
    .loan-card-warn     { border-left: 4px solid #FF9F43 !important; }
    .loan-card-mid      { border-left: 4px solid #7367F0 !important; }
    .loan-card-ok       { border-left: 4px solid #28C76F !important; }
    /* Timeline dots */
    .install-timeline { display:flex; flex-wrap:wrap; gap:3px; }
    .install-dot { width:10px; height:10px; border-radius:50%; }
    .install-dot.paid { background:#28C76F; }
    .install-dot.remaining { background:var(--bs-border-color); }
    .install-dot.next { background:#FF9F43; }
  </style>
  </x-slot>

  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Krediler</h4>
      <p class="text-muted small mb-0">{{ $loans->count() }} aktif kredi · taksit takibi</p>
    </div>
    <a href="{{ route('negotiation.index') }}" class="btn btn-outline-primary btn-sm">
      <i class="icon-base ti tabler-message-2-dollar me-1"></i>Yeniden Yapılandır
    </a>
  </div>

  {{-- Stat cards --}}
  @php $totalRemainingInstallments = $loans->sum('remaining_installments'); @endphp
  <div class="row g-4 mb-6">
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-danger"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Kalan Borç</span>
              <div class="h5 fw-bold mt-1 mb-0 text-danger">₺{{ number_format($totalBalance, 0, ',', '.') }}</div>
              <span class="small text-muted">Tüm krediler</span>
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
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-warning"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Bu Ay Ödenecek</span>
              <div class="h5 fw-bold mt-1 mb-0 text-warning">₺{{ number_format($totalNextPayment, 0, ',', '.') }}</div>
              <span class="small text-muted">Toplam taksit</span>
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
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        @php $daysLeft = $nextDue ? (int) round(now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($nextDue->next_payment_date)->startOfDay(), false)) : null; @endphp
        <div class="accent-bar {{ $daysLeft !== null && $daysLeft <= 3 ? 'bg-danger' : ($daysLeft !== null && $daysLeft <= 7 ? 'bg-warning' : 'bg-success') }}"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">En Yakın Vade</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">
                @if($nextDue) {{ \Carbon\Carbon::parse($nextDue->next_payment_date)->format('d.m.Y') }}
                @else —
                @endif
              </div>
              @if($daysLeft !== null)
                <span class="badge bg-label-{{ $daysLeft <= 3 ? 'danger' : ($daysLeft <= 7 ? 'warning' : 'success') }}" style="font-size:.72rem;">{{ $daysLeft }} gün kaldı</span>
              @endif
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $daysLeft !== null && $daysLeft <= 3 ? 'danger' : ($daysLeft !== null && $daysLeft <= 7 ? 'warning' : 'success') }}">
                <i class="icon-base ti tabler-clock icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-info"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Kalan Taksit</span>
              <div class="h5 fw-bold mt-1 mb-0 text-info">{{ number_format($totalRemainingInstallments, 0, ',', '.') }}</div>
              <span class="small text-muted">Tüm krediler</span>
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

  {{-- Loans list --}}
  <div class="row g-5">
    @forelse($loans as $loan)
    @php
      // Left-border accent class based on remaining installments
      $remPct = $loan->total_installments > 0 ? ($loan->remaining_installments / $loan->total_installments) * 100 : 0;
      $accentClass = $remPct <= 20 ? 'loan-card-ok' : ($remPct <= 40 ? 'loan-card-mid' : ($remPct <= 70 ? 'loan-card-warn' : 'loan-card-urgent'));

      // Next payment urgency
      $loanDaysLeft = $loan->next_payment_date
        ? (int) round(now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($loan->next_payment_date)->startOfDay(), false))
        : null;
      $isUrgent = $loanDaysLeft !== null && $loanDaysLeft <= 7;

      // Kalan ödeme toplam
      $remainingTotal = $loan->remaining_installments * $loan->next_payment_amount;

      // Timeline: cap dots at 24 for display
      $maxDots = min($loan->total_installments, 24);
      $paidDots = $loan->total_installments > 0 ? round(($loan->paid_installments / $loan->total_installments) * $maxDots) : 0;
    @endphp
    <div class="col-md-6">
      <div class="card h-100 shadow-sm {{ $accentClass }}">
        <div class="card-body">

          {{-- Header --}}
          <div class="d-flex align-items-start gap-3 mb-3">
            <div class="bank-logo-box flex-shrink-0" style="width:72px;height:48px;min-width:72px;">
              @if($loan->bank_logo)
                <img src="{{ asset($loan->bank_logo) }}" alt="{{ $loan->bank_name }}">
              @else
                <span class="fw-bold text-primary small">{{ strtoupper(substr($loan->bank_slug, 0, 2)) }}</span>
              @endif
            </div>
            <div class="flex-grow-1 min-width-0">
              <div class="d-flex align-items-center gap-2 flex-wrap">
                <span class="fw-semibold">{{ $loan->bank_name }}</span>
                @if($isUrgent)
                  <span class="badge bg-danger" style="font-size:.68rem;">Yaklaşıyor!</span>
                @endif
              </div>
              <div class="text-muted small">{{ ucfirst($loan->type ?? 'Bireysel') }} Kredi</div>
            </div>
            <div class="text-end flex-shrink-0">
              <div class="fw-bold text-danger">₺{{ number_format($loan->current_balance, 0, ',', '.') }}</div>
              <div class="text-muted small">kalan</div>
            </div>
          </div>

          {{-- Installment progress --}}
          <div class="mb-3">
            <div class="d-flex justify-content-between small mb-1">
              <span class="text-muted">Ödenen taksitler</span>
              <span class="fw-medium">{{ $loan->paid_installments }} / {{ $loan->total_installments }}</span>
            </div>
            <div class="progress mb-2" style="height:6px;border-radius:8px;background:var(--bs-secondary-bg);">
              <div class="progress-bar-gradient-primary" style="width:{{ $loan->paid_pct }}%;height:100%;border-radius:8px;"></div>
            </div>
            {{-- Timeline dots --}}
            <div class="install-timeline">
              @for($d = 0; $d < $maxDots; $d++)
                @if($d < $paidDots)
                  <div class="install-dot paid" title="Ödendi"></div>
                @elseif($d === $paidDots)
                  <div class="install-dot next" title="Sıradaki ödeme"></div>
                @else
                  <div class="install-dot remaining" title="Kalan"></div>
                @endif
              @endfor
            </div>
            <div class="text-muted mt-1" style="font-size:.72rem;">
              {{ $loan->remaining_installments }} taksit kaldı
            </div>
          </div>

          {{-- Detail chips --}}
          <div class="row g-2 mb-3">
            <div class="col-6">
              <div class="detail-box rounded border px-3 py-2">
                <div class="text-muted" style="font-size:.72rem;">Anapara</div>
                <div class="fw-semibold small">₺{{ number_format($loan->principal, 0, ',', '.') }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="detail-box rounded border px-3 py-2">
                <div class="text-muted" style="font-size:.72rem;">Faiz Oranı (aylık)</div>
                <div class="fw-semibold small">%{{ $loan->interest_rate }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="detail-box rounded border px-3 py-2">
                <div class="text-muted" style="font-size:.72rem;">Aylık Taksit</div>
                <div class="fw-semibold small text-warning">₺{{ number_format($loan->next_payment_amount, 0, ',', '.') }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="detail-box rounded border px-3 py-2">
                <div class="text-muted" style="font-size:.72rem;">Sonraki Ödeme</div>
                <div class="fw-semibold small {{ $isUrgent ? 'text-danger' : '' }}">
                  @if($loan->next_payment_date)
                    {{ \Carbon\Carbon::parse($loan->next_payment_date)->format('d.m.Y') }}
                    @if($loanDaysLeft !== null)
                      <span class="d-block text-muted" style="font-size:.68rem;">{{ $loanDaysLeft }} gün</span>
                    @endif
                  @else —
                  @endif
                </div>
              </div>
            </div>
          </div>

          {{-- Kalan ödeme + ends_at row --}}
          <div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
            <div class="detail-box rounded border px-3 py-2 flex-grow-1">
              <div class="text-muted" style="font-size:.72rem;">Kalan Ödeme</div>
              <div class="fw-semibold small text-primary">₺{{ number_format($remainingTotal, 0, ',', '.') }}</div>
            </div>
            @if($loan->ends_at)
            <div class="text-muted small text-end flex-shrink-0">
              <i class="icon-base ti tabler-calendar-check me-1"></i>
              Bitiş: {{ \Carbon\Carbon::parse($loan->ends_at)->format('M Y') }}
            </div>
            @endif
          </div>

          {{-- Restructure link --}}
          <div class="mt-3 pt-2 border-top">
            <a href="{{ route('negotiation.index') }}" class="btn btn-outline-primary btn-sm w-100">
              <i class="icon-base ti tabler-message-2-dollar me-1"></i>Yeniden Yapılandır
            </a>
          </div>

        </div>
      </div>
    </div>
    @empty
    <div class="col-12">
      <div class="card">
        <div class="card-body text-center py-6">
          <div class="d-flex justify-content-center mb-3">
            <i class="icon-base ti tabler-file-invoice icon-48px text-muted"></i>
          </div>
          <h5 class="mb-2">Aktif krediniz bulunmuyor</h5>
          <p class="text-muted mb-4">Banka hesabınızı bağladıktan sonra kredileriniz otomatik olarak listelenir.</p>
          <a href="{{ route('bank-connections.create') }}" class="btn btn-primary">
            <i class="icon-base ti tabler-plus me-1"></i>Banka Bağla
          </a>
        </div>
      </div>
    </div>
    @endforelse
  </div>
</x-app-layout>
