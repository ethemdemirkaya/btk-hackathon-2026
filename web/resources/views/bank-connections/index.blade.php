<x-app-layout>
  <x-slot name="title">Banka Hesapları</x-slot>

  {{-- Header --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Banka Hesapları</h4>
      <p class="text-muted small mb-0">Bağlı bankalar ve hesaplar</p>
    </div>
    <a href="{{ route('bank-connections.create') }}" class="btn btn-primary">
      <i class="icon-base ti tabler-plus me-1"></i> Banka Bağla
    </a>
  </div>

  {{-- Flash messages --}}
  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-6" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif
  @if(session('error'))
    <div class="alert alert-danger alert-dismissible mb-6" role="alert">
      <i class="icon-base ti tabler-alert-circle me-2"></i>{{ session('error') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  @if($connections->isEmpty())
    {{-- Empty state --}}
    <div class="card">
      <div class="card-body text-center py-8">
        <i class="icon-base ti tabler-building-bank icon-64px text-muted mb-4 d-block"></i>
        <h5 class="mb-2">Henüz banka bağlanmadı</h5>
        <p class="text-muted mb-4">Finansal hesaplarınızı Paranette'e bağlayarak otomatik analiz başlatın.</p>
        <a href="{{ route('bank-connections.create') }}" class="btn btn-primary">
          <i class="icon-base ti tabler-plus me-1"></i> İlk Bankayı Bağla
        </a>
      </div>
    </div>
  @else
  @php
    $totalBalance  = $connections->flatMap->accounts->sum('balance');
    $activeCount   = $connections->where('status', 'active')->count();
    $errorCount    = $connections->where('status', 'error')->count();
    $accountCount  = $connections->flatMap->accounts->count();
  @endphp
  <div class="row g-4 mb-6">
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-primary"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Bakiye</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">₺{{ number_format($totalBalance, 0, ',', '.') }}</div>
              <span class="small text-muted">{{ $accountCount }} hesap</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-building-bank icon-22px"></i>
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
              <span class="text-muted small">Bağlı Banka</span>
              <div class="h5 fw-bold mt-1 mb-0 text-success">{{ $activeCount }}</div>
              <span class="small text-muted">{{ $connections->count() }} toplam bağlantı</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-success">
                <i class="icon-base ti tabler-link icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar {{ $errorCount > 0 ? 'bg-danger' : 'bg-success' }}"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Bağlantı Durumu</span>
              <div class="h5 fw-bold mt-1 mb-0 {{ $errorCount > 0 ? 'text-danger' : 'text-success' }}">
                {{ $errorCount > 0 ? "{$errorCount} Hata" : 'Sağlıklı' }}
              </div>
              <span class="small text-muted">{{ $errorCount > 0 ? 'Yeniden bağlanın' : 'Tüm bağlantılar aktif' }}</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $errorCount > 0 ? 'danger' : 'success' }}">
                <i class="icon-base ti {{ $errorCount > 0 ? 'tabler-alert-triangle' : 'tabler-shield-check' }} icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

    {{-- Connected banks list --}}
    <div class="row g-6 mb-6">
      @foreach($connections as $conn)
        <div class="col-md-6 col-xl-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex align-items-center justify-content-between mb-4">
                <div class="d-flex align-items-center gap-3">
                  {{-- Bank logo --}}
                  <div class="bank-logo-wrap bank-logo-box rounded overflow-hidden d-flex align-items-center justify-content-center"
                       style="width:88px;height:56px;padding:8px;">
                    @if($conn->bank->logo)
                      <img src="{{ asset($conn->bank->logo) }}"
                           alt="{{ $conn->bank->name }}"
                           style="max-width:100%;max-height:100%;object-fit:contain;">
                    @else
                      <span class="fw-bold small text-primary">{{ strtoupper(substr($conn->bank->slug, 0, 2)) }}</span>
                    @endif
                  </div>
                  <div>
                    <h6 class="mb-0">{{ $conn->bank->name }}</h6>
                    <small class="text-muted text-uppercase">{{ $conn->bank->auth_type }}</small>
                  </div>
                </div>
                <span class="badge @if($conn->status === 'active') bg-label-success @elseif($conn->status === 'error') bg-label-danger @else bg-label-warning @endif">
                  {{ match($conn->status) { 'active' => 'Aktif', 'error' => 'Hata', default => 'Beklemede' } }}
                </span>
              </div>

              @if($conn->last_sync_at)
                <p class="text-muted small mb-3">
                  <i class="icon-base ti tabler-refresh me-1"></i>
                  Son sync: {{ $conn->last_sync_at->diffForHumans() }}
                </p>
              @else
                <p class="text-muted small mb-3">
                  <i class="icon-base ti tabler-clock me-1"></i>Henüz senkronize edilmedi
                </p>
              @endif

              {{-- Account balances --}}
              @if($conn->accounts->isNotEmpty())
                <div class="mb-3">
                  @foreach($conn->accounts->take(3) as $acct)
                    <div class="d-flex justify-content-between small py-1 border-bottom">
                      <span class="text-muted">
                        {{ $acct->account_type === 'checking' ? 'Vadesiz' : 'Birikimli' }}
                      </span>
                      <span class="fw-medium">₺{{ number_format($acct->balance, 2, ',', '.') }}</span>
                    </div>
                  @endforeach
                </div>
              @endif

              <div class="d-flex gap-2 mt-3">
                <form action="{{ route('bank-connections.sync', $conn) }}" method="POST" class="flex-fill">
                  @csrf
                  <button type="submit" class="btn btn-sm btn-outline-primary w-100">
                    <i class="icon-base ti tabler-refresh me-1"></i> Senkronize Et
                  </button>
                </form>
                <button type="button"
                        class="btn btn-sm btn-outline-danger btn-delete-conn"
                        data-name="{{ $conn->bank->name }}"
                        data-action="{{ route('bank-connections.destroy', $conn) }}">
                  <i class="icon-base ti tabler-trash"></i>
                </button>
                {{-- Hidden delete form --}}
                <form id="delete-form-{{ $conn->id }}"
                      action="{{ route('bank-connections.destroy', $conn) }}"
                      method="POST" class="d-none">
                  @csrf @method('DELETE')
                </form>
              </div>
            </div>
          </div>
        </div>
      @endforeach

      {{-- Add more bank card --}}
      @if($connections->count() < $banks->count())
        <div class="col-md-6 col-xl-4">
          <a href="{{ route('bank-connections.create') }}" class="text-decoration-none">
            <div class="card h-100 border-dashed">
              <div class="card-body d-flex align-items-center justify-content-center text-center py-6">
                <div>
                  <i class="icon-base ti tabler-circle-plus icon-48px text-primary mb-3 d-block"></i>
                  <h6 class="text-primary mb-0">Başka Banka Ekle</h6>
                </div>
              </div>
            </div>
          </a>
        </div>
      @endif
    </div>

    {{-- Available banks to connect --}}
    @php $connectedBankIds = $connections->pluck('bank_id')->toArray(); @endphp
    @if($banks->whereNotIn('id', $connectedBankIds)->isNotEmpty())
      <div class="card">
        <div class="card-header">
          <h5 class="card-title mb-0">Bağlanabilecek Bankalar</h5>
        </div>
        <div class="card-body">
          <div class="row g-4">
            @foreach($banks->whereNotIn('id', $connectedBankIds) as $bank)
              <div class="col-sm-6 col-xl-3">
                <div class="d-flex align-items-center gap-3 p-3 border rounded">
                  <div class="bank-logo-wrap bank-logo-box rounded d-flex align-items-center justify-content-center"
                       style="width:88px;height:56px;padding:8px;flex-shrink:0;">
                    @if($bank->logo)
                      <img src="{{ asset($bank->logo) }}" alt="{{ $bank->name }}"
                           style="max-width:100%;max-height:100%;object-fit:contain;">
                    @else
                      <span class="fw-bold small text-primary">{{ strtoupper(substr($bank->slug, 0, 2)) }}</span>
                    @endif
                  </div>
                  <div class="flex-grow-1">
                    <div class="fw-medium">{{ $bank->name }}</div>
                    <small class="text-muted text-uppercase">{{ $bank->auth_type }}</small>
                  </div>
                  <a href="{{ route('bank-connections.create', ['bank_id' => $bank->id]) }}"
                     class="btn btn-sm btn-primary">
                    Bağla
                  </a>
                </div>
              </div>
            @endforeach
          </div>
        </div>
      </div>
    @endif
  @endif

  <x-slot name="pageJs">
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
  <script>
  document.querySelectorAll('.btn-delete-conn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      const bankName = this.dataset.name;
      const action   = this.dataset.action;

      Swal.fire({
        title: bankName + ' bağlantısını kaldır',
        text: 'Bu bankaya ait tüm hesap, kart ve işlem verileri silinecek. Devam etmek istiyor musunuz?',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#6c757d',
        confirmButtonText: 'Evet, kaldır',
        cancelButtonText: 'İptal',
        reverseButtons: true,
      }).then(function (result) {
        if (result.isConfirmed) {
          // Find the hidden form by action URL and submit it
          document.querySelectorAll('form.d-none').forEach(function (form) {
            if (form.action === action) {
              form.submit();
            }
          });
        }
      });
    });
  });
  </script>
  </x-slot>
</x-app-layout>
