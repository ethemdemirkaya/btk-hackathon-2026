<x-app-layout>
  <x-slot name="title">Bütçeler</x-slot>

  <div class="d-flex align-items-center justify-content-between mb-5">
    <div>
      <h4 class="fw-bold mb-0">Bütçeler</h4>
      <p class="text-muted small mb-0">{{ now()->translatedFormat('F Y') }} — Harcama limitlerini belirle ve takip et</p>
    </div>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
      <i class="icon-base ti tabler-plus me-1"></i>Bütçe Ekle
    </button>
  </div>

  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  {{-- Summary stat cards (computed in view) --}}
  @if($budgets->isNotEmpty())
  @php
    $totalBudgeted  = $budgets->sum('amount');
    $totalSpent     = $budgets->sum('spent');
    $totalRemaining = $budgets->sum('remaining');
    $overCount      = $budgets->where('over_budget', true)->count();
    $overallPct     = $totalBudgeted > 0 ? min(100, round($totalSpent / $totalBudgeted * 100)) : 0;
  @endphp
  <div class="row g-4 mb-6">
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-primary"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Bütçe</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">₺{{ number_format($totalBudgeted, 0, ',', '.') }}</div>
              <span class="small text-muted">{{ $budgets->count() }} kategori</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-chart-pie icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar {{ $overallPct >= 90 ? 'bg-danger' : ($overallPct >= 75 ? 'bg-warning' : 'bg-success') }}"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Harcanan</span>
              <div class="h5 fw-bold mt-1 mb-0 {{ $overallPct >= 90 ? 'text-danger' : ($overallPct >= 75 ? 'text-warning' : 'text-success') }}">
                ₺{{ number_format($totalSpent, 0, ',', '.') }}
              </div>
              <div class="progress mt-2" style="height:4px;width:80px;">
                <div class="{{ $overallPct >= 90 ? 'progress-bar-gradient-danger' : ($overallPct >= 75 ? 'progress-bar-gradient-warning' : 'progress-bar-gradient-success') }}"
                     style="width:{{ $overallPct }}%;height:100%;border-radius:4px;"></div>
              </div>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $overallPct >= 90 ? 'danger' : ($overallPct >= 75 ? 'warning' : 'success') }}">
                <i class="icon-base ti tabler-trending-up icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar {{ $overCount > 0 ? 'bg-danger' : 'bg-success' }}"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Kalan</span>
              <div class="h5 fw-bold mt-1 mb-0 {{ $totalRemaining > 0 ? 'text-success' : 'text-danger' }}">
                ₺{{ number_format($totalRemaining, 0, ',', '.') }}
              </div>
              @if($overCount > 0)
                <span class="badge bg-label-danger" style="font-size:.72rem;">{{ $overCount }} kategori aşıldı!</span>
              @else
                <span class="small text-success">Bütçe içinde</span>
              @endif
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $overCount > 0 ? 'danger' : 'success' }}">
                <i class="icon-base ti {{ $overCount > 0 ? 'tabler-alert-triangle' : 'tabler-shield-check' }} icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  @endif

  @if($budgets->isEmpty())
  <div class="card">
    <div class="card-body text-center py-6">
      <i class="icon-base ti tabler-chart-pie icon-64px text-muted mb-4 d-block"></i>
      <h5 class="mb-2">Bu ay bütçe tanımlanmadı</h5>
      <p class="text-muted mb-4">Kategoriler için harcama limitleri belirle ve ne kadar harcadığını gör.</p>
      <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
        <i class="icon-base ti tabler-plus me-1"></i>İlk Bütçeyi Ekle
      </button>
    </div>
  </div>
  @else
  <div class="row g-4">
    @foreach($budgets as $b)
    @php
      $barClass = $b->over_budget ? 'progress-bar-gradient-danger' : ($b->pct >= 80 ? 'progress-bar-gradient-warning' : 'progress-bar-gradient-success');
    @endphp
    <div class="col-md-6 col-xl-4">
      <div class="card h-100 shadow-sm">
        <div class="card-body">
          <div class="d-flex align-items-center justify-content-between mb-4">
            <div class="d-flex align-items-center gap-2">
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-{{ $b->over_budget ? 'danger' : ($b->pct >= 80 ? 'warning' : 'primary') }}">
                  <i class="icon-base ti tabler-chart-pie icon-20px"></i>
                </span>
              </div>
              <div class="fw-semibold text-heading">{{ $b->category_name ?? 'Kategori' }}</div>
            </div>
            @if($b->over_budget)
              <span class="badge bg-label-danger">Aşıldı!</span>
            @elseif($b->pct >= 80)
              <span class="badge bg-label-warning">%{{ $b->pct }}</span>
            @else
              <span class="badge bg-label-success">%{{ $b->pct }}</span>
            @endif
          </div>

          <div class="d-flex justify-content-between small mb-2">
            <span class="text-muted">Harcandı</span>
            <span class="fw-bold {{ $b->over_budget ? 'text-danger' : '' }}">
              ₺{{ number_format($b->spent, 0, ',', '.') }} / ₺{{ number_format($b->amount, 0, ',', '.') }}
            </span>
          </div>

          <div class="progress mb-3" style="height:8px;border-radius:8px;background:var(--bs-secondary-bg);">
            <div class="{{ $barClass }}" style="width:{{ min(100,$b->pct) }}%;height:100%;border-radius:8px;"></div>
          </div>

          <div class="d-flex justify-content-between align-items-center">
            <span class="text-muted small">
              Kalan: <strong class="{{ $b->over_budget ? 'text-danger' : 'text-success' }}">
                ₺{{ number_format($b->remaining, 0, ',', '.') }}
              </strong>
            </span>
            <form action="{{ route('budgets.destroy', $b->id) }}" method="POST">
              @csrf @method('DELETE')
              <button type="button" class="btn btn-icon btn-sm btn-text-danger btn-swal-delete"
                      data-name="{{ $b->category_name ?? 'Bütçe' }}" title="Sil">
                <i class="icon-base ti tabler-trash icon-18px"></i>
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    @endforeach
  </div>
  @endif

  {{-- Add modal --}}
  <div class="modal fade" id="addModal" tabindex="-1">
    <div class="modal-dialog">
      <form action="{{ route('budgets.store') }}" method="POST">
        @csrf
        <div class="modal-content">
          <div class="modal-header border-0">
            <h5 class="modal-title">Bütçe Ekle — {{ now()->translatedFormat('F Y') }}</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body pt-0">
            <div class="mb-4">
              <label class="form-label">Kategori <span class="text-danger">*</span></label>
              <select name="category_id" class="form-select" required>
                <option value="">Seçin…</option>
                @foreach($categories as $cat)
                  <option value="{{ $cat->id }}">{{ $cat->name }}</option>
                @endforeach
              </select>
            </div>
            <div class="mb-4">
              <label class="form-label">Aylık Limit (₺) <span class="text-danger">*</span></label>
              <input type="number" name="amount" class="form-control" step="0.01" min="1" required>
            </div>
            <div>
              <label class="form-label">Uyarı Eşiği (%)</label>
              <input type="number" name="alert_threshold" class="form-control" min="1" max="100"
                     placeholder="örn: 80 — bütçenin %80'ine ulaşınca uyar" value="80">
            </div>
          </div>
          <div class="modal-footer border-0">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-primary">Kaydet</button>
          </div>
        </div>
      </form>
    </div>
  </div>

  <x-slot name="pageJs">
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
  <script>
  document.querySelectorAll('.btn-swal-delete').forEach(function (btn) {
    btn.addEventListener('click', function () {
      Swal.fire({
        title: '"' + this.dataset.name + '" bütçesini sil?',
        text: 'Bu ay için tanımlanmış bütçe limiti kaldırılacak.',
        icon: 'warning', showCancelButton: true,
        confirmButtonColor: '#d33', cancelButtonColor: '#6c757d',
        confirmButtonText: 'Evet, sil', cancelButtonText: 'Vazgeç', reverseButtons: true,
      }).then(result => { if (result.isConfirmed) this.closest('form').submit(); });
    });
  });
  </script>
  </x-slot>
</x-app-layout>
