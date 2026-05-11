<x-guest-layout>
  <div class="card">
    <div class="card-body">
      <div class="app-brand justify-content-center mb-6">
        <a href="{{ url('/') }}" class="app-brand-link gap-2">
          <span class="app-brand-logo" style="color:#28C76F">
            <svg width="32" height="22" viewBox="0 0 32 22" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path fill-rule="evenodd" clip-rule="evenodd" d="M0.00172773 0V6.85398C0.00172773 6.85398 -0.133178 9.01207 1.98092 10.8388L13.6912 21.9964L19.7809 21.9181L18.8042 9.88248L16.4951 7.17289L9.23799 0H0.00172773Z" fill="currentColor"/>
              <path opacity="0.06" fill-rule="evenodd" clip-rule="evenodd" d="M7.69824 16.4364L12.5199 3.23696L16.5541 7.25596L7.69824 16.4364Z" fill="#161616"/>
              <path opacity="0.06" fill-rule="evenodd" clip-rule="evenodd" d="M8.07751 15.9175L13.9419 4.63989L16.5849 7.28475L8.07751 15.9175Z" fill="#161616"/>
              <path fill-rule="evenodd" clip-rule="evenodd" d="M7.77295 16.3566L23.6563 0H32V6.88383C32 6.88383 31.8262 9.17836 30.6591 10.4057L19.7824 22H13.6938L7.77295 16.3566Z" fill="currentColor"/>
            </svg>
          </span>
          <span class="app-brand-text fw-bold text-heading">Paranette</span>
        </a>
      </div>

      <h4 class="mb-1">Paranette'e Hoş Geldiniz</h4>
      <p class="mb-6">Hesabınıza giriş yaparak devam edin</p>

      <x-auth-session-status class="alert alert-info mb-4" :status="session('status')" />

      <form method="POST" action="{{ route('login') }}" id="formLogin">
        @csrf

        <div class="mb-6">
          <label class="form-label" for="email">E-posta</label>
          <input type="email" class="form-control @error('email') is-invalid @enderror"
                 id="email" name="email" value="{{ old('email') }}"
                 placeholder="email@example.com" autofocus autocomplete="username" />
          @error('email')
            <div class="invalid-feedback">{{ $message }}</div>
          @enderror
        </div>

        <div class="mb-6 form-password-toggle">
          <div class="d-flex justify-content-between">
            <label class="form-label" for="password">Şifre</label>
            @if (Route::has('password.request'))
              <a href="{{ route('password.request') }}" class="float-end mb-1">
                <span>Şifremi unuttum?</span>
              </a>
            @endif
          </div>
          <div class="input-group input-group-merge">
            <input type="password" class="form-control @error('password') is-invalid @enderror"
                   id="password" name="password"
                   placeholder="············" autocomplete="current-password" />
            <span class="input-group-text cursor-pointer">
              <i class="icon-base ti tabler-eye-off"></i>
            </span>
            @error('password')
              <div class="invalid-feedback">{{ $message }}</div>
            @enderror
          </div>
        </div>

        <div class="mb-8">
          <div class="form-check ms-2">
            <input class="form-check-input" type="checkbox" name="remember" id="remember" />
            <label class="form-check-label" for="remember">Beni hatırla</label>
          </div>
        </div>

        <div class="mb-6">
          <button class="btn btn-primary d-grid w-100" type="submit">Giriş Yap</button>
        </div>
      </form>

      <p class="text-center">
        <span>Hesabınız yok mu?</span>
        <a href="{{ route('register') }}"><span> Kayıt Ol</span></a>
      </p>

      <div class="divider my-4">
        <div class="divider-text">veya</div>
      </div>

      <button type="button" class="btn btn-outline-secondary d-grid w-100"
              onclick="document.getElementById('email').value='demo@paranette.local';document.getElementById('password').value='password';">
        <i class="icon-base ti tabler-player-play me-2"></i>Demo Hesabıyla Dene
      </button>
    </div>
  </div>
</x-guest-layout>
