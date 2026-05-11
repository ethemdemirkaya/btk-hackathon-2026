<x-app-layout>
  <x-slot name="title">Yatırım Takibi</x-slot>

  {{-- ══ Page header ════════════════════════════════════════════════════════ --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Yatırım Takibi</h4>
      <p class="text-muted small mb-0">Portföy değerinizi takip edin</p>
    </div>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addAssetModal">
      <i class="icon-base ti tabler-plus me-1"></i>Varlık Ekle
    </button>
  </div>

  {{-- ══ Flash alerts ════════════════════════════════════════════════════════ --}}
  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif
  @if(session('error'))
    <div class="alert alert-danger alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-alert-circle me-2"></i>{{ session('error') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  {{-- ══ Stat cards ══════════════════════════════════════════════════════════ --}}
  <div class="row g-4 mb-5">

    {{-- Toplam Portföy Değeri --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-primary"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Portföy Değeri</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">
                ₺{{ number_format($totals['current_value'], 0, ',', '.') }}
              </div>
              <span class="small text-muted">{{ $assets->count() }} varlık</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-briefcase icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Toplam Maliyet --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-secondary"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Maliyet</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">
                ₺{{ number_format($totals['buy_value'], 0, ',', '.') }}
              </div>
              <span class="small text-muted">alış maliyeti</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-secondary">
                <i class="icon-base ti tabler-shopping-cart icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Toplam Kar/Zarar --}}
    @php
      $gainClass  = $totals['gain_loss'] >= 0 ? 'success' : 'danger';
      $gainSign   = $totals['gain_loss'] >= 0 ? '+' : '';
      $gainIcon   = $totals['gain_loss'] >= 0 ? 'tabler-trending-up' : 'tabler-trending-down';
    @endphp
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-{{ $gainClass }}"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Kar / Zarar</span>
              <div class="h5 fw-bold mt-1 mb-0 text-{{ $gainClass }}">
                {{ $gainSign }}₺{{ number_format(abs($totals['gain_loss']), 0, ',', '.') }}
              </div>
              <span class="small text-muted">net getiri</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $gainClass }}">
                <i class="icon-base ti {{ $gainIcon }} icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Kar/Zarar % --}}
    <div class="col-sm-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-info"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Kar / Zarar %</span>
              <div class="h5 fw-bold mt-1 mb-0 text-{{ $totals['gain_loss_pct'] >= 0 ? 'success' : 'danger' }}">
                {{ $totals['gain_loss_pct'] >= 0 ? '+' : '' }}%{{ number_format(abs($totals['gain_loss_pct']), 2, ',', '.') }}
              </div>
              <span class="small text-muted">toplam getiri oranı</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-info">
                <i class="icon-base ti tabler-percentage icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>

  {{-- ══ Main content ════════════════════════════════════════════════════════ --}}
  <div class="row g-5">

    {{-- ── Asset table (left) ─────────────────────────────────────────────── --}}
    <div class="col-xl-8">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between py-3">
          <h5 class="mb-0">Portföy Varlıkları</h5>
          <span class="badge bg-label-primary">{{ $assets->count() }} varlık</span>
        </div>

        @if($assets->isEmpty())
        <div class="card-body text-center py-8">
          <i class="icon-base ti tabler-coins icon-64px text-muted mb-4 d-block"></i>
          <h5 class="mb-2">Henüz varlık eklenmedi</h5>
          <p class="text-muted mb-4">Altın, döviz, hisse veya kripto para ekleyerek portföyünü oluştur.</p>
          <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addAssetModal">
            <i class="icon-base ti tabler-plus me-1"></i>İlk Varlığı Ekle
          </button>
        </div>
        @else
        <div class="table-responsive">
          <table class="table table-hover mb-0">
            <thead class="paranette-thead">
              <tr>
                <th>Varlık</th>
                <th class="text-end">Miktar</th>
                <th class="text-end">Maliyet Fiyatı</th>
                <th class="text-end">Güncel Değer</th>
                <th class="text-end">Kar / Zarar</th>
                <th class="text-center">İşlem</th>
              </tr>
            </thead>
            <tbody>
              @foreach($assets as $asset)
              @php
                $isGain = $asset->gain_loss_try >= 0;
                $glSign = $isGain ? '+' : '';
              @endphp
              <tr>
                {{-- Varlık adı + tip ikonu --}}
                <td>
                  <div class="d-flex align-items-center gap-3">
                    <div class="avatar flex-shrink-0">
                      <span class="avatar-initial rounded bg-label-{{ $asset->type_color }}">
                        <i class="icon-base ti {{ $asset->type_icon }} icon-18px"></i>
                      </span>
                    </div>
                    <div>
                      <div class="fw-semibold">{{ $asset->name }}</div>
                      <div class="text-muted small">{{ $asset->type_label }}</div>
                    </div>
                  </div>
                </td>
                {{-- Miktar --}}
                <td class="text-end">
                  <span class="fw-medium">
                    {{ rtrim(rtrim(number_format((float)$asset->quantity, 8, ',', '.'), '0'), ',') }}
                  </span>
                </td>
                {{-- Maliyet (alış fiyatı / birim) --}}
                <td class="text-end">
                  <div class="fw-medium">₺{{ number_format((float)$asset->buy_price_try, 2, ',', '.') }}</div>
                  <div class="text-muted small">Toplam: ₺{{ number_format($asset->buy_value_try, 0, ',', '.') }}</div>
                </td>
                {{-- Güncel değer --}}
                <td class="text-end">
                  <div class="fw-bold">₺{{ number_format($asset->current_value_try, 0, ',', '.') }}</div>
                  <div class="text-muted small">₺{{ number_format($asset->current_price_try, 2, ',', '.') }}/birim</div>
                </td>
                {{-- Kar/Zarar --}}
                <td class="text-end">
                  <span class="badge bg-label-{{ $isGain ? 'success' : 'danger' }} fs-6 fw-semibold">
                    {{ $glSign }}₺{{ number_format(abs($asset->gain_loss_try), 0, ',', '.') }}
                  </span>
                  <div class="text-muted small mt-1">
                    {{ $glSign }}%{{ number_format(abs($asset->gain_loss_pct), 2, ',', '.') }}
                  </div>
                </td>
                {{-- Sil butonu --}}
                <td class="text-center">
                  <form action="{{ route('investments.destroy', $asset->id) }}" method="POST" class="d-inline">
                    @csrf @method('DELETE')
                    <button type="button"
                            class="btn btn-icon btn-sm btn-text-danger btn-swal-delete"
                            data-name="{{ $asset->name }}"
                            title="Varlığı Sil">
                      <i class="icon-base ti tabler-trash icon-18px"></i>
                    </button>
                  </form>
                </td>
              </tr>
              @endforeach
            </tbody>
          </table>
        </div>
        @endif
      </div>
    </div>

    {{-- ── Dağılım grafiği (right) ─────────────────────────────────────────── --}}
    <div class="col-xl-4">
      <div class="card h-100">
        <div class="card-header py-3">
          <h5 class="mb-0">Varlık Dağılımı</h5>
        </div>
        <div class="card-body d-flex align-items-center justify-content-center">
          @if($assets->isEmpty())
            <div class="text-center py-6">
              <i class="icon-base ti tabler-chart-donut icon-64px text-muted mb-3 d-block"></i>
              <p class="text-muted small mb-0">Grafik için en az bir varlık ekleyin.</p>
            </div>
          @else
            <div id="portfolioDonutChart" style="min-height:290px;width:100%;"></div>
          @endif
        </div>
      </div>
    </div>

  </div>

  {{-- ══ Add Asset Modal ══════════════════════════════════════════════════════ --}}
  <div class="modal fade" id="addAssetModal" tabindex="-1" aria-labelledby="addAssetModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
      <form action="{{ route('investments.store') }}" method="POST">
        @csrf
        <div class="modal-content">

          <div class="modal-header">
            <h5 class="modal-title" id="addAssetModalLabel">
              <i class="icon-base ti tabler-plus me-1"></i>Varlık Ekle
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Kapat"></button>
          </div>

          <div class="modal-body">

            @if($errors->any())
            <div class="alert alert-danger alert-dismissible mb-4" role="alert">
              <i class="icon-base ti tabler-alert-circle me-2"></i>
              <ul class="mb-0 ps-3">
                @foreach($errors->all() as $error)
                  <li>{{ $error }}</li>
                @endforeach
              </ul>
              <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
            @endif

            {{-- Satır 1: Varlık türü + Ad/Ticker --}}
            <div class="row g-4 mb-4">
              <div class="col-md-6">
                <label class="form-label" for="asset_type">Varlık Türü <span class="text-danger">*</span></label>
                <select name="asset_type" id="asset_type"
                        class="form-select @error('asset_type') is-invalid @enderror" required>
                  <option value="" disabled {{ old('asset_type') ? '' : 'selected' }}>Seçiniz…</option>
                  <option value="gold_gram"     {{ old('asset_type') === 'gold_gram'     ? 'selected' : '' }}>Altın (gram)</option>
                  <option value="gold_quarter"  {{ old('asset_type') === 'gold_quarter'  ? 'selected' : '' }}>Çeyrek Altın</option>
                  <option value="gold_republic" {{ old('asset_type') === 'gold_republic' ? 'selected' : '' }}>Cumhuriyet Altını</option>
                  <option value="usd"           {{ old('asset_type') === 'usd'           ? 'selected' : '' }}>Amerikan Doları (USD)</option>
                  <option value="eur"           {{ old('asset_type') === 'eur'           ? 'selected' : '' }}>Euro (EUR)</option>
                  <option value="gbp"           {{ old('asset_type') === 'gbp'           ? 'selected' : '' }}>İngiliz Sterlini (GBP)</option>
                  <option value="btc"           {{ old('asset_type') === 'btc'           ? 'selected' : '' }}>Bitcoin (BTC)</option>
                  <option value="eth"           {{ old('asset_type') === 'eth'           ? 'selected' : '' }}>Ethereum (ETH)</option>
                  <option value="bist"          {{ old('asset_type') === 'bist'          ? 'selected' : '' }}>Hisse Senedi (BIST)</option>
                  <option value="fund"          {{ old('asset_type') === 'fund'          ? 'selected' : '' }}>Yatırım Fonu</option>
                  <option value="mevduat"       {{ old('asset_type') === 'mevduat'       ? 'selected' : '' }}>Vadeli Mevduat</option>
                  <option value="other"         {{ old('asset_type') === 'other'         ? 'selected' : '' }}>Diğer</option>
                </select>
                @error('asset_type')
                  <div class="invalid-feedback">{{ $message }}</div>
                @enderror
              </div>

              <div class="col-md-6">
                <label class="form-label" for="asset_name">Ad / Ticker <span class="text-danger">*</span></label>
                <input type="text" name="name" id="asset_name"
                       class="form-control @error('name') is-invalid @enderror"
                       placeholder="örn: THYAO, Altın gram, BTC"
                       value="{{ old('name') }}" maxlength="120" required>
                @error('name')
                  <div class="invalid-feedback">{{ $message }}</div>
                @enderror
              </div>
            </div>

            {{-- Satır 2: Miktar + Alış fiyatı --}}
            <div class="row g-4 mb-4">
              <div class="col-md-6">
                <label class="form-label" for="asset_quantity">Miktar <span class="text-danger">*</span></label>
                <input type="number" name="quantity" id="asset_quantity"
                       class="form-control @error('quantity') is-invalid @enderror"
                       placeholder="örn: 10 veya 0.5"
                       step="0.0001" min="0.0001"
                       value="{{ old('quantity') }}" required>
                @error('quantity')
                  <div class="invalid-feedback">{{ $message }}</div>
                @enderror
              </div>

              <div class="col-md-6">
                <label class="form-label" for="asset_buy_price">Alış Fiyatı (₺/birim) <span class="text-danger">*</span></label>
                <div class="input-group">
                  <span class="input-group-text">₺</span>
                  <input type="number" name="buy_price_try" id="asset_buy_price"
                         class="form-control @error('buy_price_try') is-invalid @enderror"
                         placeholder="0.00"
                         step="0.01" min="0.01"
                         value="{{ old('buy_price_try') }}" required>
                  @error('buy_price_try')
                    <div class="invalid-feedback">{{ $message }}</div>
                  @enderror
                </div>
              </div>
            </div>

            {{-- Satır 3: Alış tarihi --}}
            <div class="row g-4 mb-4">
              <div class="col-md-6">
                <label class="form-label" for="asset_buy_date">Alış Tarihi <span class="text-danger">*</span></label>
                <input type="date" name="buy_date" id="asset_buy_date"
                       class="form-control @error('buy_date') is-invalid @enderror"
                       value="{{ old('buy_date', date('Y-m-d')) }}" required>
                @error('buy_date')
                  <div class="invalid-feedback">{{ $message }}</div>
                @enderror
              </div>
            </div>

            {{-- Notlar --}}
            <div class="mb-2">
              <label class="form-label" for="asset_notes">Notlar <span class="text-muted small">(opsiyonel)</span></label>
              <textarea name="notes" id="asset_notes"
                        class="form-control @error('notes') is-invalid @enderror"
                        rows="2"
                        placeholder="Ek bilgi, strateji notu…">{{ old('notes') }}</textarea>
              @error('notes')
                <div class="invalid-feedback">{{ $message }}</div>
              @enderror
            </div>

          </div>{{-- /modal-body --}}

          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-primary">
              <i class="icon-base ti tabler-device-floppy me-1"></i>Portföye Ekle
            </button>
          </div>

        </div>
      </form>
    </div>
  </div>

  {{-- ══ JavaScript ═══════════════════════════════════════════════════════════ --}}
  <x-slot name="pageJs">
    <script src="{{ asset('assets/vendor/libs/apex-charts/apexcharts.js') }}"></script>
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
    <script>
    (function () {
      'use strict';

      // ── Re-open modal if validation errors exist ──────────────────────────
      @if($errors->any())
      bootstrap.Modal.getOrCreateInstance(document.getElementById('addAssetModal')).show();
      @endif

      // ── SweetAlert2 delete confirmation ──────────────────────────────────
      document.querySelectorAll('.btn-swal-delete').forEach(function (btn) {
        btn.addEventListener('click', function () {
          const name = this.dataset.name;
          Swal.fire({
            title: '"' + name + '" silinsin mi?',
            text: 'Bu işlem geri alınamaz.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#EA5455',
            cancelButtonColor: '#6c757d',
            confirmButtonText: 'Evet, sil',
            cancelButtonText: 'Vazgeç',
            reverseButtons: true,
          }).then(function (result) {
            if (result.isConfirmed) {
              btn.closest('form').submit();
            }
          });
        });
      });

      // ── ApexCharts donut ──────────────────────────────────────────────────
      const chartEl = document.getElementById('portfolioDonutChart');
      if (!chartEl) return;

      const isDark    = document.documentElement.getAttribute('data-bs-theme') === 'dark';
      const fontFam   = "'Public Sans', sans-serif";
      const textColor = isDark ? '#b4b7bd' : '#6e6b7b';

      const chartData = @json($chartData);
      if (!chartData || chartData.length === 0) return;

      const labels = chartData.map(function (d) { return d.label; });
      const values = chartData.map(function (d) { return d.value; });

      const palette = [
        '#7367F0', '#28C76F', '#FF9F43', '#EA5455', '#00CFE8',
        '#38B2AC', '#ED64A6', '#9F7AEA', '#F59E0B', '#6EE7B7',
        '#FCA5A5', '#93C5FD',
      ];

      new ApexCharts(chartEl, {
        chart: {
          type: 'donut',
          height: 290,
          fontFamily: fontFam,
          background: 'transparent',
          toolbar: { show: false },
        },
        series: values,
        labels: labels,
        colors: palette,
        legend: {
          position: 'bottom',
          fontFamily: fontFam,
          fontSize: '12px',
          labels: { colors: textColor },
          itemMargin: { horizontal: 6, vertical: 4 },
        },
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
                  fontSize: '13px',
                  color: textColor,
                  formatter: function (w) {
                    var total = w.globals.seriesTotals.reduce(function (a, b) { return a + b; }, 0);
                    return '₺' + total.toLocaleString('tr-TR', { maximumFractionDigits: 0 });
                  },
                },
                value: {
                  fontFamily: fontFam,
                  fontSize: '18px',
                  fontWeight: 700,
                  color: textColor,
                  formatter: function (val) {
                    return '₺' + parseFloat(val).toLocaleString('tr-TR', { maximumFractionDigits: 0 });
                  },
                },
              },
            },
          },
        },
        tooltip: {
          theme: isDark ? 'dark' : 'light',
          y: {
            formatter: function (val) {
              return '₺' + val.toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
            },
          },
        },
        responsive: [{
          breakpoint: 480,
          options: {
            chart: { height: 250 },
            legend: { position: 'bottom' },
          },
        }],
      }).render();

    }());
    </script>
  </x-slot>

</x-app-layout>
