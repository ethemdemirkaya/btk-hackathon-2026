<x-app-layout>
  <x-slot name="title">Kredi Kartları</x-slot>

  <x-slot name="pageCss">
  <style>
    .card-chip {
      width: 36px; height: 26px; background: linear-gradient(135deg,#c9a227,#f5d066);
      border-radius: 5px; flex-shrink: 0;
    }
    .bank-card-visual {
      border-radius: 14px;
      background: linear-gradient(135deg, #1A56DB 0%, #7367f0 100%);
      color: #fff; padding: 1.4rem 1.6rem; position: relative; overflow: hidden;
      min-height: 160px;
    }
    .bank-card-visual.debit {
      background: linear-gradient(135deg, #2d3748 0%, #4a5568 100%);
    }
    .bank-card-visual::after {
      content:''; position:absolute; right:-30px; top:-30px;
      width:140px; height:140px; border-radius:50%;
      background:rgba(255,255,255,.08);
    }
    .bank-card-visual .card-number { letter-spacing: .2em; font-size: 1.05rem; font-family: monospace; }
    .usage-ring-wrap { position:relative; width:56px; height:56px; flex-shrink:0; }
  </style>
  </x-slot>

  <div class="d-flex align-items-center justify-content-between mb-6">
    <div>
      <h4 class="fw-bold mb-1">Kredi Kartları</h4>
      <p class="text-muted mb-0">{{ $cards->count() }} kart bağlı</p>
    </div>
  </div>

  {{-- Summary --}}
  <div class="row g-4 mb-6">
    <div class="col-sm-4">
      <div class="card">
        <div class="card-body py-3">
          <div class="text-muted small">Toplam Borç</div>
          <div class="fw-bold fs-5 text-danger">₺{{ number_format($totalDebt, 0, ',', '.') }}</div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card">
        <div class="card-body py-3">
          <div class="text-muted small">Toplam Limit</div>
          <div class="fw-bold fs-5">₺{{ number_format($totalLimit, 0, ',', '.') }}</div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card">
        <div class="card-body py-3">
          <div class="text-muted small">Genel Kullanım</div>
          <div class="fw-bold fs-5 {{ $totalUsage > 70 ? 'text-danger' : ($totalUsage > 40 ? 'text-warning' : 'text-success') }}">
            %{{ $totalUsage }}
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- Card grid --}}
  <div class="row g-6 mb-6">
    @foreach($cards as $card)
    @php
      $isCredit = $card->type === 'credit';
      $usage    = $isCredit && $card->credit_limit > 0
                    ? min(100, round($card->current_debt / $card->credit_limit * 100))
                    : 0;
      $available = max(0, (float)$card->credit_limit - (float)$card->current_debt);
    @endphp
    <div class="col-md-6 col-xl-4">
      <div class="card h-100">
        <div class="card-body p-0">

          {{-- Visual card --}}
          <div class="bank-card-visual {{ $isCredit ? '' : 'debit' }} m-4 mb-3">
            <div class="d-flex align-items-start justify-content-between mb-4">
              <div>
                @if($card->bank_logo)
                  <img src="{{ asset($card->bank_logo) }}" alt="{{ $card->bank_name }}"
                       style="height:28px;width:auto;object-fit:contain;filter:brightness(0) invert(1);opacity:.9;">
                @else
                  <span class="fw-bold text-white opacity-75">{{ $card->bank_name }}</span>
                @endif
              </div>
              <span class="badge {{ $isCredit ? 'bg-warning text-dark' : 'bg-light text-dark' }} small">
                {{ $isCredit ? 'KREDİ' : 'DEBİT' }}
              </span>
            </div>
            <div class="card-chip mb-3"></div>
            <div class="card-number mb-2 opacity-90">{{ $card->masked_number }}</div>
            <div class="d-flex justify-content-between align-items-end">
              <div style="font-size:.72rem;opacity:.75;">
                @if($card->holder_name) {{ strtoupper($card->holder_name) }} @endif
              </div>
              <div style="font-size:.72rem;opacity:.75;">
                {{ str_pad($card->expiry_month ?? '??', 2, '0', STR_PAD_LEFT) }}/{{ $card->expiry_year ?? '??' }}
              </div>
            </div>
          </div>

          {{-- Stats --}}
          <div class="px-4 pb-4">
            @if($isCredit)
            <div class="d-flex align-items-center gap-3 mb-3">
              <div class="flex-grow-1">
                <div class="d-flex justify-content-between small mb-1">
                  <span class="text-muted">Kullanılan</span>
                  <span class="fw-bold text-danger">₺{{ number_format($card->current_debt, 0, ',', '.') }}</span>
                </div>
                <div class="progress" style="height:6px;">
                  <div class="progress-bar {{ $usage > 70 ? 'bg-danger' : ($usage > 40 ? 'bg-warning' : 'bg-success') }}"
                       style="width:{{ $usage }}%"></div>
                </div>
                <div class="d-flex justify-content-between mt-1" style="font-size:.72rem;">
                  <span class="text-muted">Kullanılabilir: ₺{{ number_format($available, 0, ',', '.') }}</span>
                  <span class="text-muted">Limit: ₺{{ number_format($card->credit_limit, 0, ',', '.') }}</span>
                </div>
              </div>
            </div>
            <div class="d-flex gap-3 text-muted" style="font-size:.78rem;">
              <span><i class="icon-base ti tabler-calendar me-1"></i>Ekstre: {{ $card->statement_day }}. gün</span>
              <span><i class="icon-base ti tabler-coin me-1"></i>Son ödeme: {{ $card->due_day }}. gün</span>
            </div>
            @else
            <div class="text-muted small text-center py-2">Vadesiz (Debit) Kart</div>
            @endif
          </div>

        </div>
      </div>
    </div>
    @endforeach
  </div>

  {{-- Recent transactions --}}
  @if($recentTx->isNotEmpty())
  <div class="card">
    <div class="card-header pb-2">
      <h5 class="card-title mb-0">Son 30 Günün Harcamaları</h5>
    </div>
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-hover mb-0">
          <thead class="table-light">
            <tr>
              <th class="ps-4 py-3">Tarih</th>
              <th>Açıklama / Mağaza</th>
              <th class="text-end pe-4">Tutar</th>
            </tr>
          </thead>
          <tbody>
            @foreach($recentTx as $tx)
            <tr>
              <td class="ps-4 small text-muted">{{ \Carbon\Carbon::parse($tx->posted_at)->format('d.m.Y') }}</td>
              <td>
                <div class="small fw-medium">{{ $tx->description }}</div>
                <div class="text-muted" style="font-size:.72rem;">{{ $tx->merchant_name }}</div>
              </td>
              <td class="text-end pe-4 fw-bold text-danger">
                ₺{{ number_format(abs($tx->amount), 2, ',', '.') }}
              </td>
            </tr>
            @endforeach
          </tbody>
        </table>
      </div>
    </div>
    <div class="card-footer py-2 px-4">
      <a href="{{ route('transactions.index', ['type' => 'expense']) }}" class="text-primary small">
        Tüm işlemleri gör →
      </a>
    </div>
  </div>
  @endif
</x-app-layout>
