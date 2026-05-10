<x-app-layout>
  <x-slot name="title">Hedefler</x-slot>

  <div class="d-flex align-items-center justify-content-between mb-6">
    <div>
      <h4 class="fw-bold mb-1">Tasarruf Hedefleri</h4>
      <p class="text-muted mb-0">Finansal hedeflerini belirle ve ilerlemeyi takip et</p>
    </div>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
      <i class="icon-base ti tabler-plus me-1"></i>Hedef Ekle
    </button>
  </div>

  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  @if($goals->isEmpty())
  <div class="card">
    <div class="card-body text-center py-8">
      <i class="icon-base ti tabler-target icon-64px text-muted mb-4 d-block"></i>
      <h5 class="mb-2">Henüz hedef eklenmedi</h5>
      <p class="text-muted mb-4">Tatil, araba, acil fon… bir hedef belirle ve birikimini takip et.</p>
      <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
        <i class="icon-base ti tabler-plus me-1"></i>İlk Hedefi Ekle
      </button>
    </div>
  </div>
  @else
  <div class="row g-5">
    @foreach($goals as $goal)
    @php
      $isCompleted = $goal->status === 'completed';
      $barColor    = $isCompleted ? 'bg-success' : ($goal->pct >= 75 ? 'bg-info' : ($goal->pct >= 40 ? 'bg-warning' : 'bg-primary'));
    @endphp
    <div class="col-md-6 col-xl-4">
      <div class="card h-100 {{ $isCompleted ? 'border-success' : '' }}">
        <div class="card-body">

          <div class="d-flex align-items-start justify-content-between mb-3">
            <div>
              <div class="fw-semibold">{{ $goal->name }}</div>
              @if($goal->target_date)
                <div class="text-muted small">
                  <i class="icon-base ti tabler-calendar me-1"></i>
                  {{ \Carbon\Carbon::parse($goal->target_date)->format('d.m.Y') }}
                  @if($goal->months_left !== null && !$isCompleted)
                    <span class="ms-1 text-{{ $goal->months_left < 3 ? 'danger' : 'muted' }}">
                      ({{ $goal->months_left }} ay kaldı)
                    </span>
                  @endif
                </div>
              @endif
            </div>
            @if($isCompleted)
              <span class="badge bg-label-success"><i class="icon-base ti tabler-check me-1"></i>Tamamlandı</span>
            @else
              <span class="badge bg-label-primary">%{{ $goal->pct }}</span>
            @endif
          </div>

          <div class="mb-2 d-flex justify-content-between small">
            <span class="text-muted">Birikim</span>
            <span class="fw-bold">
              ₺{{ number_format($goal->current_amount, 0, ',', '.') }}
              / ₺{{ number_format($goal->target_amount, 0, ',', '.') }}
            </span>
          </div>

          <div class="progress mb-3" style="height:10px;border-radius:5px;">
            <div class="progress-bar {{ $barColor }}" style="width:{{ $goal->pct }}%;border-radius:5px;"></div>
          </div>

          @if(!$isCompleted)
          <div class="text-muted small mb-3">
            Kalan: <strong>₺{{ number_format($goal->remaining, 0, ',', '.') }}</strong>
            @if($goal->monthly_contribution)
              &nbsp;·&nbsp; Aylık katkı: ₺{{ number_format($goal->monthly_contribution, 0, ',', '.') }}
            @endif
          </div>
          @endif

          <div class="d-flex gap-2">
            @if(!$isCompleted)
            <button class="btn btn-sm btn-outline-primary flex-fill"
                    data-bs-toggle="modal"
                    data-bs-target="#fundsModal{{ $goal->id }}">
              <i class="icon-base ti tabler-plus me-1"></i>Ödeme Ekle
            </button>
            @endif
            <form action="{{ route('goals.destroy', $goal->id) }}" method="POST">
              @csrf @method('DELETE')
              <button type="submit" class="btn btn-icon btn-sm btn-text-danger"
                      onclick="return confirm('Hedefi sil?')">
                <i class="icon-base ti tabler-trash icon-18px"></i>
              </button>
            </form>
          </div>

        </div>
      </div>

      {{-- Add funds modal --}}
      @if(!$isCompleted)
      <div class="modal fade" id="fundsModal{{ $goal->id }}" tabindex="-1">
        <div class="modal-dialog modal-sm">
          <form action="{{ route('goals.funds', $goal->id) }}" method="POST">
            @csrf
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title">{{ $goal->name }}</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
              </div>
              <div class="modal-body">
                <label class="form-label">Eklenecek Tutar (₺)</label>
                <input type="number" name="amount" class="form-control" step="0.01" min="0.01" required>
              </div>
              <div class="modal-footer">
                <button type="submit" class="btn btn-primary w-100">Ekle</button>
              </div>
            </div>
          </form>
        </div>
      </div>
      @endif

    </div>
    @endforeach
  </div>
  @endif

  {{-- Add goal modal --}}
  <div class="modal fade" id="addModal" tabindex="-1">
    <div class="modal-dialog">
      <form action="{{ route('goals.store') }}" method="POST">
        @csrf
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Yeni Hedef</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <div class="mb-4">
              <label class="form-label">Hedef Adı <span class="text-danger">*</span></label>
              <input type="text" name="name" class="form-control" placeholder="örn: Tatil Fonu, Araba, Acil Fon" required>
            </div>
            <div class="row g-4 mb-4">
              <div class="col-6">
                <label class="form-label">Hedef Tutar (₺) <span class="text-danger">*</span></label>
                <input type="number" name="target_amount" class="form-control" step="0.01" min="1" required>
              </div>
              <div class="col-6">
                <label class="form-label">Mevcut Birikim (₺)</label>
                <input type="number" name="current_amount" class="form-control" step="0.01" min="0" value="0">
              </div>
            </div>
            <div class="row g-4">
              <div class="col-6">
                <label class="form-label">Hedef Tarih</label>
                <input type="date" name="target_date" class="form-control">
              </div>
              <div class="col-6">
                <label class="form-label">Aylık Katkı (₺)</label>
                <input type="number" name="monthly_contribution" class="form-control" step="0.01" min="0">
              </div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-primary">Hedef Oluştur</button>
          </div>
        </div>
      </form>
    </div>
  </div>
</x-app-layout>
