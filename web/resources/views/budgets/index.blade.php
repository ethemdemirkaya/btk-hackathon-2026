<x-app-layout>
  <x-slot name="title">Bütçeler</x-slot>

  <div class="d-flex align-items-center justify-content-between mb-6">
    <div>
      <h4 class="fw-bold mb-1">Bütçeler</h4>
      <p class="text-muted mb-0">{{ now()->locale('tr')->isoFormat('MMMM YYYY') }} — Harcama limitlerini belirle ve takip et</p>
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

  @if($budgets->isEmpty())
  <div class="card">
    <div class="card-body text-center py-8">
      <i class="icon-base ti tabler-chart-pie icon-64px text-muted mb-4 d-block"></i>
      <h5 class="mb-2">Bu ay bütçe tanımlanmadı</h5>
      <p class="text-muted mb-4">Kategoriler için harcama limitleri belirle ve ne kadar harcadığını gör.</p>
      <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
        <i class="icon-base ti tabler-plus me-1"></i>İlk Bütçeyi Ekle
      </button>
    </div>
  </div>
  @else
  <div class="row g-5">
    @foreach($budgets as $b)
    <div class="col-md-6 col-xl-4">
      <div class="card h-100">
        <div class="card-body">
          <div class="d-flex align-items-center justify-content-between mb-4">
            <div class="d-flex align-items-center gap-2">
              <div class="rounded bg-label-primary p-2">
                <i class="icon-base ti tabler-chart-pie text-primary"></i>
              </div>
              <div class="fw-semibold">{{ $b->category_name ?? 'Kategori' }}</div>
            </div>
            @if($b->over_budget)
              <span class="badge bg-label-danger">Aşıldı!</span>
            @elseif($b->pct >= 80)
              <span class="badge bg-label-warning">%{{ $b->pct }}</span>
            @else
              <span class="badge bg-label-success">%{{ $b->pct }}</span>
            @endif
          </div>

          <div class="mb-2 d-flex justify-content-between small">
            <span class="text-muted">Harcandı</span>
            <span class="fw-bold {{ $b->over_budget ? 'text-danger' : '' }}">
              ₺{{ number_format($b->spent, 0, ',', '.') }}
              / ₺{{ number_format($b->amount, 0, ',', '.') }}
            </span>
          </div>

          <div class="progress mb-3" style="height:8px;">
            <div class="progress-bar {{ $b->over_budget ? 'bg-danger' : ($b->pct >= 80 ? 'bg-warning' : 'bg-success') }}"
                 role="progressbar" style="width:{{ $b->pct }}%"></div>
          </div>

          <div class="d-flex justify-content-between align-items-center">
            <span class="text-muted small">
              Kalan: <strong class="{{ $b->over_budget ? 'text-danger' : 'text-success' }}">
                ₺{{ number_format($b->remaining, 0, ',', '.') }}
              </strong>
            </span>
            <form action="{{ route('budgets.destroy', $b->id) }}" method="POST">
              @csrf @method('DELETE')
              <button type="submit" class="btn btn-icon btn-sm btn-text-danger"
                      onclick="return confirm('Bütçeyi sil?')" title="Sil">
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
          <div class="modal-header">
            <h5 class="modal-title">Bütçe Ekle — {{ now()->locale('tr')->isoFormat('MMMM YYYY') }}</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
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
            <div class="mb-2">
              <label class="form-label">Uyarı Eşiği (%)</label>
              <input type="number" name="alert_threshold" class="form-control" min="1" max="100"
                     placeholder="örn: 80 (bütçenin %80'ine ulaşınca uyar)">
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-primary">Kaydet</button>
          </div>
        </div>
      </form>
    </div>
  </div>
</x-app-layout>
