<x-app-layout>
  <x-slot name="title">Piyasa & Kur Alarmları</x-slot>

  @push('styles')
  <style>
    /* ── Ticker bar ──────────────────────────────────────────────────── */
    .ticker-wrap { overflow: hidden; background: var(--bs-body-bg); border-bottom: 1px solid var(--bs-border-color); }
    .ticker-inner { display: flex; gap: 0; animation: ticker-scroll 40s linear infinite; width: max-content; }
    .ticker-wrap:hover .ticker-inner { animation-play-state: paused; }
    .ticker-item { display: flex; align-items: center; gap: .5rem; padding: .55rem 1.5rem;
                   border-right: 1px solid var(--bs-border-color); white-space: nowrap; font-size: .8rem; }
    @keyframes ticker-scroll { 0% { transform: translateX(0); } 100% { transform: translateX(-50%); } }

    /* ── Live dot ────────────────────────────────────────────────────── */
    .live-dot { width: 8px; height: 8px; border-radius: 50%; background: #28c76f; display: inline-block;
                animation: pulse-dot 1.4s ease-in-out infinite; }
    @keyframes pulse-dot { 0%,100% { opacity:1; transform:scale(1); } 50% { opacity:.4; transform:scale(.7); } }

    /* ── Rate cards ──────────────────────────────────────────────────── */
    .rate-card { transition: transform .15s, box-shadow .15s; cursor: default; }
    .rate-card:hover { transform: translateY(-3px); box-shadow: 0 8px 24px rgba(0,0,0,.12); }
    .sparkline-canvas { width: 100% !important; height: 56px !important; }

    /* ── Change badge ────────────────────────────────────────────────── */
    .chg-up   { color: #28c76f; background: rgba(40,199,111,.12); }
    .chg-down { color: #ea5455; background: rgba(234,84,85,.12);  }
    .chg-flat { color: #6c757d; background: rgba(108,117,125,.1); }
    .chg-badge { display:inline-flex; align-items:center; gap:.2rem;
                 padding:.15rem .5rem; border-radius: 20px; font-size:.75rem; font-weight:600; }
  </style>
  @endpush

  {{-- ── Page Header ────────────────────────────────────────────────── --}}
  <div class="d-flex align-items-center justify-content-between mb-4 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Piyasa Verileri</h4>
      <p class="text-muted small mb-0">
        <span class="live-dot me-1"></span>
        Canlı TCMB + gram altın fiyatları &mdash;
        <span id="last-updated">{{ now()->format('d.m.Y H:i') }}</span>
        <span class="ms-2 text-muted" id="refresh-countdown">(60s)</span>
      </p>
    </div>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addAlarmModal">
      <i class="icon-base ti tabler-bell-plus me-1"></i>Alarm Ekle
    </button>
  </div>

  {{-- Flash alerts --}}
  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-4" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif
  @if(session('error'))
    <div class="alert alert-danger alert-dismissible mb-4" role="alert">
      <i class="icon-base ti tabler-alert-circle me-2"></i>{{ session('error') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  {{-- ── Ticker bar ──────────────────────────────────────────────────── --}}
  <div class="card mb-5 py-0 overflow-hidden">
    <div class="ticker-wrap">
      <div class="ticker-inner" id="ticker-inner">
        @php $tickerItems = array_values($ratesData); @endphp
        @foreach(array_merge($tickerItems, $tickerItems) as $t)
        <div class="ticker-item">
          <span>{{ $t['flag'] }}</span>
          <span class="fw-semibold">{{ $t['currency'] }}/TRY</span>
          <span class="fw-bold">₺{{ number_format($t['rate'], 2, ',', '.') }}</span>
          @php $pct = $t['change_pct']; @endphp
          @if($pct > 0)
            <span class="chg-badge chg-up"><i class="ti tabler-arrow-up" style="font-size:.7rem"></i>+{{ $pct }}%</span>
          @elseif($pct < 0)
            <span class="chg-badge chg-down"><i class="ti tabler-arrow-down" style="font-size:.7rem"></i>{{ $pct }}%</span>
          @else
            <span class="chg-badge chg-flat">±0%</span>
          @endif
        </div>
        @endforeach
      </div>
    </div>
  </div>

  {{-- ── Rate Cards ──────────────────────────────────────────────────── --}}
  <div class="row g-4 mb-5" id="rate-cards-row">
    @foreach($ratesData as $code => $r)
    @php
      $accent = match($code) {
        'USD' => 'success', 'EUR' => 'primary', 'GBP' => 'warning',
        'XAU' => 'danger',  'CHF' => 'info',    'JPY' => 'secondary', 'AUD' => 'dark',
        default => 'secondary'
      };
      $pct = $r['change_pct'];
    @endphp
    <div class="col-6 col-xl-3" data-currency="{{ $code }}">
      <div class="card rate-card h-100 position-relative overflow-hidden">
        <div class="accent-bar bg-{{ $accent }}"></div>
        <div class="card-body pt-4 pb-2">
          <div class="d-flex align-items-start justify-content-between mb-2">
            <div>
              <div class="text-muted small">{{ $r['flag'] }} {{ $r['name'] }}</div>
              <div class="h4 fw-bold mb-0 text-heading mt-1" data-field="rate">
                ₺{{ number_format($r['rate'], 2, ',', '.') }}
              </div>
            </div>
            <div>
              @if($pct > 0)
                <span class="chg-badge chg-up" data-field="chg">
                  <i class="ti tabler-trending-up" style="font-size:.75rem"></i>+{{ $pct }}%
                </span>
              @elseif($pct < 0)
                <span class="chg-badge chg-down" data-field="chg">
                  <i class="ti tabler-trending-down" style="font-size:.75rem"></i>{{ $pct }}%
                </span>
              @else
                <span class="chg-badge chg-flat" data-field="chg">±0%</span>
              @endif
            </div>
          </div>
          <div class="text-muted" style="font-size:.7rem">
            Önceki: ₺{{ number_format($r['prev_rate'], 2, ',', '.') }} &nbsp;|&nbsp;
            <span data-field="date">{{ \Carbon\Carbon::parse($r['date'])->format('d.m.Y') }}</span>
          </div>
          <canvas class="sparkline-canvas mt-3"
                  id="spark-{{ $code }}"
                  data-history="{{ json_encode($r['history']) }}"
                  data-labels="{{ json_encode($r['labels']) }}"
                  data-accent="{{ $accent }}"
                  data-change="{{ $pct }}"></canvas>
        </div>
        <div class="card-footer py-2 border-top-0">
          <button class="btn btn-sm btn-outline-{{ $accent }} w-100 alarm-prefill"
                  data-currency="{{ $code }}"
                  data-rate="{{ $r['rate'] }}"
                  data-bs-toggle="modal"
                  data-bs-target="#addAlarmModal">
            <i class="ti tabler-bell-plus me-1"></i>Alarm Kur
          </button>
        </div>
      </div>
    </div>
    @endforeach
  </div>

  {{-- ── Alert List ───────────────────────────────────────────────────── --}}
  <div class="card mb-5">
    <div class="card-header d-flex align-items-center justify-content-between py-3">
      <h6 class="mb-0 fw-semibold"><i class="ti tabler-bell me-2 text-primary"></i>Alarmlarım</h6>
      <span class="badge bg-label-primary">{{ $alerts->count() }}</span>
    </div>

    @if($alerts->isEmpty())
      <div class="card-body text-center py-8">
        <i class="icon-base ti tabler-bell-off icon-64px text-muted mb-4 d-block"></i>
        <h5 class="mb-2">Henüz alarm eklenmedi</h5>
        <p class="text-muted mb-4">Kur kartlarındaki "Alarm Kur" düğmesine tıklayarak hızlıca ekleyebilirsin.</p>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addAlarmModal">
          <i class="icon-base ti tabler-bell-plus me-1"></i>İlk Alarmı Ekle
        </button>
      </div>
    @else
      <div class="table-responsive">
        <table class="table table-hover mb-0">
          <thead class="paranette-thead">
            <tr>
              <th class="ps-4 py-3">Kur</th>
              <th class="py-3">Koşul</th>
              <th class="py-3">Eşik</th>
              <th class="py-3">Güncel</th>
              <th class="py-3">Fark</th>
              <th class="py-3">Durum</th>
              <th class="py-3 pe-4 text-end">Sil</th>
            </tr>
          </thead>
          <tbody>
            @foreach($alerts as $alert)
            @php
              $key = $alert->currency === 'GOLD' ? 'XAU' : $alert->currency;
              $meta = $labels[$key] ?? ['name'=>$key, 'flag'=>'', 'symbol'=>''];
              $currColor = match($key) {
                'USD'=>'success','EUR'=>'primary','GBP'=>'warning','XAU'=>'danger',
                'CHF'=>'info','JPY'=>'secondary','AUD'=>'dark', default=>'secondary'
              };
              $dist = $alert->current_rate !== null
                ? round($alert->current_rate - (float)$alert->threshold, 2)
                : null;
            @endphp
            <tr>
              <td class="ps-4 py-3">
                <div class="d-flex align-items-center gap-2">
                  <span class="fs-5">{{ $meta['flag'] }}</span>
                  <div>
                    <div class="fw-semibold small">{{ $key }}/TRY</div>
                    <div class="text-muted" style="font-size:.7rem">{{ $meta['name'] }}</div>
                  </div>
                </div>
              </td>
              <td class="py-3">
                @if($alert->condition === 'above')
                  <span class="badge bg-label-danger">
                    <i class="ti tabler-arrow-up icon-12px me-1"></i>Üstüne Geçince
                  </span>
                @else
                  <span class="badge bg-label-info">
                    <i class="ti tabler-arrow-down icon-12px me-1"></i>Altına Düşünce
                  </span>
                @endif
              </td>
              <td class="py-3 fw-semibold">₺{{ number_format((float)$alert->threshold, 2, ',', '.') }}</td>
              <td class="py-3">
                @if($alert->current_rate !== null)
                  <span class="fw-semibold">₺{{ number_format($alert->current_rate, 2, ',', '.') }}</span>
                @else
                  <span class="text-muted">—</span>
                @endif
              </td>
              <td class="py-3">
                @if($dist !== null)
                  @if($dist > 0)
                    <span class="chg-badge chg-up">+₺{{ number_format($dist,2,',','.') }}</span>
                  @elseif($dist < 0)
                    <span class="chg-badge chg-down">₺{{ number_format($dist,2,',','.') }}</span>
                  @else
                    <span class="chg-badge chg-flat">±0</span>
                  @endif
                @else
                  <span class="text-muted">—</span>
                @endif
              </td>
              <td class="py-3">
                @if($alert->is_triggered)
                  <span class="badge bg-danger">
                    <i class="ti tabler-bell-ringing icon-12px me-1"></i>Tetiklendi
                  </span>
                @else
                  <span class="badge bg-label-success">
                    <i class="ti tabler-bell icon-12px me-1"></i>İzleniyor
                  </span>
                @endif
              </td>
              <td class="py-3 pe-4 text-end">
                <form action="{{ route('fx-alerts.destroy', $alert->id) }}" method="POST" class="d-inline">
                  @csrf @method('DELETE')
                  <button type="button"
                          class="btn btn-icon btn-sm btn-text-danger btn-swal-delete"
                          data-name="{{ $key }}/TRY"
                          title="Sil">
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

  {{-- ── Info Bar ─────────────────────────────────────────────────────── --}}
  <div class="alert alert-info d-flex gap-3 align-items-start mb-0">
    <i class="ti tabler-info-circle fs-5 mt-1 flex-shrink-0"></i>
    <div class="small">
      <strong>Veri Kaynakları:</strong>
      Döviz kurları TCMB (Türkiye Cumhuriyet Merkez Bankası) XML servisi üzerinden alınır.
      Gram altın fiyatı <em>gold-api.com</em>'dan USD/troy-oz olarak çekilip
      USD/TRY kuru ve 31.1035 sabitiyle gram başı TRY'ye çevrilir.
      Veriler hafta içi saat 15:45'te otomatik güncellenir; sayfa her 60 saniyede bir
      <a href="{{ route('fx-alerts.live') }}" class="alert-link">/fx-alerts/live</a>
      endpoint'ini sorgular.
    </div>
  </div>

  {{-- ── Add Alarm Modal ─────────────────────────────────────────────── --}}
  <div class="modal fade" id="addAlarmModal" tabindex="-1">
    <div class="modal-dialog">
      <form action="{{ route('fx-alerts.store') }}" method="POST">
        @csrf
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              <i class="icon-base ti tabler-bell-plus me-2 text-primary"></i>Kur Alarmı Ekle
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">
            @if($errors->any())
            <div class="alert alert-danger alert-dismissible mb-4">
              <ul class="mb-0 ps-3">
                @foreach($errors->all() as $e) <li>{{ $e }}</li> @endforeach
              </ul>
              <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
            @endif

            <div class="mb-4">
              <label class="form-label fw-semibold">Kur / Emtia <span class="text-danger">*</span></label>
              <select name="currency" id="modalCurrency" class="form-select @error('currency') is-invalid @enderror" required>
                <option value="" disabled selected>Seç...</option>
                @foreach($ratesData as $code => $r)
                <option value="{{ $code }}" {{ old('currency') === $code ? 'selected' : '' }}>
                  {{ $r['flag'] }} {{ $code }}/TRY — {{ $r['name'] }} (₺{{ number_format($r['rate'],2,',','.') }})
                </option>
                @endforeach
              </select>
              @error('currency') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </div>

            <div class="mb-4">
              <label class="form-label fw-semibold">Koşul <span class="text-danger">*</span></label>
              <div class="d-flex gap-4 mt-1">
                <div class="form-check">
                  <input class="form-check-input" type="radio" name="condition" id="condAbove" value="above"
                         {{ old('condition','above') === 'above' ? 'checked' : '' }} required>
                  <label class="form-check-label" for="condAbove">
                    <i class="ti tabler-arrow-up text-danger me-1"></i>Üstüne Geçince
                  </label>
                </div>
                <div class="form-check">
                  <input class="form-check-input" type="radio" name="condition" id="condBelow" value="below"
                         {{ old('condition') === 'below' ? 'checked' : '' }}>
                  <label class="form-check-label" for="condBelow">
                    <i class="ti tabler-arrow-down text-info me-1"></i>Altına Düşünce
                  </label>
                </div>
              </div>
              @error('condition') <div class="text-danger small mt-1">{{ $message }}</div> @enderror
            </div>

            <div class="mb-4">
              <label class="form-label fw-semibold">Eşik Fiyat (₺) <span class="text-danger">*</span></label>
              <div class="input-group">
                <span class="input-group-text">₺</span>
                <input type="number" name="threshold" id="modalThreshold"
                       class="form-control @error('threshold') is-invalid @enderror"
                       step="0.01" min="0.01"
                       placeholder="örn: 34.50"
                       value="{{ old('threshold') }}" required>
                @error('threshold') <div class="invalid-feedback">{{ $message }}</div> @enderror
              </div>
              <div class="form-text" id="modalHint">Seçilen kur için mevcut oran yukarıda görünür.</div>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-primary">
              <i class="icon-base ti tabler-bell-plus me-1"></i>Alarm Ekle
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>

  <x-slot name="pageJs">
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
  <script>
  // ── Sparkline charts ────────────────────────────────────────────────
  const accentColors = {
    success: '#28c76f', primary: '#7367f0', warning: '#ff9f43',
    danger: '#ea5455', info: '#00cfe8', secondary: '#a8aaae', dark: '#4b4b4b'
  };

  document.querySelectorAll('.sparkline-canvas').forEach(function(canvas) {
    const history = JSON.parse(canvas.dataset.history || '[]');
    const lbls    = JSON.parse(canvas.dataset.labels  || '[]');
    const accent  = canvas.dataset.accent || 'primary';
    const chg     = parseFloat(canvas.dataset.change  || '0');
    const color   = accentColors[accent] || '#7367f0';

    if (!history.length) return;

    new Chart(canvas, {
      type: 'line',
      data: {
        labels: lbls,
        datasets: [{
          data: history,
          borderColor: color,
          borderWidth: 1.5,
          pointRadius: 0,
          fill: true,
          backgroundColor: (ctx) => {
            const g = ctx.chart.ctx.createLinearGradient(0,0,0,56);
            g.addColorStop(0, color + '33');
            g.addColorStop(1, color + '00');
            return g;
          },
          tension: 0.4,
        }]
      },
      options: {
        animation: false,
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false }, tooltip: {
          callbacks: { label: ctx => '₺' + ctx.parsed.y.toLocaleString('tr-TR', {minimumFractionDigits:2}) }
        }},
        scales: { x: { display: false }, y: { display: false } },
      }
    });
  });

  // ── Delete confirm ──────────────────────────────────────────────────
  document.querySelectorAll('.btn-swal-delete').forEach(function(btn) {
    btn.addEventListener('click', function() {
      const name = this.dataset.name;
      Swal.fire({
        title: '"' + name + '" alarmını sil?',
        text: 'Bu işlem geri alınamaz.',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#6c757d',
        confirmButtonText: 'Evet, sil',
        cancelButtonText: 'Vazgeç',
        reverseButtons: true,
      }).then(r => { if (r.isConfirmed) btn.closest('form').submit(); });
    });
  });

  // ── Prefill modal from card buttons ────────────────────────────────
  document.querySelectorAll('.alarm-prefill').forEach(function(btn) {
    btn.addEventListener('click', function() {
      const cur  = this.dataset.currency;
      const rate = parseFloat(this.dataset.rate);
      const sel  = document.getElementById('modalCurrency');
      if (sel) sel.value = cur;
      const thr  = document.getElementById('modalThreshold');
      if (thr && !thr.value) thr.value = rate.toFixed(2);
      const hint = document.getElementById('modalHint');
      if (hint) hint.textContent = 'Mevcut ' + cur + '/TRY: ₺' + rate.toLocaleString('tr-TR', {minimumFractionDigits:2});
    });
  });

  // ── Re-open modal if validation failed ─────────────────────────────
  @if($errors->any())
  bootstrap.Modal.getOrCreateInstance(document.getElementById('addAlarmModal')).show();
  @endif

  // ── Auto-refresh every 60 s ─────────────────────────────────────────
  const LIVE_URL = '{{ route('fx-alerts.live') }}';
  let countdown  = 60;

  function updateCountdownUI() {
    const el = document.getElementById('refresh-countdown');
    if (el) el.textContent = '(' + countdown + 's)';
  }

  setInterval(function() {
    countdown--;
    if (countdown <= 0) countdown = 60;
    updateCountdownUI();
  }, 1000);

  setInterval(function() {
    fetch(LIVE_URL, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
      .then(r => r.ok ? r.json() : null)
      .then(data => {
        if (!data) return;
        const updated = document.getElementById('last-updated');
        if (updated) updated.textContent = data.fetched_at;
        Object.entries(data.rates).forEach(([code, r]) => {
          const col = document.querySelector('[data-currency="' + code + '"]');
          if (!col) return;
          const rateEl = col.querySelector('[data-field="rate"]');
          const chgEl  = col.querySelector('[data-field="chg"]');
          const dateEl = col.querySelector('[data-field="date"]');
          if (rateEl) rateEl.textContent = '₺' + parseFloat(r.rate).toLocaleString('tr-TR',{minimumFractionDigits:2});
          if (dateEl) dateEl.textContent = r.date;
          if (chgEl) {
            const pct = r.change_pct;
            chgEl.className = 'chg-badge ' + (pct > 0 ? 'chg-up' : pct < 0 ? 'chg-down' : 'chg-flat');
            chgEl.textContent = (pct > 0 ? '+' : '') + pct + '%';
          }
        });
      })
      .catch(() => {});
    countdown = 60;
  }, 60000);
  </script>
  </x-slot>
</x-app-layout>
