<x-app-layout>
  <x-slot name="title">Raporlar</x-slot>

  <x-slot name="pageCss">
  <link rel="stylesheet" href="{{ asset('assets/vendor/libs/apex-charts/apex-charts.css') }}">
  <style>
    .report-kpi-value { font-size: 1.6rem; font-weight: 700; }
    .cat-bar-bg  { background: var(--bs-secondary-bg); border-radius: 4px; height: 8px; }
    .cat-bar-fill { height: 8px; border-radius: 4px; background: linear-gradient(90deg,#7367F0,#9E95F5); }
  </style>
  </x-slot>

  {{-- Header --}}
  <div class="d-flex align-items-center justify-content-between mb-5">
    <div>
      <h4 class="fw-bold mb-1">Raporlar</h4>
      <p class="text-muted mb-0">Son 6 aylık finansal özet · PDF indir</p>
    </div>
    <div class="d-flex gap-2 align-items-center">
      <select id="monthPicker" class="form-select form-select-sm" style="width:auto;">
        @foreach($availableMonths as $m)
          <option value="{{ $m['value'] }}" {{ $m['value'] === now()->format('Y-m') ? 'selected' : '' }}>
            {{ $m['label'] }}
          </option>
        @endforeach
      </select>
      <button id="downloadPdfBtn" class="btn btn-primary btn-sm">
        <i class="icon-base ti tabler-file-type-pdf me-1"></i>PDF İndir
      </button>
    </div>
  </div>

  {{-- Summary stat cards --}}
  <div class="row g-4 mb-6">
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-success"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">6 Aylık Gelir</span>
              <div class="report-kpi-value mt-1 mb-0 text-success">₺{{ number_format($totalIncome, 0, ',', '.') }}</div>
              <span class="small text-muted">Son 6 ay toplam</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-success">
                <i class="icon-base ti tabler-arrow-down-left icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-danger"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">6 Aylık Gider</span>
              <div class="report-kpi-value mt-1 mb-0 text-danger">₺{{ number_format($totalExpense, 0, ',', '.') }}</div>
              <span class="small text-muted">{{ $txCount }} işlem</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-danger">
                <i class="icon-base ti tabler-arrow-up-right icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar {{ $totalNet >= 0 ? 'bg-primary' : 'bg-warning' }}"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Net Tasarruf</span>
              <div class="report-kpi-value mt-1 mb-0 {{ $totalNet >= 0 ? 'text-primary' : 'text-warning' }}">
                {{ $totalNet >= 0 ? '+' : '' }}₺{{ number_format($totalNet, 0, ',', '.') }}
              </div>
              <span class="small text-muted">6 ay kümülatif</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $totalNet >= 0 ? 'primary' : 'warning' }}">
                <i class="icon-base ti tabler-piggy-bank icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-info"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">En İyi Ay</span>
              <div class="report-kpi-value mt-1 mb-0 text-info">{{ $bestMonth['label'] ?? '—' }}</div>
              <span class="small text-muted">
                @if($bestMonth)
                  {{ $bestMonth['net'] >= 0 ? '+' : '' }}₺{{ number_format($bestMonth['net'], 0, ',', '.') }} net
                @endif
              </span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-info">
                <i class="icon-base ti tabler-trophy icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="row g-5">

    {{-- Income / Expense grouped bar chart --}}
    <div class="col-xl-8">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between pb-3">
          <div>
            <h5 class="card-title mb-0">Gelir & Gider Trendi</h5>
            <small class="text-muted">Son 6 ay karşılaştırmalı</small>
          </div>
          <div class="d-flex gap-3 small text-muted">
            <span><span class="badge bg-success me-1">&nbsp;</span>Gelir</span>
            <span><span class="badge bg-danger me-1">&nbsp;</span>Gider</span>
            <span><span class="badge bg-primary me-1">&nbsp;</span>Net</span>
          </div>
        </div>
        <div class="card-body pt-0">
          <div id="trendChart" style="min-height:300px;"></div>
        </div>
      </div>
    </div>

    {{-- Category breakdown --}}
    <div class="col-xl-4">
      <div class="card h-100">
        <div class="card-header pb-3">
          <h5 class="card-title mb-0">Harcama Kategorileri</h5>
          <small class="text-muted">Son 6 ay toplam</small>
        </div>
        <div class="card-body">
          @php $maxCat = $categoryBreakdown->max('total') ?: 1; @endphp
          @forelse($categoryBreakdown as $cat)
          <div class="mb-3">
            <div class="d-flex justify-content-between small mb-1">
              <span class="fw-medium">{{ $cat->merchant_category ?: 'Diğer' }}</span>
              <span class="text-muted">₺{{ number_format($cat->total, 0, ',', '.') }}
                <span class="text-muted ms-1">({{ $cat->cnt }})</span>
              </span>
            </div>
            <div class="cat-bar-bg">
              <div class="cat-bar-fill" style="width:{{ round($cat->total / $maxCat * 100) }}%;"></div>
            </div>
          </div>
          @empty
          <div class="text-center py-4 text-muted small">
            <i class="icon-base ti tabler-chart-bar icon-32px d-block mb-2"></i>
            Bu dönemde harcama bulunamadı.
          </div>
          @endforelse
        </div>
      </div>
    </div>

    {{-- Monthly breakdown table --}}
    <div class="col-12">
      <div class="card">
        <div class="card-header d-flex align-items-center justify-content-between pb-3">
          <h5 class="card-title mb-0">Aylık Özet Tablosu</h5>
          <a href="{{ route('transactions.export') }}" class="btn btn-sm btn-outline-success">
            <i class="icon-base ti tabler-file-type-csv me-1"></i>Tüm İşlemleri İndir
          </a>
        </div>
        <div class="card-body p-0">
          <div class="table-responsive">
            <table class="table table-hover mb-0">
              <thead>
                <tr class="paranette-thead">
                  <th class="ps-4 py-3">Dönem</th>
                  <th class="py-3 text-end">Gelir</th>
                  <th class="py-3 text-end">Gider</th>
                  <th class="py-3 text-end">Net</th>
                  <th class="py-3 pe-4 text-end">Tasarruf Oranı</th>
                </tr>
              </thead>
              <tbody>
                @foreach($cashFlow as $row)
                @php
                  $savingsRate = $row['income'] > 0 ? round($row['net'] / $row['income'] * 100) : 0;
                @endphp
                <tr>
                  <td class="ps-4 py-3 fw-semibold">{{ $row['label'] }}</td>
                  <td class="py-3 text-end text-success fw-medium">₺{{ number_format($row['income'], 0, ',', '.') }}</td>
                  <td class="py-3 text-end text-danger">₺{{ number_format($row['expense'], 0, ',', '.') }}</td>
                  <td class="py-3 text-end fw-bold {{ $row['net'] >= 0 ? 'text-primary' : 'text-warning' }}">
                    {{ $row['net'] >= 0 ? '+' : '' }}₺{{ number_format($row['net'], 0, ',', '.') }}
                  </td>
                  <td class="py-3 pe-4 text-end">
                    <span class="badge bg-label-{{ $savingsRate >= 20 ? 'success' : ($savingsRate >= 0 ? 'warning' : 'danger') }}">
                      %{{ $savingsRate }}
                    </span>
                  </td>
                </tr>
                @endforeach
              </tbody>
              <tfoot>
                <tr class="fw-bold" style="background:rgba(115,103,240,.04);">
                  <td class="ps-4 py-3">Toplam</td>
                  <td class="py-3 text-end text-success">₺{{ number_format($totalIncome, 0, ',', '.') }}</td>
                  <td class="py-3 text-end text-danger">₺{{ number_format($totalExpense, 0, ',', '.') }}</td>
                  <td class="py-3 text-end {{ $totalNet >= 0 ? 'text-primary' : 'text-warning' }}">
                    {{ $totalNet >= 0 ? '+' : '' }}₺{{ number_format($totalNet, 0, ',', '.') }}
                  </td>
                  <td class="py-3 pe-4 text-end">
                    @php $overallRate = $totalIncome > 0 ? round($totalNet / $totalIncome * 100) : 0; @endphp
                    <span class="badge bg-label-{{ $overallRate >= 20 ? 'success' : ($overallRate >= 0 ? 'warning' : 'danger') }}">
                      %{{ $overallRate }}
                    </span>
                  </td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>
      </div>
    </div>

  </div>

  <x-slot name="pageJs">
  <script src="{{ asset('assets/vendor/libs/apex-charts/apexcharts.js') }}"></script>
  <script>
  (function () {
    const isDark  = () => document.documentElement.getAttribute('data-bs-theme') === 'dark';
    const cfData  = @json($cashFlow);
    const labels  = cfData.map(r => r.label);
    const incomes = cfData.map(r => r.income);
    const expenses= cfData.map(r => r.expense);
    const nets    = cfData.map(r => r.net);
    const fontFam = "'Public Sans', sans-serif";

    function gridColor() { return isDark() ? 'rgba(255,255,255,.08)' : '#e9ecef'; }
    function labelColor(){ return isDark() ? 'rgba(255,255,255,.6)' : '#6c757d'; }

    const chart = new ApexCharts(document.getElementById('trendChart'), {
      chart: {
        type: 'bar',
        height: 300,
        toolbar: { show: false },
        fontFamily: fontFam,
        background: 'transparent',
        stacked: false,
      },
      plotOptions: { bar: { borderRadius: 5, columnWidth: '55%' } },
      series: [
        { name: 'Gelir',  type: 'bar',  data: incomes  },
        { name: 'Gider',  type: 'bar',  data: expenses  },
        { name: 'Net',    type: 'line', data: nets      },
      ],
      colors: ['#28C76F', '#EA5455', '#7367F0'],
      stroke: { width: [0, 0, 3], curve: 'smooth' },
      markers: { size: [0, 0, 5] },
      xaxis: { categories: labels, labels: { style: { colors: labelColor(), fontFamily: fontFam } } },
      yaxis: { labels: { formatter: v => '₺' + Math.abs(v).toLocaleString('tr-TR', { maximumFractionDigits: 0 }), style: { colors: labelColor() } } },
      legend: { show: false },
      grid: { borderColor: gridColor(), strokeDashArray: 4 },
      tooltip: { y: { formatter: v => '₺' + parseFloat(v).toLocaleString('tr-TR', { minimumFractionDigits: 0 }) } },
      theme: { mode: isDark() ? 'dark' : 'light' },
    });
    chart.render();

    // React to theme toggle
    new MutationObserver(() => {
      chart.updateOptions({
        theme: { mode: isDark() ? 'dark' : 'light' },
        grid:  { borderColor: gridColor() },
        xaxis: { labels: { style: { colors: labelColor() } } },
        yaxis: { labels: { style: { colors: labelColor() } } },
      });
    }).observe(document.documentElement, { attributes: true, attributeFilter: ['data-bs-theme'] });

    // PDF download
    document.getElementById('downloadPdfBtn').addEventListener('click', function () {
      const month = document.getElementById('monthPicker').value;
      window.open('{{ route('report.monthly') }}?month=' + month, '_blank');
    });
  })();
  </script>
  </x-slot>
</x-app-layout>
