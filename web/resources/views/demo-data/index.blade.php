<x-app-layout>
  <x-slot name="title">Demo Veri Oluşturucu</x-slot>

  <x-slot name="pageCss">
    <style>
      .bank-check-card {
        border: 2px solid var(--bs-border-color);
        border-radius: .75rem;
        transition: border-color .18s, box-shadow .18s, background .18s;
        cursor: pointer;
        user-select: none;
      }
      .bank-check-card:hover {
        border-color: #7367F0;
        box-shadow: 0 4px 16px rgba(115,103,240,.12);
      }
      .bank-check-card.selected {
        border-color: #7367F0;
        background: rgba(115,103,240,.06);
        box-shadow: 0 4px 16px rgba(115,103,240,.15);
      }
      .bank-badge {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 44px; height: 44px;
        border-radius: .5rem;
        font-size: .8rem;
        font-weight: 700;
        color: #fff;
        flex-shrink: 0;
      }
      .bank-badge.ziraat  { background: #E30A17; }
      .bank-badge.garanti { background: #00A550; }
      .bank-badge.isbank  { background: #004B93; }
      .bank-badge.akbank  { background: #C41230; }
      .creds-accordion .accordion-button:not(.collapsed) { color: #7367F0; }
      .demo-profile-row { transition: background .15s; }
      .demo-profile-row:hover { background: rgba(115,103,240,.03); }
    </style>
  </x-slot>

  {{-- Breadcrumb --}}
  <x-slot name="breadcrumb">
    <li class="breadcrumb-item">
      <a href="{{ route('dashboard') }}">Ana Sayfa</a>
    </li>
    <li class="breadcrumb-item active">Demo Veri Oluşturucu</li>
  </x-slot>

  {{-- Başarı / Hata Bildirimleri --}}
  @if(session('success'))
  <div class="alert alert-success alert-dismissible fade show d-flex align-items-center gap-3 mb-4" role="alert">
    <i class="icon-base ti tabler-circle-check icon-20px flex-shrink-0"></i>
    <span>{{ session('success') }}</span>
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  </div>
  @endif
  @if(session('info'))
  <div class="alert alert-info alert-dismissible fade show d-flex align-items-center gap-3 mb-4" role="alert">
    <i class="icon-base ti tabler-info-circle icon-20px flex-shrink-0"></i>
    <span>{{ session('info') }}</span>
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  </div>
  @endif
  @if($errors->any())
  <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
    <i class="icon-base ti tabler-alert-circle me-2"></i>
    <strong>Hata:</strong>
    <ul class="mb-0 mt-1 ps-3">
      @foreach($errors->all() as $e)
        <li>{{ $e }}</li>
      @endforeach
    </ul>
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  </div>
  @endif

  {{-- Açıklama Kartı --}}
  <div class="card mb-5 border-0" style="background: linear-gradient(135deg, #7367F0 0%, #9E95F5 60%, #CE9FFC 100%);">
    <div class="card-body p-5">
      <div class="row align-items-center g-4">
        <div class="col-auto d-none d-md-flex">
          <div class="avatar avatar-xl">
            <span class="avatar-initial rounded-circle" style="background: rgba(255,255,255,.2); font-size: 2rem;">
              <i class="icon-base ti tabler-wand icon-40px text-white"></i>
            </span>
          </div>
        </div>
        <div class="col text-white">
          <h4 class="fw-bold text-white mb-1">Demo Veri Oluşturucu</h4>
          <p class="mb-0 opacity-85" style="max-width: 600px; font-size: .95rem;">
            Gerçekçi sahte banka verileri oluşturarak Paranette'i test edin veya sunum yapın.
            Oluşturulan veriler gerçek banka bağlantıları gibi sisteme entegre edilir — istediğiniz zaman tek tıkla silebilirsiniz.
          </p>
        </div>
      </div>
    </div>
  </div>

  <div class="row g-5">

    {{-- Sol: Form --}}
    <div class="col-xl-7">
      <div class="card shadow-sm">
        <div class="card-header">
          <h5 class="card-title mb-0">
            <i class="icon-base ti tabler-plus me-2 text-primary"></i>Yeni Demo Profili Oluştur
          </h5>
        </div>
        <div class="card-body">
          <form method="POST" action="{{ route('demo-data.generate') }}" id="demoForm">
            @csrf

            {{-- İsim --}}
            <div class="mb-4">
              <label class="form-label fw-semibold">Ad Soyad <span class="text-danger">*</span></label>
              <input
                type="text"
                name="full_name"
                class="form-control @error('full_name') is-invalid @enderror"
                placeholder="Ethem Demirkaya"
                value="{{ old('full_name') }}"
                required
              />
              <div class="form-text text-muted">Bu isim banka kullanıcı adı oluştururken kullanılacaktır.</div>
              @error('full_name')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>

            {{-- Aylık Gelir --}}
            <div class="mb-4">
              <label class="form-label fw-semibold">Aylık Gelir (₺)</label>
              <input
                type="number"
                name="monthly_income"
                class="form-control @error('monthly_income') is-invalid @enderror"
                placeholder="30000"
                value="{{ old('monthly_income', 30000) }}"
                min="1000"
                max="500000"
                step="500"
              />
              <div class="form-text text-muted">Maaş işlemleri bu tutardan oluşturulacak.</div>
              @error('monthly_income')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>

            {{-- Banka Seçimi --}}
            <div class="mb-4">
              <label class="form-label fw-semibold">Bağlanacak Bankalar <span class="text-danger">*</span></label>
              @error('banks')<div class="text-danger small mb-2">{{ $message }}</div>@enderror
              <div class="row g-3">
                @foreach($bankSlugs as $slug)
                <div class="col-sm-6">
                  <label
                    class="bank-check-card p-3 d-flex align-items-center gap-3 w-100 {{ in_array($slug, old('banks', [])) ? 'selected' : '' }}"
                    for="bank_{{ $slug }}"
                  >
                    <input
                      type="checkbox"
                      id="bank_{{ $slug }}"
                      name="banks[]"
                      value="{{ $slug }}"
                      class="form-check-input mt-0 flex-shrink-0 bank-checkbox"
                      {{ in_array($slug, old('banks', [])) ? 'checked' : '' }}
                    />
                    <div class="bank-badge {{ $slug }}">{{ strtoupper(substr($slug, 0, 2)) }}</div>
                    <div>
                      <div class="fw-semibold small">{{ $bankNames[$slug] }}</div>
                      <div class="text-muted" style="font-size: .72rem;">{{ $slug === 'garanti' ? 'OAuth2' : 'Kullanıcı Adı / Şifre' }}</div>
                    </div>
                  </label>
                </div>
                @endforeach
              </div>
            </div>

            {{-- Gelişmiş Seçenekler --}}
            <div class="accordion mb-4" id="advancedAccordion">
              <div class="accordion-item border rounded">
                <h2 class="accordion-header">
                  <button class="accordion-button collapsed py-3" type="button"
                          data-bs-toggle="collapse" data-bs-target="#advancedCollapse">
                    <i class="icon-base ti tabler-adjustments-horizontal me-2 text-muted icon-16px"></i>
                    Gelişmiş Seçenekler
                  </button>
                </h2>
                <div id="advancedCollapse" class="accordion-collapse collapse">
                  <div class="accordion-body">
                    <div class="row g-4">
                      <div class="col-sm-6">
                        <label class="form-label small fw-semibold">Kaç Aylık Geçmiş?</label>
                        <select name="months_back" class="form-select">
                          <option value="1" {{ old('months_back') == 1 ? 'selected' : '' }}>1 Ay</option>
                          <option value="3" {{ old('months_back', 3) == 3 ? 'selected' : '' }}>3 Ay (Varsayılan)</option>
                          <option value="6" {{ old('months_back') == 6 ? 'selected' : '' }}>6 Ay</option>
                          <option value="12" {{ old('months_back') == 12 ? 'selected' : '' }}>12 Ay</option>
                        </select>
                      </div>
                      <div class="col-sm-6">
                        <label class="form-label small fw-semibold">Aylık İşlem Sayısı</label>
                        <select name="tx_per_month" class="form-select">
                          <option value="10" {{ old('tx_per_month') == 10 ? 'selected' : '' }}>Az (~10)</option>
                          <option value="20" {{ old('tx_per_month', 20) == 20 ? 'selected' : '' }}>Orta (~20, Varsayılan)</option>
                          <option value="40" {{ old('tx_per_month') == 40 ? 'selected' : '' }}>Fazla (~40)</option>
                          <option value="60" {{ old('tx_per_month') == 60 ? 'selected' : '' }}>Çok Fazla (~60)</option>
                        </select>
                      </div>
                    </div>
                    <div class="alert alert-secondary mt-3 mb-0 small d-flex gap-2 align-items-start">
                      <i class="icon-base ti tabler-info-circle icon-16px flex-shrink-0 mt-1 text-muted"></i>
                      <span>Her banka için otomatik olarak bir vadesiz + bir birikimli hesap, bir kredi kartı ve rastgele bir kredi (50% olasılık) oluşturulacak. Ayrıca sisteme hedef ve bütçe de eklenecek.</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="d-flex gap-3">
              <button type="submit" class="btn btn-primary" id="btnGenerate">
                <i class="icon-base ti tabler-wand me-2"></i>Demo Veri Oluştur
              </button>
              <a href="{{ route('dashboard') }}" class="btn btn-outline-secondary">
                Dashboard'a Dön
              </a>
            </div>
          </form>
        </div>
      </div>
    </div>

    {{-- Sağ: Mevcut Demo Veriler --}}
    <div class="col-xl-5">
      <div class="card shadow-sm h-100">
        <div class="card-header d-flex align-items-center justify-content-between">
          <h5 class="card-title mb-0">
            <i class="icon-base ti tabler-database me-2 text-info"></i>Mevcut Demo Bağlantılar
          </h5>
          @if($existingConnections->isNotEmpty())
          <form method="POST" action="{{ route('demo-data.clear') }}"
                onsubmit="return confirm('Tüm demo veriler silinecek. Emin misiniz?')">
            @csrf
            <button type="submit" class="btn btn-sm btn-outline-danger">
              <i class="icon-base ti tabler-trash me-1"></i>Tümünü Sil
            </button>
          </form>
          @endif
        </div>
        <div class="card-body p-0">
          @if($existingConnections->isEmpty())
          <div class="text-center py-6 px-4">
            <div class="d-flex justify-content-center mb-3">
              <i class="icon-base ti tabler-database-off icon-48px text-muted"></i>
            </div>
            <p class="text-muted mb-1">Henüz demo bağlantı oluşturulmadı.</p>
            <p class="text-muted small mb-0">Sol formu doldurarak hemen başlayın.</p>
          </div>
          @else
          <div class="accordion creds-accordion" id="credsAccordion">
            @foreach($existingConnections as $idx => $conn)
              @php
                $creds       = $conn->getCredentials();
                $slug        = $conn->bank->slug ?? 'bank';
                $bankLabel   = $conn->bank->name ?? 'Banka';
                $accounts    = $conn->accounts;
                $checking    = $accounts->where('account_type', 'checking')->first();
                $savings     = $accounts->where('account_type', 'savings')->first();
              @endphp
            <div class="accordion-item border-0 border-bottom">
              <h2 class="accordion-header">
                <button class="accordion-button {{ $idx > 0 ? 'collapsed' : '' }} py-3 ps-4"
                        type="button"
                        data-bs-toggle="collapse"
                        data-bs-target="#creds{{ $conn->id }}">
                  <div class="d-flex align-items-center gap-3 w-100 me-3">
                    <div class="bank-badge {{ $slug }}" style="width:32px;height:32px;font-size:.65rem;">
                      {{ strtoupper(substr($slug, 0, 2)) }}
                    </div>
                    <div class="flex-grow-1">
                      <div class="fw-semibold small">{{ $bankLabel }}</div>
                      <div class="text-muted" style="font-size:.72rem;">
                        {{ $creds['username'] ?? '—' }}
                        &nbsp;·&nbsp;
                        {{ $accounts->count() }} hesap
                      </div>
                    </div>
                    <span class="badge bg-label-success me-2">Demo</span>
                  </div>
                </button>
              </h2>
              <div id="creds{{ $conn->id }}" class="accordion-collapse collapse {{ $idx === 0 ? 'show' : '' }}">
                <div class="accordion-body py-3 bg-light bg-opacity-50" style="font-size:.85rem;">
                  <table class="table table-sm mb-3">
                    <tbody>
                      <tr>
                        <td class="text-muted pe-3 border-0 py-1">Kullanıcı Adı</td>
                        <td class="fw-medium border-0 py-1">
                          <code>{{ $creds['username'] ?? '—' }}</code>
                        </td>
                      </tr>
                      <tr>
                        <td class="text-muted pe-3 border-0 py-1">Şifre</td>
                        <td class="fw-medium border-0 py-1">
                          <code>{{ $creds['password'] ?? '—' }}</code>
                        </td>
                      </tr>
                      @if($slug === 'garanti')
                      <tr>
                        <td class="text-muted pe-3 border-0 py-1">OAuth Token</td>
                        <td class="fw-medium border-0 py-1">
                          <code style="word-break:break-all;">{{ $creds['oauth_token'] ?? '—' }}</code>
                        </td>
                      </tr>
                      @endif
                      @if($checking)
                      <tr>
                        <td class="text-muted pe-3 border-0 py-1">Vadesiz Bakiye</td>
                        <td class="fw-medium border-0 py-1 text-success">
                          ₺{{ number_format($checking->balance, 2, ',', '.') }}
                        </td>
                      </tr>
                      @endif
                      @if($savings)
                      <tr>
                        <td class="text-muted pe-3 border-0 py-1">Birikimli Bakiye</td>
                        <td class="fw-medium border-0 py-1 text-info">
                          ₺{{ number_format($savings->balance, 2, ',', '.') }}
                        </td>
                      </tr>
                      @endif
                      <tr>
                        <td class="text-muted pe-3 border-0 py-1">Oluşturulma</td>
                        <td class="text-muted border-0 py-1">
                          {{ $conn->created_at->format('d.m.Y H:i') }}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                  <div class="d-flex gap-2">
                    <button
                      class="btn btn-sm btn-outline-primary btn-copy-creds"
                      data-username="{{ $creds['username'] ?? '' }}"
                      data-password="{{ $creds['password'] ?? '' }}"
                    >
                      <i class="icon-base ti tabler-copy me-1"></i>Kopyala
                    </button>
                    <a href="{{ route('bank-connections.index') }}" class="btn btn-sm btn-outline-secondary">
                      <i class="icon-base ti tabler-building-bank me-1"></i>Bağlantılara Git
                    </a>
                  </div>
                </div>
              </div>
            </div>
            @endforeach
          </div>
          @endif
        </div>
        @if($existingConnections->isNotEmpty())
        <div class="card-footer border-top d-flex justify-content-between align-items-center">
          <span class="text-muted small">
            {{ $existingConnections->count() }} demo banka bağlantısı
          </span>
          <a href="{{ route('dashboard') }}" class="btn btn-sm btn-primary">
            <i class="icon-base ti tabler-layout-dashboard me-1"></i>Dashboard
          </a>
        </div>
        @endif
      </div>
    </div>

  </div>

  {{-- Oluşturma sonrası credentials modal --}}
  @if(session('created'))
  <div class="modal fade" id="createdModal" tabindex="-1">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header border-0 pb-0">
          <h5 class="modal-title">
            <i class="icon-base ti tabler-circle-check me-2 text-success"></i>Demo Veriler Oluşturuldu!
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <div class="alert alert-info mb-4 small">
            <i class="icon-base ti tabler-lock me-2"></i>
            Aşağıdaki bilgiler şifreli olarak veritabanına kaydedildi. Bu sayfayı kapattıktan sonra "Mevcut Demo Bağlantılar" bölümünden tekrar ulaşabilirsiniz.
          </div>
          <div class="row g-4">
            @foreach(session('created') as $c)
            <div class="col-md-6">
              <div class="card border">
                <div class="card-header d-flex align-items-center gap-2 py-2">
                  <div class="bank-badge {{ $c['bank_slug'] }}" style="width:28px;height:28px;font-size:.6rem;">
                    {{ strtoupper(substr($c['bank_slug'], 0, 2)) }}
                  </div>
                  <span class="fw-semibold small">{{ $c['bank_name'] }}</span>
                </div>
                <div class="card-body py-3">
                  <table class="table table-sm mb-0" style="font-size:.82rem;">
                    <tr>
                      <td class="text-muted border-0 py-1">Kullanıcı Adı</td>
                      <td class="border-0 py-1"><code>{{ $c['username'] }}</code></td>
                    </tr>
                    <tr>
                      <td class="text-muted border-0 py-1">Şifre</td>
                      <td class="border-0 py-1"><code>{{ $c['password'] }}</code></td>
                    </tr>
                    <tr>
                      <td class="text-muted border-0 py-1">Vadesiz</td>
                      <td class="border-0 py-1 text-success fw-medium">₺{{ number_format($c['checking_bal'], 2, ',', '.') }}</td>
                    </tr>
                    <tr>
                      <td class="text-muted border-0 py-1">Birikimli</td>
                      <td class="border-0 py-1 text-info fw-medium">₺{{ number_format($c['savings_bal'], 2, ',', '.') }}</td>
                    </tr>
                  </table>
                </div>
              </div>
            </div>
            @endforeach
          </div>
        </div>
        <div class="modal-footer border-0 pt-0">
          <a href="{{ route('bank-connections.index') }}" class="btn btn-primary">
            <i class="icon-base ti tabler-building-bank me-2"></i>Banka Bağlantılarına Git
          </a>
          <a href="{{ route('dashboard') }}" class="btn btn-success">
            <i class="icon-base ti tabler-layout-dashboard me-2"></i>Dashboard'a Git
          </a>
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
        </div>
      </div>
    </div>
  </div>
  @endif

  <x-slot name="pageJs">
    <script>
    (function () {
      'use strict';

      // Bank checkbox → card seçim efekti
      document.querySelectorAll('.bank-checkbox').forEach(function (cb) {
        cb.addEventListener('change', function () {
          const card = this.closest('.bank-check-card');
          card.classList.toggle('selected', this.checked);
        });
      });

      // Form submit → loading
      const form    = document.getElementById('demoForm');
      const btnGen  = document.getElementById('btnGenerate');
      if (form && btnGen) {
        form.addEventListener('submit', function () {
          btnGen.disabled = true;
          btnGen.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Oluşturuluyor…';
        });
      }

      // Copy credentials
      document.querySelectorAll('.btn-copy-creds').forEach(function (btn) {
        btn.addEventListener('click', function () {
          const text = 'Kullanıcı Adı: ' + this.dataset.username + '\nŞifre: ' + this.dataset.password;
          navigator.clipboard.writeText(text).then(function () {
            btn.innerHTML = '<i class="icon-base ti tabler-check me-1"></i>Kopyalandı!';
            btn.classList.replace('btn-outline-primary', 'btn-success');
            setTimeout(function () {
              btn.innerHTML = '<i class="icon-base ti tabler-copy me-1"></i>Kopyala';
              btn.classList.replace('btn-success', 'btn-outline-primary');
            }, 2000);
          });
        });
      });

      // Oluşturma sonrası modal
      @if(session('created'))
      const createdModal = new bootstrap.Modal(document.getElementById('createdModal'));
      createdModal.show();
      @endif
    })();
    </script>
  </x-slot>
</x-app-layout>
