<x-app-layout>
  <x-slot name="title">Dashboard</x-slot>

  <x-slot name="pageCss">
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/apex-charts/apex-charts.css') }}" />
    <style>
      /* ── Net Worth Banner ─────────────────────────────── */
      .net-worth-banner {
        background: linear-gradient(135deg, #7367F0 0%, #CE9FFC 100%);
        border-radius: .75rem;
        color: #fff;
        position: relative;
        overflow: hidden;
      }
      .net-worth-banner::before {
        content: '';
        position: absolute;
        top: -60px; right: -60px;
        width: 220px; height: 220px;
        background: rgba(255,255,255,.08);
        border-radius: 50%;
        pointer-events: none;
      }
      .net-worth-banner::after {
        content: '';
        position: absolute;
        bottom: -80px; left: 40%;
        width: 260px; height: 260px;
        background: rgba(255,255,255,.05);
        border-radius: 50%;
        pointer-events: none;
      }
      /* ── Stat card accent bar ─────────────────────────── */
      .stat-card { transition: transform .18s ease, box-shadow .18s ease; }
      .stat-card:hover { transform: translateY(-3px); box-shadow: 0 8px 24px rgba(115,103,240,.15) !important; }
      .stat-card .accent-bar {
        height: 3px;
        border-radius: 3px 3px 0 0;
        position: absolute;
        top: 0; left: 0; right: 0;
      }
      /* ── Circular progress for health score ───────────── */
      .circle-progress {
        position: relative;
        display: inline-flex;
        align-items: center;
        justify-content: center;
      }
      .circle-progress svg { transform: rotate(-90deg); }
      .circle-progress .cp-text {
        position: absolute;
        font-weight: 700;
        font-size: 1.1rem;
        line-height: 1;
      }
      /* ── Goal progress card ───────────────────────────── */
      .goal-card { transition: box-shadow .18s ease; }
      .goal-card:hover { box-shadow: 0 4px 18px rgba(0,0,0,.10) !important; }
      /* ── Budget bar labels ────────────────────────────── */
      .budget-label { font-size: .78rem; }
      /* ── Insight list ─────────────────────────────────── */
      .insight-item { transition: background .15s; }
      .insight-item:hover { background: rgba(115,103,240,.04); }
      /* ── Trend badge ──────────────────────────────────── */
      .trend-up   { color: #28C76F; }
      .trend-down { color: #EA5455; }
      /* ── Gradient progress bars ───────────────────────── */
      .progress-bar-gradient-success { background: linear-gradient(90deg,#28C76F,#48DA89); }
      .progress-bar-gradient-warning { background: linear-gradient(90deg,#FF9F43,#FFBD60); }
      .progress-bar-gradient-danger  { background: linear-gradient(90deg,#EA5455,#F08182); }
      .progress-bar-gradient-primary { background: linear-gradient(90deg,#7367F0,#9E95F5); }
      .progress-bar-gradient-info    { background: linear-gradient(90deg,#00CFE8,#1CE7FF); }
      /* ── Inflation card — dark mode aware ────────────── */
      .inflation-card {
        background: linear-gradient(135deg, #fff8ee 0%, #fff3e0 100%) !important;
      }
      [data-bs-theme="dark"] .inflation-card {
        background: rgba(255, 159, 67, 0.08) !important;
        border: 1px solid rgba(255, 159, 67, 0.18) !important;
      }
    </style>
  </x-slot>

  {{-- ══ ONBOARDING CARD — sadece banka bağlantısı yoksa göster ══════════ --}}
  @if($summary['total_balance'] == 0 && $bankConnections->count() == 0)
  <div class="card mb-5 border-0 shadow-sm" style="background: linear-gradient(135deg, #7367F0 0%, #9E95F5 50%, #CE9FFC 100%);">
    <div class="card-body p-5">
      <div class="row align-items-center g-4">
        <div class="col-auto d-none d-md-flex">
          <div class="avatar avatar-xl">
            <span class="avatar-initial rounded-circle" style="background: rgba(255,255,255,.2); font-size: 2rem;">
              <i class="icon-base ti tabler-rocket icon-40px text-white"></i>
            </span>
          </div>
        </div>
        <div class="col text-white">
          <h3 class="fw-bold text-white mb-1">Hoş geldiniz! Paranette'e başlayın</h3>
          <p class="mb-3 opacity-85" style="font-size: 1rem;">
            Finansal verilerinizi görmek için bir banka bağlantısı ekleyin ya da demo veri oluşturarak uygulamayı keşfedin.
          </p>
          <div class="d-flex flex-wrap gap-3">
            <a href="{{ route('bank-connections.create') }}" class="btn btn-light fw-semibold">
              <i class="icon-base ti tabler-building-bank me-2"></i>Banka Bağla
            </a>
            <a href="{{ route('demo-data.index') }}" class="btn fw-semibold" style="background: rgba(255,255,255,.18); color: #fff; border: 1.5px solid rgba(255,255,255,.45);">
              <i class="icon-base ti tabler-wand me-2"></i>Demo Veri Oluştur
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
  @endif

  {{-- ══ Page Header ═══════════════════════════════════════════════════════ --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Hoş geldin, {{ explode(' ', auth()->user()->name)[0] }} 👋</h4>
      <p class="text-muted mb-0 small">
        {{ now()->translatedFormat('d F Y') }} · Finansal durumun tek bakışta
      </p>
    </div>
    <a href="{{ route('report.monthly') }}" class="btn btn-outline-primary btn-sm" target="_blank">
      <i class="icon-base ti tabler-file-type-pdf me-1"></i>Aylık Rapor PDF
    </a>
  </div>

  {{-- ══ NET WORTH BANNER ══════════════════════════════════════════════════ --}}
  <div class="net-worth-banner p-5 mb-6">
    <div class="row g-4 align-items-center">
      {{-- Net Worth --}}
      <div class="col-sm-4 col-xl-3 text-center text-sm-start">
        <div class="small mb-1 opacity-75">Net Varlık</div>
        <div class="display-6 fw-bold mb-1">
          ₺{{ number_format($summary['net_worth'] ?? 0, 0, ',', '.') }}
        </div>
        <div class="small opacity-75">Bakiye − Toplam Borç</div>
      </div>
      <div class="col-sm-4 col-xl-3 text-center">
        <div class="small mb-1 opacity-75">Toplam Bakiye</div>
        <div class="h3 fw-bold mb-1">₺{{ number_format($summary['total_balance'], 0, ',', '.') }}</div>
        <div class="small opacity-75">
          {{ $bankConnections->sum(fn ($c) => $c->accounts->count()) }} banka hesabı
        </div>
      </div>
      <div class="col-sm-4 col-xl-3 text-center">
        <div class="row g-3">
          <div class="col-6">
            <div class="small opacity-75 mb-1">Kart Borcu</div>
            <div class="fw-bold">₺{{ number_format($summary['total_card_debt'], 0, ',', '.') }}</div>
          </div>
          <div class="col-6">
            <div class="small opacity-75 mb-1">Kredi</div>
            <div class="fw-bold">₺{{ number_format($summary['total_loan'], 0, ',', '.') }}</div>
          </div>
        </div>
      </div>
      <div class="col-xl-3 text-center">
        @if($summary['health_score'])
          @php
            $hs      = $summary['health_score'];
            $hsColor = $hs >= 70 ? '#28C76F' : ($hs >= 40 ? '#FF9F43' : '#EA5455');
            $circ    = round($hs * 2.827); // circumference ~282.7
          @endphp
          <div class="d-flex flex-column align-items-center cursor-pointer" data-bs-toggle="modal" data-bs-target="#healthModal">
            <div class="circle-progress mb-1" style="width:72px;height:72px;">
              <svg width="72" height="72" viewBox="0 0 72 72">
                <circle cx="36" cy="36" r="30" fill="none" stroke="rgba(255,255,255,.2)" stroke-width="6"/>
                <circle cx="36" cy="36" r="30" fill="none"
                        stroke="{{ $hsColor }}" stroke-width="6"
                        stroke-linecap="round"
                        stroke-dasharray="{{ $circ }}, 282.7"
                        style="transition: stroke-dasharray .6s ease;"/>
              </svg>
              <span class="cp-text text-white">{{ $hs }}</span>
            </div>
            <div class="small opacity-75">Sağlık Skoru</div>
          </div>
        @else
          <div class="text-center opacity-75">
            <div class="d-flex justify-content-center mb-1">
              <i class="icon-base ti tabler-heart-rate-monitor icon-32px"></i>
            </div>
            <div class="small">Skor hesaplanıyor…</div>
          </div>
        @endif
      </div>
    </div>
  </div>

  {{-- ══ ROW 1 — Quick Stat Cards ══════════════════════════════════════════ --}}
  <div class="row row-cols-2 row-cols-xl-4 g-4 mb-6">

    {{-- Aylık Gelir --}}
    <div class="col">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-success"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Aylık Gelir</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">
                ₺{{ number_format(auth()->user()->monthly_income ?? 0, 0, ',', '.') }}
              </div>
              <div class="d-flex align-items-center gap-1 mt-1">
                <i class="icon-base ti tabler-arrow-up-right trend-up icon-14px"></i>
                <span class="small trend-up">Sabit gelir</span>
              </div>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-success">
                <i class="icon-base ti tabler-wallet icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Kart Borcu --}}
    <div class="col">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-danger"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Kart Borcu</span>
              <div class="h5 fw-bold mt-1 mb-0 @if($summary['total_card_debt'] > 0) text-danger @else text-heading @endif">
                ₺{{ number_format($summary['total_card_debt'], 0, ',', '.') }}
              </div>
              <span class="small text-muted">Tüm kredi kartları</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-danger">
                <i class="icon-base ti tabler-credit-card icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Aktif Kredi --}}
    <div class="col">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-warning"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Aktif Kredi</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">
                ₺{{ number_format($summary['total_loan'], 0, ',', '.') }}
              </div>
              <span class="small text-muted">Kalan bakiye</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-warning">
                <i class="icon-base ti tabler-file-invoice icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Abonelik Maliyeti --}}
    <div class="col">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-info"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Dijital Abonelik</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">
                ₺{{ number_format($monthlySubscriptionCost, 0, ',', '.') }}
              </div>
              <a href="{{ route('subscriptions.index') }}" class="small text-info">Abonelikleri Yönet →</a>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-info">
                <i class="icon-base ti tabler-device-tv icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- ══ SMART ALERTS ══════════════════════════════════════════════════════ --}}
  @if(count($smartAlerts) > 0)
  <div class="row g-3 mb-6">
    @foreach($smartAlerts as $alert)
    <div class="col-md-6 col-xl-3">
      <div class="card h-100 border-start border-4 border-{{ $alert['type'] }} shadow-none">
        <div class="card-body py-3 d-flex align-items-center gap-3">
          <div class="avatar flex-shrink-0">
            <span class="avatar-initial rounded bg-label-{{ $alert['type'] }}">
              <i class="icon-base ti {{ $alert['icon'] }} icon-20px"></i>
            </span>
          </div>
          <div class="flex-grow-1 overflow-hidden">
            <div class="fw-semibold small text-{{ $alert['type'] }} text-truncate">{{ $alert['title'] }}</div>
            <div class="text-muted" style="font-size:.74rem; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">{{ $alert['body'] }}</div>
          </div>
          <a href="{{ $alert['link'] }}" class="text-{{ $alert['type'] }} flex-shrink-0">
            <i class="icon-base ti tabler-chevron-right icon-16px"></i>
          </a>
        </div>
      </div>
    </div>
    @endforeach
  </div>
  @endif

  {{-- ══ KİŞİSEL ENFLASYON ══════════════════════════════════════════════════ --}}
  <div class="card mb-6 border-0 shadow-sm inflation-card">
    <div class="card-body">
      <div class="row align-items-center g-4">
        <div class="col-auto d-none d-lg-flex">
          <div class="avatar avatar-lg">
            <span class="avatar-initial rounded-circle bg-label-warning">
              <i class="icon-base ti tabler-flame icon-32px text-warning"></i>
            </span>
          </div>
        </div>
        <div class="col-md-5">
          <div class="d-flex align-items-center gap-2 mb-2">
            <h5 class="fw-bold mb-0">Kişisel Enflasyonun</h5>
            <span class="badge bg-label-warning">TÜİK Verisi</span>
          </div>
          @if($personalInflation['personal_rate'] !== null)
            <div class="d-flex align-items-end gap-3 mb-2">
              <div class="display-5 fw-bold text-danger lh-1">
                %{{ number_format($personalInflation['personal_rate'], 1, ',', '.') }}
              </div>
              <div class="pb-1">
                <div class="small text-muted">TÜFE: <strong class="text-warning">%{{ number_format($personalInflation['tufe_rate'], 2, ',', '.') }}</strong></div>
                @if($personalInflation['diff'] !== null)
                  <div class="small fw-semibold {{ $personalInflation['diff'] > 0 ? 'text-danger' : 'text-success' }}">
                    {{ $personalInflation['diff'] > 0 ? '▲ +' : '▼ ' }}%{{ number_format(abs($personalInflation['diff']), 2, ',', '.') }} fark
                  </div>
                @endif
              </div>
            </div>
            <p class="text-muted small mb-0">
              @if($personalInflation['diff'] !== null && $personalInflation['diff'] > 0)
                Genel enflasyonun <strong>{{ number_format($personalInflation['diff'], 1, ',', '.') }} puan üstünde</strong> etkileniyorsun.
              @elseif($personalInflation['diff'] !== null && $personalInflation['diff'] <= 0)
                Genel enflasyonun altında etkileniyorsun — finansal kararların etkili.
              @endif
            </p>
          @else
            <div class="h3 fw-bold text-warning mb-1">
              TÜFE: %{{ number_format($personalInflation['tufe_rate'], 2, ',', '.') }}
            </div>
            <p class="text-muted small mb-0">
              Harcamalarını kategorize ettikten sonra kişisel enflasyonun hesaplanacak.
            </p>
          @endif
        </div>
        @if($personalInflation['personal_rate'] !== null && count($personalInflation['breakdown']) > 0)
        <div class="col-md">
          <div class="small fw-semibold text-muted mb-2 text-uppercase" style="letter-spacing:.05em;">En Etkili 4 Kategori</div>
          @foreach(array_slice($personalInflation['breakdown'], 0, 4) as $b)
          <div class="d-flex align-items-center gap-2 mb-2">
            <span class="text-muted" style="width:120px;font-size:.78rem;flex-shrink:0;">{{ $b['category'] }}</span>
            <div class="flex-grow-1 progress" style="height:6px;border-radius:6px;">
              <div class="progress-bar bg-warning" style="width:{{ min(100, $b['weight_pct']) }}%;border-radius:6px;"></div>
            </div>
            <span style="font-size:.78rem;width:42px;text-align:right;" class="text-muted">%{{ number_format($b['weight_pct'], 0) }}</span>
            <span style="font-size:.78rem;width:50px;text-align:right;" class="fw-semibold text-danger">%{{ number_format($b['tuik_rate'], 1, ',', '.') }}</span>
          </div>
          @endforeach
        </div>
        @else
        <div class="col-md">
          <div class="small fw-semibold text-muted mb-2 text-uppercase" style="letter-spacing:.05em;">Güncel TÜİK Kategorileri</div>
          @php
            $tuikSample = ['Konut'=>59.08,'Eğitim'=>75.33,'Lokanta'=>43.51,'Alkol/Sigara'=>42.30,'Genel TÜFE'=>37.86];
          @endphp
          @foreach($tuikSample as $cat => $rate)
          <div class="d-flex align-items-center gap-2 mb-2">
            <span class="text-muted" style="width:120px;font-size:.78rem;flex-shrink:0;">{{ $cat }}</span>
            <div class="flex-grow-1 progress" style="height:6px;border-radius:6px;">
              <div class="progress-bar bg-warning" style="width:{{ min(100, $rate) }}%;border-radius:6px;"></div>
            </div>
            <span style="font-size:.78rem;width:50px;text-align:right;" class="fw-semibold text-danger">%{{ number_format($rate, 2, ',', '.') }}</span>
          </div>
          @endforeach
        </div>
        @endif
      </div>
    </div>
  </div>

  {{-- ══ ROW — Nakit Akışı + Kategori Donut ════════════════════════════════ --}}
  <div class="row g-5 mb-6">
    <div class="col-xl-8">
      <div class="card h-100 shadow-sm">
        <div class="card-header d-flex align-items-center justify-content-between">
          <div>
            <h5 class="card-title mb-0">Gelir & Gider Trendi</h5>
            <small class="text-muted">Son 6 ay · çubuk karşılaştırma + net çizgi</small>
          </div>
          <a href="{{ route('report.index') }}" class="btn btn-sm btn-outline-secondary">
            <i class="icon-base ti tabler-report-analytics me-1"></i>Tüm Rapor
          </a>
        </div>
        <div class="card-body pt-2">
          <div id="cashFlowChart"></div>
        </div>
      </div>
    </div>
    <div class="col-xl-4">
      <div class="card h-100 shadow-sm">
        <div class="card-header d-flex align-items-center justify-content-between">
          <div>
            <h5 class="card-title mb-0">Harcama Dağılımı</h5>
            <small class="text-muted">Son 30 gün · Kategoriye göre</small>
          </div>
        </div>
        <div class="card-body d-flex align-items-center justify-content-center pt-2">
          @if(count($categorySpend) > 0)
            <div id="categoryDonutChart" class="w-100"></div>
          @else
            <div class="text-center py-5">
              <div class="d-flex justify-content-center mb-3">
                <i class="icon-base ti tabler-chart-donut-3 icon-48px text-muted"></i>
              </div>
              <p class="text-muted small mb-2">Henüz kategori verisi yok.</p>
              <a href="{{ route('demo-data.index') }}" class="btn btn-sm btn-outline-primary">
                <i class="icon-base ti tabler-database-plus me-1"></i>Demo veri oluştur
              </a>
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- ══ BÜTÇE DURUMU ═══════════════════════════════════════════════════════ --}}
  @if(count($budgetSummary) > 0)
  <div class="card mb-6 shadow-sm">
    <div class="card-header d-flex align-items-center justify-content-between">
      <div>
        <h5 class="card-title mb-0">
          <i class="icon-base ti tabler-chart-pie me-2 text-primary"></i>Bu Ay Bütçe Durumu
        </h5>
        <small class="text-muted">{{ now()->translatedFormat('F Y') }}</small>
      </div>
      <a href="{{ route('budgets.index') }}" class="btn btn-sm btn-outline-secondary">
        <i class="icon-base ti tabler-settings me-1"></i>Bütçeleri Yönet
      </a>
    </div>
    <div class="card-body">
      <div class="row g-4">
        @foreach($budgetSummary as $b)
        @php
          $barClass = $b['over_budget'] ? 'progress-bar-gradient-danger' : ($b['pct'] >= 80 ? 'progress-bar-gradient-warning' : 'progress-bar-gradient-success');
        @endphp
        <div class="col-sm-6 col-xl-3">
          <div class="d-flex justify-content-between align-items-center mb-2">
            <span class="fw-semibold small text-heading">{{ $b['name'] }}</span>
            @if($b['over_budget'])
              <span class="badge bg-label-danger" style="font-size:.7rem;">Aşıldı!</span>
            @else
              <span class="badge bg-label-{{ $b['pct'] >= 80 ? 'warning' : 'success' }}" style="font-size:.7rem;">%{{ $b['pct'] }}</span>
            @endif
          </div>
          <div class="progress mb-2" style="height:8px;border-radius:8px;background:rgba(115,103,240,.08);">
            <div class="{{ $barClass }}"
                 style="width:{{ min(100, $b['pct']) }}%;height:100%;border-radius:8px;"></div>
          </div>
          <div class="d-flex justify-content-between budget-label">
            <span class="text-muted">₺{{ number_format($b['spent'], 0, ',', '.') }} harcandı</span>
            <span class="{{ $b['over_budget'] ? 'text-danger fw-semibold' : 'text-muted' }}">
              / ₺{{ number_format($b['amount'], 0, ',', '.') }}
            </span>
          </div>
        </div>
        @endforeach
      </div>
    </div>
  </div>
  @endif

  {{-- ══ HEDEFLER ════════════════════════════════════════════════════════════ --}}
  @if($goalsSummary->isNotEmpty())
  <div class="card mb-6 shadow-sm">
    <div class="card-header d-flex align-items-center justify-content-between">
      <div>
        <h5 class="card-title mb-0">
          <i class="icon-base ti tabler-target me-2 text-success"></i>Finansal Hedefler
        </h5>
        <small class="text-muted">{{ $goalsSummary->count() }} aktif hedef</small>
      </div>
      <a href="{{ route('goals.index') }}" class="btn btn-sm btn-outline-secondary">
        <i class="icon-base ti tabler-plus me-1"></i>Hedef Yönet
      </a>
    </div>
    <div class="card-body">
      <div class="row g-4">
        @php
          $goalIcons = [
            0 => ['icon' => 'tabler-beach', 'color' => 'warning'],
            1 => ['icon' => 'tabler-shield-check', 'color' => 'success'],
            2 => ['icon' => 'tabler-device-laptop', 'color' => 'info'],
            3 => ['icon' => 'tabler-home-2', 'color' => 'primary'],
          ];
        @endphp
        @foreach($goalsSummary as $i => $goal)
        @php
          $gi = $goalIcons[$i % 4];
          $pct = $goal['pct'];
          $barClass = $pct >= 75 ? 'progress-bar-gradient-success' : ($pct >= 40 ? 'progress-bar-gradient-primary' : 'progress-bar-gradient-info');
        @endphp
        <div class="col-sm-6 col-xl-3">
          <div class="card goal-card border h-100 mb-0">
            <div class="card-body p-3">
              <div class="d-flex align-items-center gap-2 mb-3">
                <div class="avatar avatar-sm flex-shrink-0">
                  <span class="avatar-initial rounded bg-label-{{ $gi['color'] }}">
                    <i class="icon-base ti {{ $gi['icon'] }} icon-16px"></i>
                  </span>
                </div>
                <div class="fw-semibold small text-heading overflow-hidden text-truncate">{{ $goal['name'] }}</div>
              </div>
              <div class="d-flex justify-content-between align-items-end mb-1">
                <div>
                  <div class="h5 fw-bold mb-0 text-heading">₺{{ number_format($goal['current_amount'], 0, ',', '.') }}</div>
                  <div class="text-muted" style="font-size:.73rem;">/ ₺{{ number_format($goal['target_amount'], 0, ',', '.') }}</div>
                </div>
                <span class="badge bg-label-{{ $gi['color'] }} fs-6 fw-bold">%{{ $pct }}</span>
              </div>
              <div class="progress mb-2" style="height:6px;border-radius:6px;background:var(--bs-secondary-bg);">
                <div class="{{ $barClass }}" style="width:{{ $pct }}%;height:100%;border-radius:6px;"></div>
              </div>
              @if($goal['target_date'])
              <div class="text-muted" style="font-size:.72rem;">
                <i class="icon-base ti tabler-calendar-event icon-12px me-1"></i>
                Hedef: {{ \Carbon\Carbon::parse($goal['target_date'])->format('M Y') }}
                @if($goal['monthly_contribution'])
                  · ₺{{ number_format($goal['monthly_contribution'], 0, ',', '.') }}/ay
                @endif
              </div>
              @endif
            </div>
          </div>
        </div>
        @endforeach
      </div>
    </div>
  </div>
  @endif

  {{-- ══ ROW — Enflasyon Karşılaştırma + Banka Hesapları ═══════════════════ --}}
  <div class="row g-5 mb-6">
    {{-- Enflasyon Bar --}}
    <div class="col-xl-5">
      <div class="card h-100 shadow-sm">
        <div class="card-header d-flex align-items-center justify-content-between">
          <div>
            <h5 class="card-title mb-0">Kişisel Enflasyon vs TÜFE</h5>
            <small class="text-muted">Aylık karşılaştırma</small>
          </div>
          <span class="badge bg-label-warning">TÜİK</span>
        </div>
        <div class="card-body pt-2">
          @if(count($inflationData) > 0)
            <div id="inflationBarChart" class="w-100"></div>
          @else
            <div class="d-flex flex-column align-items-center justify-content-center py-5">
              <i class="icon-base ti tabler-chart-bar icon-48px text-muted mb-3"></i>
              <p class="text-muted small mb-2 text-center">
                Banka hesapları bağlandıktan sonra kişisel enflasyon hesaplanacak.
              </p>
              <a href="{{ route('demo-data.index') }}" class="btn btn-sm btn-outline-primary">
                <i class="icon-base ti tabler-database-plus me-1"></i>Demo veri oluştur
              </a>
            </div>
          @endif
        </div>
      </div>
    </div>

    {{-- Banka Hesapları --}}
    <div class="col-xl-7">
      <div class="card h-100 shadow-sm">
        <div class="card-header d-flex align-items-center justify-content-between">
          <div>
            <h5 class="card-title mb-0">
              <i class="icon-base ti tabler-building-bank me-2 text-primary"></i>Banka Hesapları
            </h5>
            <small class="text-muted">Bağlı {{ $bankConnections->count() }} banka</small>
          </div>
          <a href="{{ route('bank-connections.create') }}" class="btn btn-sm btn-primary">
            <i class="icon-base ti tabler-plus me-1"></i>Banka Bağla
          </a>
        </div>
        <div class="card-body p-0">
          @if($bankConnections->isNotEmpty())
            <div class="table-responsive">
              <table class="table table-hover mb-0">
                <thead class="paranette-thead">
                  <tr>
                    <th class="ps-4 py-3">Banka</th>
                    <th class="py-3">Tür</th>
                    <th class="py-3 d-none d-md-table-cell">IBAN</th>
                    <th class="py-3 pe-4 text-end">Bakiye</th>
                  </tr>
                </thead>
                <tbody>
                  @foreach($bankConnections as $conn)
                    @foreach($conn->accounts as $acct)
                      <tr>
                        <td class="ps-4 py-3">
                          <div class="d-flex align-items-center gap-2">
                            <div class="avatar avatar-sm flex-shrink-0">
                              <span class="avatar-initial rounded bg-label-primary" style="font-size:.65rem;font-weight:700;">
                                {{ strtoupper(substr($conn->bank->slug, 0, 2)) }}
                              </span>
                            </div>
                            <span class="fw-medium small">{{ $conn->bank->name }}</span>
                          </div>
                        </td>
                        <td class="py-3">
                          @if($acct->account_type === 'checking')
                            <span class="badge bg-label-primary">Vadesiz</span>
                          @elseif($acct->account_type === 'savings')
                            <span class="badge bg-label-info">Birikimli</span>
                          @else
                            <span class="badge bg-label-secondary">{{ $acct->account_type }}</span>
                          @endif
                        </td>
                        <td class="py-3 d-none d-md-table-cell">
                          <small class="text-muted font-monospace">{{ Str::mask($acct->iban ?? '—', '*', 4, -4) }}</small>
                        </td>
                        <td class="py-3 pe-4 text-end">
                          <div class="fw-semibold small">₺{{ number_format($acct->balance, 2, ',', '.') }}</div>
                          <div class="text-success" style="font-size:.72rem;">₺{{ number_format($acct->available_balance, 2, ',', '.') }} müsait</div>
                        </td>
                      </tr>
                    @endforeach
                  @endforeach
                </tbody>
              </table>
            </div>
          @else
            <div class="text-center py-6">
              <div class="d-flex justify-content-center mb-3">
                <i class="icon-base ti tabler-building-bank icon-48px text-muted"></i>
              </div>
              <p class="text-muted mb-3">Henüz banka hesabı bağlanmamış.</p>
              <div class="d-flex justify-content-center gap-2 flex-wrap">
                <a href="{{ route('bank-connections.create') }}" class="btn btn-outline-primary">
                  <i class="icon-base ti tabler-plus me-1"></i>Banka Bağla
                </a>
                <a href="{{ route('demo-data.index') }}" class="btn btn-outline-secondary">
                  <i class="icon-base ti tabler-database-plus me-1"></i>Demo Veri
                </a>
              </div>
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- ══ ROW — Son İşlemler + AI Öngörüler ═════════════════════════════════ --}}
  <div class="row g-5 mb-6">
    {{-- Son İşlemler --}}
    <div class="col-xl-8">
      <div class="card shadow-sm">
        <div class="card-header d-flex align-items-center justify-content-between">
          <div>
            <h5 class="card-title mb-0">Son İşlemler</h5>
            <small class="text-muted">En son 10 işlem</small>
          </div>
          <a href="{{ route('transactions.index') }}" class="btn btn-sm btn-outline-secondary">
            Tümünü Gör <i class="icon-base ti tabler-chevron-right icon-14px"></i>
          </a>
        </div>
        <div class="card-body p-0">
          @if($recentTxns->isNotEmpty())
            <div class="table-responsive">
              <table class="table table-hover mb-0">
                <thead class="paranette-thead">
                  <tr>
                    <th class="ps-4 py-3">İşlem</th>
                    <th class="py-3 d-none d-sm-table-cell">Banka</th>
                    <th class="py-3 d-none d-md-table-cell">Tarih</th>
                    <th class="py-3 pe-4 text-end">Tutar</th>
                  </tr>
                </thead>
                <tbody>
                  @foreach($recentTxns as $tx)
                    <tr>
                      <td class="ps-4 py-3">
                        <div class="d-flex align-items-center gap-2">
                          <div class="avatar avatar-sm flex-shrink-0">
                            <span class="avatar-initial rounded bg-label-{{ $tx->amount >= 0 ? 'success' : 'danger' }}">
                              <i class="icon-base ti {{ $tx->amount >= 0 ? 'tabler-arrow-down-left' : 'tabler-arrow-up-right' }} icon-14px"></i>
                            </span>
                          </div>
                          <div class="overflow-hidden">
                            <div class="fw-medium small text-truncate" style="max-width:200px;">{{ Str::limit($tx->description, 35) }}</div>
                            @if($tx->merchant_name)
                              <div class="text-muted" style="font-size:.72rem;">{{ $tx->merchant_name }}</div>
                            @endif
                          </div>
                        </div>
                      </td>
                      <td class="py-3 d-none d-sm-table-cell">
                        @if($tx->account?->bankConnection?->bank)
                          <span class="badge bg-label-secondary">{{ strtoupper($tx->account->bankConnection->bank->slug) }}</span>
                        @endif
                      </td>
                      <td class="py-3 d-none d-md-table-cell">
                        <small class="text-muted">{{ \Carbon\Carbon::parse($tx->posted_at)->format('d.m.Y') }}</small>
                      </td>
                      <td class="py-3 pe-4 text-end">
                        <span class="fw-semibold {{ $tx->amount >= 0 ? 'text-success' : 'text-danger' }}">
                          {{ $tx->amount >= 0 ? '+' : '' }}₺{{ number_format(abs($tx->amount), 2, ',', '.') }}
                        </span>
                      </td>
                    </tr>
                  @endforeach
                </tbody>
              </table>
            </div>
          @else
            <div class="text-center py-6">
              <div class="d-flex justify-content-center mb-3">
                <i class="icon-base ti tabler-receipt-2 icon-48px text-muted"></i>
              </div>
              <p class="text-muted mb-0">İşlem geçmişi bulunamadı.</p>
            </div>
          @endif
        </div>
      </div>
    </div>

    {{-- AI Öngörüler --}}
    <div class="col-xl-4">
      {{-- ── Agentic Real-Time Insights (auto-loads on page open) ── --}}
      <x-ai-insight-panel page="dashboard" :autoload="true" title="Canlı AI Analizi" />

      <div class="card h-100 shadow-sm">
        <div class="card-header d-flex align-items-center justify-content-between">
          <div>
            <h5 class="card-title mb-0">
              <i class="icon-base ti tabler-sparkles me-2 text-warning"></i>AI Öngörüler
            </h5>
            <small class="text-muted">{{ $aiInsights->count() }} aktif öneri</small>
          </div>
          <a href="{{ route('agent-chat.index') }}" class="btn btn-sm btn-outline-primary">
            <i class="icon-base ti tabler-message-2 me-1"></i>Sohbet
          </a>
        </div>
        <div class="card-body d-flex flex-column p-0">
          @php
            $insightTypeIcons = [
              'warning'     => ['icon' => 'tabler-alert-triangle', 'color' => 'warning'],
              'opportunity' => ['icon' => 'tabler-star',            'color' => 'success'],
              'tip'         => ['icon' => 'tabler-bulb',            'color' => 'info'],
              'anomaly'     => ['icon' => 'tabler-radar',           'color' => 'danger'],
            ];
          @endphp
          @if($aiInsights->isNotEmpty())
            <ul class="list-group list-group-flush flex-grow-1" id="insights-list">
              @foreach($aiInsights as $insight)
              @php
                $iMeta = $insightTypeIcons[$insight->type] ?? ['icon' => 'tabler-info-circle', 'color' => 'secondary'];
              @endphp
                <li class="list-group-item insight-item px-4 py-3" id="insight-{{ $insight->id }}">
                  <div class="d-flex align-items-start gap-3">
                    <div class="avatar avatar-sm flex-shrink-0 mt-1">
                      <span class="avatar-initial rounded bg-label-{{ $iMeta['color'] }}">
                        <i class="icon-base ti {{ $iMeta['icon'] }} icon-14px"></i>
                      </span>
                    </div>
                    <div class="flex-grow-1 overflow-hidden">
                      <div class="d-flex align-items-start justify-content-between gap-1 mb-1">
                        <div class="fw-semibold small text-heading">{{ $insight->title }}</div>
                        <button type="button"
                                class="btn btn-icon btn-text-secondary btn-sm flex-shrink-0 btn-dismiss-insight"
                                data-id="{{ $insight->id }}"
                                data-url="{{ route('agent-chat.insight-dismiss', $insight->id) }}"
                                title="Kapat" style="margin-top:-4px;width:22px;height:22px;">
                          <i class="icon-base ti tabler-x icon-12px"></i>
                        </button>
                      </div>
                      <p class="text-muted small mb-1" style="font-size:.78rem;">{{ \Illuminate\Support\Str::limit($insight->body, 100) }}</p>
                      @if($insight->action_link)
                        <a href="{{ $insight->action_link }}" class="text-primary small">
                          Detay <i class="icon-base ti tabler-chevron-right icon-12px"></i>
                        </a>
                      @endif
                    </div>
                  </div>
                </li>
              @endforeach
            </ul>
            <div class="p-3 border-top">
              <a href="{{ route('agent-chat.index') }}" class="btn btn-primary w-100 btn-sm">
                <i class="icon-base ti tabler-robot me-2"></i>Ajana Daha Fazla Sor
              </a>
            </div>
          @else
            <div class="flex-grow-1 d-flex flex-column justify-content-center p-4">
              <div class="bg-label-primary rounded-3 p-4 mb-4 text-center">
                <div class="d-flex justify-content-center mb-2">
                  <i class="icon-base ti tabler-robot icon-40px text-primary"></i>
                </div>
                <p class="text-muted small mb-3">
                  Yapay zeka ajanları finansal durumunuzu analiz ederek kişiselleştirilmiş öneriler üretebilir.
                </p>
                <button id="btn-quick-analyze" class="btn btn-sm btn-primary">
                  <i class="icon-base ti tabler-sparkles me-1"></i>Hızlı Analiz Yap
                </button>
              </div>
              <div id="quick-analyze-status" class="d-none alert alert-info py-2 small mb-3"></div>
              <a href="{{ route('agent-chat.index') }}" class="btn btn-outline-primary btn-sm">
                <i class="icon-base ti tabler-message-2 me-2"></i>Ajana Sor
              </a>
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- ══ EKONOMİK GÖSTERGELER ════════════════════════════════════════════════ --}}
  @php
    $macroLabels = [
      'tufe'                  => ['label' => 'TÜFE',          'unit' => '%',  'icon' => 'tabler-flame'],
      'unemployment'          => ['label' => 'İşsizlik',      'unit' => '%',  'icon' => 'tabler-briefcase'],
      'gdp_growth'            => ['label' => 'GSYH Büyüme',   'unit' => '%',  'icon' => 'tabler-trending-up'],
      'industrial_production' => ['label' => 'Sanayi Üretim', 'unit' => '%',  'icon' => 'tabler-building-factory-2'],
      'consumer_confidence'   => ['label' => 'Tüketici Güven','unit' => '',   'icon' => 'tabler-mood-smile'],
      'population'            => ['label' => 'Nüfus',         'unit' => 'M',  'icon' => 'tabler-users'],
    ];
  @endphp
  @if($macroIndicators->isNotEmpty())
  <div class="card mb-6 shadow-sm">
    <div class="card-header d-flex align-items-center justify-content-between">
      <div>
        <h5 class="card-title mb-0">
          <i class="icon-base ti tabler-chart-infographic me-2 text-info"></i>Türkiye Ekonomik Göstergeler
        </h5>
        <small class="text-muted">TÜİK ve resmi kaynaklardan güncel veriler</small>
      </div>
      <span class="badge bg-label-info">Güncel</span>
    </div>
    <div class="card-body">
      <div class="row g-4">
        @foreach($macroLabels as $type => $meta)
          @if($macroIndicators->has($type))
          @php $ind = $macroIndicators->get($type); @endphp
          <div class="col-6 col-md-4 col-xl-2">
            <div class="p-3 rounded border h-100" style="background:var(--bs-body-bg);">
              <div class="d-flex align-items-center gap-2 mb-2">
                <div class="avatar avatar-sm flex-shrink-0">
                  <span class="avatar-initial rounded bg-label-{{ $ind->trend === 'up' ? 'success' : ($ind->trend === 'down' ? 'danger' : 'secondary') }}">
                    <i class="icon-base ti {{ $meta['icon'] }} icon-14px"></i>
                  </span>
                </div>
                <span class="text-muted" style="font-size:.72rem;">{{ $meta['label'] }}</span>
              </div>
              <div class="fw-bold h5 mb-0 text-heading">
                {{ number_format($ind->value, $ind->value > 10 ? 1 : 2, ',', '.') }}{{ $meta['unit'] }}
              </div>
              <div class="small mt-1">
                @if($ind->trend === 'up')
                  <span class="text-success"><i class="icon-base ti tabler-arrow-up-right icon-14px"></i> Artış</span>
                @elseif($ind->trend === 'down')
                  <span class="text-danger"><i class="icon-base ti tabler-arrow-down-right icon-14px"></i> Düşüş</span>
                @else
                  <span class="text-muted"><i class="icon-base ti tabler-minus icon-14px"></i> Sabit</span>
                @endif
              </div>
            </div>
          </div>
          @endif
        @endforeach
      </div>
    </div>
  </div>
  @endif

  {{-- ══ FİNANSAL SAĞLIK MODAL ═══════════════════════════════════════════════ --}}
  @if($healthDetails)
  <div class="modal fade" id="healthModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header border-0 pb-0">
          <h5 class="modal-title">
            <i class="icon-base ti tabler-heart-rate-monitor me-2 text-success"></i>Finansal Sağlık Skoru
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <div class="text-center mb-5">
            @php
              $s = $healthDetails->score;
              $sColor = $s >= 70 ? 'success' : ($s >= 40 ? 'warning' : 'danger');
              $sLabel = $s >= 70 ? 'Sağlıklı Finansal Durum' : ($s >= 40 ? 'Geliştirilmesi Gerekiyor' : 'Risk Altında — Dikkat!');
              $sCirc = round($s * 2.827);
            @endphp
            <div class="circle-progress mb-2" style="width:100px;height:100px;">
              <svg width="100" height="100" viewBox="0 0 72 72">
                <circle cx="36" cy="36" r="30" fill="none" stroke="var(--bs-border-color)" stroke-width="6"/>
                <circle cx="36" cy="36" r="30" fill="none"
                        stroke="{{ $s >= 70 ? '#28C76F' : ($s >= 40 ? '#FF9F43' : '#EA5455') }}"
                        stroke-width="6" stroke-linecap="round"
                        stroke-dasharray="{{ $sCirc }}, 282.7"/>
              </svg>
              <div class="cp-text text-{{ $sColor }}" style="font-size:1.4rem;">{{ $s }}</div>
            </div>
            <div class="text-muted small">{{ $sLabel }}</div>
          </div>
          @php
            $components = [
              ['label' => 'Borç Oranı',         'score' => $healthDetails->debt_ratio_score,          'icon' => 'tabler-trending-down', 'color' => 'danger',  'tip' => 'Toplam borcun yıllık gelire oranı'],
              ['label' => 'Tasarruf Oranı',      'score' => $healthDetails->savings_rate_score,        'icon' => 'tabler-piggy-bank',    'color' => 'success', 'tip' => 'Aylık tasarruf / gelir oranı'],
              ['label' => 'Acil Fon',            'score' => $healthDetails->emergency_fund_score,      'icon' => 'tabler-shield',        'color' => 'info',    'tip' => 'Bakiyenin aylık gidere oranı (hedef: 6 ay)'],
              ['label' => 'Gider Tutarlılığı',   'score' => $healthDetails->expense_consistency_score, 'icon' => 'tabler-chart-line',    'color' => 'warning', 'tip' => 'Aylık giderlerin değişkenliği'],
            ];
          @endphp
          <div class="row g-4">
            @foreach($components as $c)
            <div class="col-6">
              <div class="d-flex align-items-center gap-2 mb-1">
                <i class="icon-base ti {{ $c['icon'] }} text-{{ $c['color'] }} icon-16px"></i>
                <span class="fw-medium small flex-grow-1">{{ $c['label'] }}</span>
                <span class="badge bg-label-{{ $c['color'] }}">{{ $c['score'] }}/100</span>
              </div>
              <div class="progress" style="height:6px;border-radius:6px;">
                <div class="progress-bar bg-{{ $c['color'] }}" style="width:{{ $c['score'] }}%;border-radius:6px;"></div>
              </div>
              <div class="text-muted mt-1" style="font-size:.7rem;">{{ $c['tip'] }}</div>
            </div>
            @endforeach
          </div>
          <div class="alert alert-secondary mt-4 mb-0 small d-flex align-items-center gap-2">
            <i class="icon-base ti tabler-clock icon-16px text-muted flex-shrink-0"></i>
            <span>Son güncelleme: {{ \Carbon\Carbon::parse($healthDetails->calculated_at)->diffForHumans() }}</span>
          </div>
        </div>
        <div class="modal-footer border-0 pt-0">
          <a href="{{ route('simulator.index') }}" class="btn btn-primary">
            <i class="icon-base ti tabler-calculator me-1"></i>Simülatörde Dene
          </a>
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
        </div>
      </div>
    </div>
  </div>
  @endif

  {{-- ══ APEX CHARTS + JS ════════════════════════════════════════════════════ --}}
  <x-slot name="pageJs">
    <script src="{{ asset('assets/vendor/libs/apex-charts/apexcharts.js') }}"></script>
    <script>
    (function () {
      'use strict';

      const isDark    = document.documentElement.getAttribute('data-bs-theme') === 'dark';
      const primary   = '#7367F0';
      const success   = '#28C76F';
      const danger    = '#EA5455';
      const warning   = '#FF9F43';
      const info      = '#00CFE8';
      const gridColor = isDark ? 'rgba(255,255,255,.08)' : 'rgba(0,0,0,.05)';
      const textColor = isDark ? '#b4b7bd' : '#6e6b7b';
      const fontFam   = "'Public Sans', sans-serif";

      // ── 1. Nakit Akışı ─────────────────────────────────────────────────
      const cfData = @json($cashFlow);

      if (document.getElementById('cashFlowChart')) {
        if (cfData.length > 0) {
          const cfLabels  = cfData.map(r => {
            const [y, m] = r.month.split('-');
            return new Date(y, m - 1).toLocaleDateString('tr-TR', { month: 'short', year: '2-digit' });
          });
          const cfIncomes  = cfData.map(r => r.income);
          const cfExpenses = cfData.map(r => r.expense);
          const cfNets     = cfData.map(r => r.income - r.expense);

          new ApexCharts(document.getElementById('cashFlowChart'), {
            chart: {
              type: 'bar', height: 255,
              toolbar: { show: false }, fontFamily: fontFam, background: 'transparent',
            },
            plotOptions: { bar: { borderRadius: 5, columnWidth: '50%' } },
            series: [
              { name: 'Gelir',   type: 'bar',  data: cfIncomes  },
              { name: 'Gider',   type: 'bar',  data: cfExpenses  },
              { name: 'Net',     type: 'line', data: cfNets      },
            ],
            colors: [success, danger, primary],
            stroke: { width: [0, 0, 3], curve: 'smooth' },
            markers: { size: [0, 0, 4] },
            xaxis: {
              categories: cfLabels,
              labels: { style: { colors: textColor, fontFamily: fontFam, fontSize: '12px' } },
              axisBorder: { show: false }, axisTicks: { show: false },
            },
            yaxis: {
              labels: {
                formatter: v => v >= 1000 ? '₺' + (v / 1000).toFixed(0) + 'B' : '₺' + v,
                style: { colors: textColor, fontFamily: fontFam },
              },
            },
            legend: {
              position: 'top', horizontalAlign: 'right', fontFamily: fontFam,
              markers: { radius: 50, width: 10, height: 10 },
            },
            grid: { borderColor: gridColor, strokeDashArray: 4, padding: { top: -10 } },
            dataLabels: { enabled: false },
            tooltip: {
              y: { formatter: v => '₺ ' + parseFloat(v).toLocaleString('tr-TR', { minimumFractionDigits: 0 }) },
              theme: isDark ? 'dark' : 'light',
            },
          }).render();
        } else {
          document.getElementById('cashFlowChart').innerHTML =
            '<div class="d-flex flex-column align-items-center justify-content-center py-6 text-muted"><i class="icon-base ti tabler-chart-bar icon-48px d-block mb-2"></i><p class="small mb-2">Nakit akışı verisi bulunamadı.</p><a href="{{ route("demo-data.index") }}" class="btn btn-sm btn-outline-primary"><i class="icon-base ti tabler-database-plus me-1"></i>Demo veri oluştur</a></div>';
        }
      }

      // ── 2. Kategori Donut ───────────────────────────────────────────────
      const catData = @json($categorySpend);

      if (document.getElementById('categoryDonutChart') && catData.length > 0) {
        new ApexCharts(document.getElementById('categoryDonutChart'), {
          chart: { type: 'donut', height: 290, fontFamily: fontFam },
          series: catData.map(r => r.total),
          labels: catData.map(r => r.category),
          colors: [primary, success, warning, danger, info, '#38B2AC', '#ED64A6', '#9F7AEA'],
          legend: { position: 'bottom', fontFamily: fontFam, fontSize: '12px', itemMargin: { horizontal: 6, vertical: 4 }, labels: { colors: textColor } },
          dataLabels: { enabled: false },
          stroke: { width: 2 },
          plotOptions: {
            pie: {
              donut: {
                size: '68%',
                labels: {
                  show: true,
                  total: {
                    show: true,
                    label: 'Toplam',
                    fontFamily: fontFam,
                    fontSize: '12px',
                    color: textColor,
                    formatter: w => '₺' + w.globals.seriesTotals
                      .reduce((a, b) => a + b, 0)
                      .toLocaleString('tr-TR', { maximumFractionDigits: 0 }),
                  },
                },
              },
            },
          },
          tooltip: {
            y: { formatter: v => '₺ ' + v.toLocaleString('tr-TR', { minimumFractionDigits: 2 }) },
            theme: isDark ? 'dark' : 'light',
          },
        }).render();
      }

      // ── 3. Enflasyon Bar ────────────────────────────────────────────────
      const infData = @json($inflationData);

      if (document.getElementById('inflationBarChart') && infData.length > 0) {
        new ApexCharts(document.getElementById('inflationBarChart'), {
          chart: { type: 'bar', height: 230, toolbar: { show: false }, fontFamily: fontFam },
          series: [
            { name: 'Kişisel Enflasyon', data: infData.map(r => r.personal) },
            { name: 'TÜFE',              data: infData.map(r => r.tufe) },
          ],
          colors: [danger, warning],
          xaxis: {
            categories: infData.map(r => r.month),
            labels: { style: { colors: textColor, fontFamily: fontFam, fontSize: '11px' } },
            axisBorder: { show: false },
            axisTicks: { show: false },
          },
          yaxis: {
            labels: { formatter: v => '%' + v, style: { colors: textColor, fontFamily: fontFam } },
          },
          grid: { borderColor: gridColor, strokeDashArray: 4 },
          dataLabels: { enabled: false },
          legend: { position: 'top', horizontalAlign: 'right', fontFamily: fontFam },
          tooltip: { y: { formatter: v => '%' + v }, theme: isDark ? 'dark' : 'light' },
          plotOptions: { bar: { columnWidth: '55%', borderRadius: 4, borderRadiusApplication: 'end' } },
        }).render();
      }
    })();

    // ── Dismiss insight ───────────────────────────────────────────────────
    document.querySelectorAll('.btn-dismiss-insight').forEach(function (btn) {
      btn.addEventListener('click', function () {
        const id  = this.dataset.id;
        const url = this.dataset.url;
        fetch(url, {
          method: 'PATCH',
          headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content },
        }).then(() => {
          const li = document.getElementById('insight-' + id);
          if (li) { li.style.opacity = 0; setTimeout(() => { li.remove(); }, 200); }
          const list = document.getElementById('insights-list');
          if (list && list.children.length === 0) { setTimeout(() => location.reload(), 300); }
        });
      });
    });

    // ── Browser Notifications ─────────────────────────────────────────────
    (function () {
      const alerts = @json($smartAlerts);
      if (!('Notification' in window) || !alerts.length) return;

      const STORAGE_KEY = 'paranette-notif-shown';
      const today       = new Date().toISOString().slice(0, 10);
      const shownToday  = localStorage.getItem(STORAGE_KEY) === today;
      if (shownToday) return;

      function fireNotifications() {
        localStorage.setItem(STORAGE_KEY, today);
        alerts.slice(0, 3).forEach((al, i) => {
          setTimeout(() => {
            const n = new Notification('Paranette — ' + al.title, {
              body: al.body,
              icon: '/assets/img/favicon/favicon.ico',
              tag:  'paranette-alert-' + i,
            });
            if (al.link) n.onclick = () => { window.focus(); window.location.href = al.link; };
          }, i * 600);
        });
      }

      if (Notification.permission === 'granted') {
        fireNotifications();
      } else if (Notification.permission === 'default') {
        Notification.requestPermission().then(p => { if (p === 'granted') fireNotifications(); });
      }
    })();

    // ── Quick AI Analyze ──────────────────────────────────────────────────
    const btnAnalyze = document.getElementById('btn-quick-analyze');
    if (btnAnalyze) {
      btnAnalyze.addEventListener('click', function () {
        const statusBox = document.getElementById('quick-analyze-status');
        btnAnalyze.disabled = true;
        btnAnalyze.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Analiz yapılıyor…';
        statusBox.className = 'alert alert-info py-2 small mb-3';
        statusBox.textContent = 'Yapay zeka ajanları analiz ediyor…';

        fetch('{{ route("agent-chat.quick-analyze") }}', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
          },
        })
        .then(r => r.json())
        .then(data => {
          if (data.status === 'ok') {
            statusBox.className = 'alert alert-success py-2 small mb-3';
            statusBox.textContent = 'Analiz tamamlandı! Yenileniyor…';
            setTimeout(() => location.reload(), 1800);
          } else {
            statusBox.className = 'alert alert-warning py-2 small mb-3';
            statusBox.textContent = 'Hata: ' + (data.message || 'Bilinmiyor');
            btnAnalyze.disabled = false;
            btnAnalyze.innerHTML = '<i class="icon-base ti tabler-sparkles me-1"></i>Tekrar Dene';
          }
        })
        .catch(() => {
          statusBox.className = 'alert alert-danger py-2 small mb-3';
          statusBox.textContent = 'Bağlantı hatası.';
          btnAnalyze.disabled = false;
          btnAnalyze.innerHTML = '<i class="icon-base ti tabler-sparkles me-1"></i>Tekrar Dene';
        });
      });
    }
    </script>
  </x-slot>
</x-app-layout>
