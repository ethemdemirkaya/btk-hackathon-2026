<x-app-layout>
  <x-slot name="title">Krediler</x-slot>

  <div class="d-flex align-items-center justify-content-between mb-6">
    <div>
      <h4 class="fw-bold mb-1">Krediler</h4>
      <p class="text-muted mb-0">{{ $loans->count() }} aktif kredi</p>
    </div>
    <a href="{{ route('negotiation.index') }}" class="btn btn-outline-primary btn-sm">
      <i class="icon-base ti tabler-message-2-dollar me-1"></i>Yeniden Yapılandır
    </a>
  </div>

  {{-- Summary --}}
  <div class="row g-4 mb-6">
    <div class="col-sm-4">
      <div class="card">
        <div class="card-body py-3">
          <div class="text-muted small">Toplam Kalan Borç</div>
          <div class="fw-bold fs-5 text-danger">₺{{ number_format($totalBalance, 0, ',', '.') }}</div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card">
        <div class="card-body py-3">
          <div class="text-muted small">Bu Ay Ödenecek</div>
          <div class="fw-bold fs-5 text-warning">₺{{ number_format($totalNextPayment, 0, ',', '.') }}</div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card">
        <div class="card-body py-3">
          <div class="text-muted small">En Yakın Vade</div>
          <div class="fw-bold fs-5">
            @if($nextDue)
              {{ \Carbon\Carbon::parse($nextDue->next_payment_date)->format('d.m.Y') }}
              @php $daysLeft = (int) round(now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($nextDue->next_payment_date)->startOfDay(), false)); @endphp
              <span class="badge {{ $daysLeft <= 3 ? 'bg-label-danger' : ($daysLeft <= 7 ? 'bg-label-warning' : 'bg-label-success') }} ms-1">
                {{ $daysLeft }} gün
              </span>
            @else
              —
            @endif
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- Loans list --}}
  <div class="row g-6">
    @foreach($loans as $loan)
    <div class="col-md-6">
      <div class="card h-100">
        <div class="card-body">

          {{-- Header --}}
          <div class="d-flex align-items-start gap-3 mb-4">
            <div class="d-flex align-items-center justify-content-center bg-white border rounded flex-shrink-0"
                 style="width:72px;height:48px;padding:6px;">
              @if($loan->bank_logo)
                <img src="{{ asset($loan->bank_logo) }}" alt="{{ $loan->bank_name }}"
                     style="max-width:100%;max-height:100%;object-fit:contain;">
              @else
                <span class="fw-bold text-primary">{{ strtoupper(substr($loan->bank_slug, 0, 2)) }}</span>
              @endif
            </div>
            <div>
              <div class="fw-semibold">{{ $loan->bank_name }}</div>
              <div class="text-muted small">{{ ucfirst($loan->type ?? 'Bireysel') }} Kredi</div>
            </div>
            <div class="ms-auto text-end">
              <div class="fw-bold text-danger fs-6">₺{{ number_format($loan->current_balance, 0, ',', '.') }}</div>
              <div class="text-muted small">kalan</div>
            </div>
          </div>

          {{-- Progress --}}
          <div class="mb-3">
            <div class="d-flex justify-content-between small mb-1">
              <span class="text-muted">Ödenen taksitler</span>
              <span class="fw-medium">{{ $loan->paid_installments }} / {{ $loan->total_installments }}</span>
            </div>
            <div class="progress" style="height:8px;border-radius:4px;">
              <div class="progress-bar bg-primary" style="width:{{ $loan->paid_pct }}%;border-radius:4px;"></div>
            </div>
            <div class="text-muted mt-1" style="font-size:.72rem;">
              Kalan: {{ $loan->remaining_installments }} taksit
            </div>
          </div>

          {{-- Details grid --}}
          <div class="row g-2 mb-3">
            <div class="col-6">
              <div class="bg-light rounded p-2 text-center">
                <div class="text-muted" style="font-size:.72rem;">Anapara</div>
                <div class="fw-semibold small">₺{{ number_format($loan->principal, 0, ',', '.') }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="bg-light rounded p-2 text-center">
                <div class="text-muted" style="font-size:.72rem;">Faiz Oranı (aylık)</div>
                <div class="fw-semibold small">%{{ $loan->interest_rate }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="bg-light rounded p-2 text-center">
                <div class="text-muted" style="font-size:.72rem;">Aylık Taksit</div>
                <div class="fw-semibold small text-warning">₺{{ number_format($loan->next_payment_amount, 0, ',', '.') }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="bg-light rounded p-2 text-center">
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

          {{-- Payoff date estimate --}}
          @if($loan->ends_at)
          <div class="text-muted small">
            <i class="icon-base ti tabler-calendar-check me-1"></i>
            Tahmini bitiş: {{ \Carbon\Carbon::parse($loan->ends_at)->format('d.m.Y') }}
          </div>
          @endif

        </div>
      </div>
    </div>
    @endforeach
  </div>
</x-app-layout>
