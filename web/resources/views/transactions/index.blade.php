<x-app-layout>
  <x-slot name="title">İşlemler</x-slot>

  <x-slot name="pageCss">
  <style>
    .filter-chip { cursor:pointer; transition:all .15s; border-radius:20px; padding:.2rem .65rem; }
    .filter-chip:hover { transform:translateY(-1px); box-shadow:0 2px 8px rgba(0,0,0,.1); }
    .debt-given   { border-left:3px solid #EA5455 !important; }
    .debt-received{ border-left:3px solid #28C76F !important; }
    .btn-debt-tag { opacity:0; transition:opacity .15s; }
    .tx-row:hover .btn-debt-tag { opacity:1; }
    @media(max-width:767px){ .btn-debt-tag { opacity:1; } }
  </style>
  </x-slot>

  {{-- Header --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">İşlemler</h4>
      <p class="text-muted small mb-0">Tüm banka hesaplarınızdaki hareketler</p>
    </div>
    <div class="d-flex gap-2 flex-wrap">
      <a href="{{ route('transactions.import') }}" class="btn btn-outline-warning btn-sm">
        <i class="icon-base ti tabler-upload me-1"></i>CSV İçe Aktar
      </a>
      <a href="{{ route('report.monthly') }}" class="btn btn-outline-primary btn-sm" target="_blank">
        <i class="icon-base ti tabler-file-type-pdf me-1"></i>PDF
      </a>
      <a href="{{ route('transactions.export', request()->only(['q','type','from','to','category','bank','min_amount','max_amount'])) }}"
         class="btn btn-outline-success btn-sm">
        <i class="icon-base ti tabler-file-type-csv me-1"></i>CSV İndir
      </a>
    </div>
  </div>

  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  @if(session('error'))
    <div class="alert alert-danger alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-alert-circle me-2"></i>{{ session('error') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  {{-- Stat Cards --}}
  <div class="row g-4 mb-5">
    <div class="col-6 col-xl-3">
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
    <div class="col-6 col-xl-3">
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
    <div class="col-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-primary"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">İşlem Sayısı</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">{{ $stats->total_count ?? 0 }}</div>
              <span class="small text-muted">Bu ay</span>
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
    <div class="col-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-info"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Ort. İşlem</span>
              <div class="h5 fw-bold mt-1 mb-0 text-info">₺{{ number_format($stats->avg_amount ?? 0, 0, ',', '.') }}</div>
              <span class="small text-muted">Ortalama tutar</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-info">
                <i class="icon-base ti tabler-calculator icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- Personal Debts Panel --}}
  @if($personalDebts->isNotEmpty())
  <div class="card mb-5 shadow-sm" style="border:1px solid rgba(115,103,240,.25);background:var(--bs-body-bg);">
    <div class="card-header border-0 d-flex align-items-center justify-content-between py-3">
      <h6 class="card-title mb-0 fw-semibold">
        <i class="icon-base ti tabler-users me-2 text-primary"></i>Açık Borçlar
        <span class="badge bg-label-primary ms-1">{{ $personalDebts->count() }}</span>
      </h6>
      <button class="btn btn-sm btn-text-secondary" type="button"
              data-bs-toggle="collapse" data-bs-target="#debtPanel">
        <i class="icon-base ti tabler-chevron-down icon-16px"></i>
      </button>
    </div>
    <div class="collapse show" id="debtPanel">
      <div class="card-body pt-0">
        <div class="row g-3">
          @foreach($personalDebts as $debt)
          <div class="col-md-6 col-xl-4">
            <div class="p-3 rounded border h-100 {{ $debt->direction === 'given' ? 'debt-given' : 'debt-received' }}"
                 style="background:var(--bs-body-bg);">
              <div class="d-flex align-items-start justify-content-between mb-2">
                <div class="d-flex align-items-center gap-2">
                  <div class="avatar avatar-sm">
                    <span class="avatar-initial rounded bg-label-{{ $debt->direction === 'given' ? 'danger' : 'success' }}">
                      <i class="icon-base ti {{ $debt->direction === 'given' ? 'tabler-arrow-up-right' : 'tabler-arrow-down-left' }} icon-14px"></i>
                    </span>
                  </div>
                  <div>
                    <div class="fw-semibold small">{{ $debt->contact_name }}</div>
                    <div class="text-muted" style="font-size:.7rem;">
                      {{ $debt->direction === 'given' ? 'Borç Verdim' : 'Borç Aldım' }}
                      · {{ \Carbon\Carbon::parse($debt->created_at)->format('d.m.Y') }}
                    </div>
                  </div>
                </div>
                <div class="fw-bold {{ $debt->direction === 'given' ? 'text-danger' : 'text-success' }}">
                  ₺{{ number_format($debt->amount, 0, ',', '.') }}
                </div>
              </div>
              @if($debt->note)
                <p class="text-muted small mb-2" style="font-size:.72rem;line-height:1.3;">{{ $debt->note }}</p>
              @endif
              <div class="d-flex gap-2 mt-2">
                <form action="{{ route('personal-debts.settle', $debt->id) }}" method="POST" class="flex-fill">
                  @csrf @method('PATCH')
                  <button type="submit" class="btn btn-sm btn-outline-success w-100" style="font-size:.75rem;">
                    <i class="icon-base ti tabler-check icon-12px me-1"></i>Ödendi
                  </button>
                </form>
                <form action="{{ route('personal-debts.destroy', $debt->id) }}" method="POST">
                  @csrf @method('DELETE')
                  <button type="submit" class="btn btn-sm btn-icon btn-text-danger">
                    <i class="icon-base ti tabler-trash icon-14px"></i>
                  </button>
                </form>
              </div>
            </div>
          </div>
          @endforeach
        </div>
      </div>
    </div>
  </div>
  @endif

  {{-- Advanced Filters --}}
  <div class="card mb-5 shadow-sm">
    <div class="card-body py-3">
      <form method="GET" action="{{ route('transactions.index') }}">
        <div class="row g-3 align-items-end mb-2">
          <div class="col-md-5">
            <label class="form-label small mb-1">Arama</label>
            <div class="input-group input-group-sm">
              <span class="input-group-text"><i class="icon-base ti tabler-search icon-14px"></i></span>
              <input type="text" name="q" class="form-control"
                     placeholder="Açıklama veya mağaza…" value="{{ request('q') }}">
            </div>
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
          <div class="col-md-1 d-flex gap-1">
            <button type="submit" class="btn btn-primary btn-sm flex-fill">
              <i class="icon-base ti tabler-search icon-14px"></i>
            </button>
            <a href="{{ route('transactions.index') }}" class="btn btn-outline-secondary btn-sm">
              <i class="icon-base ti tabler-x icon-14px"></i>
            </a>
          </div>
        </div>

        <button type="button" class="btn btn-link btn-sm text-muted p-0 mb-2"
                data-bs-toggle="collapse" data-bs-target="#advFilters">
          <i class="icon-base ti tabler-adjustments-horizontal me-1 icon-13px"></i>Gelişmiş Filtreler
          @if(request()->hasAny(['category','bank','min_amount','max_amount']))
            <span class="badge bg-primary ms-1" style="font-size:.58rem;">Aktif</span>
          @endif
        </button>

        <div class="collapse {{ request()->hasAny(['category','bank','min_amount','max_amount']) ? 'show' : '' }}"
             id="advFilters">
          <div class="row g-3 mb-2">
            <div class="col-sm-3">
              <label class="form-label small mb-1">Kategori</label>
              <select name="category" class="form-select form-select-sm">
                <option value="">Tüm Kategoriler</option>
                @foreach($categories as $cat)
                  <option value="{{ $cat->id }}" {{ request('category') == $cat->id ? 'selected' : '' }}>
                    {{ $cat->name }}
                  </option>
                @endforeach
              </select>
            </div>
            <div class="col-sm-3">
              <label class="form-label small mb-1">Banka</label>
              <select name="bank" class="form-select form-select-sm">
                <option value="">Tüm Bankalar</option>
                @foreach($banks as $bank)
                  <option value="{{ $bank->slug }}" {{ request('bank') === $bank->slug ? 'selected' : '' }}>
                    {{ $bank->name }}
                  </option>
                @endforeach
              </select>
            </div>
            <div class="col-sm-3">
              <label class="form-label small mb-1">Min. Tutar (₺)</label>
              <input type="number" name="min_amount" class="form-control form-control-sm"
                     placeholder="0" min="0" step="1" value="{{ request('min_amount') }}">
            </div>
            <div class="col-sm-3">
              <label class="form-label small mb-1">Maks. Tutar (₺)</label>
              <input type="number" name="max_amount" class="form-control form-control-sm"
                     placeholder="∞" min="0" step="1" value="{{ request('max_amount') }}">
            </div>
          </div>
        </div>

        {{-- Quick date chips --}}
        <div class="d-flex gap-2 flex-wrap mt-1">
          @foreach([
            ['label' => 'Bu Ay',       'from' => now()->startOfMonth()->format('Y-m-d'), 'to' => now()->format('Y-m-d')],
            ['label' => 'Geçen Ay',    'from' => now()->subMonth()->startOfMonth()->format('Y-m-d'), 'to' => now()->subMonth()->endOfMonth()->format('Y-m-d')],
            ['label' => 'Son 7 Gün',   'from' => now()->subDays(7)->format('Y-m-d'),  'to' => now()->format('Y-m-d')],
            ['label' => 'Son 90 Gün',  'from' => now()->subDays(90)->format('Y-m-d'), 'to' => now()->format('Y-m-d')],
          ] as $chip)
          <a href="{{ route('transactions.index', array_merge(request()->except(['from','to','page']), ['from'=>$chip['from'],'to'=>$chip['to']])) }}"
             class="badge bg-label-secondary text-secondary filter-chip text-decoration-none">
            {{ $chip['label'] }}
          </a>
          @endforeach
        </div>
      </form>
    </div>
  </div>

  {{-- Transaction Table --}}
  <div class="card shadow-sm">
    @if($transactions->total() > 0)
    <div class="card-header d-flex align-items-center justify-content-between py-3">
      <span class="text-muted small">
        Toplam <strong>{{ $transactions->total() }}</strong> işlem
        @if(request()->hasAny(['q','type','from','to','category','bank','min_amount','max_amount']))
          <span class="badge bg-label-warning ms-2">Filtreli</span>
        @endif
      </span>
      <span class="text-muted small">{{ $transactions->firstItem() }}–{{ $transactions->lastItem() }} gösteriliyor</span>
    </div>
    @endif
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-hover mb-0">
          <thead class="paranette-thead">
            <tr>
              <th class="ps-4 py-3" style="width:95px;">Tarih</th>
              <th class="py-3">Açıklama</th>
              <th class="py-3 d-none d-md-table-cell" style="width:130px;">Kategori</th>
              <th class="py-3 d-none d-sm-table-cell" style="width:110px;">Banka</th>
              <th class="py-3 pe-4 text-end" style="width:140px;">Tutar</th>
            </tr>
          </thead>
          <tbody>
            @forelse($transactions as $tx)
              <tr class="tx-row">
                <td class="ps-4 py-3">
                  <div class="fw-medium small">{{ \Carbon\Carbon::parse($tx->posted_at)->format('d.m.Y') }}</div>
                  <div class="text-muted" style="font-size:.7rem;">{{ \Carbon\Carbon::parse($tx->posted_at)->format('H:i') }}</div>
                </td>
                <td class="py-3">
                  <div class="d-flex align-items-center gap-2">
                    <div class="avatar avatar-sm flex-shrink-0">
                      <span class="avatar-initial rounded bg-label-{{ $tx->amount >= 0 ? 'success' : 'danger' }}">
                        <i class="icon-base ti {{ $tx->amount >= 0 ? 'tabler-arrow-down-left' : 'tabler-arrow-up-right' }} icon-14px"></i>
                      </span>
                    </div>
                    <div class="overflow-hidden flex-grow-1">
                      <div class="small fw-medium text-truncate" style="max-width:220px;">{{ $tx->description }}</div>
                      @if($tx->merchant_name)
                        <div class="text-muted" style="font-size:.7rem;">{{ $tx->merchant_name }}</div>
                      @endif
                      @if(in_array($tx->channel, ['transfer']) || preg_match('/havale|eft|gönder|transfer/i', $tx->description))
                        <span class="badge bg-label-info" style="font-size:.58rem; line-height:1.6;">EFT/Havale</span>
                      @endif
                    </div>
                    <button type="button"
                            class="btn btn-icon btn-sm btn-text-secondary btn-debt-tag flex-shrink-0"
                            title="Borç Kaydet"
                            data-tx-id="{{ $tx->id }}"
                            data-tx-desc="{{ \Illuminate\Support\Str::limit($tx->description, 45) }}"
                            data-tx-amount="{{ abs($tx->amount) }}"
                            data-tx-dir="{{ $tx->amount >= 0 ? 'received' : 'given' }}"
                            data-bs-toggle="modal" data-bs-target="#debtModal">
                      <i class="icon-base ti tabler-users icon-14px"></i>
                    </button>
                  </div>
                </td>
                <td class="py-3 d-none d-md-table-cell">
                  @if($tx->category_name)
                    <span class="badge bg-label-secondary" style="font-size:.68rem;">{{ $tx->category_name }}</span>
                  @elseif($tx->merchant_category)
                    <span class="badge bg-label-secondary" style="font-size:.68rem;">{{ $tx->merchant_category }}</span>
                  @else
                    <span class="text-muted small">—</span>
                  @endif
                </td>
                <td class="py-3 d-none d-sm-table-cell">
                  @if($tx->bank_logo)
                    <img src="{{ asset($tx->bank_logo) }}" alt="{{ $tx->bank_name }}"
                         style="height:18px;width:auto;object-fit:contain;" title="{{ $tx->bank_name }}">
                  @else
                    <span class="badge bg-label-secondary small">{{ strtoupper(substr($tx->bank_slug ?? $tx->bank_name, 0, 6)) }}</span>
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
                <td colspan="5" class="text-center py-5">
                  <i class="icon-base ti tabler-inbox icon-48px text-muted d-block mb-3 mx-auto"></i>
                  <h6 class="fw-semibold mb-1">İşlem bulunamadı</h6>
                  <p class="text-muted small mb-3">
                    @if(request()->hasAny(['q','type','from','to','category','bank','min_amount','max_amount']))
                      Seçilen filtrelere uyan işlem kaydı yok.
                    @else
                      Henüz hiç işlem kaydedilmemiş.
                    @endif
                  </p>
                  @if(request()->hasAny(['q','type','from','to','category','bank','min_amount','max_amount']))
                    <a href="{{ route('transactions.index') }}" class="btn btn-sm btn-outline-secondary">
                      <i class="icon-base ti tabler-x me-1"></i>Filtreleri Temizle
                    </a>
                  @else
                    <a href="{{ route('transactions.import') }}" class="btn btn-sm btn-outline-primary">
                      <i class="icon-base ti tabler-upload me-1"></i>CSV İçe Aktar
                    </a>
                  @endif
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
          {{ $transactions->firstItem() }}–{{ $transactions->lastItem() }} / {{ $transactions->total() }} işlem
        </div>
        {{ $transactions->links() }}
      </div>
    @endif
  </div>

  {{-- Debt Tag Modal --}}
  <div class="modal fade" id="debtModal" tabindex="-1">
    <div class="modal-dialog modal-sm">
      <form id="debtForm" method="POST" action="">
        @csrf
        <div class="modal-content">
          <div class="modal-header border-0 pb-1">
            <h6 class="modal-title fw-semibold">
              <i class="icon-base ti tabler-users me-2 text-primary"></i>Borç Kaydet
            </h6>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <div class="p-2 rounded mb-3 text-muted small" id="debtTxInfo"
                 style="background:var(--bs-secondary-bg);font-size:.75rem;"></div>
            <div class="mb-3">
              <label class="form-label small">Kişi Adı <span class="text-danger">*</span></label>
              <input type="text" name="contact_name" class="form-control form-control-sm"
                     placeholder="Ahmet Yılmaz" required>
            </div>
            <div class="mb-3">
              <label class="form-label small">Yön</label>
              <select name="direction" id="debtDirection" class="form-select form-select-sm">
                <option value="given">Borç Verdim</option>
                <option value="received">Borç Aldım</option>
              </select>
            </div>
            <div class="mb-3">
              <label class="form-label small">Tutar (₺) <span class="text-danger">*</span></label>
              <input type="number" name="amount" id="debtAmount" class="form-control form-control-sm"
                     step="0.01" min="0.01" required>
            </div>
            <div>
              <label class="form-label small">Not</label>
              <input type="text" name="note" class="form-control form-control-sm"
                     placeholder="Opsiyonel…">
            </div>
          </div>
          <div class="modal-footer border-0 pt-0">
            <button type="button" class="btn btn-outline-secondary btn-sm" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-primary btn-sm">Kaydet</button>
          </div>
        </div>
      </form>
    </div>
  </div>

  <x-slot name="pageJs">
  <script>
  document.querySelectorAll('.btn-debt-tag').forEach(function (btn) {
    btn.addEventListener('click', function () {
      document.getElementById('debtForm').action = '/transactions/' + this.dataset.txId + '/debt';
      document.getElementById('debtTxInfo').textContent = this.dataset.txDesc;
      document.getElementById('debtAmount').value   = parseFloat(this.dataset.txAmount).toFixed(2);
      document.getElementById('debtDirection').value = this.dataset.txDir;
    });
  });
  </script>
  </x-slot>
</x-app-layout>
