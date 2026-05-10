<x-app-layout>
  <x-slot name="title">Kişisel Enflasyon</x-slot>

  <x-slot name="pageCss">
  <link rel="stylesheet" href="{{ asset('assets/vendor/libs/apex-charts/apex-charts.css') }}">
  <style>
    .inflation-hero {
      background: linear-gradient(135deg, #1A56DB 0%, #7367f0 100%);
      border-radius: 12px; color: #fff; padding: 2rem;
    }
    .inflation-hero .rate { font-size: 3.5rem; font-weight: 800; line-height: 1; }
    .inflation-hero .delta { font-size: 1rem; opacity: .85; }
    .cat-row { margin-bottom: .75rem; }
    .cat-bar-bg  { background: #e9ecef; border-radius: 4px; height: 8px; }
    .cat-bar-fill { height: 8px; border-radius: 4px; transition: width .5s; }
  </style>
  </x-slot>

  <div class="d-flex align-items-center mb-6">
    <div>
      <h4 class="fw-bold mb-1">Kişisel Enflasyon</h4>
      <p class="text-muted mb-0">Harcama profiline göre hesaplanan kişisel TÜFE — {{ $periodLabel }}</p>
    </div>
  </div>

  <div class="row g-6">

    {{-- Hero card --}}
    <div class="col-xl-4">
      <div class="inflation-hero mb-5">
        <div class="mb-2 opacity-75 small text-uppercase fw-semibold">Kişisel Enflasyonun</div>
        <div class="rate">%{{ $personalRate }}</div>
        <div class="delta mt-2">
          @if($personalDelta > 0)
            <i class="icon-base ti tabler-arrow-up-right me-1"></i>TÜFE'den <strong>+%{{ abs($personalDelta) }}</strong> yüksek
          @elseif($personalDelta < 0)
            <i class="icon-base ti tabler-arrow-down-right me-1"></i>TÜFE'den <strong>-%{{ abs($personalDelta) }}</strong> düşük
          @else
            TÜFE ile aynı seviyede
          @endif
        </div>
        <div class="mt-3 pt-3 border-top border-white border-opacity-25 d-flex justify-content-between">
          <div>
            <div class="opacity-75" style="font-size:.8rem;">Manşet TÜFE</div>
            <div class="fw-bold">%{{ $headline }}</div>
          </div>
          <div class="text-end">
            <div class="opacity-75" style="font-size:.8rem;">Referans Dönem</div>
            <div class="fw-bold">{{ $periodLabel }}</div>
          </div>
        </div>
      </div>

      @if($topImpact)
      <div class="card">
        <div class="card-body">
          <div class="fw-medium mb-2">
            <i class="icon-base ti tabler-alert-triangle text-warning me-1"></i>En Çok Etkileyen
          </div>
          <div class="d-flex align-items-center justify-content-between">
            <span class="text-muted small">{{ strtoupper($topImpact['slug']) }}</span>
            <span class="fw-bold text-danger">%{{ $topImpact['rate'] }}/yıl</span>
          </div>
          <div class="text-muted small mt-1">
            Harcamanın %{{ $topImpact['weight'] }}'ini oluşturuyor → %{{ $topImpact['impact'] }} puan etki
          </div>
        </div>
      </div>
      @endif
    </div>

    {{-- Category rates chart --}}
    <div class="col-xl-8">
      <div class="card mb-5">
        <div class="card-header pb-2">
          <h5 class="card-title mb-0">TÜİK Kategori Enflasyonları — {{ $periodLabel }}</h5>
        </div>
        <div class="card-body pt-2">
          <div id="categoryChart" style="min-height:300px;"></div>
        </div>
      </div>

      {{-- Personal breakdown --}}
      @if(count($personalBreakdown))
      <div class="card">
        <div class="card-header pb-2">
          <h5 class="card-title mb-0">Harcama Ağırlıklı Kişisel Etki</h5>
        </div>
        <div class="card-body">
          @php $maxImpact = collect($personalBreakdown)->max('impact') ?: 1; @endphp
          @foreach($personalBreakdown as $item)
          <div class="cat-row">
            <div class="d-flex justify-content-between align-items-center mb-1">
              <div class="d-flex align-items-center gap-2">
                <span class="small fw-medium text-uppercase">{{ $item['slug'] }}</span>
                <span class="badge bg-label-secondary" style="font-size:.68rem;">%{{ $item['weight'] }} harcama</span>
              </div>
              <div class="d-flex gap-3 small">
                <span class="text-muted">Oran: <strong>%{{ $item['rate'] }}</strong></span>
                <span class="text-danger fw-bold">+%{{ $item['impact'] }} etki</span>
              </div>
            </div>
            <div class="cat-bar-bg">
              <div class="cat-bar-fill"
                   style="width:{{ round($item['impact'] / $maxImpact * 100) }}%;
                          background:{{ $item['impact'] > 15 ? '#ea5455' : ($item['impact'] > 8 ? '#ff9f43' : '#28c76f') }};">
              </div>
            </div>
          </div>
          @endforeach
        </div>
      </div>
      @else
      <div class="card">
        <div class="card-body text-center py-6">
          <i class="icon-base ti tabler-chart-bar icon-48px text-muted mb-3 d-block"></i>
          <p class="text-muted">Son 3 ayda harcama verisi bulunamadı. Banka hesaplarınızı senkronize edin.</p>
        </div>
      </div>
      @endif
    </div>

  </div>

  {{-- Historical chart --}}
  @if($historical->isNotEmpty())
  <div class="card mt-6">
    <div class="card-header pb-2">
      <h5 class="card-title mb-0">Manşet TÜFE Tarihçesi (Son 12 Ay)</h5>
    </div>
    <div class="card-body pt-0">
      <div id="historyChart" style="min-height:220px;"></div>
    </div>
  </div>
  @endif

  <x-slot name="pageJs">
  <script src="{{ asset('assets/vendor/libs/apex-charts/apexcharts.js') }}"></script>
  <script>
  (function () {
    const isDark = () => document.documentElement.getAttribute('data-bs-theme') === 'dark';

    // ── Category bar chart ──────────────────────────────────────────────
    const catData = @json($categoryRates->map(fn($r) => ['slug' => strtoupper($r->tuik_category_slug), 'rate' => (float)$r->annual_change_rate])->sortByDesc('rate')->values());

    new ApexCharts(document.getElementById('categoryChart'), {
      chart: { type: 'bar', height: 300, toolbar: { show: false }, background: 'transparent' },
      series: [{ name: 'Yıllık Değişim %', data: catData.map(d => d.rate) }],
      xaxis: { categories: catData.map(d => d.slug), labels: { style: { fontSize: '10px' } } },
      yaxis: { labels: { formatter: v => '%' + v } },
      colors: catData.map(d => d.rate > 50 ? '#ea5455' : d.rate > 35 ? '#ff9f43' : '#28c76f'),
      plotOptions: { bar: { borderRadius: 4, distributed: true } },
      legend: { show: false },
      dataLabels: { enabled: true, formatter: v => '%' + v },
      tooltip: { y: { formatter: v => '%' + v } },
      theme: { mode: isDark() ? 'dark' : 'light' },
      grid: { borderColor: isDark() ? 'rgba(255,255,255,.08)' : '#e9ecef' },
    }).render();

    @if($historical->isNotEmpty())
    // ── Historical line chart ───────────────────────────────────────────
    const histData  = @json($historical->map(fn($r) => (float)$r->annual_change_rate)->values());
    const histLabels = @json($historical->map(fn($r) => $r->period_month . '/' . $r->period_year)->values());

    new ApexCharts(document.getElementById('historyChart'), {
      chart: { type: 'area', height: 220, toolbar: { show: false }, background: 'transparent', sparkline: { enabled: false } },
      series: [{ name: 'TÜFE %', data: histData }],
      xaxis: { categories: histLabels, labels: { style: { fontSize: '10px' } } },
      yaxis: { labels: { formatter: v => '%' + v } },
      stroke: { curve: 'smooth', width: 2 },
      fill: { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: .3, opacityTo: .05 } },
      colors: ['#7367f0'],
      dataLabels: { enabled: false },
      tooltip: { y: { formatter: v => '%' + v } },
      theme: { mode: isDark() ? 'dark' : 'light' },
      grid: { borderColor: isDark() ? 'rgba(255,255,255,.08)' : '#e9ecef' },
    }).render();
    @endif

    // React to theme change
    const obs = new MutationObserver(() => location.reload());
    obs.observe(document.documentElement, { attributes: true, attributeFilter: ['data-bs-theme'] });

  })();
  </script>
  </x-slot>
</x-app-layout>
