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

    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Public+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,300;1,400;1,500;1,600;1,700&display=swap" rel="stylesheet" />

    <link rel="stylesheet" href="{{ asset('assets/vendor/fonts/iconify-icons.css') }}" />
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/node-waves/node-waves.css') }}" />
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/pickr/pickr-themes.css') }}" />
    <link rel="stylesheet" href="{{ asset('assets/vendor/css/core.css') }}" />
    <link rel="stylesheet" href="{{ asset('assets/css/demo.css') }}" />
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/perfect-scrollbar/perfect-scrollbar.css') }}" />

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
            <li class="menu-item {{ request()->routeIs('cards.*') ? 'active' : '' }}">
              <a href="#" class="menu-link">
                <i class="menu-icon icon-base ti tabler-credit-card"></i>
                <div>Kredi Kartları</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('loans.*') ? 'active' : '' }}">
              <a href="#" class="menu-link">
                <i class="menu-icon icon-base ti tabler-file-invoice"></i>
                <div>Krediler</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('transactions.*') ? 'active' : '' }}">
              <a href="#" class="menu-link">
                <i class="menu-icon icon-base ti tabler-arrows-exchange"></i>
                <div>İşlemler</div>
              </a>
            </li>

            <li class="menu-header small"><span class="menu-header-text">Takip & Analiz</span></li>
            <li class="menu-item {{ request()->routeIs('subscriptions.*') ? 'active' : '' }}">
              <a href="#" class="menu-link">
                <i class="menu-icon icon-base ti tabler-repeat"></i>
                <div>Abonelikler</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('budgets.*') ? 'active' : '' }}">
              <a href="#" class="menu-link">
                <i class="menu-icon icon-base ti tabler-chart-pie"></i>
                <div>Bütçeler</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('goals.*') ? 'active' : '' }}">
              <a href="#" class="menu-link">
                <i class="menu-icon icon-base ti tabler-target"></i>
                <div>Hedefler</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('receipts.*') ? 'active' : '' }}">
              <a href="#" class="menu-link">
                <i class="menu-icon icon-base ti tabler-receipt"></i>
                <div>Fişler & OCR</div>
              </a>
            </li>

            <li class="menu-header small"><span class="menu-header-text">Yapay Zeka</span></li>
            <li class="menu-item {{ request()->routeIs('agent-chat.*') ? 'active' : '' }}">
              <a href="{{ route('agent-chat.index') }}" class="menu-link">
                <i class="menu-icon icon-base ti tabler-robot"></i>
                <div>Ajan Asistan</div>
              </a>
            </li>
            <li class="menu-item {{ request()->routeIs('inflation.*') ? 'active' : '' }}">
              <a href="#" class="menu-link">
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
                <!-- User dropdown -->
                <li class="nav-item navbar-dropdown dropdown-user dropdown">
                  <a class="nav-link dropdown-toggle hide-arrow p-0" href="javascript:void(0);" data-bs-toggle="dropdown">
                    <div class="avatar avatar-online">
                      <img src="{{ asset('assets/img/avatars/1.png') }}" class="h-auto rounded-circle" alt="" />
                    </div>
                  </a>
                  <ul class="dropdown-menu dropdown-menu-end">
                    <li>
                      <a class="dropdown-item mt-1" href="{{ route('profile.edit') }}">
                        <div class="d-flex align-items-center">
                          <div class="flex-shrink-0 me-2">
                            <div class="avatar"><img src="{{ asset('assets/img/avatars/1.png') }}" class="h-auto rounded-circle" alt="" /></div>
                          </div>
                          <div class="flex-grow-1">
                            <span class="fw-medium d-block small">{{ auth()->user()->name ?? '' }}</span>
                            <small class="text-muted">{{ auth()->user()->email ?? '' }}</small>
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
                  <div class="text-body">&copy; {{ date('Y') }}, <strong>Paranette</strong> &mdash; TEKNOFEST Hackathon 2026</div>
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

    @isset($pageJs){{ $pageJs }}@endisset
  </body>
</html>
