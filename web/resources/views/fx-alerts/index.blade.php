<x-app-layout>
<x-slot name="title">Piyasa & Kur Alarmları</x-slot>

<style>
/* ── Ticker ──────────────────────────────────────────────────────────── */
.mkt-ticker-wrap{overflow:hidden;border-top:1px solid var(--bs-border-color);
                 border-bottom:1px solid var(--bs-border-color)}
.mkt-ticker-track{display:flex;width:max-content;animation:ticker 50s linear infinite}
.mkt-ticker-wrap:hover .mkt-ticker-track{animation-play-state:paused}
.mkt-ticker-item{display:flex;align-items:center;gap:.35rem;padding:.45rem 1.1rem;
                 border-right:1px solid var(--bs-border-color);white-space:nowrap;font-size:.78rem}
@keyframes ticker{0%{transform:translateX(0)}100%{transform:translateX(-50%)}}

/* ── Compact rate card ───────────────────────────────────────────────── */
.mkt-card{transition:box-shadow .15s}
.mkt-card:hover{box-shadow:0 4px 18px rgba(0,0,0,.1)}
.mkt-rate{font-size:1.25rem;font-weight:700;letter-spacing:-.4px;line-height:1}
.mkt-spark-wrap{height:36px;flex:1;min-width:0}

/* ── Change pills ────────────────────────────────────────────────────── */
.pill{display:inline-flex;align-items:center;gap:.15rem;padding:.18rem .48rem;
      border-radius:20px;font-size:.7rem;font-weight:700;line-height:1;white-space:nowrap}
.pill-up  {color:#28c76f;background:rgba(40,199,111,.13)}
.pill-dn  {color:#ea5455;background:rgba(234,84,85,.13)}
.pill-flat{color:#a8aaae;background:rgba(168,170,174,.12)}

/* ── Live dot ────────────────────────────────────────────────────────── */
.live-dot{display:inline-block;width:7px;height:7px;border-radius:50%;background:#28c76f;
          flex-shrink:0;animation:ldot 1.5s ease-in-out infinite}
@keyframes ldot{0%,100%{opacity:1}50%{opacity:.25}}

/* ── Source chip ─────────────────────────────────────────────────────── */
.src-chip{font-size:.68rem;padding:.12rem .48rem;border-radius:10px;font-weight:600}
.src-yahoo  {background:rgba(0,207,232,.12);color:#00cfe8}
.src-open-er{background:rgba(115,103,240,.12);color:#7367f0}
.src-db     {background:rgba(168,170,174,.12);color:#a8aaae}

/* ── Countdown ring ──────────────────────────────────────────────────── */
.cnt-ring{position:relative;width:32px;height:32px;flex-shrink:0}
.cnt-ring svg{transform:rotate(-90deg)}
.cnt-ring circle{fill:none;stroke-width:2.5}
.cnt-ring .bg{stroke:var(--bs-border-color)}
.cnt-ring .fg{stroke:#7367f0;stroke-linecap:round;
               stroke-dasharray:88;stroke-dashoffset:0;transition:stroke-dashoffset .9s linear}
.cnt-ring span{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;
               font-size:.55rem;font-weight:700;color:var(--bs-body-color)}

/* ── Triggered row ───────────────────────────────────────────────────── */
.triggered-row td{background:rgba(234,84,85,.04)}
</style>

{{-- ═══════════════════ HEADER (compact) ══════════════════════════════ --}}
<div class="d-flex align-items-center justify-content-between mb-3 flex-wrap gap-2">
  <div>
    <h5 class="fw-bold mb-0 text-heading">Piyasa & Kur Alarmları</h5>
    <div class="d-flex align-items-center gap-2 mt-1 flex-wrap">
      <span class="live-dot"></span>
      <span class="text-muted small" id="hdr-time">—</span>
      <span class="src-chip src-db" id="hdr-src">DB</span>
    </div>
  </div>
  <div class="d-flex align-items-center gap-3">
    {{-- Countdown ring --}}
    <div class="cnt-ring" title="Sonraki güncelleme">
      <svg viewBox="0 0 32 32" width="32" height="32">
        <circle class="bg" cx="16" cy="16" r="14"/>
        <circle class="fg" id="cnt-arc" cx="16" cy="16" r="14"/>
      </svg>
      <span id="cnt-label">5:00</span>
    </div>
    <button class="btn btn-primary btn-sm d-flex align-items-center gap-1"
            data-bs-toggle="modal" data-bs-target="#addAlarmModal">
      <i class="ti tabler-bell-plus icon-14px"></i>Alarm Ekle
    </button>
  </div>
</div>

{{-- flash --}}
@if(session('success'))
<div class="alert alert-success alert-dismissible mb-3 py-2">
  <i class="ti tabler-circle-check me-2"></i>{{ session('success') }}
  <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
</div>
@endif
@if(session('error'))
<div class="alert alert-danger alert-dismissible mb-3 py-2">
  <i class="ti tabler-alert-circle me-2"></i>{{ session('error') }}
  <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
</div>
@endif

{{-- ═══════════════════════════ TICKER ═════════════════════════════════ --}}
<div class="mb-3">
  <div class="mkt-ticker-wrap" style="border-radius:.5rem;overflow:hidden">
    <div class="mkt-ticker-track" id="ticker-track">
      @php $ts = array_values($ratesData); @endphp
      @foreach(array_merge($ts,$ts) as $t)
      <div class="mkt-ticker-item" data-ticker-code="{{ $t['currency'] }}">
        <span>{{ $t['flag'] }}</span>
        <span class="fw-semibold">{{ $t['currency'] }}/TRY</span>
        <span class="fw-bold" data-ticker-rate>₺{{ number_format($t['rate'],$t['currency']==='XAU'?0:2,',','.') }}</span>
        @php $p=$t['change_pct']; @endphp
        <span class="pill {{ $p>0?'pill-up':($p<0?'pill-dn':'pill-flat') }}" data-ticker-chg>
          {{ $p>0?'▲':($p<0?'▼':'±') }} {{ abs($p) }}%
        </span>
      </div>
      @endforeach
    </div>
  </div>
</div>

{{-- ══════════════════ RATE CARDS (compact horizontal) ═════════════════ --}}
<div class="row g-3 mb-3">
  @foreach($ratesData as $code => $r)
  @php $c=$r['color']; $p=$r['change_pct']; $dp=$code==='XAU'?0:2; @endphp
  <div class="col-12 col-sm-6 col-xl-4 col-xxl-3">
    <div class="card mkt-card position-relative overflow-hidden mb-0">
      <div class="accent-bar bg-{{ $c }}"></div>
      <div class="card-body py-3 px-4">

        {{-- Row 1: flag + pair + change + alarm btn --}}
        <div class="d-flex align-items-center gap-2 mb-2">
          <span style="font-size:1.1rem;line-height:1">{{ $r['flag'] }}</span>
          <span class="fw-bold small text-heading">{{ $code }}/TRY</span>
          <span class="pill {{ $p>0?'pill-up':($p<0?'pill-dn':'pill-flat') }} ms-1" data-chg="{{ $code }}">
            @if($p>0)<i class="ti tabler-trending-up" style="font-size:.65rem"></i>+{{ $p }}%
            @elseif($p<0)<i class="ti tabler-trending-down" style="font-size:.65rem"></i>{{ $p }}%
            @else±0%@endif
          </span>
          <button class="btn btn-icon btn-sm btn-text-secondary p-0 ms-auto alarm-quick"
                  data-currency="{{ $code }}" data-rate="{{ $r['rate'] }}"
                  data-bs-toggle="modal" data-bs-target="#addAlarmModal"
                  title="Alarm kur">
            <i class="ti tabler-bell-plus icon-16px"></i>
          </button>
        </div>

        {{-- Row 2: rate + sparkline --}}
        <div class="d-flex align-items-center gap-3">
          <div class="flex-shrink-0">
            <div class="mkt-rate text-heading" data-rate="{{ $code }}">
              ₺{{ number_format($r['rate'],$dp,',','.') }}
            </div>
            <div class="text-muted" style="font-size:.63rem;margin-top:2px">
              {{ $r['name'] }}
            </div>
          </div>
          <div class="mkt-spark-wrap">
            <canvas id="spark-{{ $code }}"
                    data-history="{{ json_encode($r['history']) }}"
                    data-labels="{{ json_encode($r['labels']) }}"
                    data-change="{{ $p }}"
                    style="width:100%;height:36px"></canvas>
          </div>
        </div>

      </div>
    </div>
  </div>
  @endforeach
</div>

{{-- ══════════════════════ ALERTS TABLE ════════════════════════════════ --}}
<div class="card mb-3">
  <div class="card-header d-flex align-items-center justify-content-between py-2">
    <h6 class="mb-0 fw-semibold small">
      <i class="ti tabler-bell me-2 text-primary"></i>Alarmlarım
    </h6>
    <div class="d-flex align-items-center gap-2">
      @php $triggered=$alerts->where('is_triggered',true)->count(); @endphp
      @if($triggered)<span class="badge bg-danger">{{ $triggered }} tetiklendi</span>@endif
      <span class="badge bg-label-primary">{{ $alerts->count() }} toplam</span>
    </div>
  </div>

  @if($alerts->isEmpty())
  <div class="card-body text-center py-5">
    <i class="ti tabler-bell-off icon-48px text-muted mb-3 d-block"></i>
    <p class="fw-semibold mb-1">Henüz alarm yok</p>
    <p class="text-muted small mb-3">Kur kartlarındaki <i class="ti tabler-bell-plus"></i> ikonuna tıkla.</p>
    <button class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#addAlarmModal">
      <i class="ti tabler-bell-plus me-1"></i>İlk Alarmı Ekle
    </button>
  </div>
  @else
  <div class="table-responsive">
    <table class="table table-hover align-middle mb-0 table-sm">
      <thead class="paranette-thead">
        <tr>
          <th class="ps-4 py-2">Kur</th>
          <th class="py-2">Koşul</th>
          <th class="py-2">Eşik</th>
          <th class="py-2">Güncel</th>
          <th class="py-2">Fark</th>
          <th class="py-2">Durum</th>
          <th class="py-2 pe-4 text-end">Sil</th>
        </tr>
      </thead>
      <tbody>
        @foreach($alerts as $alert)
        @php
          $key   = $alert->currency==='GOLD'?'XAU':$alert->currency;
          $meta  = $labels[$key]??['name'=>$key,'flag'=>'','color'=>'secondary'];
          $dist  = $alert->current_rate!==null?round($alert->current_rate-(float)$alert->threshold,2):null;
          $dp2   = $key==='XAU'?0:2;
        @endphp
        <tr class="{{ $alert->is_triggered?'triggered-row':'' }}">
          <td class="ps-4 py-2">
            <div class="d-flex align-items-center gap-2">
              <span>{{ $meta['flag'] }}</span>
              <span class="fw-semibold small">{{ $key }}/TRY</span>
            </div>
          </td>
          <td class="py-2">
            @if($alert->condition==='above')
              <span class="badge bg-label-danger"><i class="ti tabler-arrow-up icon-10px me-1"></i>Üstüne</span>
            @else
              <span class="badge bg-label-info"><i class="ti tabler-arrow-down icon-10px me-1"></i>Altına</span>
            @endif
          </td>
          <td class="py-2 fw-semibold small">₺{{ number_format((float)$alert->threshold,$dp2,',','.') }}</td>
          <td class="py-2 small" data-alert-rate="{{ $key }}">
            {{ $alert->current_rate!==null?'₺'.number_format($alert->current_rate,$dp2,',','.'):'—' }}
          </td>
          <td class="py-2 small">
            @if($dist!==null)
              <span class="pill {{ $dist>0?'pill-up':($dist<0?'pill-dn':'pill-flat') }}">
                {{ $dist>0?'+':'' }}₺{{ number_format(abs($dist),$dp2,',','.') }}
              </span>
            @else—@endif
          </td>
          <td class="py-2">
            @if($alert->is_triggered)
              <span class="badge bg-danger"><i class="ti tabler-bell-ringing icon-10px me-1"></i>Tetiklendi</span>
            @else
              <span class="badge bg-label-success"><i class="ti tabler-bell icon-10px me-1"></i>İzleniyor</span>
            @endif
          </td>
          <td class="py-2 pe-4 text-end">
            <form action="{{ route('fx-alerts.destroy',$alert->id) }}" method="POST" class="d-inline">
              @csrf @method('DELETE')
              <button type="button" class="btn btn-icon btn-sm btn-text-danger btn-del"
                      data-name="{{ $key }}/TRY @ ₺{{ number_format((float)$alert->threshold,2,',','.') }}">
                <i class="ti tabler-trash icon-16px"></i>
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

{{-- ════════════ SOURCE NOTE (collapsed, 1 line) ══════════════════════ --}}
<p class="text-muted mb-0" style="font-size:.7rem">
  <i class="ti tabler-info-circle me-1"></i>
  Veri kaynakları: Yahoo Finance (anlık) → open.er-api.com (saatlik) → TCMB DB (günlük).
  Altın: gold-api.com (USD/oz → TRY/gram). JPY: 100 birim üzerinden.
  Her <strong>5 dakikada</strong> bir otomatik güncellenir.
</p>

{{-- ══════════════════════ ADD ALARM MODAL ════════════════════════════ --}}
<div class="modal fade" id="addAlarmModal" tabindex="-1" aria-modal="true">
  <div class="modal-dialog modal-dialog-centered modal-sm">
    <form action="{{ route('fx-alerts.store') }}" method="POST">
      @csrf
      <div class="modal-content">
        <div class="modal-header pb-2">
          <h6 class="modal-title fw-bold">
            <i class="ti tabler-bell-plus text-primary me-1"></i>Kur Alarmı
          </h6>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body py-3">

          @if($errors->any())
          <div class="alert alert-danger py-2 mb-3">
            <ul class="mb-0 ps-3 small">
              @foreach($errors->all() as $e)<li>{{ $e }}</li>@endforeach
            </ul>
          </div>
          @endif

          {{-- Preview chip --}}
          <div id="modal-preview" class="rounded-3 px-3 py-2 mb-3 d-flex align-items-center justify-content-between"
               style="background:var(--bs-light);min-height:44px">
            <span class="text-muted small">Kur seçin…</span>
          </div>

          <div class="mb-3">
            <label class="form-label fw-semibold small mb-1">Kur <span class="text-danger">*</span></label>
            <select name="currency" id="modal-cur"
                    class="form-select form-select-sm @error('currency') is-invalid @enderror" required>
              <option value="" disabled {{ old('currency')?'':'selected' }}>Seç…</option>
              @foreach($ratesData as $code => $r)
              <option value="{{ $code }}"
                      data-rate="{{ $r['rate'] }}" data-color="{{ $r['color'] }}"
                      data-flag="{{ $r['flag'] }}" data-name="{{ $r['name'] }}"
                      {{ old('currency')===$code?'selected':'' }}>
                {{ $r['flag'] }} {{ $code }}/TRY
                (₺{{ number_format($r['rate'],$code==='XAU'?0:2,',','.') }})
              </option>
              @endforeach
            </select>
            @error('currency')<div class="invalid-feedback">{{ $message }}</div>@enderror
          </div>

          <div class="mb-3">
            <label class="form-label fw-semibold small mb-1">Koşul <span class="text-danger">*</span></label>
            <div class="d-flex gap-3">
              <div class="form-check">
                <input class="form-check-input" type="radio" name="condition"
                       id="cond-above" value="above"
                       {{ old('condition','above')==='above'?'checked':'' }} required>
                <label class="form-check-label small" for="cond-above">▲ Üstüne</label>
              </div>
              <div class="form-check">
                <input class="form-check-input" type="radio" name="condition"
                       id="cond-below" value="below"
                       {{ old('condition')==='below'?'checked':'' }}>
                <label class="form-check-label small" for="cond-below">▼ Altına</label>
              </div>
            </div>
          </div>

          <div>
            <label class="form-label fw-semibold small mb-1">Eşik Fiyat <span class="text-danger">*</span></label>
            <div class="input-group input-group-sm">
              <span class="input-group-text">₺</span>
              <input type="number" name="threshold" id="modal-thr"
                     class="form-control @error('threshold') is-invalid @enderror"
                     step="0.01" min="0.01" placeholder="38.50"
                     value="{{ old('threshold') }}" required>
              @error('threshold')<div class="invalid-feedback">{{ $message }}</div>@enderror
            </div>
            <div class="form-text small" id="modal-hint">Güncel kur kur seçince görünür.</div>
          </div>
        </div>
        <div class="modal-footer py-2">
          <button type="button" class="btn btn-outline-secondary btn-sm" data-bs-dismiss="modal">İptal</button>
          <button type="submit" class="btn btn-primary btn-sm">
            <i class="ti tabler-bell-plus me-1"></i>Ekle
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
// ── Sparklines ────────────────────────────────────────────────────────
document.querySelectorAll('[id^="spark-"]').forEach(canvas => {
  const history = JSON.parse(canvas.dataset.history || '[]');
  const labels  = JSON.parse(canvas.dataset.labels  || '[]');
  const up      = parseFloat(canvas.dataset.change || '0') >= 0;
  const color   = up ? '#28c76f' : '#ea5455';
  if (!history.length) return;
  new Chart(canvas, {
    type: 'line',
    data: {
      labels,
      datasets: [{
        data: history, borderColor: color, borderWidth: 1.5,
        pointRadius: 0, fill: true, tension: 0.4,
        backgroundColor: ctx => {
          const g = ctx.chart.ctx.createLinearGradient(0,0,0,36);
          g.addColorStop(0, color+'28'); g.addColorStop(1, color+'00'); return g;
        }
      }]
    },
    options: {
      animation:false, responsive:true, maintainAspectRatio:false,
      plugins:{ legend:{display:false}, tooltip:{
        callbacks:{ label:c=>'₺'+parseFloat(c.parsed.y).toLocaleString('tr-TR',{minimumFractionDigits:2}) }
      }},
      scales:{ x:{display:false}, y:{display:false} }
    }
  });
});

// ── Auto-refresh (5 minutes = 300 s) ─────────────────────────────────
const MARKET_URL  = '{{ route('fx-alerts.market') }}';
const TOTAL_SECS  = 300;
const CIRCUMF     = 2 * Math.PI * 14; // r=14 → ~87.96
const arc         = document.getElementById('cnt-arc');
const cntLabel    = document.getElementById('cnt-label');
const srcEl       = document.getElementById('hdr-src');
const timeEl      = document.getElementById('hdr-time');
const SRC_LABELS  = { yahoo:'Yahoo Finance', 'open-er':'OpenER', db:'TCMB DB' };
const SRC_CLASSES = { yahoo:'src-yahoo', 'open-er':'src-open-er', db:'src-db' };
let liveRates = {};
let remaining = TOTAL_SECS;

function setRing(secs) {
  const pct = secs / TOTAL_SECS;
  if (arc) arc.style.strokeDashoffset = CIRCUMF * (1 - pct);
  if (cntLabel) {
    const m = Math.floor(secs / 60), s = secs % 60;
    cntLabel.textContent = m + ':' + String(s).padStart(2,'0');
  }
}

function fmtRate(v, code) {
  const dp = code === 'XAU' ? 0 : 2;
  return '₺' + parseFloat(v).toLocaleString('tr-TR',{minimumFractionDigits:dp,maximumFractionDigits:dp});
}

function applyRates(rates) {
  Object.entries(rates).forEach(([code, r]) => {
    const dp = code === 'XAU' ? 0 : 2;

    // Rate card
    const rEl = document.querySelector(`[data-rate="${code}"]`);
    if (rEl) rEl.textContent = fmtRate(r.rate, code);

    // Change pill
    const cEl = document.querySelector(`[data-chg="${code}"]`);
    if (cEl) {
      const p = parseFloat(r.change_pct || 0);
      cEl.className = `pill ${p>0?'pill-up':p<0?'pill-dn':'pill-flat'}`;
      const icon = p>0?'tabler-trending-up':'tabler-trending-down';
      cEl.innerHTML = `<i class="ti ${icon}" style="font-size:.65rem"></i>${p>0?'+':''}${Math.abs(p).toFixed(2)}%`;
    }

    // Ticker
    document.querySelectorAll(`[data-ticker-code="${code}"]`).forEach(item => {
      const p = parseFloat(r.change_pct || 0);
      const rr = item.querySelector('[data-ticker-rate]');
      if (rr) rr.textContent = fmtRate(r.rate, code);
      const cc = item.querySelector('[data-ticker-chg]');
      if (cc) {
        cc.className = `pill ${p>0?'pill-up':p<0?'pill-dn':'pill-flat'}`;
        cc.textContent = `${p>=0?'▲':'▼'} ${Math.abs(p).toFixed(2)}%`;
      }
    });

    // Alarm button data-rate
    const ab = document.querySelector(`.alarm-quick[data-currency="${code}"]`);
    if (ab) ab.dataset.rate = r.rate;
  });
  liveRates = rates;
}

function fetchRates() {
  fetch(MARKET_URL, {headers:{'X-Requested-With':'XMLHttpRequest'}})
    .then(res => res.ok ? res.json() : Promise.reject())
    .then(data => {
      if (!data.rates) return;
      if (timeEl) timeEl.textContent = data.date + ' ' + data.at;
      if (srcEl) {
        srcEl.textContent = SRC_LABELS[data.source] || data.source;
        srcEl.className   = 'src-chip ' + (SRC_CLASSES[data.source] || 'src-db');
      }
      applyRates(data.rates);
    })
    .catch(() => {});
}

// Tick every second, fetch when remaining hits 0
setInterval(() => {
  remaining--;
  if (remaining < 0) remaining = TOTAL_SECS;
  setRing(remaining);
  if (remaining === 0) fetchRates();
}, 1000);

setRing(TOTAL_SECS);
fetchRates(); // immediate on load

// ── Modal: currency select preview ───────────────────────────────────
const modalCur  = document.getElementById('modal-cur');
const modalThr  = document.getElementById('modal-thr');
const modalHint = document.getElementById('modal-hint');
const preview   = document.getElementById('modal-preview');

function syncPreview() {
  if (!modalCur || !modalCur.value) return;
  const opt   = modalCur.options[modalCur.selectedIndex];
  const code  = modalCur.value;
  const live  = liveRates[code];
  const rate  = live ? parseFloat(live.rate) : parseFloat(opt.dataset.rate || 0);
  const dp    = code === 'XAU' ? 0 : 2;
  if (preview) {
    preview.style.background = '';
    preview.innerHTML = `
      <div class="d-flex align-items-center gap-2">
        <span style="font-size:1.1rem">${opt.dataset.flag||''}</span>
        <span class="fw-semibold small">${code}/TRY</span>
        <span class="src-chip src-${opt.dataset.color||'primary'} ms-1">${opt.dataset.name||''}</span>
      </div>
      <span class="fw-bold">₺${rate.toLocaleString('tr-TR',{minimumFractionDigits:dp,maximumFractionDigits:dp})}</span>`;
  }
  if (modalHint) modalHint.textContent = `Anlık: ₺${rate.toLocaleString('tr-TR',{minimumFractionDigits:dp})}`;
}

if (modalCur) modalCur.addEventListener('change', syncPreview);

document.querySelectorAll('.alarm-quick').forEach(btn => {
  btn.addEventListener('click', () => {
    if (modalCur) { modalCur.value = btn.dataset.currency; syncPreview(); }
    if (modalThr && !modalThr.value)
      modalThr.value = parseFloat(btn.dataset.rate).toFixed(2);
  });
});

const _hasErrors = {{ $errors->any() ? 'true' : 'false' }};
if (_hasErrors)
  bootstrap.Modal.getOrCreateInstance(document.getElementById('addAlarmModal')).show();

// ── Delete confirm ────────────────────────────────────────────────────
document.querySelectorAll('.btn-del').forEach(btn => {
  btn.addEventListener('click', function () {
    Swal.fire({
      title: 'Alarm silinsin mi?',
      html: `<span class="text-muted small">${this.dataset.name}</span>`,
      icon: 'warning', showCancelButton: true,
      confirmButtonColor:'#ea5455', cancelButtonColor:'#6c757d',
      confirmButtonText:'Evet, sil', cancelButtonText:'Vazgeç', reverseButtons:true,
    }).then(r => { if (r.isConfirmed) this.closest('form').submit(); });
  });
});
</script>
</x-slot>
</x-app-layout>
