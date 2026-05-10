<x-app-layout>
  <x-slot name="title">Dashboard</x-slot>

  {{-- Apex Charts CSS --}}
  <x-slot name="pageCss">
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/apex-charts/apex-charts.css') }}" />
  </x-slot>

  {{-- ══ Page header with report download ══════════════════════════════ --}}
  <div class="d-flex align-items-center justify-content-between mb-5">
    <div>
      <h4 class="fw-bold mb-0">Ana Sayfa</h4>
      <p class="text-muted mb-0 small">Finansal özet ve analiz</p>
    </div>
    <a href="{{ route('report.monthly') }}" class="btn btn-outline-primary btn-sm" target="_blank">
      <i class="icon-base ti tabler-file-type-pdf me-1"></i>Aylık Rapor PDF
    </a>
  </div>

  {{-- ══ ROW 1 — 4 Metrik Kart ══════════════════════════════════════════ --}}
  <div class="row g-6 mb-6">
    {{-- Toplam Bakiye --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Toplam Bakiye</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2">₺{{ number_format($summary['total_balance'], 2, ',', '.') }}</h4>
                @if($bankConnections->isNotEmpty())
                  <span class="badge bg-label-success">Canlı</span>
                @endif
              </div>
              <small class="text-muted">{{ $bankConnections->sum(fn($c) => $c->accounts->count()) }} hesap</small>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-building-bank icon-26px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Kart Borcu --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Kart Borcu</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2 @if($summary['total_card_debt'] > 0) text-danger @endif">
                  ₺{{ number_format($summary['total_card_debt'], 2, ',', '.') }}
                </h4>
              </div>
              <small class="text-muted">Tüm kredi kartları</small>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-danger">
                <i class="icon-base ti tabler-credit-card icon-26px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Aktif Kredi --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Aktif Kredi</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2">₺{{ number_format($summary['total_loan'], 2, ',', '.') }}</h4>
              </div>
              <small class="text-muted">Kalan bakiye</small>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-warning">
                <i class="icon-base ti tabler-file-invoice icon-26px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Finansal Sağlık --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Finansal Sağlık</span>
              <div class="d-flex align-items-center my-1">
                @if($summary['health_score'])
                  <h4 class="mb-0 me-2 @if($summary['health_score'] >= 70) text-success @elseif($summary['health_score'] >= 40) text-warning @else text-danger @endif">
                    {{ $summary['health_score'] }}/100
                  </h4>
                @else
                  <h4 class="mb-0 me-2 text-muted">--/100</h4>
                @endif
              </div>
              <small class="text-muted">Sağlık skoru</small>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-success">
                <i class="icon-base ti tabler-heart-rate-monitor icon-26px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- ══ ROW 2 — Nakit Akışı + Kategori Donut ════════════════════════════ --}}
  <div class="row g-6 mb-6">
    {{-- Nakit Akışı Alan Grafik --}}
    <div class="col-xl-8">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between pb-0">
          <h5 class="card-title mb-0">Nakit Akışı — Son 6 Ay</h5>
          <small class="text-muted">₺ TRY</small>
        </div>
        <div class="card-body">
          <div id="cashFlowChart"></div>
        </div>
      </div>
    </div>

    {{-- Kategori Harcama Donut --}}
    <div class="col-xl-4">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between pb-0">
          <h5 class="card-title mb-0">Harcama Dağılımı</h5>
          <small class="text-muted">Son 30 gün</small>
        </div>
        <div class="card-body d-flex align-items-center justify-content-center">
          @if(count($categorySpend) > 0)
            <div id="categoryDonutChart" class="w-100"></div>
          @else
            <div class="text-center">
              <i class="icon-base ti tabler-chart-donut-3 icon-48px text-muted mb-3 d-block"></i>
              <p class="text-muted small mb-0">Henüz kategori verisi yok.</p>
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- ══ ROW 3 — Enflasyon Karşılaştırma + Banka Hesapları ══════════════ --}}
  <div class="row g-6 mb-6">
    {{-- Kişisel Enflasyon vs TÜFE --}}
    <div class="col-xl-5">
      <div class="card border-primary h-100">
        <div class="card-header d-flex align-items-center">
          <h5 class="card-title mb-0 me-auto">Kişisel Enflasyon vs TÜFE</h5>
          <span class="badge bg-label-warning">TÜİK</span>
        </div>
        <div class="card-body d-flex align-items-center justify-content-center">
          @if(count($inflationData) > 0)
            <div id="inflationBarChart" class="w-100"></div>
          @else
            <div class="text-center">
              <i class="icon-base ti tabler-chart-bar icon-48px text-muted mb-3 d-block"></i>
              <p class="text-muted small mb-0">
                Banka hesapları bağlandıktan sonra kişisel enflasyon hesaplanacak.
              </p>
            </div>
          @endif
        </div>
      </div>
    </div>

    {{-- Banka Hesapları Tablosu --}}
    <div class="col-xl-7">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between">
          <h5 class="card-title mb-0">Banka Hesapları</h5>
          <a href="#" class="btn btn-sm btn-primary">
            <i class="icon-base ti tabler-plus me-1"></i> Banka Bağla
          </a>
        </div>
        <div class="card-body p-0">
          @if($bankConnections->isNotEmpty())
            <div class="table-responsive">
              <table class="table table-hover mb-0">
                <thead class="table-light">
                  <tr>
                    <th>Banka</th>
                    <th>Tür</th>
                    <th>IBAN</th>
                    <th class="text-end">Bakiye</th>
                    <th class="text-end">Müsait</th>
                  </tr>
                </thead>
                <tbody>
                  @foreach($bankConnections as $conn)
                    @foreach($conn->accounts as $acct)
                      <tr>
                        <td>
                          <div class="d-flex align-items-center gap-2">
                            <span class="badge bg-label-secondary">{{ strtoupper($conn->bank->slug) }}</span>
                            <span>{{ $conn->bank->name }}</span>
                          </div>
                        </td>
                        <td>
                          @if($acct->account_type === 'checking')
                            <span class="badge bg-label-primary">Vadesiz</span>
                          @elseif($acct->account_type === 'savings')
                            <span class="badge bg-label-info">Birikimli</span>
                          @else
                            <span class="badge bg-label-secondary">{{ $acct->account_type }}</span>
                          @endif
                        </td>
                        <td><small class="text-muted font-monospace">{{ Str::mask($acct->iban ?? '—', '*', 4, -4) }}</small></td>
                        <td class="text-end fw-medium">₺{{ number_format($acct->balance, 2, ',', '.') }}</td>
                        <td class="text-end text-success">₺{{ number_format($acct->available_balance, 2, ',', '.') }}</td>
                      </tr>
                    @endforeach
                  @endforeach
                </tbody>
              </table>
            </div>
          @else
            <div class="text-center py-6">
              <i class="icon-base ti tabler-building-bank icon-48px text-muted mb-3 d-block"></i>
              <p class="text-muted mb-3">Henüz banka hesabı bağlanmamış.</p>
              <a href="#" class="btn btn-outline-primary">
                <i class="icon-base ti tabler-plus me-1"></i> Banka Bağla
              </a>
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- ══ ROW 4 — Son İşlemler + Ajan Asistan ════════════════════════════ --}}
  <div class="row g-6">
    {{-- Son İşlemler --}}
    <div class="col-xl-8">
      <div class="card">
        <div class="card-header d-flex align-items-center justify-content-between">
          <h5 class="card-title mb-0">Son İşlemler</h5>
          <a href="#" class="btn btn-sm btn-outline-secondary">Tümünü Gör</a>
        </div>
        <div class="card-body p-0">
          @if($recentTxns->isNotEmpty())
            <div class="table-responsive">
              <table class="table table-hover mb-0">
                <thead class="table-light">
                  <tr>
                    <th>İşlem</th>
                    <th>Banka</th>
                    <th>Tarih</th>
                    <th class="text-end">Tutar</th>
                  </tr>
                </thead>
                <tbody>
                  @foreach($recentTxns as $tx)
                    <tr>
                      <td>
                        <div>
                          <span class="fw-medium">{{ Str::limit($tx->description, 38) }}</span>
                          @if($tx->merchant_name)
                            <br><small class="text-muted">{{ $tx->merchant_name }}</small>
                          @endif
                        </div>
                      </td>
                      <td>
                        @if($tx->account?->bankConnection?->bank)
                          <span class="badge bg-label-secondary">
                            {{ strtoupper($tx->account->bankConnection->bank->slug) }}
                          </span>
                        @endif
                      </td>
                      <td>
                        <small class="text-muted">
                          {{ \Carbon\Carbon::parse($tx->posted_at)->format('d.m.Y') }}
                        </small>
                      </td>
                      <td class="text-end fw-semibold @if($tx->amount >= 0) text-success @else text-danger @endif">
                        @if($tx->amount >= 0)+@endif₺{{ number_format(abs($tx->amount), 2, ',', '.') }}
                      </td>
                    </tr>
                  @endforeach
                </tbody>
              </table>
            </div>
          @else
            <div class="text-center py-5">
              <i class="icon-base ti tabler-receipt-2 icon-48px text-muted mb-3 d-block"></i>
              <p class="text-muted mb-0">İşlem geçmişi bulunamadı.</p>
            </div>
          @endif
        </div>
      </div>
    </div>

    {{-- Ajan Asistan --}}
    <div class="col-xl-4">
      <div class="card h-100">
        <div class="card-header">
          <h5 class="card-title mb-0">
            <i class="icon-base ti tabler-robot me-2 text-primary"></i>Ajan Asistan
          </h5>
        </div>
        <div class="card-body d-flex flex-column">
          <p class="text-muted mb-4">
            Finansal durumunuz hakkında sorularınızı yapay zeka destekli ajan asistanınıza sorun.
          </p>
          <div class="bg-label-primary rounded p-3 mb-4 small">
            <strong>Önerilen sorular:</strong>
            <ul class="mb-0 mt-1 ps-3">
              <li>Bu ay ne kadar harcadım?</li>
              <li>Birikim için önerilerin neler?</li>
              <li>En yüksek harcama kategorim hangisi?</li>
            </ul>
          </div>
          <a href="#" class="btn btn-primary mt-auto">
            <i class="icon-base ti tabler-message-2 me-2"></i>Ajana Sor
          </a>
        </div>
      </div>
    </div>
  </div>

  {{-- ══ Apex Charts JS ══════════════════════════════════════════════════ --}}
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

      // ── 1. Nakit Akışı Alan Grafik ────────────────────────────────────
      const cfData = @json($cashFlow);

      if (document.getElementById('cashFlowChart')) {
        if (cfData.length > 0) {
          new ApexCharts(document.getElementById('cashFlowChart'), {
            chart: { type: 'area', height: 240, toolbar: { show: false }, fontFamily: fontFam },
            series: [
              { name: 'Gelir', data: cfData.map(r => r.income) },
              { name: 'Gider', data: cfData.map(r => r.expense) },
            ],
            colors: [success, danger],
            fill:   { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.35, opacityTo: 0.05 } },
            stroke: { curve: 'smooth', width: 2 },
            xaxis: {
              categories: cfData.map(r => r.month),
              labels: { style: { colors: textColor, fontFamily: fontFam } },
              axisBorder: { show: false }, axisTicks: { show: false },
            },
            yaxis: {
              labels: {
                formatter: v => v >= 1000 ? '₺' + (v/1000).toFixed(0) + 'B' : '₺' + v,
                style: { colors: textColor, fontFamily: fontFam },
              },
            },
            grid: { borderColor: gridColor, padding: { top: -15 } },
            dataLabels: { enabled: false },
            legend: { position: 'top', horizontalAlign: 'right', fontFamily: fontFam, markers: { radius: 50 } },
            tooltip: { y: { formatter: v => '₺ ' + v.toLocaleString('tr-TR', { minimumFractionDigits: 2 }) } },
          }).render();
        } else {
          document.getElementById('cashFlowChart').innerHTML =
            '<div class="text-center py-5 text-muted"><i class="icon-base ti tabler-chart-area icon-48px d-block mb-2"></i><p class="small mb-0">Nakit akışı verisi bulunamadı.</p></div>';
        }
      }

      // ── 2. Kategori Harcama Donut ─────────────────────────────────────
      const catData = @json($categorySpend);

      if (document.getElementById('categoryDonutChart') && catData.length > 0) {
        new ApexCharts(document.getElementById('categoryDonutChart'), {
          chart: { type: 'donut', height: 280, fontFamily: fontFam },
          series: catData.map(r => r.total),
          labels: catData.map(r => r.category),
          colors: [primary, success, warning, danger, info, '#38B2AC', '#ED64A6', '#9F7AEA'],
          legend: { position: 'bottom', fontFamily: fontFam, fontSize: '12px' },
          dataLabels: { enabled: false },
          plotOptions: {
            pie: { donut: { size: '65%', labels: {
              show: true,
              total: {
                show: true, label: 'Toplam', fontFamily: fontFam, fontSize: '12px', color: textColor,
                formatter: w => '₺' + w.globals.seriesTotals
                  .reduce((a, b) => a + b, 0)
                  .toLocaleString('tr-TR', { maximumFractionDigits: 0 }),
              },
            }}},
          },
          tooltip: { y: { formatter: v => '₺ ' + v.toLocaleString('tr-TR', { minimumFractionDigits: 2 }) } },
        }).render();
      }

      // ── 3. Enflasyon Karşılaştırma Bar Grafik ─────────────────────────
      const infData = @json($inflationData);

      if (document.getElementById('inflationBarChart') && infData.length > 0) {
        new ApexCharts(document.getElementById('inflationBarChart'), {
          chart: { type: 'bar', height: 220, toolbar: { show: false }, fontFamily: fontFam },
          series: [
            { name: 'Kişisel Enflasyon', data: infData.map(r => r.personal) },
            { name: 'TÜFE',              data: infData.map(r => r.tufe) },
          ],
          colors: [danger, warning],
          xaxis: {
            categories: infData.map(r => r.month),
            labels: { style: { colors: textColor, fontFamily: fontFam } },
          },
          yaxis: {
            labels: { formatter: v => v + '%', style: { colors: textColor, fontFamily: fontFam } },
          },
          grid: { borderColor: gridColor },
          dataLabels: { enabled: false },
          legend: { position: 'top', fontFamily: fontFam },
          tooltip: { y: { formatter: v => v + '%' } },
          plotOptions: { bar: { columnWidth: '50%', borderRadius: 4 } },
        }).render();
      }
    })();
    </script>
  </x-slot>
</x-app-layout>
