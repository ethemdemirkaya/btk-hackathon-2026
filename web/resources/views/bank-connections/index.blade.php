<x-app-layout>
  <x-slot name="title">Banka Hesapları</x-slot>

  {{-- Header --}}
  <div class="d-flex align-items-center justify-content-between mb-6">
    <div>
      <h4 class="fw-bold mb-1">Banka Hesapları</h4>
      <p class="text-muted mb-0">Bağlı bankalar ve hesaplar</p>
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
    {{-- Connected banks list --}}
    <div class="row g-6 mb-6">
      @foreach($connections as $conn)
        <div class="col-md-6 col-xl-4">
          <div class="card h-100">
            <div class="card-body">
              <div class="d-flex align-items-center justify-content-between mb-4">
                <div class="d-flex align-items-center gap-3">
                  <div class="avatar">
                    <span class="avatar-initial rounded bg-label-primary fw-bold">
                      {{ strtoupper(substr($conn->bank->slug, 0, 2)) }}
                    </span>
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
                <form action="{{ route('bank-connections.destroy', $conn) }}" method="POST"
                      onsubmit="return confirm('{{ $conn->bank->name }} bağlantısını kaldırmak istediğinizden emin misiniz?')">
                  @csrf
                  @method('DELETE')
                  <button type="submit" class="btn btn-sm btn-outline-danger">
                    <i class="icon-base ti tabler-trash"></i>
                  </button>
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
                  <div class="avatar">
                    <span class="avatar-initial rounded bg-label-secondary fw-bold">
                      {{ strtoupper(substr($bank->slug, 0, 2)) }}
                    </span>
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
</x-app-layout>
