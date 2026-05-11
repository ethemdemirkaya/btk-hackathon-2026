<x-app-layout>
  <x-slot name="title">İşlemler</x-slot>

  <div class="d-flex align-items-center justify-content-between mb-5">
    <div>
      <h4 class="fw-bold mb-0">İşlemler</h4>
      <p class="text-muted small mb-0">Tüm banka hesaplarınızdaki hareketler</p>
    </div>
    <div class="d-flex gap-2">
      <a href="{{ route('report.monthly') }}" class="btn btn-outline-primary btn-sm" target="_blank">
        <i class="icon-base ti tabler-file-type-pdf me-1"></i>PDF Rapor
      </a>
      <a href="{{ route('transactions.export', request()->only(['q','type','from','to'])) }}"
         class="btn btn-outline-success btn-sm">
        <i class="icon-base ti tabler-file-type-csv me-1"></i>CSV İndir
      </a>
    </div>
  </div>

  {{-- Premium stat cards --}}
  <div class="row g-4 mb-6">
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-success"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Bu Ay Gelir</span>
              <div class="h5 fw-bold mt-1 mb-0 text-success">₺{{ number_format($stats->income ?? 0, 0, ',', '.') }}</div>
              <span class="small text-muted">{{ now()->translatedFormat('F') }}</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-success">
                <i class="icon-base ti tabler-arrow-down-left icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-danger"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Bu Ay Gider</span>
              <div class="h5 fw-bold mt-1 mb-0 text-danger">₺{{ number_format($stats->expense ?? 0, 0, ',', '.') }}</div>
              <span class="small text-muted">Harcamalar</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-danger">
                <i class="icon-base ti tabler-arrow-up-right icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-primary"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Bu Ay İşlem</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">{{ $stats->total_count ?? 0 }}</div>
              <span class="small text-muted">Toplam hareket</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-arrows-exchange icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- Filters --}}
  <div class="card mb-5 shadow-sm">
    <div class="card-body py-3">
      <form method="GET" action="{{ route('transactions.index') }}" class="row g-3 align-items-end">
        <div class="col-md-4">
          <label class="form-label small mb-1">Ara</label>
          <input type="text" name="q" class="form-control form-control-sm"
                 placeholder="Açıklama veya mağaza…" value="{{ request('q') }}">
        </div>
        <div class="col-md-2">
          <label class="form-label small mb-1">Tür</label>
          <select name="type" class="form-select form-select-sm">
            <option value="">Tümü</option>
            <option value="income"  {{ request('type') === 'income'  ? 'selected' : '' }}>Gelir</option>
            <option value="expense" {{ request('type') === 'expense' ? 'selected' : '' }}>Gider</option>
          </select>
        </div>
        <div class="col-md-2">
          <label class="form-label small mb-1">Başlangıç</label>
          <input type="date" name="from" class="form-control form-control-sm" value="{{ request('from') }}">
        </div>
        <div class="col-md-2">
          <label class="form-label small mb-1">Bitiş</label>
          <input type="date" name="to" class="form-control form-control-sm" value="{{ request('to') }}">
        </div>
        <div class="col-md-2 d-flex gap-2">
          <button type="submit" class="btn btn-primary btn-sm flex-fill">
            <i class="icon-base ti tabler-search me-1"></i>Filtrele
          </button>
          <a href="{{ route('transactions.index') }}" class="btn btn-outline-secondary btn-sm">
            <i class="icon-base ti tabler-x"></i>
          </a>
        </div>
      </form>
    </div>
  </div>

  {{-- Table --}}
  <div class="card shadow-sm">
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-hover mb-0">
          <thead>
            <tr class="paranette-thead">
              <th class="ps-4 py-3">Tarih</th>
              <th class="py-3">Açıklama</th>
              <th class="py-3 d-none d-md-table-cell">Mağaza</th>
              <th class="py-3 d-none d-sm-table-cell">Banka</th>
              <th class="py-3 pe-4 text-end">Tutar</th>
            </tr>
          </thead>
          <tbody>
            @forelse($transactions as $tx)
              <tr>
                <td class="ps-4 py-3">
                  <div class="fw-medium small">{{ \Carbon\Carbon::parse($tx->posted_at)->format('d.m.Y') }}</div>
                  <div class="text-muted" style="font-size:.72rem;">{{ \Carbon\Carbon::parse($tx->posted_at)->format('H:i') }}</div>
                </td>
                <td class="py-3">
                  <div class="d-flex align-items-center gap-2">
                    <div class="avatar avatar-sm flex-shrink-0">
                      <span class="avatar-initial rounded bg-label-{{ $tx->amount >= 0 ? 'success' : 'danger' }}">
                        <i class="icon-base ti {{ $tx->amount >= 0 ? 'tabler-arrow-down-left' : 'tabler-arrow-up-right' }} icon-14px"></i>
                      </span>
                    </div>
                    <div class="overflow-hidden">
                      <div class="small fw-medium text-truncate" style="max-width:220px;">{{ $tx->description }}</div>
                      @if($tx->merchant_category)
                        <span class="badge bg-label-secondary" style="font-size:.68rem;">{{ $tx->merchant_category }}</span>
                      @endif
                    </div>
                  </div>
                </td>
                <td class="py-3 d-none d-md-table-cell small text-muted">{{ $tx->merchant_name ?: '—' }}</td>
                <td class="py-3 d-none d-sm-table-cell">
                  @if($tx->bank_logo)
                    <img src="{{ asset($tx->bank_logo) }}" alt="{{ $tx->bank_name }}"
                         style="height:18px;width:auto;object-fit:contain;">
                  @else
                    <span class="badge bg-label-secondary small">{{ $tx->bank_name }}</span>
                  @endif
                </td>
                <td class="py-3 pe-4 text-end">
                  <span class="fw-bold {{ $tx->amount >= 0 ? 'text-success' : 'text-danger' }}">
                    {{ $tx->amount >= 0 ? '+' : '' }}₺{{ number_format(abs($tx->amount), 2, ',', '.') }}
                  </span>
                </td>
              </tr>
            @empty
              <tr>
                <td colspan="5" class="text-center py-6 text-muted">
                  <i class="icon-base ti tabler-inbox icon-48px d-block mb-3 mx-auto"></i>
                  Filtreye uyan işlem bulunamadı.
                </td>
              </tr>
            @endforelse
          </tbody>
        </table>
      </div>
    </div>
    @if($transactions->hasPages())
      <div class="card-footer py-3 px-4 d-flex align-items-center justify-content-between flex-wrap gap-3">
        <div class="text-muted small">
          Toplam <strong>{{ $transactions->total() }}</strong> işlem —
          {{ $transactions->firstItem() }}–{{ $transactions->lastItem() }} gösteriliyor
        </div>
        {{ $transactions->links() }}
      </div>
    @endif
  </div>
</x-app-layout>
