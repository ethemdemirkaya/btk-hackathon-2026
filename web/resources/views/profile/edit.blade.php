<x-app-layout>
  <x-slot name="title">Profil</x-slot>

  <div class="d-flex align-items-center justify-content-between mb-6">
    <div>
      <h4 class="fw-bold mb-1">Profil Ayarları</h4>
      <p class="text-muted mb-0">Hesap bilgilerini ve şifreni güncelle</p>
    </div>
  </div>

  <div class="row g-6">

    {{-- ── Update profile info ──────────────────────────────────────── --}}
    <div class="col-xl-6">
      <div class="card h-100">
        <div class="card-header pb-3">
          <h5 class="card-title mb-0">
            <i class="icon-base ti tabler-user me-2 text-primary"></i>Profil Bilgileri
          </h5>
        </div>
        <div class="card-body">

          @if(session('status') === 'profile-updated')
            <div class="alert alert-success alert-dismissible mb-4" role="alert">
              <i class="icon-base ti tabler-circle-check me-2"></i>Profil başarıyla güncellendi.
              <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
          @endif

          <form method="POST" action="{{ route('profile.update') }}">
            @csrf
            @method('PATCH')

            <div class="mb-4">
              <label class="form-label" for="name">Ad Soyad</label>
              <input type="text" id="name" name="name"
                     class="form-control @error('name') is-invalid @enderror"
                     value="{{ old('name', auth()->user()->name) }}"
                     required autocomplete="name">
              @error('name')
                <div class="invalid-feedback">{{ $message }}</div>
              @enderror
            </div>

            <div class="mb-4">
              <label class="form-label" for="email">E-posta</label>
              <input type="email" id="email" name="email"
                     class="form-control @error('email') is-invalid @enderror"
                     value="{{ old('email', auth()->user()->email) }}"
                     required autocomplete="email">
              @error('email')
                <div class="invalid-feedback">{{ $message }}</div>
              @enderror
            </div>

            <div class="mb-5">
              <label class="form-label" for="monthly_income">Aylık Net Gelir (₺)</label>
              <div class="input-group">
                <span class="input-group-text">₺</span>
                <input type="number" id="monthly_income" name="monthly_income"
                       class="form-control @error('monthly_income') is-invalid @enderror"
                       value="{{ old('monthly_income', auth()->user()->monthly_income) }}"
                       min="0" step="0.01"
                       placeholder="örn: 25000">
                @error('monthly_income')
                  <div class="invalid-feedback">{{ $message }}</div>
                @enderror
              </div>
              <div class="form-text">Karar Simülatörü ve AI analizleri için kullanılır</div>
            </div>

            <button type="submit" class="btn btn-primary">
              <i class="icon-base ti tabler-check me-1"></i>Kaydet
            </button>
          </form>
        </div>
      </div>
    </div>

    {{-- ── Update password ─────────────────────────────────────────── --}}
    <div class="col-xl-6">
      <div class="card mb-6">
        <div class="card-header pb-3">
          <h5 class="card-title mb-0">
            <i class="icon-base ti tabler-lock me-2 text-warning"></i>Şifre Değiştir
          </h5>
        </div>
        <div class="card-body">

          @if(session('status') === 'password-updated')
            <div class="alert alert-success alert-dismissible mb-4" role="alert">
              <i class="icon-base ti tabler-circle-check me-2"></i>Şifre başarıyla güncellendi.
              <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
          @endif

          <form method="POST" action="{{ route('password.update') }}">
            @csrf
            @method('PUT')

            <div class="mb-4">
              <label class="form-label" for="current_password">Mevcut Şifre</label>
              <input type="password" id="current_password" name="current_password"
                     class="form-control @error('current_password', 'updatePassword') is-invalid @enderror"
                     autocomplete="current-password">
              @error('current_password', 'updatePassword')
                <div class="invalid-feedback">{{ $message }}</div>
              @enderror
            </div>

            <div class="mb-4">
              <label class="form-label" for="password">Yeni Şifre</label>
              <input type="password" id="password" name="password"
                     class="form-control @error('password', 'updatePassword') is-invalid @enderror"
                     autocomplete="new-password">
              @error('password', 'updatePassword')
                <div class="invalid-feedback">{{ $message }}</div>
              @enderror
            </div>

            <div class="mb-5">
              <label class="form-label" for="password_confirmation">Yeni Şifre (Tekrar)</label>
              <input type="password" id="password_confirmation" name="password_confirmation"
                     class="form-control"
                     autocomplete="new-password">
            </div>

            <button type="submit" class="btn btn-warning">
              <i class="icon-base ti tabler-lock me-1"></i>Şifreyi Güncelle
            </button>
          </form>
        </div>
      </div>

      {{-- ── Delete account ─────────────────────────────────────── --}}
      <div class="card border-danger">
        <div class="card-header pb-3">
          <h5 class="card-title mb-0 text-danger">
            <i class="icon-base ti tabler-trash me-2"></i>Hesabı Sil
          </h5>
        </div>
        <div class="card-body">
          <p class="text-muted small mb-4">
            Hesabınız silindiğinde tüm veriler kalıcı olarak kaldırılır. Devam etmeden önce indirmek istediğiniz verileri dışa aktarın.
          </p>
          <button type="button" class="btn btn-outline-danger btn-sm"
                  data-bs-toggle="modal" data-bs-target="#deleteAccountModal">
            <i class="icon-base ti tabler-trash me-1"></i>Hesabı Kalıcı Olarak Sil
          </button>
        </div>
      </div>
    </div>

  </div>

  {{-- Delete account modal --}}
  <div class="modal fade" id="deleteAccountModal" tabindex="-1">
    <div class="modal-dialog modal-sm">
      <form method="POST" action="{{ route('profile.destroy') }}">
        @csrf
        @method('DELETE')
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title text-danger">Hesabı Sil</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            <p class="small text-muted mb-3">Devam etmek için şifrenizi girin:</p>
            <input type="password" name="password"
                   class="form-control @error('password', 'userDeletion') is-invalid @enderror"
                   placeholder="Şifreniz" required>
            @error('password', 'userDeletion')
              <div class="invalid-feedback">{{ $message }}</div>
            @enderror
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary btn-sm" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-danger btn-sm">Hesabı Sil</button>
          </div>
        </div>
      </form>
    </div>
  </div>

  @if($errors->userDeletion->isNotEmpty())
    <x-slot name="pageJs">
    <script>
    document.addEventListener('DOMContentLoaded', function () {
      new bootstrap.Modal(document.getElementById('deleteAccountModal')).show();
    });
    </script>
    </x-slot>
  @endif

</x-app-layout>
