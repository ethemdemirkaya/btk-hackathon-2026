<x-app-layout>
  <x-slot name="title">Karar Simülatörü</x-slot>

  <x-slot name="pageCss">
  <link rel="stylesheet" href="{{ asset('assets/vendor/libs/apex-charts/apex-charts.css') }}">
  <style>
    .slider-value-badge {
      min-width: 64px;
      text-align: center;
    }
    .current-card {
      transition: box-shadow .2s;
    }
    .current-card:hover {
      box-shadow: 0 4px 18px rgba(0,0,0,.10);
    }
    .impact-neutral  { color: var(--bs-secondary); }
    .impact-positive { color: #28c76f; }
    .impact-negative { color: #ea5455; }
    input[type=range] {
      accent-color: var(--bs-primary);
    }
    .score-bar-wrap {
      height: 8px;
      border-radius: 4px;
      background: var(--bs-secondary-bg);
      overflow: hidden;
    }
    .score-bar-fill {
      height: 100%;
      border-radius: 4px;
      transition: width .4s ease, background-color .4s;
    }
    /* Tutorial step tabs */
    .tut-step-tab {
      flex: 1;
      padding: .6rem .5rem;
      text-align: center;
      font-size: .78rem;
      font-weight: 600;
      color: var(--bs-secondary-color);
      border-bottom: 3px solid transparent;
      cursor: default;
      transition: color .2s, border-color .2s;
    }
    .tut-step-tab.active {
      color: var(--bs-primary);
      border-bottom-color: var(--bs-primary);
    }
    .tut-panel { display: none; padding: 1.5rem 1.75rem; }
    .tut-panel.active { display: block; }
    .tut-icon-wrap {
      width: 56px; height: 56px;
      border-radius: 50%;
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 1rem;
      font-size: 1.6rem;
    }
  </style>
  </x-slot>

  {{-- Page header --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Karar Simülatörü</h4>
      <p class="text-muted mb-0">"Ya şu olsa?" — Finansal kararlarınızın geleceğe etkisini simüle edin</p>
    </div>
    <div>
      <button type="button" class="btn btn-outline-secondary btn-sm" id="showTutorialBtn">
        <i class="icon-base ti tabler-help-circle me-1"></i>Nasıl Kullanılır?
      </button>
    </div>
  </div>

  {{-- ══════════════ TUTORIAL MODAL ══════════════ --}}
  <div class="modal fade" id="tutorialModal" tabindex="-1" data-bs-backdrop="static" aria-labelledby="tutModalLabel" aria-modal="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header pb-2">
          <div>
            <h5 class="modal-title mb-0" id="tutModalLabel">Karar Simülatörü Rehberi</h5>
            <small class="text-muted" id="tutStepLabel">Adım 1 / 4</small>
          </div>
          <button type="button" class="btn-close" id="tutCloseBtn" data-bs-dismiss="modal" aria-label="Kapat"></button>
        </div>
        <div class="modal-body p-0">

          {{-- Step indicator tabs --}}
          <div class="d-flex border-bottom">
            <div class="tut-step-tab active" data-tut-tab="0">
              <i class="icon-base ti tabler-info-circle d-block mx-auto mb-1" style="font-size:1.1rem"></i>
              Nedir?
            </div>
            <div class="tut-step-tab" data-tut-tab="1">
              <i class="icon-base ti tabler-layout-dashboard d-block mx-auto mb-1" style="font-size:1.1rem"></i>
              Mevcut Durum
            </div>
            <div class="tut-step-tab" data-tut-tab="2">
              <i class="icon-base ti tabler-adjustments-horizontal d-block mx-auto mb-1" style="font-size:1.1rem"></i>
              Parametreler
            </div>
            <div class="tut-step-tab" data-tut-tab="3">
              <i class="icon-base ti tabler-chart-line d-block mx-auto mb-1" style="font-size:1.1rem"></i>
              Sonuçlar
            </div>
          </div>

          {{-- Panel 0: Nedir? --}}
          <div class="tut-panel active" id="tut-panel-0">
            <div class="text-center">
              <div class="tut-icon-wrap bg-label-primary">
                <i class="icon-base ti tabler-robot text-primary"></i>
              </div>
              <h5 class="fw-bold mb-2">Karar Simülatörü Nedir?</h5>
              <p class="text-muted mb-3" style="max-width:480px; margin: 0 auto;">
                Karar Simülatörü, "ya gelirim %20 artarsa?", "ya enflasyon yükselirse?" gibi
                <strong>hipotetik finansal senaryoları</strong> gerçek verilerinizle test etmenizi sağlar.
              </p>
            </div>
            <div class="row g-3 mt-2">
              <div class="col-md-4">
                <div class="rounded border p-3 h-100">
                  <i class="icon-base ti tabler-calculator text-success mb-2 d-block" style="font-size:1.3rem"></i>
                  <div class="fw-semibold small mb-1">Anlık Hesaplama</div>
                  <p class="text-muted small mb-0">Slider'ları hareket ettirdikçe sonuçlar anında güncellenir.</p>
                </div>
              </div>
              <div class="col-md-4">
                <div class="rounded border p-3 h-100">
                  <i class="icon-base ti tabler-chart-area text-primary mb-2 d-block" style="font-size:1.3rem"></i>
                  <div class="fw-semibold small mb-1">Projeksiyon Grafiği</div>
                  <p class="text-muted small mb-0">Nominal ve reel bakiyenizin aylara göre gidişatını görün.</p>
                </div>
              </div>
              <div class="col-md-4">
                <div class="rounded border p-3 h-100">
                  <i class="icon-base ti tabler-heart-rate-monitor text-danger mb-2 d-block" style="font-size:1.3rem"></i>
                  <div class="fw-semibold small mb-1">Sağlık Skoru Etkisi</div>
                  <p class="text-muted small mb-0">Her senaryo için tahmini finansal sağlık skorunuzu görün.</p>
                </div>
              </div>
            </div>
          </div>

          {{-- Panel 1: Mevcut Durum --}}
          <div class="tut-panel" id="tut-panel-1">
            <div class="text-center mb-3">
              <div class="tut-icon-wrap bg-label-info">
                <i class="icon-base ti tabler-layout-dashboard text-info"></i>
              </div>
              <h5 class="fw-bold mb-1">Mevcut Durum Paneli</h5>
              <p class="text-muted small" style="max-width:480px; margin: 0 auto;">
                Sol kolondaki <strong>"Mevcut Durum"</strong> kartı, hesabınızdan çekilen gerçek finansal anlık görüntünüzü gösterir.
                Bu değerler simülasyonun başlangıç noktasıdır ve değişmez.
              </p>
            </div>
            <div class="row g-3">
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-coin text-warning mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Aylık Gelir &amp; Ortalama Gider</div>
                    <p class="text-muted small mb-0">Son 3 ayın ortalaması kullanılarak hesaplanır.</p>
                  </div>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-wallet text-success mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Toplam Bakiye</div>
                    <p class="text-muted small mb-0">Tüm bağlı hesaplarınızın anlık toplamı.</p>
                  </div>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-credit-card text-danger mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Kredi Kartı Borcu</div>
                    <p class="text-muted small mb-0">Var ise kırmızı ile gösterilir; simülasyonda hesaba katılır.</p>
                  </div>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-heart-rate-monitor text-primary mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Sağlık Skoru &amp; Acil Fon</div>
                    <p class="text-muted small mb-0">Mevcut finansal sağlık puanı ve kaç aylık giderinizi karşılayacak birikminiz.</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {{-- Panel 2: Senaryo Parametreleri --}}
          <div class="tut-panel" id="tut-panel-2">
            <div class="text-center mb-3">
              <div class="tut-icon-wrap bg-label-warning">
                <i class="icon-base ti tabler-adjustments-horizontal text-warning"></i>
              </div>
              <h5 class="fw-bold mb-1">Senaryo Parametreleri</h5>
              <p class="text-muted small" style="max-width:480px; margin: 0 auto;">
                Sol kolondaki <strong>"Senaryo Parametreleri"</strong> kartındaki 4 slider ile farklı senaryolar oluşturabilirsiniz.
              </p>
            </div>
            <div class="row g-3">
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-trending-up text-success mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Gelir Değişimi (−50% → +200%)</div>
                    <p class="text-muted small mb-0">Gelirinizin mevcut duruma göre yüzde kaç artacağını/azalacağını simüle eder. Zam, yeni iş veya ek gelir senaryoları için kullanın.</p>
                  </div>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-trending-down text-danger mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Gider Değişimi (−50% → +100%)</div>
                    <p class="text-muted small mb-0">Aylık harcamalarınızdaki artış veya tasarruf oranını belirleyin. Kira artışı, yeni abonelik veya tasarruf senaryoları için ideal.</p>
                  </div>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-coin text-warning mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Yıllık Enflasyon (%0 → %100)</div>
                    <p class="text-muted small mb-0">Varsayılan değer kişisel enflasyonunuzdur. Bu değer, reel satın alma gücü hesabında kullanılır.</p>
                  </div>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-calendar text-primary mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Zaman Dilimi (1 → 60 ay)</div>
                    <p class="text-muted small mb-0">Projeksiyon kaç aylık süreyi kapsayacak? Kısa vadeli (3–6 ay) veya uzun vadeli (12–60 ay) planlar yapabilirsiniz.</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {{-- Panel 3: Sonuçları Yorumla --}}
          <div class="tut-panel" id="tut-panel-3">
            <div class="text-center mb-3">
              <div class="tut-icon-wrap bg-label-success">
                <i class="icon-base ti tabler-chart-line text-success"></i>
              </div>
              <h5 class="fw-bold mb-1">Sonuçları Yorumla</h5>
              <p class="text-muted small" style="max-width:480px; margin: 0 auto;">
                Sağ kolonda 4 özet kart, bir projeksiyon grafiği ve finansal sağlık çubuğu bulunur.
              </p>
            </div>
            <div class="row g-3">
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-pig-money text-success mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Yeni Aylık Tasarruf &amp; Tasarruf Oranı</div>
                    <p class="text-muted small mb-0">Gelir − gider farkı. Pozitif ise yeşil, negatif ise kırmızı gösterilir.</p>
                  </div>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-chart-area text-primary mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Bakiye Projeksiyonu Grafiği</div>
                    <p class="text-muted small mb-0">Mor çizgi nominal bakiye, yeşil çizgi enflasyon düzeltmeli reel bakiye, kırmızı ise kart borcunu gösterir.</p>
                  </div>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-flame text-danger mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Enflasyon Kaybı &amp; Reel Bakiye</div>
                    <p class="text-muted small mb-0">Seçilen dönemde enflasyonun erittiği satın alma gücünü gösterir.</p>
                  </div>
                </div>
              </div>
              <div class="col-sm-6">
                <div class="d-flex align-items-start gap-2 p-3 rounded border">
                  <i class="icon-base ti tabler-heart-rate-monitor text-warning mt-1" style="font-size:1.1rem"></i>
                  <div>
                    <div class="fw-semibold small">Tahmini Finansal Sağlık Skoru</div>
                    <p class="text-muted small mb-0">0&#8211;100 arasında. 70+ iyi, 40&#8211;70 orta, 40 altı kritik. Delta mevcut skorunuzla farkı gösterir.</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" id="tutPrevBtn" disabled>
            <i class="icon-base ti tabler-arrow-left me-1"></i>Geri
          </button>
          <button type="button" class="btn btn-primary" id="tutNextBtn">
            İleri<i class="icon-base ti tabler-arrow-right ms-1"></i>
          </button>
        </div>
      </div>
    </div>
  </div>

  <div class="row g-6">

    {{-- LEFT COLUMN: sliders + current state --}}
    <div class="col-xl-5">

      {{-- Current state snapshot --}}
      <div class="card mb-6">
        <div class="card-header pb-3">
          <h5 class="card-title mb-0">Mevcut Durum</h5>
        </div>
        <div class="card-body pt-0">
          <div class="row g-3">
            <div class="col-6">
              <div class="current-card rounded border p-3">
                <div class="text-muted small mb-1">Aylık Gelir</div>
                <div class="fw-bold fs-6">₺{{ number_format($current['monthly_income'], 2, ',', '.') }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="current-card rounded border p-3">
                <div class="text-muted small mb-1">Ort. Aylık Gider</div>
                <div class="fw-bold fs-6">₺{{ number_format($current['avg_monthly_expense'], 2, ',', '.') }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="current-card rounded border p-3">
                <div class="text-muted small mb-1">Toplam Bakiye</div>
                <div class="fw-bold fs-6">₺{{ number_format($current['total_balance'], 2, ',', '.') }}</div>
              </div>
            </div>
            <div class="col-6">
              <div class="current-card rounded border p-3">
                <div class="text-muted small mb-1">Kredi Kartı Borcu</div>
                <div class="fw-bold fs-6 {{ $current['total_card_debt'] > 0 ? 'text-danger' : '' }}">
                  ₺{{ number_format($current['total_card_debt'], 2, ',', '.') }}
                </div>
              </div>
            </div>
            <div class="col-6">
              <div class="current-card rounded border p-3">
                <div class="text-muted small mb-1">Sağlık Skoru</div>
                <div class="fw-bold fs-6">{{ $current['health_score'] }}<span class="text-muted small">/100</span></div>
              </div>
            </div>
            <div class="col-6">
              <div class="current-card rounded border p-3">
                <div class="text-muted small mb-1">Acil Fon (ay)</div>
                <div class="fw-bold fs-6">{{ $current['months_emergency'] }} ay</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {{-- Scenario sliders --}}
      <div class="card">
        <div class="card-header pb-3">
          <h5 class="card-title mb-0">Senaryo Parametreleri</h5>
        </div>
        <div class="card-body pt-2">

          {{-- Income change --}}
          <div class="mb-5">
            <div class="d-flex justify-content-between align-items-center mb-2">
              <label class="form-label mb-0 fw-medium">
                <i class="icon-base ti tabler-trending-up text-success me-1"></i>Gelir Değişimi
              </label>
              <span class="badge bg-label-success slider-value-badge" id="label-income">+0%</span>
            </div>
            <input type="range" class="form-range" id="slider-income"
                   min="-50" max="200" step="1" value="0">
            <div class="d-flex justify-content-between">
              <small class="text-muted">-50%</small>
              <small class="text-muted">+200%</small>
            </div>
          </div>

          {{-- Expense change --}}
          <div class="mb-5">
            <div class="d-flex justify-content-between align-items-center mb-2">
              <label class="form-label mb-0 fw-medium">
                <i class="icon-base ti tabler-trending-down text-danger me-1"></i>Gider Değişimi
              </label>
              <span class="badge bg-label-danger slider-value-badge" id="label-expense">+0%</span>
            </div>
            <input type="range" class="form-range" id="slider-expense"
                   min="-50" max="100" step="1" value="0">
            <div class="d-flex justify-content-between">
              <small class="text-muted">-50%</small>
              <small class="text-muted">+100%</small>
            </div>
          </div>

          {{-- Inflation --}}
          <div class="mb-5">
            <div class="d-flex justify-content-between align-items-center mb-2">
              <label class="form-label mb-0 fw-medium">
                <i class="icon-base ti tabler-coin text-warning me-1"></i>Yıllık Enflasyon
              </label>
              <span class="badge bg-label-warning slider-value-badge" id="label-inflation">{{ $current['personal_inflation'] }}%</span>
            </div>
            <input type="range" class="form-range" id="slider-inflation"
                   min="0" max="100" step="0.5" value="{{ $current['personal_inflation'] }}">
            <div class="d-flex justify-content-between">
              <small class="text-muted">0%</small>
              <small class="text-muted">100%</small>
            </div>
          </div>

          {{-- Time horizon --}}
          <div class="mb-2">
            <div class="d-flex justify-content-between align-items-center mb-2">
              <label class="form-label mb-0 fw-medium">
                <i class="icon-base ti tabler-calendar text-primary me-1"></i>Zaman Dilimi
              </label>
              <span class="badge bg-label-primary slider-value-badge" id="label-months">12 ay</span>
            </div>
            <input type="range" class="form-range" id="slider-months"
                   min="1" max="60" step="1" value="12">
            <div class="d-flex justify-content-between">
              <small class="text-muted">1 ay</small>
              <small class="text-muted">60 ay</small>
            </div>
          </div>

        </div>
      </div>
    </div>

    {{-- RIGHT COLUMN: chart + impact --}}
    <div class="col-xl-7">

      {{-- Impact summary cards --}}
      <div class="row g-4 mb-6">
        <div class="col-sm-6 col-xl-3">
          <div class="card stat-card position-relative overflow-hidden h-100">
            <div class="accent-bar bg-success"></div>
            <div class="card-body pt-4 text-center">
              <div class="text-muted small mb-1">Yeni Aylık Tasarruf</div>
              <div class="fw-bold fs-5" id="impact-savings">—</div>
              <div class="small mt-1" id="impact-savings-rate">—</div>
            </div>
          </div>
        </div>
        <div class="col-sm-6 col-xl-3">
          <div class="card stat-card position-relative overflow-hidden h-100">
            <div class="accent-bar bg-primary"></div>
            <div class="card-body pt-4 text-center">
              <div class="text-muted small mb-1">Tahmini Skor</div>
              <div class="fw-bold fs-5" id="impact-score">—</div>
              <div class="small mt-1" id="impact-score-delta">—</div>
            </div>
          </div>
        </div>
        <div class="col-sm-6 col-xl-3">
          <div class="card stat-card position-relative overflow-hidden h-100">
            <div class="accent-bar bg-info"></div>
            <div class="card-body pt-4 text-center">
              <div class="text-muted small mb-1">Nominal Bakiye</div>
              <div class="fw-bold fs-5" id="impact-balance">—</div>
              <div class="small mt-1 text-muted" id="impact-months-emergency">— ay</div>
            </div>
          </div>
        </div>
        <div class="col-sm-6 col-xl-3">
          <div class="card stat-card position-relative overflow-hidden h-100">
            <div class="accent-bar bg-danger"></div>
            <div class="card-body pt-4 text-center">
              <div class="text-muted small mb-1">Enflasyon Kaybı</div>
              <div class="fw-bold fs-5 text-danger" id="impact-inflation-loss">—</div>
              <div class="small mt-1 text-muted" id="impact-real-balance">Reel: —</div>
            </div>
          </div>
        </div>
      </div>

      {{-- Chart --}}
      <div class="card mb-6">
        <div class="card-header d-flex align-items-center justify-content-between pb-3">
          <h5 class="card-title mb-0">Bakiye Projeksiyonu</h5>
          <div id="chart-loading" class="spinner-border spinner-border-sm text-primary d-none" role="status"></div>
        </div>
        <div class="card-body pt-0">
          <div id="projectionChart" style="min-height:280px;"></div>
        </div>
      </div>

      {{-- Health score bar --}}
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-center justify-content-between mb-3">
            <h6 class="mb-0 fw-medium">Tahmini Finansal Sağlık Skoru</h6>
            <span class="fw-bold" id="score-label">—</span>
          </div>
          <div class="score-bar-wrap mb-1">
            <div class="score-bar-fill bg-success" id="score-bar" style="width:0%;"></div>
          </div>
          <div class="d-flex justify-content-between mt-1">
            <small class="text-muted">0 — Kritik</small>
            <small class="text-muted">100 — Mükemmel</small>
          </div>
          <div class="mt-3 small text-muted" id="score-hint">
            Senaryo parametrelerini ayarlayarak sağlık skorunuza etkisini görün.
          </div>
        </div>
      </div>

    </div>
  </div>

  <x-slot name="pageJs">
  <script src="{{ asset('assets/vendor/libs/apex-charts/apexcharts.js') }}"></script>
  <script>
  (function () {
    // Current state passed from PHP
    const BASE = {
      monthly_income:     {{ $current['monthly_income'] }},
      avg_monthly_expense: {{ $current['avg_monthly_expense'] }},
      total_balance:      {{ $current['total_balance'] }},
      total_card_debt:    {{ $current['total_card_debt'] }},
      health_score:       {{ $current['health_score'] }},
      personal_inflation: {{ $current['personal_inflation'] }},
    };

    // ---- Slider label helpers ----
    function fmtPct(v) { return (v >= 0 ? '+' : '') + v + '%'; }
    function fmtMonth(v) { return v + ' ay'; }
    function fmtTl(v) { return '₺' + numFmt(v); }
    function numFmt(v) { return parseFloat(v).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 0 }); }

    document.getElementById('slider-income').addEventListener('input', function () {
      const lbl = document.getElementById('label-income');
      lbl.textContent = fmtPct(this.value);
      lbl.className = 'badge slider-value-badge ' + (this.value < 0 ? 'bg-label-danger' : 'bg-label-success');
      debounceCalc();
    });
    document.getElementById('slider-expense').addEventListener('input', function () {
      const lbl = document.getElementById('label-expense');
      lbl.textContent = fmtPct(this.value);
      lbl.className = 'badge slider-value-badge ' + (this.value > 0 ? 'bg-label-danger' : 'bg-label-success');
      debounceCalc();
    });
    document.getElementById('slider-inflation').addEventListener('input', function () {
      document.getElementById('label-inflation').textContent = this.value + '%';
      debounceCalc();
    });
    document.getElementById('slider-months').addEventListener('input', function () {
      document.getElementById('label-months').textContent = fmtMonth(this.value);
      debounceCalc();
    });

    // ---- ApexCharts setup ----
    const isDark = () => document.documentElement.getAttribute('data-bs-theme') === 'dark';
    const chartOptions = {
      chart: { type: 'line', height: 280, toolbar: { show: false }, animations: { speed: 400 }, background: 'transparent' },
      stroke: { curve: 'smooth', width: [2, 2, 1] },
      series: [
        { name: 'Nominal Bakiye', data: [] },
        { name: 'Reel Bakiye', data: [] },
        { name: 'Kart Borcu', data: [] },
      ],
      colors: ['#7367f0', '#28c76f', '#ea5455'],
      xaxis: { type: 'numeric', title: { text: 'Ay' }, labels: { formatter: v => v + '.ay' } },
      yaxis: { labels: { formatter: v => '₺' + numFmt(v) } },
      legend: { position: 'top' },
      tooltip: { y: { formatter: v => '₺' + numFmt(v) } },
      grid: { borderColor: isDark() ? 'rgba(255,255,255,.08)' : '#e9ecef' },
      theme: { mode: isDark() ? 'dark' : 'light' },
    };

    const chart = new ApexCharts(document.getElementById('projectionChart'), chartOptions);
    chart.render();

    // Re-apply theme on toggle
    const observer = new MutationObserver(() => {
      chart.updateOptions({ theme: { mode: isDark() ? 'dark' : 'light' }, grid: { borderColor: isDark() ? 'rgba(255,255,255,.08)' : '#e9ecef' } });
    });
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ['data-bs-theme'] });

    // ---- Debounce + fetch ----
    let timer = null;
    function debounceCalc() {
      clearTimeout(timer);
      timer = setTimeout(calculate, 280);
    }

    function calculate() {
      const payload = {
        income_change_pct:   parseFloat(document.getElementById('slider-income').value),
        expense_change_pct:  parseFloat(document.getElementById('slider-expense').value),
        inflation_rate:      parseFloat(document.getElementById('slider-inflation').value),
        months_horizon:      parseInt(document.getElementById('slider-months').value),
        monthly_income:      BASE.monthly_income,
        avg_monthly_expense: BASE.avg_monthly_expense,
        total_balance:       BASE.total_balance,
        total_card_debt:     BASE.total_card_debt,
      };

      document.getElementById('chart-loading').classList.remove('d-none');

      fetch('{{ route('simulator.calculate') }}', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json',
        },
        body: JSON.stringify(payload),
      })
        .then(r => r.json())
        .then(data => {
          document.getElementById('chart-loading').classList.add('d-none');
          renderResults(data);
        })
        .catch(() => document.getElementById('chart-loading').classList.add('d-none'));
    }

    function renderResults(data) {
      // Impact cards
      const savingsColor = data.new_savings >= 0 ? 'impact-positive' : 'impact-negative';
      const savingsEl = document.getElementById('impact-savings');
      savingsEl.textContent = fmtTl(data.new_savings);
      savingsEl.className = 'fw-bold fs-5 ' + savingsColor;

      document.getElementById('impact-savings-rate').textContent = data.savings_rate_pct + '% tasarruf oranı';

      const scoreEl = document.getElementById('impact-score');
      scoreEl.textContent = data.estimated_score + ' / 100';
      const delta = data.estimated_score - BASE.health_score;
      const deltaEl = document.getElementById('impact-score-delta');
      deltaEl.textContent = (delta >= 0 ? '▲ +' : '▼ ') + delta + ' mevcut duruma göre';
      deltaEl.className = 'small mt-1 ' + (delta >= 0 ? 'impact-positive' : 'impact-negative');

      document.getElementById('impact-balance').textContent = fmtTl(data.final_balance);
      document.getElementById('impact-months-emergency').textContent = data.months_emergency + ' ay acil fon';

      document.getElementById('impact-inflation-loss').textContent = '-' + fmtTl(data.inflation_loss);
      document.getElementById('impact-real-balance').textContent = 'Reel: ' + fmtTl(data.real_final_balance);

      // Chart
      const nominals  = data.projections.map(p => ({ x: p.month, y: p.balance }));
      const reals     = data.projections.map(p => ({ x: p.month, y: p.real_balance }));
      const debts     = data.projections.map(p => ({ x: p.month, y: p.card_debt }));
      chart.updateSeries([
        { name: 'Nominal Bakiye', data: nominals },
        { name: 'Reel Bakiye',    data: reals },
        { name: 'Kart Borcu',     data: debts },
      ]);

      // Health score bar
      const pct = Math.min(100, Math.max(0, data.estimated_score));
      const barColor = pct >= 70 ? '#28c76f' : pct >= 40 ? '#ff9f43' : '#ea5455';
      const bar = document.getElementById('score-bar');
      bar.style.width = pct + '%';
      bar.style.backgroundColor = barColor;
      document.getElementById('score-label').textContent = data.estimated_score + ' / 100';

      const hints = {
        high:   'Harika! Bu senaryo finansal sağlığınızı güçlendiriyor.',
        medium: 'Orta düzeyde sağlıklı — tasarruf oranını artırmayı deneyin.',
        low:    'Dikkat: Bu senaryo finansal stresinizi artırabilir.',
      };
      document.getElementById('score-hint').textContent =
        pct >= 70 ? hints.high : pct >= 40 ? hints.medium : hints.low;
    }

    // Trigger initial calculation on load
    calculate();

  })();

  // ── Tutorial modal ──────────────────────────────────────────────────
  (function () {
    const LS_KEY      = 'paranette_sim_tutorial_seen';
    const modal       = document.getElementById('tutorialModal');
    const bsModal     = bootstrap.Modal.getOrCreateInstance(modal);
    const prevBtn     = document.getElementById('tutPrevBtn');
    const nextBtn     = document.getElementById('tutNextBtn');
    const stepLabel   = document.getElementById('tutStepLabel');
    const tabs        = document.querySelectorAll('.tut-step-tab');
    const panels      = document.querySelectorAll('.tut-panel');
    const TOTAL_STEPS = 4;
    let current = 0;

    function goTo(step) {
      current = step;
      tabs.forEach((t, i)   => t.classList.toggle('active', i === current));
      panels.forEach((p, i) => p.classList.toggle('active', i === current));
      stepLabel.textContent  = 'Adım ' + (current + 1) + ' / ' + TOTAL_STEPS;
      prevBtn.disabled       = current === 0;
      if (current === TOTAL_STEPS - 1) {
        nextBtn.innerHTML = 'Tamam<i class="icon-base ti tabler-check ms-1"></i>';
      } else {
        nextBtn.innerHTML = 'İleri<i class="icon-base ti tabler-arrow-right ms-1"></i>';
      }
    }

    prevBtn.addEventListener('click', () => { if (current > 0) goTo(current - 1); });

    nextBtn.addEventListener('click', () => {
      if (current < TOTAL_STEPS - 1) {
        goTo(current + 1);
      } else {
        localStorage.setItem(LS_KEY, '1');
        bsModal.hide();
      }
    });

    // Dismiss button also marks as seen
    document.getElementById('tutCloseBtn').addEventListener('click', () => {
      localStorage.setItem(LS_KEY, '1');
    });

    // "?" button always opens the tutorial
    const showBtn = document.getElementById('showTutorialBtn');
    if (showBtn) {
      showBtn.addEventListener('click', () => {
        goTo(0);
        bsModal.show();
      });
    }

    // Auto-open on first visit
    if (!localStorage.getItem(LS_KEY)) {
      goTo(0);
      bsModal.show();
    }
  })();
  </script>
  </x-slot>
</x-app-layout>
