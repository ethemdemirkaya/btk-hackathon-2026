<!doctype html>
<html lang="tr" data-bs-theme="light">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Paranette — Akıllı Finansal Asistan</title>
  <link rel="icon" type="image/x-icon" href="{{ asset('assets/img/favicon/favicon.ico') }}" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Public+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;0,800&display=swap" rel="stylesheet" />
  <link rel="stylesheet" href="{{ asset('assets/vendor/fonts/iconify-icons.css') }}" />
  <link rel="stylesheet" href="{{ asset('assets/vendor/libs/node-waves/node-waves.css') }}" />
  <link rel="stylesheet" href="{{ asset('assets/vendor/css/core.css') }}" />
  <link rel="stylesheet" href="{{ asset('assets/css/demo.css') }}" />
  <style>
    body { font-family: 'Public Sans', sans-serif; }

    .hero-section {
      background: linear-gradient(135deg, #0f0c29 0%, #302b63 50%, #24243e 100%);
      color: #fff;
      padding: 6rem 0 5rem;
      position: relative;
      overflow: hidden;
    }
    .hero-section::before {
      content: '';
      position: absolute; inset: 0;
      background: radial-gradient(ellipse at 70% 50%, rgba(115,103,240,.25) 0%, transparent 65%);
    }
    .hero-badge {
      display: inline-block;
      background: rgba(115,103,240,.2);
      border: 1px solid rgba(115,103,240,.4);
      color: #a596f5;
      border-radius: 20px;
      padding: .3rem 1rem;
      font-size: .8rem;
      font-weight: 600;
      letter-spacing: .05em;
      text-transform: uppercase;
    }
    .hero-title {
      font-size: clamp(2.2rem, 5vw, 3.8rem);
      font-weight: 800;
      line-height: 1.15;
    }
    .hero-title .accent { color: #7367f0; }
    .hero-subtitle { font-size: 1.15rem; color: rgba(255,255,255,.75); max-width: 560px; }

    .stat-pill {
      background: rgba(255,255,255,.08);
      border: 1px solid rgba(255,255,255,.12);
      border-radius: 12px;
      padding: .8rem 1.2rem;
      display: flex; align-items: center; gap: .75rem;
    }
    .stat-pill .stat-icon { font-size: 1.4rem; }
    .stat-pill .stat-val { font-size: 1.2rem; font-weight: 700; }
    .stat-pill .stat-label { font-size: .78rem; opacity: .7; }

    .features-section { padding: 5rem 0; }
    .feature-card {
      border-radius: 14px;
      border: 1px solid rgba(115,103,240,.12);
      transition: transform .2s, box-shadow .2s, border-color .2s;
    }
    .feature-card:hover {
      transform: translateY(-4px);
      box-shadow: 0 12px 32px rgba(115,103,240,.12);
      border-color: rgba(115,103,240,.35);
    }
    .feature-icon-wrap {
      width: 56px; height: 56px;
      border-radius: 14px;
      display: flex; align-items: center; justify-content: center;
      font-size: 1.5rem;
    }
    .ai-section {
      background: linear-gradient(135deg, rgba(115,103,240,.06) 0%, rgba(40,199,111,.04) 100%);
      border-radius: 20px;
    }
    .agent-chip {
      display: inline-flex; align-items: center; gap: .5rem;
      background: var(--bs-card-bg);
      border: 1px solid var(--bs-border-color);
      border-radius: 24px;
      padding: .4rem .9rem;
      font-size: .82rem;
    }
    .cta-section {
      background: linear-gradient(135deg, #7367f0 0%, #ce9ffc 100%);
      border-radius: 20px;
      color: #fff;
    }
    .navbar-brand-text { font-size: 1.3rem; font-weight: 700; }
    .landing-nav {
      background: rgba(255,255,255,.04);
      backdrop-filter: blur(12px);
      border-bottom: 1px solid rgba(255,255,255,.08);
    }
  </style>
</head>
<body>

  {{-- ── Navbar ──────────────────────────────────────────────────────── --}}
  <nav class="navbar navbar-dark landing-nav sticky-top px-4 px-lg-5" style="padding-top:.9rem;padding-bottom:.9rem;">
    <a class="navbar-brand d-flex align-items-center gap-2" href="/">
      <span style="color:#28C76F;">
        <svg width="28" height="20" viewBox="0 0 32 22" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path fill-rule="evenodd" clip-rule="evenodd" d="M0.00172773 0V6.85398C0.00172773 6.85398 -0.133178 9.01207 1.98092 10.8388L13.6912 21.9964L19.7809 21.9181L18.8042 9.88248L16.4951 7.17289L9.23799 0H0.00172773Z" fill="currentColor"/>
          <path opacity="0.06" fill-rule="evenodd" clip-rule="evenodd" d="M7.69824 16.4364L12.5199 3.23696L16.5541 7.25596L7.69824 16.4364Z" fill="#161616"/>
          <path fill-rule="evenodd" clip-rule="evenodd" d="M7.77295 16.3566L23.6563 0H32V6.88383C32 6.88383 31.8262 9.17836 30.6591 10.4057L19.7824 22H13.6938L7.77295 16.3566Z" fill="currentColor"/>
        </svg>
      </span>
      <span class="navbar-brand-text text-white">Paranette</span>
    </a>
    <div class="ms-auto d-flex gap-3 align-items-center">
      @auth
        <a href="{{ route('dashboard') }}" class="btn btn-primary btn-sm">Panele Git</a>
      @else
        <a href="{{ route('login') }}" class="btn btn-outline-light btn-sm">Giriş Yap</a>
        <a href="{{ route('register') }}" class="btn btn-primary btn-sm">Ücretsiz Başla</a>
      @endauth
    </div>
  </nav>

  {{-- ── Hero ────────────────────────────────────────────────────────── --}}
  <section class="hero-section">
    <div class="container py-3">
      <div class="row align-items-center g-5">
        <div class="col-lg-6">
          <span class="hero-badge mb-4 d-inline-block">
            <i class="ti tabler-sparkles me-1"></i>TEKNOFEST Hackathon 2026
          </span>
          <h1 class="hero-title mb-4">
            Paranızı<br>
            <span class="accent">Yapay Zeka</span><br>
            ile Yönetin
          </h1>
          <p class="hero-subtitle mb-5">
            Tüm banka hesaplarınızı tek platformda görün. Kişisel enflasyonunuzu ölçün.
            AI ajanlarıyla finansal kararlarınızı optimize edin.
          </p>
          <div class="d-flex gap-3 flex-wrap">
            @auth
              <a href="{{ route('dashboard') }}" class="btn btn-primary btn-lg px-5">
                <i class="ti tabler-layout-dashboard me-2"></i>Panele Git
              </a>
            @else
              <a href="{{ route('register') }}" class="btn btn-primary btn-lg px-5">
                <i class="ti tabler-rocket me-2"></i>Ücretsiz Başla
              </a>
              <a href="{{ route('login') }}" class="btn btn-outline-light btn-lg px-5">Giriş Yap</a>
            @endauth
          </div>
        </div>
        <div class="col-lg-6">
          <div class="row g-3">
            <div class="col-6">
              <div class="stat-pill">
                <span class="stat-icon">🏦</span>
                <div>
                  <div class="stat-val">8 Banka</div>
                  <div class="stat-label">Destekleniyor</div>
                </div>
              </div>
            </div>
            <div class="col-6">
              <div class="stat-pill">
                <span class="stat-icon">🤖</span>
                <div>
                  <div class="stat-val">5 AI Ajan</div>
                  <div class="stat-label">Paralel Çalışma</div>
                </div>
              </div>
            </div>
            <div class="col-6">
              <div class="stat-pill">
                <span class="stat-icon">📊</span>
                <div>
                  <div class="stat-val">TÜİK Verisi</div>
                  <div class="stat-label">Kişisel Enflasyon</div>
                </div>
              </div>
            </div>
            <div class="col-6">
              <div class="stat-pill">
                <span class="stat-icon">🎯</span>
                <div>
                  <div class="stat-val">Simülatör</div>
                  <div class="stat-label">Karar Desteği</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>

  {{-- ── Features Grid ───────────────────────────────────────────────── --}}
  <section class="features-section">
    <div class="container">
      <div class="text-center mb-6">
        <h2 class="fw-bold fs-1 mb-2">Her Şey Bir Arada</h2>
        <p class="text-muted fs-5">Finansal hayatınızı yönetmek için ihtiyacınız olan tüm araçlar</p>
      </div>

      <div class="row g-5">
        <div class="col-md-6 col-lg-4">
          <div class="card feature-card h-100 p-4">
            <div class="feature-icon-wrap bg-label-primary mb-4">
              <i class="ti tabler-building-bank text-primary"></i>
            </div>
            <h5 class="fw-bold mb-2">Banka Hesap Takibi</h5>
            <p class="text-muted small mb-0">
              Tüm banka hesaplarınızı, kredi kartlarınızı ve kredilerinizi tek ekranda görün. Anlık bakiye ve işlem senkronizasyonu.
            </p>
          </div>
        </div>

        <div class="col-md-6 col-lg-4">
          <div class="card feature-card h-100 p-4">
            <div class="feature-icon-wrap bg-label-warning mb-4">
              <i class="ti tabler-trending-up text-warning"></i>
            </div>
            <h5 class="fw-bold mb-2">Kişisel Enflasyon</h5>
            <p class="text-muted small mb-0">
              TÜİK kategorileriyle harcama profilinizi eşleştirerek gerçek kişisel enflasyonunuzu ölçün. TÜFE'den farklılaşmanızı görün.
            </p>
          </div>
        </div>

        <div class="col-md-6 col-lg-4">
          <div class="card feature-card h-100 p-4">
            <div class="feature-icon-wrap bg-label-success mb-4">
              <i class="ti tabler-adjustments-horizontal text-success"></i>
            </div>
            <h5 class="fw-bold mb-2">Karar Simülatörü</h5>
            <p class="text-muted small mb-0">
              "Gelirimi %20 artırsam ne olur?" Kaydırıcılarla farklı senaryolar oluşturun, bakiye projeksiyonunuzu ve sağlık skorunuzu görün.
            </p>
          </div>
        </div>

        <div class="col-md-6 col-lg-4">
          <div class="card feature-card h-100 p-4">
            <div class="feature-icon-wrap bg-label-danger mb-4">
              <i class="ti tabler-message-2-dollar text-danger"></i>
            </div>
            <h5 class="fw-bold mb-2">Pazarlık Ajanı</h5>
            <p class="text-muted small mb-0">
              Faiz indirimi veya kredi yeniden yapılandırma için Gemini Pro, finansal durumunuza özel resmi müzakere mektubu yazar.
            </p>
          </div>
        </div>

        <div class="col-md-6 col-lg-4">
          <div class="card feature-card h-100 p-4">
            <div class="feature-icon-wrap bg-label-info mb-4">
              <i class="ti tabler-receipt text-info"></i>
            </div>
            <h5 class="fw-bold mb-2">OCR Fiş Tarayıcı</h5>
            <p class="text-muted small mb-0">
              Fişinizi fotoğraflayın, Gemini Vision otomatik olarak tutarı, kategoriyi ve garanti bilgilerini çıkarsın.
            </p>
          </div>
        </div>

        <div class="col-md-6 col-lg-4">
          <div class="card feature-card h-100 p-4">
            <div class="feature-icon-wrap mb-4" style="background:rgba(206,159,252,.15);">
              <i class="ti tabler-robot" style="color:#ce9ffc;"></i>
            </div>
            <h5 class="fw-bold mb-2">Çok-Ajan Asistan</h5>
            <p class="text-muted small mb-0">
              5 uzman AI ajanı paralel çalışır: satın alma planlayıcı, bütçe danışmanı, anomali dedektörü ve daha fazlası.
            </p>
          </div>
        </div>
      </div>
    </div>
  </section>

  {{-- ── AI Section ──────────────────────────────────────────────────── --}}
  <section class="py-5 px-3 px-lg-0">
    <div class="container">
      <div class="ai-section p-5">
        <div class="row align-items-center g-5">
          <div class="col-lg-5">
            <span class="badge bg-label-primary mb-3">Yapay Zeka Mimarisi</span>
            <h2 class="fw-bold fs-2 mb-3">Paralel Çalışan<br>Uzman Ajanlar</h2>
            <p class="text-muted mb-4">
              Google Gemini 2.5 Pro & Flash tabanlı orkestratör, sorgunuzu analiz eder
              ve en uygun uzman ajanları paralel olarak tetikler. Saniyeler içinde kapsamlı finansal analiz.
            </p>
            <div class="d-flex flex-wrap gap-2">
              <span class="agent-chip"><i class="ti tabler-shopping-cart text-primary me-1"></i>Satın Alma Planlayıcı</span>
              <span class="agent-chip"><i class="ti tabler-chart-pie text-success me-1"></i>Bütçe Danışmanı</span>
              <span class="agent-chip"><i class="ti tabler-trending-up text-warning me-1"></i>Enflasyon Analisti</span>
              <span class="agent-chip"><i class="ti tabler-alert-triangle text-danger me-1"></i>Anomali Dedektörü</span>
              <span class="agent-chip"><i class="ti tabler-tag text-info me-1"></i>İşlem Sınıflandırıcı</span>
            </div>
          </div>
          <div class="col-lg-7">
            <div class="card">
              <div class="card-body p-4">
                <div class="d-flex gap-2 align-items-center mb-4 pb-3 border-bottom">
                  <div class="rounded-circle bg-label-primary d-flex align-items-center justify-content-center flex-shrink-0"
                       style="width:32px;height:32px;">
                    <i class="ti tabler-robot text-primary" style="font-size:14px;"></i>
                  </div>
                  <span class="fw-medium small">Paranette AI</span>
                  <span class="badge bg-label-success ms-auto">Çevrimiçi</span>
                </div>
                <div class="bg-label-primary rounded p-3 mb-3 small" style="max-width:80%;margin-left:auto;">
                  50.000 TL'ye iPhone almak istiyorum, uygun mu?
                </div>
                <div class="d-flex gap-2 mb-2">
                  <span class="badge bg-label-warning">Satın Alma Planlayıcı</span>
                  <span class="badge bg-label-info">Bütçe Danışmanı</span>
                </div>
                <div class="bg-light rounded p-3 small text-muted">
                  Mevcut aylık tasarruf oranınız <strong>%14.2</strong>. Bu alım 3.8 aylık birikiminize eşit.
                  Acil fonunuz minimum seviyenin üzerinde, ancak 12 taksit seçeneği ile <strong>%31</strong> daha az faiz yükü oluşur.
                  Alternatif: 6 ay bekleyip <strong>₺8.200</strong> tasarruf edin.
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>

  {{-- ── CTA ─────────────────────────────────────────────────────────── --}}
  <section class="py-5 px-3 px-lg-0">
    <div class="container">
      <div class="cta-section p-5 text-center">
        <h2 class="fw-bold fs-2 mb-3 text-white">Finansal Özgürlüğe Başlayın</h2>
        <p class="mb-5 opacity-90">Banka hesaplarınızı bağlayın, AI ajanlarınızı aktive edin, finansal hedeflerinize ulaşın.</p>
        @auth
          <a href="{{ route('dashboard') }}" class="btn btn-light btn-lg px-5 fw-bold">
            <i class="ti tabler-layout-dashboard me-2"></i>Panele Git
          </a>
        @else
          <div class="d-flex gap-3 justify-content-center flex-wrap">
            <a href="{{ route('register') }}" class="btn btn-light btn-lg px-5 fw-bold text-primary">
              <i class="ti tabler-rocket me-2"></i>Ücretsiz Başla
            </a>
            <a href="{{ route('login') }}" class="btn btn-outline-light btn-lg px-5">Giriş Yap</a>
          </div>
        @endauth
      </div>
    </div>
  </section>

  {{-- ── Footer ──────────────────────────────────────────────────────── --}}
  <footer class="py-4 text-center text-muted small border-top mt-4">
    <div class="container">
      <strong>Paranette</strong> &copy; {{ date('Y') }} &mdash; TEKNOFEST Hackathon 2026
      &nbsp;·&nbsp; Laravel 13 &middot; Gemini 2.5 &middot; Bootstrap 5
    </div>
  </footer>

  <script src="{{ asset('assets/vendor/libs/jquery/jquery.js') }}"></script>
  <script src="{{ asset('assets/vendor/js/bootstrap.js') }}"></script>
</body>
</html>
