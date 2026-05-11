<x-app-layout>
<x-slot name="title">Piyasa & Kur Alarmları</x-slot>

<style>
/* ── Ticker ─────────────────────────────────────────── */
.mkt-ticker-wrap{overflow:hidden;border-bottom:1px solid var(--bs-border-color);background:var(--bs-body-bg)}
.mkt-ticker-track{display:flex;width:max-content;animation:ticker 45s linear infinite}
.mkt-ticker-wrap:hover .mkt-ticker-track{animation-play-state:paused}
.mkt-ticker-item{display:flex;align-items:center;gap:.4rem;padding:.5rem 1.25rem;
                 border-right:1px solid var(--bs-border-color);white-space:nowrap;font-size:.8rem}
@keyframes ticker{0%{transform:translateX(0)}100%{transform:translateX(-50%)}}

/* ── Rate card ──────────────────────────────────────── */
.mkt-card{transition:transform .15s ease,box-shadow .15s ease}
.mkt-card:hover{transform:translateY(-4px);box-shadow:0 10px 28px rgba(0,0,0,.13)}
.mkt-rate{font-size:1.65rem;font-weight:700;letter-spacing:-.5px;line-height:1.1}
.mkt-pair{font-size:.7rem;font-weight:600;letter-spacing:.5px;text-transform:uppercase}
.mkt-sparkline{height:52px;width:100%}

/* ── Change pills ───────────────────────────────────── */
.pill{display:inline-flex;align-items:center;gap:.18rem;padding:.2rem .55rem;
      border-radius:20px;font-size:.72rem;font-weight:700;line-height:1}
.pill-up  {color:#28c76f;background:rgba(40,199,111,.13)}
.pill-dn  {color:#ea5455;background:rgba(234,84,85,.13)}
.pill-flat{color:#a8aaae;background:rgba(168,170,174,.12)}

/* ── Live dot ───────────────────────────────────────── */
.live-dot{display:inline-block;width:8px;height:8px;border-radius:50%;background:#28c76f;
          animation:pulse 1.4s ease-in-out infinite}
@keyframes pulse{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.35;transform:scale(.65)}}

/* ── Source chip ────────────────────────────────────── */
.src-chip{font-size:.7rem;padding:.15rem .55rem;border-radius:12px;font-weight:600}
.src-yahoo  {background:rgba(0,207,232,.13);color:#00cfe8}
.src-open-er{background:rgba(115,103,240,.13);color:#7367f0}
.src-db     {background:rgba(168,170,174,.13);color:#a8aaae}

/* ── Alert table accent ─────────────────────────────── */
.triggered-row td{background:rgba(234,84,85,.04)}
</style>

{{-- ═══════════════════════════ HEADER ═══════════════════════════════ --}}
<div class="d-flex align-items-start justify-content-between mb-4 flex-wrap gap-3">
  <div>
    <h4 class="fw-bold mb-1 text-heading">Piyasa & Kur Alarmları</h4>
    <p class="text-muted small mb-0 d-flex align-items-center gap-2 flex-wrap">
      <span class="live-dot"></span>
      <span id="hdr-time">—</span>
      <span class="src-chip src-db" id="hdr-src">DB</span>
      <span class="text-muted">·</span>
      <span id="hdr-countdown" class="text-muted">güncelleniyor…</span>
    </p>
  </div>
  <button class="btn btn-primary d-flex align-items-center gap-1"
          data-bs-toggle="modal" data-bs-target="#addAlarmModal">
    <i class="ti tabler-bell-plus icon-16px"></i>Alarm Ekle
  </button>
</div>

{{-- flash --}}
@if(session('success'))
<div class="alert alert-success alert-dismissible mb-4">
  <i class="ti tabler-circle-check me-2"></i>{{ session('success') }}
  <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
</div>
@endif
@if(session('error'))
<div class="alert alert-danger alert-dismissible mb-4">
  <i class="ti tabler-alert-circle me-2"></i>{{ session('error') }}
  <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
</div>
@endif

{{-- ═══════════════════════════ TICKER ════════════════════════════════ --}}
<div class="card mb-5 py-0 overflow-hidden border-0 shadow-none">
  <div class="mkt-ticker-wrap">
    <div class="mkt-ticker-track" id="ticker-track">
      @php $tickerSet = array_values($ratesData); @endphp
      @foreach(array_merge($tickerSet, $tickerSet) as $t)
      <div class="mkt-ticker-item" data-ticker-code="{{ $t['currency'] }}">
        <span>{{ $t['flag'] }}</span>
        <span class="fw-semibold">{{ $t['currency'] }}/TRY</span>
        <span class="fw-bold" data-ticker-rate>
          ₺{{ number_format($t['rate'], $t['currency']==='XAU'?0:2, ',', '.') }}
        </span>
        @php $p=$t['change_pct']; @endphp
        <span class="pill {{ $p>0?'pill-up':($p<0?'pill-dn':'pill-flat') }}" data-ticker-chg>
          {{ $p>0?'▲':'▼' }} {{ abs($p) }}%
        </span>
      </div>
      @endforeach
    </div>
  </div>
</div>

{{-- ═══════════════════════ RATE CARDS GRID ═══════════════════════════ --}}
<div class="row g-4 mb-5">
  @foreach($ratesData as $code => $r)
  @php
    $color = $r['color'];
    $pct   = $r['change_pct'];
    $dpFmt = $code === 'XAU' ? 0 : 2;
  @endphp
  <div class="col-6 col-md-4 col-xxl-3">
    <div class="card mkt-card h-100 position-relative overflow-hidden" data-card="{{ $code }}">
      <div class="accent-bar bg-{{ $color }}"></div>
      <div class="card-body pt-4 pb-2">

        {{-- pair label + change pill --}}
        <div class="d-flex align-items-center justify-content-between mb-3">
          <div>
            <div class="d-flex align-items-center gap-2">
              <span style="font-size:1.3rem">{{ $r['flag'] }}</span>
              <div>
                <span class="mkt-pair text-muted">{{ $code }}/TRY</span>
                <div class="text-muted" style="font-size:.68rem;margin-top:1px">{{ $r['name'] }}</div>
              </div>
            </div>
          </div>
          <span class="pill {{ $pct>0?'pill-up':($pct<0?'pill-dn':'pill-flat') }}" data-chg="{{ $code }}">
            @if($pct>0)<i class="ti tabler-trending-up" style="font-size:.7rem"></i>+{{ $pct }}%
            @elseif($pct<0)<i class="ti tabler-trending-down" style="font-size:.7rem"></i>{{ $pct }}%
            @else±0%@endif
          </span>
        </div>

        {{-- rate --}}
        <div class="mkt-rate text-heading mb-1" data-rate="{{ $code }}">
          ₺{{ number_format($r['rate'], $dpFmt, ',', '.') }}
        </div>
        <div class="text-muted mb-3" style="font-size:.69rem">
          Önceki: <span data-prev="{{ $code }}">₺{{ number_format($r['prev_rate'], $dpFmt, ',', '.') }}</span>
          &nbsp;·&nbsp;
          <span data-rdate="{{ $code }}">{{ \Carbon\Carbon::parse($r['date'])->format('d.m.Y') }}</span>
        </div>

        {{-- sparkline --}}
        <canvas id="spark-{{ $code }}" class="mkt-sparkline"
                data-history="{{ json_encode($r['history']) }}"
                data-labels="{{ json_encode($r['labels']) }}"
                data-color="{{ $color }}"
                data-change="{{ $pct }}"></canvas>
      </div>

      <div class="card-footer bg-transparent pt-0 pb-3 border-0">
        <button class="btn btn-sm btn-outline-{{ $color }} w-100 alarm-quick"
                data-currency="{{ $code }}"
                data-rate="{{ $r['rate'] }}"
                data-bs-toggle="modal" data-bs-target="#addAlarmModal">
          <i class="ti tabler-bell-plus me-1" style="font-size:.8rem"></i>Alarm Kur
        </button>
      </div>
    </div>
  </div>
  @endforeach
</div>

{{-- ════════════════════════ ALERTS TABLE ═════════════════════════════ --}}
<div class="card mb-5">
  <div class="card-header d-flex align-items-center justify-content-between py-3">
    <h6 class="mb-0 fw-semibold">
      <i class="ti tabler-bell me-2 text-primary"></i>Alarmlarım
    </h6>
    <div class="d-flex align-items-center gap-2">
      @php
        $triggered = $alerts->where('is_triggered', true)->count();
      @endphp
      @if($triggered > 0)
      <span class="badge bg-danger">{{ $triggered }} tetiklendi</span>
      @endif
      <span class="badge bg-label-primary">{{ $alerts->count() }} toplam</span>
    </div>
  </div>

  @if($alerts->isEmpty())
  <div class="card-body text-center py-8">
    <i class="ti tabler-bell-off icon-64px text-muted mb-3 d-block"></i>
    <h5 class="mb-2">Henüz alarm kurulmadı</h5>
    <p class="text-muted mb-4 small">Kur kartlarındaki <strong>Alarm Kur</strong> butonuna tıkla ya da sağ üstten ekle.</p>
    <button class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#addAlarmModal">
      <i class="ti tabler-bell-plus me-1"></i>İlk Alarmı Ekle
    </button>
  </div>
  @else
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0">
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
          $key    = $alert->currency === 'GOLD' ? 'XAU' : $alert->currency;
          $meta   = $labels[$key] ?? ['name'=>$key,'flag'=>'','color'=>'secondary'];
          $color  = $meta['color'];
          $dist   = $alert->current_rate !== null
                  ? round($alert->current_rate - (float)$alert->threshold, 2)
                  : null;
          $dpFmt  = $key === 'XAU' ? 0 : 2;
        @endphp
        <tr class="{{ $alert->is_triggered ? 'triggered-row' : '' }}">
          <td class="ps-4 py-3">
            <div class="d-flex align-items-center gap-2">
              <span style="font-size:1.15rem">{{ $meta['flag'] }}</span>
              <div>
                <div class="fw-semibold small">{{ $key }}/TRY</div>
                <div class="text-muted" style="font-size:.68rem">{{ $meta['name'] }}</div>
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
          <td class="py-3 fw-semibold small">
            ₺{{ number_format((float)$alert->threshold, $dpFmt, ',', '.') }}
          </td>
          <td class="py-3 small" data-alert-rate="{{ $key }}">
            @if($alert->current_rate !== null)
              ₺{{ number_format($alert->current_rate, $dpFmt, ',', '.') }}
            @else
              <span class="text-muted">—</span>
            @endif
          </td>
          <td class="py-3 small">
            @if($dist !== null)
              <span class="pill {{ $dist>0?'pill-up':($dist<0?'pill-dn':'pill-flat') }}">
                {{ $dist>0?'+':'' }}₺{{ number_format(abs($dist),$dpFmt,',','.') }}
              </span>
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
                      class="btn btn-icon btn-sm btn-text-danger btn-del"
                      data-name="{{ $key }}/TRY @ ₺{{ number_format((float)$alert->threshold,2,',','.') }}">
                <i class="ti tabler-trash icon-18px"></i>
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

{{-- ════════════════════ INFO / SOURCE FOOTER ══════════════════════════ --}}
<div class="alert alert-secondary d-flex gap-3 align-items-start mb-0 py-3">
  <i class="ti tabler-info-circle fs-5 mt-1 flex-shrink-0 text-muted"></i>
  <p class="mb-0 small text-muted">
    <strong>Veri hiyerarşisi:</strong>
    İlk olarak Yahoo Finance anlık FX verileri denenir (dakika başı);
    başarısız olursa <em>open.er-api.com</em> (saatlik) devreye girer;
    son çare olarak TCMB günlük verisi gösterilir.
    Gram altın her durumda <em>gold-api.com</em>'dan çekilir (USD/troy oz → TRY/gram).
    Japon Yeni 100 JPY = ₺X formatında gösterilmektedir.
  </p>
</div>

{{-- ════════════════════════ ADD ALARM MODAL ══════════════════════════ --}}
<div class="modal fade" id="addAlarmModal" tabindex="-1" aria-modal="true">
  <div class="modal-dialog modal-dialog-centered">
    <form action="{{ route('fx-alerts.store') }}" method="POST">
      @csrf
      <div class="modal-content">
        <div class="modal-header border-bottom-0 pb-0">
          <h5 class="modal-title fw-bold">
            <i class="ti tabler-bell-plus text-primary me-2"></i>Kur Alarmı Ekle
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>

        <div class="modal-body pt-3">
          @if($errors->any())
          <div class="alert alert-danger alert-dismissible mb-4">
            <ul class="mb-0 ps-3 small">
              @foreach($errors->all() as $e) <li>{{ $e }}</li> @endforeach
            </ul>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
          </div>
          @endif

          {{-- Live preview --}}
          <div class="card bg-label-primary border-0 mb-4 py-2 px-3 d-flex flex-row align-items-center justify-content-between"
               id="modal-preview" style="min-height:52px">
            <span class="text-muted small">Kur seçin…</span>
          </div>

          {{-- Currency --}}
          <div class="mb-4">
            <label class="form-label fw-semibold">Kur / Emtia <span class="text-danger">*</span></label>
            <select name="currency" id="modal-cur"
                    class="form-select @error('currency') is-invalid @enderror" required>
              <option value="" disabled {{ old('currency') ? '' : 'selected' }}>Seç…</option>
              @foreach($ratesData as $code => $r)
              <option value="{{ $code }}"
                      data-rate="{{ $r['rate'] }}"
                      data-color="{{ $r['color'] }}"
                      data-flag="{{ $r['flag'] }}"
                      data-name="{{ $r['name'] }}"
                      {{ old('currency') === $code ? 'selected' : '' }}>
                {{ $r['flag'] }} {{ $code }}/TRY — {{ $r['name'] }}
                &nbsp;(₺{{ number_format($r['rate'], $code==='XAU'?0:2, ',', '.') }})
              </option>
              @endforeach
            </select>
            @error('currency') <div class="invalid-feedback">{{ $message }}</div> @enderror
          </div>

          {{-- Condition --}}
          <div class="mb-4">
            <label class="form-label fw-semibold">Koşul <span class="text-danger">*</span></label>
            <div class="d-flex gap-3 mt-1">
              <div class="form-check">
                <input class="form-check-input" type="radio" name="condition"
                       id="cond-above" value="above"
                       {{ old('condition','above') === 'above' ? 'checked' : '' }} required>
                <label class="form-check-label" for="cond-above">
                  <span class="pill pill-dn me-1">▲</span>Üstüne Geçince
                </label>
              </div>
              <div class="form-check">
                <input class="form-check-input" type="radio" name="condition"
                       id="cond-below" value="below"
                       {{ old('condition') === 'below' ? 'checked' : '' }}>
                <label class="form-check-label" for="cond-below">
                  <span class="pill pill-up me-1">▼</span>Altına Düşünce
                </label>
              </div>
            </div>
            @error('condition') <div class="text-danger small mt-1">{{ $message }}</div> @enderror
          </div>

          {{-- Threshold --}}
          <div class="mb-2">
            <label class="form-label fw-semibold">Eşik Fiyat <span class="text-danger">*</span></label>
            <div class="input-group">
              <span class="input-group-text fw-bold">₺</span>
              <input type="number" name="threshold" id="modal-thr"
                     class="form-control @error('threshold') is-invalid @enderror"
                     step="0.01" min="0.01"
                     placeholder="örn: 38.50"
                     value="{{ old('threshold') }}" required>
              @error('threshold') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </div>
            <div class="form-text" id="modal-hint">Güncel kur seçilen para biriminde gösterilir.</div>
          </div>
        </div>

        <div class="modal-footer border-top-0 pt-0">
          <button type="button" class="btn btn-outline-secondary btn-sm" data-bs-dismiss="modal">İptal</button>
          <button type="submit" class="btn btn-primary btn-sm">
            <i class="ti tabler-bell-plus me-1"></i>Alarm Ekle
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
// ── palette ────────────────────────────────────────────────────────────
const COLORS = {
  success:'#28c76f', primary:'#7367f0', warning:'#ff9f43',
  danger:'#ea5455',  info:'#00cfe8',    secondary:'#a8aaae', dark:'#535c68'
};

// ── Chart.js sparklines (30-day DB history) ────────────────────────────
document.querySelectorAll('[id^="spark-"]').forEach(canvas => {
  const history = JSON.parse(canvas.dataset.history || '[]');
  const labels  = JSON.parse(canvas.dataset.labels  || '[]');
  const accent  = COLORS[canvas.dataset.color] || '#7367f0';
  const up      = parseFloat(canvas.dataset.change || '0') >= 0;
  if (!history.length) return;

  new Chart(canvas, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        data: history,
        borderColor: up ? '#28c76f' : '#ea5455',
        borderWidth: 1.5,
        pointRadius: 0,
        fill: true,
        backgroundColor: ctx => {
          const g = ctx.chart.ctx.createLinearGradient(0, 0, 0, 52);
          g.addColorStop(0, (up ? '#28c76f' : '#ea5455') + '30');
          g.addColorStop(1, (up ? '#28c76f' : '#ea5455') + '00');
          return g;
        },
        tension: 0.4,
      }]
    },
    options: {
      animation: false,
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: ctx => '₺' + parseFloat(ctx.parsed.y).toLocaleString('tr-TR', { minimumFractionDigits: 2 })
          }
        }
      },
      scales: { x: { display: false }, y: { display: false } }
    }
  });
});

// ── Auto-refresh live rates ────────────────────────────────────────────
const MARKET_URL = '{{ route('fx-alerts.market') }}';
let liveRates = {};
let countdown = 0;

const srcEl       = document.getElementById('hdr-src');
const timeEl      = document.getElementById('hdr-time');
const cntEl       = document.getElementById('hdr-countdown');

const SRC_LABELS  = { yahoo: 'Yahoo Finance', 'open-er': 'OpenER', db: 'TCMB DB' };
const SRC_CLASSES = { yahoo: 'src-yahoo', 'open-er': 'src-open-er', db: 'src-db' };

function fmtRate(v, code) {
  const dp = code === 'XAU' ? 0 : 2;
  return '₺' + parseFloat(v).toLocaleString('tr-TR', { minimumFractionDigits: dp, maximumFractionDigits: dp });
}

function updateCards(rates) {
  Object.entries(rates).forEach(([code, r]) => {
    // Rate value
    const rateEl = document.querySelector(`[data-rate="${code}"]`);
    if (rateEl) rateEl.textContent = fmtRate(r.rate, code);

    // Prev / date
    const prevEl = document.querySelector(`[data-prev="${code}"]`);
    if (prevEl && r.prev_rate != null) prevEl.textContent = fmtRate(r.prev_rate, code);
    const rdEl = document.querySelector(`[data-rdate="${code}"]`);
    if (rdEl && r.date) rdEl.textContent = r.date;

    // Change pill on card
    const chgEl = document.querySelector(`[data-chg="${code}"]`);
    if (chgEl) {
      const p = parseFloat(r.change_pct || 0);
      chgEl.className = `pill ${p > 0 ? 'pill-up' : p < 0 ? 'pill-dn' : 'pill-flat'}`;
      const icon = p > 0 ? '▲' : '▼';
      const iconClass = p > 0 ? 'ti-trending-up' : 'ti-trending-down';
      chgEl.innerHTML = `<i class="ti ${iconClass}" style="font-size:.7rem"></i>${p > 0 ? '+' : ''}${Math.abs(p)}%`;
    }

    // Ticker items (both copies)
    document.querySelectorAll(`[data-ticker-code="${code}"]`).forEach(item => {
      const p = parseFloat(r.change_pct || 0);
      const rEl = item.querySelector('[data-ticker-rate]');
      if (rEl) rEl.textContent = fmtRate(r.rate, code);
      const cEl = item.querySelector('[data-ticker-chg]');
      if (cEl) {
        cEl.className = `pill ${p > 0 ? 'pill-up' : p < 0 ? 'pill-dn' : 'pill-flat'}`;
        cEl.textContent = `${p >= 0 ? '▲' : '▼'} ${Math.abs(p)}%`;
      }
    });

    // Quick-fill alarm button
    const btn = document.querySelector(`.alarm-quick[data-currency="${code}"]`);
    if (btn) btn.dataset.rate = r.rate;
  });

  // Store for alarm modal prefill
  liveRates = rates;
}

function fetchRates() {
  fetch(MARKET_URL, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
    .then(res => res.ok ? res.json() : Promise.reject(res.status))
    .then(data => {
      if (!data.rates) return;

      // Update header
      if (timeEl) timeEl.textContent = data.date + ' ' + data.at;
      if (srcEl) {
        srcEl.textContent = SRC_LABELS[data.source] || data.source;
        srcEl.className   = 'src-chip ' + (SRC_CLASSES[data.source] || 'src-db');
      }

      updateCards(data.rates);
      countdown = 60;
    })
    .catch(() => { /* silent fallback */ });
}

// Countdown tick
setInterval(() => {
  if (countdown > 0) countdown--;
  if (cntEl) cntEl.textContent = countdown > 0
    ? `${countdown}s sonra yenilenir`
    : 'yenileniyor…';
  if (countdown === 0) fetchRates();
}, 1000);

// Fetch immediately on page load
fetchRates();

// ── Add alarm modal: currency select prefill ───────────────────────────
const modalCur = document.getElementById('modal-cur');
const modalThr = document.getElementById('modal-thr');
const modalHint = document.getElementById('modal-hint');
const preview   = document.getElementById('modal-preview');

function updateModalPreview(sel) {
  if (!sel || !sel.value) return;
  const opt   = sel.options[sel.selectedIndex];
  const rate  = parseFloat(opt.dataset.rate || 0);
  const flag  = opt.dataset.flag || '';
  const name  = opt.dataset.name || '';
  const color = opt.dataset.color || 'primary';
  const code  = sel.value;

  if (preview) {
    preview.className = `card bg-label-${color} border-0 mb-4 py-2 px-3 d-flex flex-row align-items-center justify-content-between`;
    preview.innerHTML = `
      <div class="d-flex align-items-center gap-2">
        <span style="font-size:1.2rem">${flag}</span>
        <span class="fw-semibold small">${code}/TRY — ${name}</span>
      </div>
      <span class="fw-bold">₺${rate.toLocaleString('tr-TR', { minimumFractionDigits: code === 'XAU' ? 0 : 2 })}</span>
    `;
  }
  if (modalHint) {
    const live = liveRates[code];
    const display = live ? parseFloat(live.rate) : rate;
    modalHint.textContent = `Anlık: ₺${display.toLocaleString('tr-TR', { minimumFractionDigits: code === 'XAU' ? 0 : 2 })}`;
  }
}

if (modalCur) {
  modalCur.addEventListener('change', () => updateModalPreview(modalCur));
}

// Prefill from "Alarm Kur" card buttons
document.querySelectorAll('.alarm-quick').forEach(btn => {
  btn.addEventListener('click', () => {
    const code = btn.dataset.currency;
    const rate = btn.dataset.rate;
    if (modalCur) {
      modalCur.value = code;
      updateModalPreview(modalCur);
    }
    if (modalThr && !modalThr.value) {
      modalThr.value = parseFloat(rate).toFixed(2);
    }
  });
});

// Re-open if validation failed
const _hasErrors = {{ $errors->any() ? 'true' : 'false' }};
if (_hasErrors) {
  bootstrap.Modal.getOrCreateInstance(document.getElementById('addAlarmModal')).show();
}

// ── Delete confirm ─────────────────────────────────────────────────────
document.querySelectorAll('.btn-del').forEach(btn => {
  btn.addEventListener('click', function() {
    Swal.fire({
      title: 'Alarm silinsin mi?',
      html: `<span class="text-muted small">${this.dataset.name}</span>`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#ea5455',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Evet, sil',
      cancelButtonText: 'Vazgeç',
      reverseButtons: true,
    }).then(r => { if (r.isConfirmed) this.closest('form').submit(); });
  });
});
</script>
</x-slot>
</x-app-layout>
