<x-app-layout>
  <x-slot name="title">Faturalar</x-slot>

  <div class="d-flex align-items-center justify-content-between mb-6">
    <div>
      <h4 class="fw-bold mb-1">Faturalar</h4>
      <p class="text-muted mb-0">Elektrik, su, doğalgaz ve diğer sabit giderler</p>
    </div>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
      <i class="icon-base ti tabler-plus me-1"></i>Fatura Ekle
    </button>
  </div>

  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  {{-- Monthly summary --}}
  @if($totalMonthly > 0)
  <div class="row g-4 mb-6">
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body d-flex align-items-center gap-3">
          <div class="avatar flex-shrink-0">
            <span class="avatar-initial rounded bg-label-primary">
              <i class="icon-base ti tabler-file-dollar"></i>
            </span>
          </div>
          <div>
            <small class="text-muted d-block">Aylık Toplam</small>
            <span class="fw-bold">₺{{ number_format($totalMonthly, 2, ',', '.') }}</span>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body d-flex align-items-center gap-3">
          <div class="avatar flex-shrink-0">
            <span class="avatar-initial rounded bg-label-warning">
              <i class="icon-base ti tabler-calendar-due"></i>
            </span>
          </div>
          <div>
            <small class="text-muted d-block">Bu Ay Bekleyen</small>
            <span class="fw-bold">{{ $upcoming->count() }} fatura</span>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body d-flex align-items-center gap-3">
          <div class="avatar flex-shrink-0">
            <span class="avatar-initial rounded bg-label-success">
              <i class="icon-base ti tabler-robot"></i>
            </span>
          </div>
          <div>
            <small class="text-muted d-block">Otomatik Ödeme</small>
            <span class="fw-bold">{{ $bills->where('is_autopay', true)->count() }} fatura</span>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body d-flex align-items-center gap-3">
          <div class="avatar flex-shrink-0">
            <span class="avatar-initial rounded bg-label-info">
              <i class="icon-base ti tabler-list"></i>
            </span>
          </div>
          <div>
            <small class="text-muted d-block">Toplam Kayıt</small>
            <span class="fw-bold">{{ $bills->count() }} fatura</span>
          </div>
        </div>
      </div>
    </div>
  </div>
  @endif

  {{-- Bills list --}}
  @if($bills->isEmpty())
  <div class="card">
    <div class="card-body text-center py-8">
      <i class="icon-base ti tabler-file-dollar icon-64px text-muted mb-4 d-block"></i>
      <h5 class="mb-2">Henüz fatura eklenmedi</h5>
      <p class="text-muted mb-4">Elektrik, su, doğalgaz gibi sabit giderlerini takip et.</p>
      <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
        <i class="icon-base ti tabler-plus me-1"></i>İlk Faturayı Ekle
      </button>
    </div>
  </div>
  @else
  <div class="row g-4">
    @foreach($bills as $bill)
    @php
      $typeLabel = \App\Models\Bill::typeLabel($bill->type);
      $typeIcon  = \App\Models\Bill::typeIcon($bill->type);
      $typeColor = \App\Models\Bill::typeColor($bill->type);
      $daysUntil = $bill->due_day ? ($bill->due_day >= now()->day ? $bill->due_day - now()->day : (now()->daysInMonth - now()->day + $bill->due_day)) : null;
    @endphp
    <div class="col-md-6 col-xl-4">
      <div class="card h-100">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between mb-3">
            <div class="d-flex align-items-center gap-3">
              <div class="avatar flex-shrink-0">
                <span class="avatar-initial rounded bg-label-{{ $typeColor }}">
                  <i class="icon-base ti {{ $typeIcon }}"></i>
                </span>
              </div>
              <div>
                <div class="fw-semibold">{{ $bill->name }}</div>
                <div class="text-muted small">{{ $bill->provider ?? $typeLabel }}</div>
              </div>
            </div>
            <div class="text-end">
              @if($bill->average_amount)
              <div class="fw-bold">₺{{ number_format($bill->average_amount, 2, ',', '.') }}</div>
              <div class="text-muted small">/ay ort.</div>
              @else
              <div class="text-muted small">Tutar yok</div>
              @endif
            </div>
          </div>

          <div class="d-flex flex-wrap gap-2 mb-3">
            @if($bill->is_autopay)
            <span class="badge bg-label-success">
              <i class="icon-base ti tabler-robot icon-12px me-1"></i>Otomatik
            </span>
            @endif
            @if($bill->due_day)
            <span class="badge bg-label-{{ $daysUntil <= 3 ? 'danger' : ($daysUntil <= 7 ? 'warning' : 'secondary') }}">
              <i class="icon-base ti tabler-calendar icon-12px me-1"></i>
              {{ $bill->due_day }}. günde
              @if($daysUntil !== null) ({{ $daysUntil === 0 ? 'bugün!' : "{$daysUntil} gün" }}) @endif
            </span>
            @endif
            @if($bill->last_paid_at)
            <span class="badge bg-label-info">
              Son: {{ \Carbon\Carbon::parse($bill->last_paid_at)->format('d.m') }}
            </span>
            @endif
          </div>

          <div class="d-flex align-items-center justify-content-between">
            <button type="button"
                    class="btn btn-sm btn-outline-primary btn-pay-record"
                    data-id="{{ $bill->id }}"
                    data-name="{{ $bill->name }}"
                    data-amount="{{ number_format($bill->average_amount ?? 0, 2, '.', '') }}"
                    data-action="{{ route('bills.update', $bill->id) }}">
              <i class="icon-base ti tabler-check icon-14px me-1"></i>Ödendi
            </button>
            <form action="{{ route('bills.destroy', $bill->id) }}" method="POST" class="d-inline">
              @csrf @method('DELETE')
              <button type="button"
                      class="btn btn-icon btn-sm btn-text-danger btn-swal-delete"
                      data-name="{{ $bill->name }}"
                      title="Sil">
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

  {{-- Add Modal --}}
  <div class="modal fade" id="addModal" tabindex="-1">
    <div class="modal-dialog">
      <form action="{{ route('bills.store') }}" method="POST">
        @csrf
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Fatura Ekle</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <div class="mb-4">
              <label class="form-label">Fatura Adı <span class="text-danger">*</span></label>
              <input type="text" name="name" class="form-control" placeholder="örn: Evim Elektrik" required>
            </div>
            <div class="row g-4 mb-4">
              <div class="col-6">
                <label class="form-label">Tür <span class="text-danger">*</span></label>
                <select name="type" class="form-select" required>
                  <option value="electricity">Elektrik</option>
                  <option value="water">Su</option>
                  <option value="gas">Doğalgaz</option>
                  <option value="internet">İnternet</option>
                  <option value="phone">Telefon</option>
                  <option value="rent">Kira</option>
                  <option value="insurance">Sigorta</option>
                  <option value="other">Diğer</option>
                </select>
              </div>
              <div class="col-6">
                <label class="form-label">Son Ödeme Günü</label>
                <input type="number" name="due_day" class="form-control" min="1" max="31" placeholder="örn: 15">
              </div>
            </div>
            <div class="row g-4 mb-4">
              <div class="col-6">
                <label class="form-label">Tedarikçi / Firma</label>
                <input type="text" name="provider" class="form-control" placeholder="örn: AYEDAŞ">
              </div>
              <div class="col-6">
                <label class="form-label">Ortalama Tutar</label>
                <input type="number" name="average_amount" class="form-control" step="0.01" min="0" placeholder="₺">
              </div>
            </div>
            <div class="mb-4">
              <label class="form-label">Abone / Sözleşme No</label>
              <input type="text" name="account_number" class="form-control" placeholder="Opsiyonel">
            </div>
            <div class="form-check">
              <input class="form-check-input" type="checkbox" name="is_autopay" value="1" id="chkAutopay">
              <label class="form-check-label" for="chkAutopay">Otomatik ödeme aktif</label>
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

  {{-- Pay Record Modal --}}
  <div class="modal fade" id="payModal" tabindex="-1">
    <div class="modal-dialog modal-sm">
      <form id="payForm" method="POST">
        @csrf @method('PATCH')
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Ödeme Kaydet</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <p class="text-muted small mb-3" id="payModalBillName"></p>
            <label class="form-label">Ödenen Tutar (₺) <span class="text-danger">*</span></label>
            <input type="number" name="last_amount" id="payAmount" class="form-control" step="0.01" min="0" required>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-success">Kaydet</button>
          </div>
        </div>
      </form>
    </div>
  </div>

  <x-slot name="pageJs">
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
  <script>
  // Delete
  document.querySelectorAll('.btn-swal-delete').forEach(function (btn) {
    btn.addEventListener('click', function () {
      const name = this.dataset.name;
      Swal.fire({
        title: '"' + name + '" faturasını sil?',
        text: 'Bu işlem geri alınamaz.',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#6c757d',
        confirmButtonText: 'Evet, sil',
        cancelButtonText: 'Vazgeç',
        reverseButtons: true,
      }).then(function (result) {
        if (result.isConfirmed) btn.closest('form').submit();
      });
    });
  });

  // Record payment — open modal pre-filled
  const payModal    = document.getElementById('payModal');
  const payForm     = document.getElementById('payForm');
  const payAmountEl = document.getElementById('payAmount');
  const payNameEl   = document.getElementById('payModalBillName');

  document.querySelectorAll('.btn-pay-record').forEach(function (btn) {
    btn.addEventListener('click', function () {
      payForm.action    = this.dataset.action;
      payAmountEl.value = this.dataset.amount;
      payNameEl.textContent = this.dataset.name + ' için tutar girin:';
      bootstrap.Modal.getOrCreateInstance(payModal).show();
    });
  });
  </script>
  </x-slot>
</x-app-layout>
