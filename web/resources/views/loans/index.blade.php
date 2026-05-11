<x-app-layout>
  <x-slot name="title">Krediler</x-slot>

  <div class="d-flex align-items-center justify-content-between mb-5">
    <div>
      <h4 class="fw-bold mb-0">Krediler</h4>
      <p class="text-muted small mb-0">{{ $loans->count() }} aktif kredi · taksit takibi</p>
    </div>
    <a href="{{ route('negotiation.index') }}" class="btn btn-outline-primary btn-sm">
      <i class="icon-base ti tabler-message-2-dollar me-1"></i>Yeniden Yapılandır
    </a>
  </div>

  {{-- Premium stat cards --}}
  <div class="row g-4 mb-6">
    <div class="col-sm-4">
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
    <div class="col-sm-4">
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
    <div class="col-sm-4">
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
  </div>

  {{-- Loans list --}}
  <div class="row g-5">
    @forelse($loans as $loan)
    <div class="col-md-6">
      <div class="card h-100 shadow-sm">
        <div class="card-body">

          {{-- Header --}}
          <div class="d-flex align-items-start gap-3 mb-4">
            <div class="bank-logo-box rounded flex-shrink-0 d-flex align-items-center justify-content-center"
                 style="width:72px;height:48px;padding:6px;">
              @if($loan->bank_logo)
                <img src="{{ asset($loan->bank_logo) }}" alt="{{ $loan->bank_name }}"
                     style="max-width:100%;max-height:100%;object-fit:contain;">
              @else
                <span class="fw-bold text-primary small">{{ strtoupper(substr($loan->bank_slug, 0, 2)) }}</span>
              @endif
            </div>
            <div class="flex-grow-1">
              <div class="fw-semibold">{{ $loan->bank_name }}</div>
              <div class="text-muted small">{{ ucfirst($loan->type ?? 'Bireysel') }} Kredi</div>
            </div>
            <div class="text-end">
              <div class="fw-bold text-danger">₺{{ number_format($loan->current_balance, 0, ',', '.') }}</div>
              <div class="text-muted small">kalan</div>
            </div>
          </div>

          {{-- Installment progress --}}
          <div class="mb-4">
            <div class="d-flex justify-content-between small mb-1">
              <span class="text-muted">Ödenen taksitler</span>
              <span class="fw-medium">{{ $loan->paid_installments }} / {{ $loan->total_installments }}</span>
            </div>
            <div class="progress mb-1" style="height:8px;border-radius:8px;background:var(--bs-secondary-bg);">
              <div class="progress-bar-gradient-primary" style="width:{{ $loan->paid_pct }}%;height:100%;border-radius:8px;"></div>
            </div>
            <div class="text-muted" style="font-size:.72rem;">
              {{ $loan->remaining_installments }} taksit kaldı
            </div>
          </div>

          {{-- Detail boxes (dark mode safe) --}}
          <div class="row g-2 mb-3">
            <div class="col-6">
              <div class="detail-box">
                <div class="text-muted" style="font-size:.72rem;">Anapara</div>
                <div class="fw-semibold small">₺{{ number_format($loan->principal, 0, ',', '.') }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="detail-box">
                <div class="text-muted" style="font-size:.72rem;">Faiz Oranı (aylık)</div>
                <div class="fw-semibold small">%{{ $loan->interest_rate }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="detail-box">
                <div class="text-muted" style="font-size:.72rem;">Aylık Taksit</div>
                <div class="fw-semibold small text-warning">₺{{ number_format($loan->next_payment_amount, 0, ',', '.') }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="detail-box">
                <div class="text-muted" style="font-size:.72rem;">Sonraki Ödeme</div>
                <div class="fw-semibold small">
                  @if($loan->next_payment_date)
                    {{ \Carbon\Carbon::parse($loan->next_payment_date)->format('d.m.Y') }}
                  @else —
                  @endif
                </div>
              </div>
            </div>
          </div>

          @if($loan->ends_at)
          <div class="text-muted small">
            <i class="icon-base ti tabler-calendar-check me-1"></i>
            Tahmini bitiş: {{ \Carbon\Carbon::parse($loan->ends_at)->format('M Y') }}
          </div>
          @endif

        </div>
      </div>
    </div>
    @empty
    <div class="col-12">
      <div class="card">
        <div class="card-body text-center py-6">
          <i class="icon-base ti tabler-file-invoice icon-48px text-muted mb-3 d-block"></i>
          <p class="text-muted mb-0">Aktif krediniz bulunmuyor.</p>
        </div>
      </div>
    </div>
    @endforelse
  </div>
</x-app-layout>
