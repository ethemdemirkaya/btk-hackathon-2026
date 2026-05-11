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
  </style>
  </x-slot>

  {{-- Page header --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Karar Simülatörü</h4>
      <p class="text-muted mb-0">"Ya şu olsa?" — Finansal kararlarınızın geleceğe etkisini simüle edin</p>
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
  </script>
  </x-slot>
</x-app-layout>
