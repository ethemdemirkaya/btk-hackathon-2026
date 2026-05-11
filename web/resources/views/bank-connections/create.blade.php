<x-app-layout>
  <x-slot name="title">Banka Bağla</x-slot>

  <x-slot name="pageCss">
  <style>
    /* Bank option cards: 2px border, thickens to primary on selection */
    .bank-card { border-width: 2px !important; transition: border-color .15s, box-shadow .15s; }
    .bank-card:hover { border-color: var(--bs-primary) !important; box-shadow: 0 0 0 3px rgba(115,103,240,.12); }
    .bank-card.border-primary { box-shadow: 0 0 0 3px rgba(115,103,240,.18); }
  </style>
  </x-slot>

  <div class="row justify-content-center">
    <div class="col-xl-8">

      <div class="d-flex align-items-center mb-6">
        <a href="{{ route('bank-connections.index') }}" class="btn btn-icon btn-outline-secondary me-3">
          <i class="icon-base ti tabler-arrow-left"></i>
        </a>
        <div>
          <h4 class="fw-bold mb-0">Banka Bağla</h4>
          <p class="text-muted mb-0">Bankanızı seçin ve kimlik bilgilerinizi girin</p>
        </div>
      </div>

      @if($errors->any())
        <div class="alert alert-danger alert-dismissible mb-6" role="alert">
          <ul class="mb-0 ps-3">
            @foreach($errors->all() as $error)
              <li>{{ $error }}</li>
            @endforeach
          </ul>
          <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
      @endif

      <form action="{{ route('bank-connections.store') }}" method="POST" id="bankConnectForm">
        @csrf

        {{-- Step 1: Banka Seçimi --}}
        <div class="card mb-6">
          <div class="card-header">
            <h5 class="card-title mb-0">
              <span class="badge bg-primary rounded-pill me-2">1</span>Banka Seçin
            </h5>
          </div>
          <div class="card-body">
            <div class="row g-4">
              @foreach($banks as $bank)
                <div class="col-sm-6 col-xl-3">
                  <label class="bank-option cursor-pointer w-100">
                    <input type="radio" name="bank_id" value="{{ $bank->id }}"
                           class="d-none bank-radio"
                           {{ old('bank_id', request('bank_id')) == $bank->id ? 'checked' : '' }}>
                    <div class="card border bank-card h-100 p-3 text-center @if(old('bank_id', request('bank_id')) == $bank->id) border-primary @endif">
                      <div class="mx-auto mb-3 d-flex align-items-center justify-content-center bank-logo-box rounded"
                           style="width:110px;height:68px;padding:10px;">
                        @if($bank->logo)
                          <img src="{{ asset($bank->logo) }}" alt="{{ $bank->name }}"
                               style="max-width:100%;max-height:100%;object-fit:contain;">
                        @else
                          <span class="fw-bold text-primary">{{ strtoupper(substr($bank->slug, 0, 2)) }}</span>
                        @endif
                      </div>
                      <div class="fw-semibold mb-1">{{ $bank->name }}</div>
                      <small class="badge bg-label-info">{{ strtoupper($bank->auth_type) }}</small>
                    </div>
                  </label>
                </div>
              @endforeach
            </div>
            @error('bank_id')
              <div class="text-danger mt-2 small">{{ $message }}</div>
            @enderror
          </div>
        </div>

        {{-- Step 2: Kimlik Bilgileri (dynamic per bank type) --}}
        <div class="card mb-6" id="credentialsCard" style="{{ old('bank_id') ? '' : 'display:none;' }}">
          <div class="card-header">
            <h5 class="card-title mb-0">
              <span class="badge bg-primary rounded-pill me-2">2</span>Kimlik Bilgileri
            </h5>
          </div>
          <div class="card-body">

            {{-- Ziraat — Bearer Token: TCKN + Parola --}}
            <div class="bank-fields" data-slug="ziraat" style="display:none;">
              <div class="alert alert-info mb-4 small">
                <i class="icon-base ti tabler-shield-lock me-2"></i>
                Ziraat Bankası internet bankacılığı TC Kimlik numarası ve parolanızı girin.
              </div>
              <div class="row g-4">
                <div class="col-md-6">
                  <label class="form-label">TC Kimlik No <span class="text-danger">*</span></label>
                  <input type="text" name="credentials[tckn]" class="form-control"
                         maxlength="11" pattern="[0-9]{11}" placeholder="12345678901"
                         value="{{ old('credentials.tckn') }}">
                </div>
                <div class="col-md-6">
                  <label class="form-label">İnternet Bankacılığı Parolası <span class="text-danger">*</span></label>
                  <div class="input-group input-group-merge">
                    <input type="password" name="credentials[password]" class="form-control" placeholder="••••••••">
                    <span class="input-group-text cursor-pointer toggle-pw">
                      <i class="icon-base ti tabler-eye-off"></i>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {{-- Garanti — OAuth2: client_id + client_secret --}}
            <div class="bank-fields" data-slug="garanti" style="display:none;">
              <div class="alert alert-info mb-4 small">
                <i class="icon-base ti tabler-key me-2"></i>
                Garanti API Yönetim Paneli'nden aldığınız OAuth2 kimlik bilgilerini girin.
              </div>
              <div class="row g-4">
                <div class="col-md-6">
                  <label class="form-label">Client ID (TC Kimlik No) <span class="text-danger">*</span></label>
                  <input type="text" name="credentials[client_id]" class="form-control"
                         placeholder="12345678901" value="{{ old('credentials.client_id') }}">
                </div>
                <div class="col-md-6">
                  <label class="form-label">Client Secret <span class="text-danger">*</span></label>
                  <div class="input-group input-group-merge">
                    <input type="password" name="credentials[client_secret]" class="form-control" placeholder="••••••••">
                    <span class="input-group-text cursor-pointer toggle-pw">
                      <i class="icon-base ti tabler-eye-off"></i>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {{-- İşbank — HMAC: TCKN + HMAC Secret --}}
            <div class="bank-fields" data-slug="isbank" style="display:none;">
              <div class="alert alert-info mb-4 small">
                <i class="icon-base ti tabler-fingerprint me-2"></i>
                İş Bankası API portalından aldığınız HMAC imzalama bilgilerini girin.
              </div>
              <div class="row g-4">
                <div class="col-md-6">
                  <label class="form-label">TC Kimlik No <span class="text-danger">*</span></label>
                  <input type="text" name="credentials[tckn]" class="form-control"
                         maxlength="11" pattern="[0-9]{11}" placeholder="12345678901"
                         value="{{ old('credentials.tckn') }}">
                </div>
                <div class="col-md-6">
                  <label class="form-label">HMAC Secret Key <span class="text-danger">*</span></label>
                  <div class="input-group input-group-merge">
                    <input type="password" name="credentials[hmac_secret]" class="form-control" placeholder="••••••••••••">
                    <span class="input-group-text cursor-pointer toggle-pw">
                      <i class="icon-base ti tabler-eye-off"></i>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {{-- Akbank — JSON-RPC: API Key --}}
            <div class="bank-fields" data-slug="akbank" style="display:none;">
              <div class="alert alert-info mb-4 small">
                <i class="icon-base ti tabler-api me-2"></i>
                Akbank API platformundan (Akbank API Portal) aldığınız API anahtarını girin.
              </div>
              <div class="row g-4">
                <div class="col-12">
                  <label class="form-label">API Anahtarı <span class="text-danger">*</span></label>
                  <div class="input-group input-group-merge">
                    <input type="password" name="credentials[api_key]" class="form-control"
                           placeholder="akb_••••••••••••••••••••••••••••••••••••••••">
                    <span class="input-group-text cursor-pointer toggle-pw">
                      <i class="icon-base ti tabler-eye-off"></i>
                    </span>
                  </div>
                </div>
              </div>
            </div>

            <div id="selectBankFirst" @if(!old('bank_id')) class="text-center py-4 text-muted" @else class="d-none" @endif>
              <i class="icon-base ti tabler-arrow-up icon-32px d-block mb-2"></i>
              Önce yukarıdan bir banka seçin
            </div>
          </div>
        </div>

        {{-- Security note + submit --}}
        <div class="card" id="submitCard" style="{{ old('bank_id') ? '' : 'display:none;' }}">
          <div class="card-body">
            <div class="alert alert-secondary mb-4">
              <div class="d-flex">
                <i class="icon-base ti tabler-shield-check icon-24px text-success me-3 mt-1"></i>
                <div class="small">
                  <strong>Güvenlik Notu:</strong> Kimlik bilgileriniz <strong>AES-256 şifrelemesiyle</strong>
                  cihazınızda saklanır. Paranette'in sunucularına asla düz metin olarak gönderilmez.
                  Sadece banka API'siyle doğrulama için kullanılır.
                </div>
              </div>
            </div>
            <div class="d-flex gap-3">
              <button type="submit" class="btn btn-primary">
                <i class="icon-base ti tabler-link me-2"></i>Bankayı Bağla
              </button>
              <a href="{{ route('bank-connections.index') }}" class="btn btn-outline-secondary">İptal</a>
            </div>
          </div>
        </div>
      </form>
    </div>
  </div>

  <x-slot name="pageJs">
  <script>
  (function () {
    const bankSlugs = @json($banks->pluck('slug', 'id'));

    // Bank selection toggle
    document.querySelectorAll('.bank-radio').forEach(radio => {
      radio.addEventListener('change', function () {
        const bankId  = this.value;
        const slug    = bankSlugs[bankId];
        // radio is a sibling of .bank-card inside the <label>, so go up to label first
        const label   = this.closest('label');
        const myCard  = label.querySelector('.bank-card');

        // Update card styles
        document.querySelectorAll('.bank-card').forEach(c => {
          c.classList.remove('border-primary');
        });
        myCard.classList.add('border-primary');

        // Show credentials section
        document.getElementById('credentialsCard').style.display = '';
        document.getElementById('submitCard').style.display = '';
        document.getElementById('selectBankFirst')?.classList.add('d-none');

        // Show correct fields
        document.querySelectorAll('.bank-fields').forEach(f => {
          f.style.display = f.dataset.slug === slug ? '' : 'none';
        });
      });
    });

    // Fire change if bank pre-selected (via old() or query param)
    const checked = document.querySelector('.bank-radio:checked');
    if (checked) checked.dispatchEvent(new Event('change'));

    // Password toggle
    document.querySelectorAll('.toggle-pw').forEach(btn => {
      btn.addEventListener('click', function () {
        const input = this.closest('.input-group').querySelector('input');
        const isHidden = input.type === 'password';
        input.type = isHidden ? 'text' : 'password';
        this.querySelector('i').className = isHidden
          ? 'icon-base ti tabler-eye'
          : 'icon-base ti tabler-eye-off';
      });
    });
  })();
  </script>
  </x-slot>
</x-app-layout>
