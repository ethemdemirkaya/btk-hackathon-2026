<x-app-layout>
  <x-slot name="title">Hedefler</x-slot>

  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Tasarruf Hedefleri</h4>
      <p class="text-muted small mb-0">Finansal hedeflerini belirle ve ilerlemeyi takip et</p>
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

  {{-- Summary stat cards (computed in view) --}}
  @if($goals->isNotEmpty())
  @php
    $activeGoals    = $goals->where('status', '!=', 'completed');
    $completedGoals = $goals->where('status', 'completed');
    $totalTarget    = $activeGoals->sum('target_amount');
    $totalCurrent   = $activeGoals->sum('current_amount');
    $avgPct         = $activeGoals->count() > 0 ? round($activeGoals->avg('pct')) : 0;
  @endphp
  <div class="row g-4 mb-6">
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-primary"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Birikilen</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">₺{{ number_format($totalCurrent, 0, ',', '.') }}</div>
              <span class="small text-muted">/ ₺{{ number_format($totalTarget, 0, ',', '.') }} hedef</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-piggy-bank icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar {{ $avgPct >= 75 ? 'bg-success' : ($avgPct >= 40 ? 'bg-info' : 'bg-warning') }}"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Ortalama İlerleme</span>
              <div class="h5 fw-bold mt-1 mb-0 {{ $avgPct >= 75 ? 'text-success' : ($avgPct >= 40 ? 'text-info' : 'text-warning') }}">
                %{{ $avgPct }}
              </div>
              <div class="progress mt-2" style="height:4px;width:80px;">
                <div class="{{ $avgPct >= 75 ? 'progress-bar-gradient-success' : ($avgPct >= 40 ? 'progress-bar-gradient-info' : 'progress-bar-gradient-warning') }}"
                     style="width:{{ $avgPct }}%;height:100%;border-radius:4px;"></div>
              </div>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $avgPct >= 75 ? 'success' : ($avgPct >= 40 ? 'info' : 'warning') }}">
                <i class="icon-base ti tabler-target icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-success"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Tamamlanan</span>
              <div class="h5 fw-bold mt-1 mb-0 text-success">{{ $completedGoals->count() }}</div>
              <span class="small text-muted">{{ $activeGoals->count() }} aktif hedef</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-success">
                <i class="icon-base ti tabler-rosette-discount-check icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  @endif

  @php
    $goalIcons  = ['tabler-beach','tabler-shield-check','tabler-device-laptop','tabler-home-2','tabler-car','tabler-plane','tabler-school','tabler-heart'];
    $goalColors = ['warning','success','info','primary','danger','info','primary','danger'];
  @endphp

  @if($goals->isEmpty())
  <div class="card">
    <div class="card-body text-center py-6">
      <div class="d-flex justify-content-center mb-4">
        <i class="icon-base ti tabler-target icon-64px text-muted"></i>
      </div>
      <h5 class="mb-2">Henüz hedef eklenmedi</h5>
      <p class="text-muted mb-4">Tatil, araba, acil fon… bir hedef belirle ve birikimini takip et.</p>
      <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
        <i class="icon-base ti tabler-plus me-1"></i>İlk Hedefi Ekle
      </button>
    </div>
  </div>
  @else
  <div class="row g-4">
    @foreach($goals as $i => $goal)
    @php
      $isCompleted = $goal->status === 'completed';
      $gi          = $goalIcons[$i % count($goalIcons)];
      $gc          = $goalColors[$i % count($goalColors)];
      $barClass    = $isCompleted ? 'progress-bar-gradient-success' : ($goal->pct >= 75 ? 'progress-bar-gradient-info' : ($goal->pct >= 40 ? 'progress-bar-gradient-primary' : 'progress-bar-gradient-warning'));
    @endphp
    <div class="col-md-6 col-xl-4">
      <div class="card h-100 shadow-sm {{ $isCompleted ? 'border-success' : '' }}">
        <div class="card-body">

          <div class="d-flex align-items-start justify-content-between mb-4">
            <div class="d-flex align-items-center gap-3">
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-{{ $gc }}">
                  <i class="icon-base ti {{ $gi }} icon-20px"></i>
                </span>
              </div>
              <div>
                <div class="fw-semibold text-heading">{{ $goal->name }}</div>
                @if($goal->target_date)
                  <div class="text-muted small">
                    <i class="icon-base ti tabler-calendar me-1"></i>
                    {{ \Carbon\Carbon::parse($goal->target_date)->format('d.m.Y') }}
                    @if($goal->months_left !== null && !$isCompleted && $goal->months_left >= 0)
                      <span class="text-{{ $goal->months_left < 3 ? 'danger' : 'muted' }}">
                        · {{ $goal->months_left }} ay kaldı
                      </span>
                    @endif
                  </div>
                @endif
              </div>
            </div>
            @if($isCompleted)
              <span class="badge bg-label-success"><i class="icon-base ti tabler-check me-1"></i>Tamam</span>
            @else
              <span class="badge bg-label-{{ $gc }}">%{{ $goal->pct }}</span>
            @endif
          </div>

          <div class="d-flex justify-content-between small mb-2">
            <span class="text-muted">Birikim</span>
            <span class="fw-bold">
              ₺{{ number_format($goal->current_amount, 0, ',', '.') }}
              / ₺{{ number_format($goal->target_amount, 0, ',', '.') }}
            </span>
          </div>

          <div class="progress mb-3" style="height:10px;border-radius:10px;background:var(--bs-secondary-bg);">
            <div class="{{ $barClass }}" style="width:{{ $goal->pct }}%;height:100%;border-radius:10px;"></div>
          </div>

          @if(!$isCompleted)
          <div class="text-muted small mb-4">
            Kalan: <strong>₺{{ number_format($goal->remaining, 0, ',', '.') }}</strong>
            @if($goal->monthly_contribution)
              &nbsp;·&nbsp; ₺{{ number_format($goal->monthly_contribution, 0, ',', '.') }}/ay
            @endif
          </div>
          @endif

          <div class="d-flex gap-2">
            @if(!$isCompleted)
            <button class="btn btn-sm btn-outline-primary flex-fill"
                    data-bs-toggle="modal" data-bs-target="#fundsModal{{ $goal->id }}">
              <i class="icon-base ti tabler-plus me-1"></i>Fon Ekle
            </button>
            @endif
            <form action="{{ route('goals.destroy', $goal->id) }}" method="POST">
              @csrf @method('DELETE')
              <button type="button" class="btn btn-icon btn-sm btn-text-danger btn-swal-delete"
                      data-name="{{ $goal->name }}">
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
              <div class="modal-header border-0">
                <h5 class="modal-title">{{ $goal->name }}</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
              </div>
              <div class="modal-body pt-0">
                <label class="form-label">Eklenecek Tutar (₺)</label>
                <div class="input-group mb-2">
                  <input type="number" name="amount" id="fundsAmount{{ $goal->id }}"
                         class="form-control" step="0.01" min="0.01"
                         value="{{ $goal->monthly_contribution ?? '' }}" required>
                  <button type="button" class="btn btn-outline-info btn-suggest-contrib"
                          data-goal="{{ $goal->id }}"
                          data-url="{{ route('goals.suggest', $goal->id) }}"
                          title="Tasarruf geçmişine göre tavsiye al">
                    <i class="icon-base ti tabler-bulb"></i>
                  </button>
                </div>
                <div class="text-muted small mb-1">
                  Kalan: ₺{{ number_format($goal->remaining, 0, ',', '.') }}
                </div>
                <div id="suggestBox{{ $goal->id }}" class="d-none alert alert-info py-2 px-3 small mb-0"></div>
              </div>
              <div class="modal-footer border-0">
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
          <div class="modal-header border-0">
            <h5 class="modal-title">Yeni Hedef</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body pt-0">
            @if($errors->any())
            <div class="alert alert-danger alert-dismissible mb-4" role="alert">
              <ul class="mb-0 ps-3">
                @foreach($errors->all() as $error)
                  <li>{{ $error }}</li>
                @endforeach
              </ul>
              <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
            @endif
            <div class="mb-4">
              <label class="form-label">Hedef Adı <span class="text-danger">*</span></label>
              <input type="text" name="name" class="form-control @error('name') is-invalid @enderror"
                     placeholder="örn: Tatil Fonu, Araba, Acil Fon" value="{{ old('name') }}" required>
              @error('name') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </div>
            <div class="row g-4 mb-4">
              <div class="col-6">
                <label class="form-label">Hedef Tutar (₺) <span class="text-danger">*</span></label>
                <input type="number" name="target_amount" class="form-control @error('target_amount') is-invalid @enderror"
                       step="0.01" min="1" value="{{ old('target_amount') }}" required>
                @error('target_amount') <div class="invalid-feedback">{{ $message }}</div> @enderror
              </div>
              <div class="col-6">
                <label class="form-label">Mevcut Birikim (₺)</label>
                <input type="number" name="current_amount" class="form-control @error('current_amount') is-invalid @enderror"
                       step="0.01" min="0" value="{{ old('current_amount', 0) }}">
                @error('current_amount') <div class="invalid-feedback">{{ $message }}</div> @enderror
              </div>
            </div>
            <div class="row g-4">
              <div class="col-6">
                <label class="form-label">Hedef Tarih</label>
                <input type="date" name="target_date" class="form-control @error('target_date') is-invalid @enderror"
                       value="{{ old('target_date') }}">
                @error('target_date') <div class="invalid-feedback">{{ $message }}</div> @enderror
              </div>
              <div class="col-6">
                <label class="form-label">Aylık Katkı (₺)</label>
                <input type="number" name="monthly_contribution" class="form-control @error('monthly_contribution') is-invalid @enderror"
                       step="0.01" min="0" value="{{ old('monthly_contribution') }}">
                @error('monthly_contribution') <div class="invalid-feedback">{{ $message }}</div> @enderror
              </div>
            </div>
          </div>
          <div class="modal-footer border-0">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-primary">Hedef Oluştur</button>
          </div>
        </div>
      </form>
    </div>
  </div>

  <x-slot name="pageJs">
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
  <script>
  // Re-open add modal if validation failed
  @if($errors->any())
  bootstrap.Modal.getOrCreateInstance(document.getElementById('addModal')).show();
  @endif

  // Delete confirmation
  document.querySelectorAll('.btn-swal-delete').forEach(function (btn) {
    btn.addEventListener('click', function () {
      Swal.fire({
        title: '"' + this.dataset.name + '" hedefini sil?',
        text: 'Bu hedef kalıcı olarak silinecek.',
        icon: 'warning', showCancelButton: true,
        confirmButtonColor: '#d33', cancelButtonColor: '#6c757d',
        confirmButtonText: 'Evet, sil', cancelButtonText: 'Vazgeç', reverseButtons: true,
      }).then(result => { if (result.isConfirmed) this.closest('form').submit(); });
    });
  });

  // AI contribution suggestion
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

  document.querySelectorAll('.btn-suggest-contrib').forEach(function (btn) {
    btn.addEventListener('click', async function () {
      const goalId   = this.dataset.goal;
      const url      = this.dataset.url;
      const amountEl = document.getElementById('fundsAmount' + goalId);
      const boxEl    = document.getElementById('suggestBox' + goalId);

      btn.disabled = true;
      btn.innerHTML = '<span class="spinner-border spinner-border-sm"></span>';

      try {
        const resp = await fetch(url, {
          headers: { 'Accept': 'application/json', 'X-CSRF-TOKEN': csrfToken },
        });
        const data = await resp.json();

        const fmt = v => parseFloat(v).toLocaleString('tr-TR', { maximumFractionDigits: 0 });

        boxEl.innerHTML =
          '<i class="icon-base ti tabler-bulb me-1"></i>' +
          '<strong>Tavsiye:</strong> ₺' + fmt(data.affordable) + '/ay &nbsp;·&nbsp; ' +
          'Ort. aylık tasarruf: ₺' + fmt(data.avg_savings) + ' &nbsp;·&nbsp; ' +
          data.months_left + ' ay kaldı';
        boxEl.classList.remove('d-none');

        // Pre-fill the amount input
        amountEl.value = data.affordable;
      } catch (e) {
        boxEl.innerHTML = 'Öneri hesaplanamadı. Lütfen manuel girin.';
        boxEl.classList.remove('d-none');
      } finally {
        btn.disabled = false;
        btn.innerHTML = '<i class="icon-base ti tabler-bulb"></i>';
      }
    });
  });
  </script>
  </x-slot>
</x-app-layout>
