<x-guest-layout>
  <div class="card">
    <div class="card-body">
      <h4 class="mb-1">Yeni Şifre Belirle 🔑</h4>
      <p class="mb-6">Güçlü bir şifre seçin</p>

      <form method="POST" action="{{ route('password.store') }}">
        @csrf
        <input type="hidden" name="token" value="{{ $request->route('token') }}">

        <div class="mb-6">
          <label class="form-label" for="email">E-posta</label>
          <input type="email" class="form-control @error('email') is-invalid @enderror"
                 id="email" name="email" value="{{ old('email', $request->email) }}"
                 autofocus autocomplete="username" />
          @error('email')<div class="invalid-feedback">{{ $message }}</div>@enderror
        </div>

        <div class="mb-6 form-password-toggle">
          <label class="form-label" for="password">Yeni Şifre</label>
          <div class="input-group input-group-merge">
            <input type="password" class="form-control @error('password') is-invalid @enderror"
                   id="password" name="password" placeholder="············" autocomplete="new-password" />
            <span class="input-group-text cursor-pointer"><i class="icon-base ti tabler-eye-off"></i></span>
            @error('password')<div class="invalid-feedback">{{ $message }}</div>@enderror
          </div>
        </div>

        <div class="mb-6 form-password-toggle">
          <label class="form-label" for="password_confirmation">Şifre (Tekrar)</label>
          <div class="input-group input-group-merge">
            <input type="password" class="form-control"
                   id="password_confirmation" name="password_confirmation"
                   placeholder="············" autocomplete="new-password" />
            <span class="input-group-text cursor-pointer"><i class="icon-base ti tabler-eye-off"></i></span>
          </div>
        </div>

        <div class="mb-6">
          <button class="btn btn-primary d-grid w-100" type="submit">Şifremi Sıfırla</button>
        </div>
      </form>
    </div>
  </div>
</x-guest-layout>
