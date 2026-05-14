<!doctype html>
<html
  lang="{{ str_replace('_', '-', app()->getLocale()) }}"
  class="layout-navbar-fixed layout-menu-fixed layout-compact"
  dir="ltr"
  data-skin="default"
  data-assets-path="{{ asset('assets/') }}"
  data-template="vertical-menu-template"
  data-bs-theme="light">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0" />
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>@isset($title){{ $title }} | @endisset{{ config('app.name') }}</title>

    <link rel="icon" type="image/x-icon" href="{{ asset('assets/img/favicon/favicon.ico') }}" />

    {{-- PWA --}}
    <link rel="manifest" href="/manifest.json">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="default">
    <meta name="apple-mobile-web-app-title" content="Paranette">
    <meta name="theme-color" content="#7367F0">

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Public+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,300;1,400;1,500;1,600;1,700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="{{ asset('assets/vendor/fonts/iconify-icons.css') }}" />
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/node-waves/node-waves.css') }}" />
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/pickr/pickr-themes.css') }}" />
    <link rel="stylesheet" href="{{ asset('assets/vendor/css/core.css') }}" />
    <link rel="stylesheet" href="{{ asset('assets/css/demo.css') }}" />
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/perfect-scrollbar/perfect-scrollbar.css') }}" />

    {{-- Global Paranette overrides (shared across all pages) --}}
    <style>
      /* ── Stat cards ─────────────────────────────────────────────────── */
      .stat-card { transition: transform .18s ease, box-shadow .18s ease; }
      .stat-card:hover { transform: translateY(-3px); box-shadow: 0 8px 24px rgba(115,103,240,.15) !important; }
      .stat-card .accent-bar { height: 3px; border-radius: 3px 3px 0 0; position: absolute; top: 0; left: 0; right: 0; }
      /* ── Gradient progress bars ──────────────────────────────────────── */
      .progress-bar-gradient-success { background: linear-gradient(90deg,#28C76F,#48DA89); }
      .progress-bar-gradient-warning { background: linear-gradient(90deg,#FF9F43,#FFBD60); }
      .progress-bar-gradient-danger  { background: linear-gradient(90deg,#EA5455,#F08182); }
      .progress-bar-gradient-primary { background: linear-gradient(90deg,#7367F0,#9E95F5); }
      .progress-bar-gradient-info    { background: linear-gradient(90deg,#00CFE8,#1CE7FF); }
      /* ── Dark-mode-safe bank logo box ────────────────────────────────── */
      .bank-logo-box {
        background: rgba(255,255,255,.9);
        border: 1px solid rgba(0,0,0,.1);
        transition: background .2s, border-color .2s;
      }
      [data-bs-theme="dark"] .bank-logo-box {
        background: rgba(255,255,255,.07) !important;
        border-color: rgba(255,255,255,.12) !important;
      }
      /* ── Dark-mode-safe detail box (loans/simulator) ─────────────────── */
      .detail-box {
        background: var(--bs-secondary-bg);
        border-radius: .375rem;
        padding: .5rem;
        text-align: center;
      }
      /* ── Table header consistent across pages ────────────────────────── */
      .paranette-thead th {
        background: rgba(115,103,240,.05);
        font-size: .72rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: .05em;
        color: var(--bs-secondary-color);
      }
      /* ── Avatar icon centering fix ───────────────────────────────────── */
      .avatar-initial {
        display: flex !important;
        align-items: center !important;
        justify-content: center !important;
      }
      .avatar-initial .icon-base {
        display: flex !important;
        line-height: 1 !important;
      }
    </style>

    @isset($pageCss){{ $pageCss }}@endisset

    <script src="{{ asset('assets/vendor/js/helpers.js') }}"></script>
    <script src="{{ asset('assets/vendor/js/template-customizer.js') }}"></script>
    <script src="{{ asset('assets/js/config.js') }}"></script>
  </head>

  <body>
    <div class="layout-wrapper layout-content-navbar">
      <div class="layout-container">

        <!-- Sidebar -->
        <aside id="layout-menu" class="layout-menu menu-vertical menu">
          <div class="app-brand demo">
            <a href="{{ route('dashboard') }}" class="app-brand-link">
              <span class="app-brand-logo demo">
                <span style="color:#28C76F">
                  <svg width="32" height="22" viewBox="0 0 32 22" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path fill-rule="evenodd" clip-rule="evenodd" d="M0.00172773 0V6.85398C0.00172773 6.85398 -0.133178 9.01207 1.98092 10.8388L13.6912 21.9964L19.7809 21.9181L18.8042 9.88248L16.4951 7.17289L9.23799 0H0.00172773Z" fill="currentColor"/>
                    <path opacity="0.06" fill-rule="evenodd" clip-rule="evenodd" d="M7.69824 16.4364L12.5199 3.23696L16.5541 7.25596L7.69824 16.4364Z" fill="#161616"/>
                    <path opacity="0.06" fill-rule="evenodd" clip-rule="evenodd" d="M8.07751 15.9175L13.9419 4.63989L16.5849 7.28475L8.07751 15.9175Z" fill="#161616"/>
                    <path fill-rule="evenodd" clip-rule="evenodd" d="M7.77295 16.3566L23.6563 0H32V6.88383C32 6.88383 31.8262 9.17836 30.6591 10.4057L19.7824 22H13.6938L7.77295 16.3566Z" fill="currentColor"/>
                  </svg>
                </span>
              </span>
              <span class="app-brand-text demo menu-text fw-bold ms-3">Paranette</span>
            </a>
            <a href="javascript:void(0);" class="layout-menu-toggle menu-link text-large ms-auto">
              <i class="icon-base ti menu-toggle-icon d-none d-xl-block"></i>
              <i class="icon-base ti tabler-x d-block d-xl-none"></i>
            </a>
          </div>

          <div class="menu-inner-shadow"></div>

          <ul class="menu-inner py-1">
            <li class="menu-item {{ request()->routeIs('dashboard') ? 'active' : '' }}">
              <a href="{{ route('dashboard') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-smart-home"></i>
                <div>Ana Sayfa</div>
              </a>
            </li>

            <li class="menu-header small"><span class="menu-header-text">Finansal Varlıklar</span></li>
            <li class="menu-item {{ request()->routeIs('bank-connections.*') ? 'active' : '' }}">
              <a href="{{ route('bank-connections.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-building-bank"></i>
                <div>Banka Hesapları</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('investments.*') ? 'active' : '' }}">
              <a href="{{ route('investments.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-chart-candle"></i>
                <div>Yatırımlar</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('cards.*') ? 'active' : '' }}">
              <a href="{{ route('cards.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-credit-card"></i>
                <div>Kredi Kartları</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('loans.*') ? 'active' : '' }}">
              <a href="{{ route('loans.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-file-invoice"></i>
                <div>Krediler</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('transactions.*') ? 'active' : '' }}">
              <a href="{{ route('transactions.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-arrows-exchange"></i>
                <div>İşlemler</div>
              </a>
            </li>

            <li class="menu-header small"><span class="menu-header-text">Takip & Analiz</span></li>
            <li class="menu-item {{ request()->routeIs('bills.*') ? 'active' : '' }}">
              <a href="{{ route('bills.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-file-dollar"></i>
                <div>Faturalar</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('subscriptions.*') ? 'active' : '' }}">
              <a href="{{ route('subscriptions.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-repeat"></i>
                <div>Abonelikler</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('budgets.*') ? 'active' : '' }}">
              <a href="{{ route('budgets.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-chart-pie"></i>
                <div>Bütçeler</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('goals.*') ? 'active' : '' }}">
              <a href="{{ route('goals.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-target"></i>
                <div>Hedefler</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('receipts.*') ? 'active' : '' }}">
              <a href="{{ route('receipts.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-receipt"></i>
                <div>Fişler & OCR</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('report.*') ? 'active' : '' }}">
              <a href="{{ route('report.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-report-analytics"></i>
                <div>Raporlar</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('calendar.*') ? 'active' : '' }}">
              <a href="{{ route('calendar.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-calendar-event"></i>
                <div>Ödeme Takvimi</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('personal-debts.*') ? 'active' : '' }}">
              <a href="{{ route('personal-debts.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-users-group"></i>
                <div>Kişisel Borçlar</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('fx-alerts.*') ? 'active' : '' }}">
              <a href="{{ route('fx-alerts.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-bell-ringing"></i>
                <div>Kur Alarmları</div>
              </a>
            </li>

            <li class="menu-header small"><span class="menu-header-text">Yapay Zeka</span></li>
            <li class="menu-item {{ request()->routeIs('agent-chat.*') ? 'active' : '' }}">
              <a href="{{ route('agent-chat.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-robot"></i>
                <div>Ajan Asistan</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('simulator.*') ? 'active' : '' }}">
              <a href="{{ route('simulator.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-adjustments-horizontal"></i>
                <div>Karar Simülatörü</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('negotiation.*') ? 'active' : '' }}">
              <a href="{{ route('negotiation.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-message-2-dollar"></i>
                <div>Pazarlık Ajanı</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('inflation.*') ? 'active' : '' }}">
              <a href="{{ route('inflation.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-trending-up"></i>
                <div>Kişisel Enflasyon</div>
              </a>
            </li>

            <li class="menu-header small"><span class="menu-header-text">Hesap</span></li>
            <li class="menu-item {{ request()->routeIs('profile.*') ? 'active' : '' }}">
              <a href="{{ route('profile.edit') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-user"></i>
                <div>Profil</div>
              </a>
            </li>
            <li class="menu-item">
              <a href="{{ route('logout') }}" class="menu-link"
                 onclick="event.preventDefault(); document.getElementById('sidebar-logout-form').submit();">
                <i class="menu-icon icon-base ti tabler-logout"></i>
                <div>Çıkış Yap</div>
              </a>
              <form id="sidebar-logout-form" action="{{ route('logout') }}" method="POST" class="d-none">@csrf</form>
            </li>
          </ul>
        </aside>
        <!-- / Sidebar -->

        <!-- Layout page -->
        <div class="layout-page">
          <!-- Navbar -->
          <nav class="layout-navbar container-xxl navbar-detached navbar navbar-expand-xl align-items-center bg-navbar-theme" id="layout-navbar">
            <div class="layout-menu-toggle navbar-nav align-items-xl-center me-3 me-xl-0 d-xl-none">
              <a class="nav-item nav-link px-0 me-xl-6" href="javascript:void(0)">
                <i class="icon-base ti tabler-menu-2 icon-md"></i>
              </a>
            </div>
            <div class="navbar-nav-right d-flex align-items-center justify-content-end w-100" id="navbar-collapse">
              <ul class="navbar-nav flex-row align-items-center ms-auto">

                <!-- Theme switcher -->
                <li class="nav-item me-2 me-xl-1">
                  <button id="theme-toggle-btn"
                          class="btn btn-icon btn-text-secondary rounded-pill"
                          title="Temayı değiştir"
                          onclick="window.toggleAppTheme()">
                    <i id="theme-icon" class="icon-base ti tabler-moon icon-22px text-heading"></i>
                  </button>
                </li>

                <!-- Notification bell -->
                @php $alertCount = isset($navAlerts) ? count($navAlerts) : 0; @endphp
                <li class="nav-item dropdown me-2 me-xl-1">
                  <a class="nav-link btn btn-icon btn-text-secondary rounded-pill position-relative"
                     href="javascript:void(0);" data-bs-toggle="dropdown" aria-expanded="false">
                    <i class="icon-base ti tabler-bell icon-22px text-heading"></i>
                    @if($alertCount > 0)
                      <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger"
                            style="font-size:.6rem;padding:.2em .45em;">{{ $alertCount }}</span>
                    @endif
                  </a>
                  <ul class="dropdown-menu dropdown-menu-end p-0" style="min-width:22rem;max-height:400px;overflow-y:auto;">
                    <li class="border-bottom px-4 py-3 d-flex align-items-center">
                      <h6 class="mb-0 me-auto fw-semibold">Bildirimler</h6>
                      @if($alertCount > 0)
                        <span class="badge bg-label-danger">{{ $alertCount }} yeni</span>
                      @endif
                    </li>
                    @if($alertCount > 0)
                      @foreach($navAlerts as $alert)
                      <li>
                        <a class="dropdown-item px-4 py-3 d-flex align-items-start gap-3 border-bottom"
                           href="{{ $alert['link'] }}">
                          <span class="avatar avatar-sm flex-shrink-0">
                            <span class="avatar-initial rounded bg-label-{{ $alert['type'] }}">
                              <i class="icon-base ti {{ $alert['icon'] }} icon-18px"></i>
                            </span>
                          </span>
                          <div class="overflow-hidden">
                            <div class="fw-medium small text-{{ $alert['type'] }}">{{ $alert['title'] }}</div>
                            <small class="text-muted text-truncate d-block">{{ $alert['body'] }}</small>
                          </div>
                        </a>
                      </li>
                      @endforeach
                    @else
                      <li class="text-center py-4 text-muted small">
                        <i class="icon-base ti tabler-bell-off d-block mb-2 icon-24px"></i>
                        Yeni bildirim yok
                      </li>
                    @endif
                  </ul>
                </li>

                <!-- User dropdown -->
                @php
                  $authUser   = auth()->user();
                  $initials   = collect(explode(' ', $authUser?->name ?? 'U'))
                                  ->filter()->map(fn($w) => strtoupper($w[0]))->take(2)->implode('');
                @endphp
                <li class="nav-item navbar-dropdown dropdown-user dropdown">
                  <a class="nav-link dropdown-toggle hide-arrow p-0" href="javascript:void(0);" data-bs-toggle="dropdown">
                    <div class="avatar avatar-online">
                      <span class="avatar-initial rounded-circle bg-primary text-white fw-bold"
                            style="width:38px;height:38px;display:flex;align-items:center;justify-content:center;font-size:14px;">
                        {{ $initials }}
                      </span>
                    </div>
                  </a>
                  <ul class="dropdown-menu dropdown-menu-end">
                    <li>
                      <a class="dropdown-item mt-1" href="{{ route('profile.edit') }}">
                        <div class="d-flex align-items-center">
                          <div class="flex-shrink-0 me-2">
                            <span class="avatar-initial rounded-circle bg-primary text-white fw-bold d-flex align-items-center justify-content-center"
                                  style="width:34px;height:34px;font-size:13px;">
                              {{ $initials }}
                            </span>
                          </div>
                          <div class="flex-grow-1">
                            <span class="fw-medium d-block small">{{ $authUser?->name ?? '' }}</span>
                            <small class="text-muted">{{ $authUser?->email ?? '' }}</small>
                          </div>
                        </div>
                      </a>
                    </li>
                    <li><div class="dropdown-divider my-1"></div></li>
                    <li>
                      <a class="dropdown-item" href="{{ route('logout') }}"
                         onclick="event.preventDefault(); document.getElementById('nav-logout-form').submit();">
                        <i class="icon-base ti tabler-logout me-2 icon-22px"></i> Çıkış Yap
                      </a>
                      <form id="nav-logout-form" action="{{ route('logout') }}" method="POST" class="d-none">@csrf</form>
                    </li>
                  </ul>
                </li>
              </ul>
            </div>
          </nav>
          <!-- / Navbar -->

          <!-- Content wrapper -->
          <div class="content-wrapper">
            <div class="container-xxl flex-grow-1 container-p-y">
              {{ $slot }}
            </div>

            <footer class="content-footer footer bg-footer-theme">
              <div class="container-xxl">
                <div class="footer-container d-flex align-items-center justify-content-between py-4 flex-md-row flex-column">
                  <div class="text-body">&copy; {{ date('Y') }}, <strong>Paranette</strong> &mdash; BTK Akademi Hackathon 2026</div>
                </div>
              </div>
            </footer>

            <div class="content-backdrop fade"></div>
          </div>
          <!-- / Content wrapper -->
        </div>
        <!-- / Layout page -->
      </div>

      <div class="layout-overlay layout-menu-toggle"></div>
      <div class="drag-target"></div>
    </div>

    <!-- Core JS -->
    <script src="{{ asset('assets/vendor/libs/jquery/jquery.js') }}"></script>
    <script src="{{ asset('assets/vendor/libs/popper/popper.js') }}"></script>
    <script src="{{ asset('assets/vendor/js/bootstrap.js') }}"></script>
    <script src="{{ asset('assets/vendor/libs/node-waves/node-waves.js') }}"></script>
    <script src="{{ asset('assets/vendor/libs/pickr/pickr.js') }}"></script>
    <script src="{{ asset('assets/vendor/libs/perfect-scrollbar/perfect-scrollbar.js') }}"></script>
    <script src="{{ asset('assets/vendor/libs/hammer/hammer.js') }}"></script>
    <script src="{{ asset('assets/vendor/libs/i18n/i18n.js') }}"></script>
    <script src="{{ asset('assets/vendor/js/menu.js') }}"></script>
    <script src="{{ asset('assets/js/main.js') }}"></script>

    <!-- Theme toggle logic -->
    <script>
    (function () {
      var STORAGE_KEY = 'paranette-theme';
      var html = document.documentElement;

      function getTheme() {
        return localStorage.getItem(STORAGE_KEY) || 'light';
      }

      function applyTheme(theme) {
        html.setAttribute('data-bs-theme', theme);
        localStorage.setItem(STORAGE_KEY, theme);
        var icon = document.getElementById('theme-icon');
        if (icon) {
          icon.className = theme === 'dark'
            ? 'icon-base ti tabler-sun icon-22px text-heading'
            : 'icon-base ti tabler-moon icon-22px text-heading';
        }
        if (typeof window.templateCustomizer !== 'undefined') {
          window.templateCustomizer.changeTheme(theme);
        }
      }

      window.toggleAppTheme = function () {
        applyTheme(getTheme() === 'dark' ? 'light' : 'dark');
      };

      // Apply persisted theme immediately to avoid flash
      applyTheme(getTheme());
    })();
    </script>

    {{-- PWA Service Worker --}}
    <script>
    if ('serviceWorker' in navigator) {
      window.addEventListener('load', () => {
        navigator.serviceWorker.register('/sw.js').catch(() => {});
      });
    }
    </script>

    @isset($pageJs){{ $pageJs }}@endisset
  </body>
</html>
