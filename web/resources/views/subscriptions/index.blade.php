<x-app-layout>
  <x-slot name="title">Abonelikler</x-slot>

  <div class="d-flex align-items-center justify-content-between mb-6">
    <div>
      <h4 class="fw-bold mb-1">Abonelikler</h4>
      <p class="text-muted mb-0">Tekrarlayan ödemeler ve dijital abonelikler</p>
    </div>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
      <i class="icon-base ti tabler-plus me-1"></i>Abonelik Ekle
    </button>
  </div>

  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  {{-- Monthly total --}}
  @if($totalMonthly > 0)
  <div class="alert alert-info mb-6">
    <i class="icon-base ti tabler-coin me-2"></i>
    Aylık toplam abonelik gideriniz: <strong>₺{{ number_format($totalMonthly, 2, ',', '.') }}</strong>
    &mdash; yıllık <strong>₺{{ number_format($totalMonthly * 12, 0, ',', '.') }}</strong>
  </div>
  @endif

  {{-- Auto-detected candidates --}}
  @if($candidates->isNotEmpty())
  <div class="card mb-6">
    <div class="card-header pb-2">
      <h5 class="card-title mb-0">
        <i class="icon-base ti tabler-sparkles me-2 text-warning"></i>Otomatik Tespit Edilenler
      </h5>
    </div>
    <div class="card-body">
      <p class="text-muted small mb-3">İşlemlerinde tekrar eden bu ödemeler abonelik olabilir:</p>
      <div class="row g-3">
        @foreach($candidates as $c)
        <div class="col-sm-6 col-xl-3">
          <div class="border rounded p-3 d-flex align-items-center gap-3">
            <div class="rounded-circle bg-label-primary d-flex align-items-center justify-content-center flex-shrink-0"
                 style="width:40px;height:40px;">
              <i class="icon-base ti tabler-repeat text-primary"></i>
            </div>
            <div class="flex-grow-1 min-w-0">
              <div class="fw-medium small text-truncate">{{ $c->merchant_name ?: $c->description }}</div>
              <div class="text-muted" style="font-size:.75rem;">
                ~₺{{ number_format($c->avg_amount, 2, ',', '.') }} · {{ $c->occurrences }}x
              </div>
            </div>
            <button type="button"
                    class="btn btn-sm btn-outline-primary flex-shrink-0 btn-convert-candidate"
                    data-name="{{ $c->merchant_name ?: ucwords(mb_strtolower($c->description)) }}"
                    data-merchant="{{ $c->merchant_name }}"
                    data-amount="{{ number_format($c->avg_amount, 2, '.', '') }}"
                    title="Abonelik olarak ekle">
              <i class="icon-base ti tabler-plus icon-14px"></i>
            </button>
          </div>
        </div>
        @endforeach
      </div>
    </div>
  </div>
  @endif

  {{-- Subscriptions list --}}
  @if($subscriptions->isEmpty())
  <div class="card">
    <div class="card-body text-center py-8">
      <i class="icon-base ti tabler-repeat-off icon-64px text-muted mb-4 d-block"></i>
      <h5 class="mb-2">Abonelik eklenmedi</h5>
      <p class="text-muted mb-4">Dijital aboneliklerini ve tekrarlayan ödemelerini takip et.</p>
      <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
        <i class="icon-base ti tabler-plus me-1"></i>İlk Aboneliği Ekle
      </button>
    </div>
  </div>
  @else
  <div class="row g-4">
    @foreach($subscriptions as $sub)
    <div class="col-md-6 col-xl-4">
      <div class="card h-100">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between mb-3">
            <div class="d-flex align-items-center gap-3">
              <div class="rounded-circle bg-label-primary d-flex align-items-center justify-content-center flex-shrink-0"
                   style="width:44px;height:44px;">
                <i class="icon-base ti tabler-repeat text-primary icon-22px"></i>
              </div>
              <div>
                <div class="fw-semibold">{{ $sub->name }}</div>
                <div class="text-muted small">{{ $sub->merchant_name }}</div>
              </div>
            </div>
            <div class="text-end">
              <div class="fw-bold text-primary">₺{{ number_format($sub->amount, 2, ',', '.') }}</div>
              <div class="text-muted small">
                {{ match($sub->billing_cycle) { 'monthly' => '/ay', 'yearly' => '/yıl', 'weekly' => '/hafta', default => '' } }}
              </div>
            </div>
          </div>
          <div class="d-flex align-items-center justify-content-between">
            <div class="text-muted small">
              <i class="icon-base ti tabler-calendar me-1"></i>
              Sonraki: {{ \Carbon\Carbon::parse($sub->next_billing_date)->format('d.m.Y') }}
            </div>
            <form action="{{ route('subscriptions.destroy', $sub->id) }}" method="POST" class="d-inline">
              @csrf @method('DELETE')
              <button type="button" class="btn btn-icon btn-sm btn-text-danger btn-swal-delete"
                      data-name="{{ $sub->name }}" title="İptal">
                <i class="icon-base ti tabler-x icon-18px"></i>
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
      <form action="{{ route('subscriptions.store') }}" method="POST">
        @csrf
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Abonelik Ekle</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <div class="mb-4">
              <label class="form-label">Abonelik Adı <span class="text-danger">*</span></label>
              <input type="text" name="name" class="form-control" placeholder="örn: Spotify Premium" required>
            </div>
            <div class="mb-4">
              <label class="form-label">Mağaza / Hizmet</label>
              <input type="text" name="merchant_name" class="form-control" placeholder="örn: Spotify AB">
            </div>
            <div class="row g-4">
              <div class="col-6">
                <label class="form-label">Tutar <span class="text-danger">*</span></label>
                <input type="number" name="amount" class="form-control" step="0.01" min="0" required>
              </div>
              <div class="col-6">
                <label class="form-label">Döngü</label>
                <select name="billing_cycle" class="form-select">
                  <option value="monthly">Aylık</option>
                  <option value="yearly">Yıllık</option>
                  <option value="weekly">Haftalık</option>
                </select>
              </div>
            </div>
            <div class="mt-4">
              <label class="form-label">Sonraki Ödeme <span class="text-danger">*</span></label>
              <input type="date" name="next_billing_date" class="form-control"
                     value="{{ now()->addMonth()->format('Y-m-d') }}" required>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-primary">Ekle</button>
          </div>
        </div>
      </form>
    </div>
  </div>

  <x-slot name="pageJs">
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
  <script>
  // Delete subscription
  document.querySelectorAll('.btn-swal-delete').forEach(function (btn) {
    btn.addEventListener('click', function () {
      const name = this.dataset.name;
      Swal.fire({
        title: '"' + name + '" aboneliğini iptal et?',
        text: 'Bu abonelik iptal edilecek.',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#6c757d',
        confirmButtonText: 'Evet, iptal et',
        cancelButtonText: 'Vazgeç',
        reverseButtons: true,
      }).then(function (result) {
        if (result.isConfirmed) btn.closest('form').submit();
      });
    });
  });

  // Convert candidate to subscription — pre-fill the add modal
  const addModal   = document.getElementById('addModal');
  const nameInput  = addModal.querySelector('[name="name"]');
  const merchantIn = addModal.querySelector('[name="merchant_name"]');
  const amountIn   = addModal.querySelector('[name="amount"]');

  document.querySelectorAll('.btn-convert-candidate').forEach(function (btn) {
    btn.addEventListener('click', function () {
      nameInput.value  = this.dataset.name;
      merchantIn.value = this.dataset.merchant;
      amountIn.value   = this.dataset.amount;
      bootstrap.Modal.getOrCreateInstance(addModal).show();
    });
  });
  </script>
  </x-slot>
</x-app-layout>
