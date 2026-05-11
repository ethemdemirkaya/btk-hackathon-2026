<x-app-layout>
  <x-slot name="title">Finansal Zeka Merkezi</x-slot>

  <x-slot name="pageCss">
  <style>
    /* ── Command input ──────────────────────────────────────────────────────── */
    .command-bar {
      background: var(--bs-body-bg);
      border: 2px solid var(--bs-border-color);
      border-radius: 14px;
      transition: border-color .18s, box-shadow .18s;
      overflow: hidden;
    }
    .command-bar:focus-within {
      border-color: #7367F0;
      box-shadow: 0 0 0 3px rgba(115,103,240,.12);
    }
    .command-bar input {
      border: none !important;
      box-shadow: none !important;
      background: transparent !important;
      font-size: .95rem;
      padding: .85rem 1rem .85rem 1.1rem;
    }
    .command-bar .cmd-send {
      border-radius: 0 12px 12px 0;
      padding: .75rem 1.25rem;
      border: none;
      background: #7367F0;
      color: #fff;
      font-size: .85rem;
      font-weight: 600;
      transition: background .14s;
      flex-shrink: 0;
    }
    .command-bar .cmd-send:hover  { background: #5f53e5; }
    .command-bar .cmd-send:disabled { background: var(--bs-secondary-bg); color: var(--bs-secondary-color); cursor: not-allowed; }

    /* ── Quick trigger pills ─────────────────────────────────────────────── */
    .trigger-pills { display: flex; gap: .5rem; flex-wrap: wrap; }
    .trigger-pill {
      cursor: pointer; border-radius: 20px; padding: .3rem .8rem;
      font-size: .75rem; font-weight: 500;
      border: 1px solid var(--bs-border-color);
      color: var(--bs-secondary-color);
      background: var(--bs-body-bg);
      transition: all .15s; user-select: none;
    }
    .trigger-pill:hover {
      border-color: #7367F0; color: #7367F0;
      background: rgba(115,103,240,.06);
    }
    .trigger-pill i { font-size: 13px; vertical-align: middle; margin-right: 3px; }

    /* ── Analysis result card ───────────────────────────────────────────── */
    .analysis-card {
      border: 1px solid var(--bs-border-color);
      border-radius: 12px;
      overflow: hidden;
      transition: box-shadow .18s;
      background: var(--bs-body-bg);
    }
    .analysis-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,.08); }
    .analysis-card .ac-header {
      background: var(--bs-tertiary-bg);
      border-bottom: 1px solid var(--bs-border-color);
      padding: .6rem 1rem;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: .5rem;
      flex-wrap: wrap;
    }
    .query-label {
      font-size: .7rem; font-weight: 600; color: var(--bs-secondary-color);
      background: var(--bs-secondary-bg);
      border: 1px solid var(--bs-border-color);
      border-radius: 10px;
      padding: .15rem .55rem;
      max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .ac-agents { display: flex; gap: .3rem; flex-wrap: wrap; }
    .ac-agent-badge {
      font-size: .62rem; font-weight: 700; letter-spacing: .02em;
      padding: .15rem .5rem; border-radius: 10px;
    }
    .ac-time {
      font-size: .68rem; color: var(--bs-tertiary-color); flex-shrink: 0; margin-left: auto;
    }
    .ac-body {
      padding: .9rem 1rem;
      font-size: .86rem;
      line-height: 1.65;
      color: var(--bs-body-color);
      white-space: pre-wrap;
      word-break: break-word;
    }

    /* ── Skeleton loading card ───────────────────────────────────────────── */
    .skeleton-card {
      border: 1px solid var(--bs-border-color);
      border-radius: 12px;
      overflow: hidden;
      background: var(--bs-body-bg);
    }
    .skeleton-card .sk-header {
      background: var(--bs-tertiary-bg);
      border-bottom: 1px solid var(--bs-border-color);
      padding: .65rem 1rem;
      display: flex; align-items: center; gap: .75rem;
    }
    .sk-dot {
      width: 7px; height: 7px; border-radius: 50%;
      background: #7367F0; flex-shrink: 0;
      animation: skPulse 1.2s ease-in-out infinite;
    }
    .sk-dot:nth-child(2) { animation-delay: .2s; }
    .sk-dot:nth-child(3) { animation-delay: .4s; }
    @@keyframes skPulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50%       { opacity: .35; transform: scale(.65); }
    }
    .sk-label { font-size: .75rem; color: var(--bs-secondary-color); font-weight: 600; }
    .sk-body { padding: .9rem 1rem; }
    .sk-line {
      height: 9px; border-radius: 5px;
      background: var(--bs-secondary-bg);
      margin-bottom: .55rem;
      animation: skShimmer 1.6s ease-in-out infinite;
    }
    @@keyframes skShimmer {
      0%   { opacity: .5; }
      50%  { opacity: 1; }
      100% { opacity: .5; }
    }

    /* ── Empty state ─────────────────────────────────────────────────────── */
    .empty-intelligence {
      padding: 3.5rem 1rem;
      text-align: center;
    }
    .empty-intelligence .ei-icon-wrap {
      width: 80px; height: 80px; border-radius: 50%;
      background: rgba(115,103,240,.08);
      border: 2px dashed rgba(115,103,240,.25);
      display: flex; align-items: center; justify-content: center;
      margin: 0 auto 1.25rem;
    }

    /* ── Agent status sidebar ────────────────────────────────────────────── */
    .agent-li {
      display: flex; align-items: center; gap: .65rem;
      padding: .6rem .9rem;
      border-bottom: 1px solid var(--bs-border-color);
      transition: background .1s;
    }
    .agent-li:last-child { border-bottom: none; }
    .agent-li:hover { background: var(--bs-secondary-bg); }
    .agent-name { font-size: .78rem; font-weight: 500; color: var(--bs-heading-color); line-height: 1.2; }
    .agent-status-badge {
      font-size: .62rem; font-weight: 700; border-radius: 10px;
      padding: .15rem .5rem; white-space: nowrap; flex-shrink: 0;
    }

    /* ── Pulsing dot for running state ───────────────────────────────────── */
    .agent-pulse {
      width: 7px; height: 7px; border-radius: 50%;
      background: #ff9f43; flex-shrink: 0;
      animation: agentPulse 1.1s ease-in-out infinite;
    }
    @@keyframes agentPulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50%       { opacity: .4; transform: scale(.65); }
    }

    /* ── Run timeline ────────────────────────────────────────────────────── */
    .run-item {
      padding: .55rem .9rem;
      border-bottom: 1px solid var(--bs-border-color);
      display: flex; align-items: flex-start; gap: .6rem;
    }
    .run-item:last-child { border-bottom: none; }
    .run-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; margin-top: 4px; }
    .run-name { font-size: .76rem; font-weight: 500; line-height: 1.2; }
    .run-meta { font-size: .67rem; color: var(--bs-secondary-color); margin-top: 1px; }

    /* ── Insight cards ───────────────────────────────────────────────────── */
    .insight-li {
      padding: .65rem .9rem;
      border-bottom: 1px solid var(--bs-border-color);
    }
    .insight-li:last-child { border-bottom: none; }
    .insight-title { font-size: .78rem; font-weight: 600; color: var(--bs-heading-color); }
    .insight-body  { font-size: .72rem; color: var(--bs-secondary-color); margin-top: 2px; }
  </style>
  </x-slot>

  {{-- ══ Page Header ═══════════════════════════════════════════════════════════ --}}
  <div class="d-flex align-items-center justify-content-between mb-4 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">
        <i class="icon-base ti tabler-brain text-primary me-2"></i>Finansal Zeka Merkezi
      </h4>
      <p class="text-muted mb-0 small">Yapay zeka ajanları finansal durumunuzu analiz ediyor</p>
    </div>
    <div class="d-flex gap-2 flex-wrap">
      <button type="button" class="btn btn-sm btn-outline-secondary" id="btn-clear-session">
        <i class="icon-base ti tabler-refresh me-1"></i>Yeni Analiz
      </button>
    </div>
  </div>

  {{-- ══ Command Bar ════════════════════════════════════════════════════════════ --}}
  <div class="command-bar d-flex align-items-center mb-3 shadow-sm">
    <input type="text" id="cmd-input" placeholder="Finansal durumunu sorgula, analiz et, planla…" autocomplete="off">
    <button class="cmd-send" id="cmd-send" type="button">
      <i class="icon-base ti tabler-arrow-up me-1" style="font-size:14px;"></i>Gönder
    </button>
  </div>

  {{-- ══ Quick Triggers ══════════════════════════════════════════════════════════ --}}
  <div class="trigger-pills mb-5">
    <span class="trigger-pill" data-msg="Son harcamalarımda anormal bir durum var mı? Ayrıntılı analiz yap.">
      <i class="icon-base ti tabler-radar"></i>Anomali Tara
    </span>
    <span class="trigger-pill" data-msg="Bu ayki bütçe durumumu analiz et ve nerede tasarruf yapabileceğimi göster.">
      <i class="icon-base ti tabler-chart-pie"></i>Bütçe Analizi
    </span>
    <span class="trigger-pill" data-msg="Önümüzdeki 6 ay için nakit akışımı tahmin et. Birikimim artar mı?">
      <i class="icon-base ti tabler-chart-line"></i>6 Aylık Tahmin
    </span>
    <span class="trigger-pill" data-msg="Kredi kartı borçlarımı en hızlı şekilde kapatmak için strateji öner.">
      <i class="icon-base ti tabler-credit-card"></i>Borç Stratejisi
    </span>
    <span class="trigger-pill" data-msg="Gereksiz veya pahalı aboneliklerim var mı? Tespit et ve öneri sun.">
      <i class="icon-base ti tabler-repeat"></i>Abonelik Tara
    </span>
    <span class="trigger-pill" data-msg="Enflasyon birikimimi ve satın alma gücümü nasıl etkiliyor?">
      <i class="icon-base ti tabler-flame"></i>Enflasyon Etkisi
    </span>
  </div>

  <input type="hidden" id="session-id" value="{{ $sessionId }}">

  <div class="row g-5">

    {{-- ══ MAIN: Analysis results ══════════════════════════════════════════════ --}}
    <div class="col-xl-8">
      <div id="results-feed">

        {{-- Empty state (hidden when results exist) --}}
        <div id="empty-state" class="{{ $history->isNotEmpty() ? 'd-none' : '' }}">
          <div class="card shadow-sm">
            <div class="empty-intelligence">
              <div class="ei-icon-wrap">
                <i class="icon-base ti tabler-sparkles icon-36px text-primary"></i>
              </div>
              <h5 class="fw-semibold mb-2">Analize Hazır</h5>
              <p class="text-muted mb-4" style="max-width:400px;margin:0 auto;">
                Finansal durumunuzu analiz etmek için yukarıdan bir konu seçin veya kendi sorunuzu yazın.
                Uzman ajanlar verilerinizi derinlemesine inceler.
              </p>
              <div class="d-flex gap-3 justify-content-center flex-wrap">
                <div class="d-flex align-items-center gap-2 text-muted small">
                  <span class="avatar avatar-xs bg-label-success"><i class="icon-base ti tabler-shield-check text-success" style="font-size:10px"></i></span>
                  Verileriniz güvende
                </div>
                <div class="d-flex align-items-center gap-2 text-muted small">
                  <span class="avatar avatar-xs bg-label-primary"><i class="icon-base ti tabler-cpu text-primary" style="font-size:10px"></i></span>
                  9 uzman ajan
                </div>
                <div class="d-flex align-items-center gap-2 text-muted small">
                  <span class="avatar avatar-xs bg-label-info"><i class="icon-base ti tabler-bolt text-info" style="font-size:10px"></i></span>
                  Gerçek zamanlı analiz
                </div>
              </div>
            </div>
          </div>
        </div>

        {{-- Existing history as analysis cards --}}
        @php $prevQuery = null; @endphp
        @foreach($history as $msg)
          @if($msg->role === 'user')
            @php $prevQuery = $msg->content; @endphp
          @else
            @php
              $agentsUsed = $msg->metadata['agents_used'] ?? [];
              $agentColorMap = [
                'purchase_planner'       => 'primary',
                'budget_advisor'         => 'success',
                'inflation_aware'        => 'warning',
                'anomaly_detector'       => 'danger',
                'transaction_classifier' => 'info',
                'forecaster'             => 'info',
                'debt_optimizer'         => 'danger',
                'subscription_hunter'    => 'secondary',
                'receipt_ocr'            => 'primary',
                'critic'                 => 'secondary',
              ];
              $agentLabelMap = [
                'purchase_planner'       => 'Satın Alma',
                'budget_advisor'         => 'Bütçe',
                'inflation_aware'        => 'Enflasyon',
                'anomaly_detector'       => 'Anomali',
                'transaction_classifier' => 'Sınıflandırma',
                'forecaster'             => 'Tahmin',
                'debt_optimizer'         => 'Borç',
                'subscription_hunter'    => 'Abonelik',
                'receipt_ocr'            => 'OCR',
                'critic'                 => 'Eleştirmen',
              ];
            @endphp
            <div class="analysis-card mb-4">
              <div class="ac-header">
                @if($prevQuery)
                  <span class="query-label" title="{{ $prevQuery }}">
                    <i class="icon-base ti tabler-message-2 icon-12px me-1"></i>{{ \Illuminate\Support\Str::limit($prevQuery, 60) }}
                  </span>
                @endif
                <div class="ac-agents">
                  @foreach($agentsUsed as $a)
                    @php $c = $agentColorMap[$a] ?? 'secondary'; $lbl = $agentLabelMap[$a] ?? $a; @endphp
                    <span class="ac-agent-badge bg-label-{{ $c }} text-{{ $c }}">{{ $lbl }}</span>
                  @endforeach
                </div>
                <span class="ac-time">{{ \Carbon\Carbon::parse($msg->created_at)->format('d.m H:i') }}</span>
              </div>
              <div class="ac-body">{{ $msg->content }}</div>
            </div>
            @php $prevQuery = null; @endphp
          @endif
        @endforeach

      </div>
    </div>

    {{-- ══ SIDEBAR ════════════════════════════════════════════════════════════ --}}
    <div class="col-xl-4">

      {{-- Agent Status --}}
      <div class="card mb-4 shadow-sm">
        <div class="card-header py-3 d-flex align-items-center justify-content-between">
          <h6 class="card-title mb-0 fw-semibold">
            <i class="icon-base ti tabler-cpu me-2 text-primary"></i>Uzman Ajanlar
          </h6>
          <span class="badge bg-label-success" style="font-size:.68rem;">Hazır</span>
        </div>
        <div id="agent-status-list">
          @foreach([
            'purchase_planner'       => ['Satın Alma Planlayıcı',  'tabler-shopping-cart',   'primary'],
            'budget_advisor'         => ['Bütçe Danışmanı',         'tabler-chart-pie',       'success'],
            'inflation_aware'        => ['Enflasyon Analisti',      'tabler-flame',           'warning'],
            'anomaly_detector'       => ['Anomali Dedektörü',       'tabler-radar',           'danger'],
            'transaction_classifier' => ['İşlem Sınıflandırıcı',   'tabler-tag',             'info'],
            'forecaster'             => ['Tahmin & Projeksiyon',    'tabler-chart-line',      'info'],
            'debt_optimizer'         => ['Borç Optimizasyonu',      'tabler-credit-card',     'danger'],
            'subscription_hunter'    => ['Abonelik Avcısı',         'tabler-repeat',          'secondary'],
            'receipt_ocr'            => ['Fiş & OCR Analizi',       'tabler-receipt',         'primary'],
          ] as $key => [$label, $icon, $color])
          <div class="agent-li" id="agent-{{ $key }}">
            <div class="avatar avatar-sm flex-shrink-0">
              <span class="avatar-initial rounded bg-label-{{ $color }}">
                <i class="icon-base ti {{ $icon }} text-{{ $color }}" style="font-size:13px;"></i>
              </span>
            </div>
            <div class="flex-grow-1">
              <div class="agent-name">{{ $label }}</div>
            </div>
            <span class="agent-status-badge bg-label-secondary agent-state">Beklemede</span>
          </div>
          @endforeach
        </div>
      </div>

      {{-- Recent Runs --}}
      <div class="card mb-4 shadow-sm">
        <div class="card-header py-3">
          <h6 class="card-title mb-0 fw-semibold">
            <i class="icon-base ti tabler-history me-2 text-muted"></i>Son Çalışmalar
          </h6>
        </div>
        <div id="runs-list">
          @forelse($recentRuns as $run)
          <div class="run-item">
            <div class="run-dot
              @if($run->status === 'completed') bg-success
              @elseif($run->status === 'failed') bg-danger
              @else bg-warning @endif"></div>
            <div class="flex-grow-1">
              <div class="run-name text-truncate" style="max-width:160px;">{{ $run->agent_name }}</div>
              <div class="run-meta">
                {{ $run->model_used ?? '—' }}
                @if($run->duration_ms) · {{ $run->duration_ms }}ms @endif
                · {{ ($run->tokens_in ?? 0) + ($run->tokens_out ?? 0) }} tok
              </div>
            </div>
            <span class="badge
              @if($run->status === 'completed') bg-label-success
              @elseif($run->status === 'failed') bg-label-danger
              @else bg-label-warning @endif" style="font-size:.62rem;">
              {{ $run->status }}
            </span>
          </div>
          @empty
          <div class="text-muted small text-center py-4">Henüz çalışma yok</div>
          @endforelse
        </div>
      </div>

      {{-- Active Insights --}}
      @if($insights->isNotEmpty())
      <div class="card shadow-sm">
        <div class="card-header py-3 d-flex align-items-center justify-content-between">
          <h6 class="card-title mb-0 fw-semibold">
            <i class="icon-base ti tabler-bulb me-2 text-warning"></i>Proaktif Öngörüler
          </h6>
          <span class="badge bg-label-warning" style="font-size:.68rem;">{{ $insights->count() }}</span>
        </div>
        @foreach($insights as $insight)
        @php
          $insightColors = ['warning' => 'warning', 'opportunity' => 'success', 'tip' => 'info', 'anomaly' => 'danger'];
          $ic = $insightColors[$insight->type] ?? 'secondary';
        @endphp
        <div class="insight-li" id="insight-{{ $insight->id }}">
          <div class="d-flex align-items-start gap-2">
            <span class="avatar avatar-xs bg-label-{{ $ic }} flex-shrink-0 mt-1">
              <i class="icon-base ti tabler-bulb text-{{ $ic }}" style="font-size:10px;"></i>
            </span>
            <div class="flex-grow-1">
              <div class="insight-title">{{ $insight->title }}</div>
              <div class="insight-body">{{ \Illuminate\Support\Str::limit($insight->body, 90) }}</div>
            </div>
            <button type="button"
                    class="btn btn-icon btn-text-secondary btn-sm flex-shrink-0 btn-dismiss-insight"
                    data-id="{{ $insight->id }}"
                    data-url="{{ route('agent-chat.insight-dismiss', $insight->id) }}"
                    style="width:20px;height:20px;margin-top:-2px;">
              <i class="icon-base ti tabler-x icon-12px"></i>
            </button>
          </div>
        </div>
        @endforeach
      </div>
      @endif

    </div>
  </div>

  <x-slot name="pageJs">
  <script>
  (function () {
    'use strict';

    const cmdInput  = document.getElementById('cmd-input');
    const cmdSend   = document.getElementById('cmd-send');
    const sessionId = document.getElementById('session-id').value;
    const csrf      = document.querySelector('meta[name=csrf-token]').content;
    const feed      = document.getElementById('results-feed');
    const emptyState = document.getElementById('empty-state');

    const agentLabelMap = {
      purchase_planner: 'Satın Alma', budget_advisor: 'Bütçe',
      inflation_aware: 'Enflasyon', anomaly_detector: 'Anomali',
      transaction_classifier: 'Sınıflandırma', forecaster: 'Tahmin',
      debt_optimizer: 'Borç', subscription_hunter: 'Abonelik',
      receipt_ocr: 'OCR', critic: 'Eleştirmen',
    };
    const agentColorMap = {
      purchase_planner: 'primary', budget_advisor: 'success',
      inflation_aware: 'warning', anomaly_detector: 'danger',
      transaction_classifier: 'info', forecaster: 'info',
      debt_optimizer: 'danger', subscription_hunter: 'secondary',
      receipt_ocr: 'primary', critic: 'secondary',
    };

    // ── Quick triggers ──────────────────────────────────────────────────────
    document.querySelectorAll('.trigger-pill').forEach(pill => {
      pill.addEventListener('click', () => {
        cmdInput.value = pill.dataset.msg;
        cmdInput.focus();
      });
    });

    // ── New session ─────────────────────────────────────────────────────────
    document.getElementById('btn-clear-session')?.addEventListener('click', () => {
      window.location.href = '{{ route("agent-chat.index") }}';
    });

    // ── Build analysis card HTML ────────────────────────────────────────────
    function buildAnalysisCard(query, content, agentsUsed, timestamp) {
      const now = timestamp || new Date().toLocaleString('tr-TR', { day:'2-digit', month:'2-digit', hour:'2-digit', minute:'2-digit' });
      const badges = (agentsUsed || []).map(a => {
        const c   = agentColorMap[a]  || 'secondary';
        const lbl = agentLabelMap[a]  || a;
        return `<span class="ac-agent-badge bg-label-${c} text-${c}">${lbl}</span>`;
      }).join('');

      const qLabel = query
        ? `<span class="query-label" title="${escHtml(query)}">
             <i class="icon-base ti tabler-message-2 icon-12px me-1"></i>${escHtml(query.length > 60 ? query.slice(0,60)+'…' : query)}
           </span>`
        : '';

      const el = document.createElement('div');
      el.className = 'analysis-card mb-4';
      el.innerHTML = `
        <div class="ac-header">
          ${qLabel}
          <div class="ac-agents">${badges}</div>
          <span class="ac-time">${now}</span>
        </div>
        <div class="ac-body">${escHtml(content)}</div>`;
      return el;
    }

    function buildSkeleton(query) {
      const el = document.createElement('div');
      el.className = 'skeleton-card mb-4';
      el.id = 'skeleton-loading';
      el.innerHTML = `
        <div class="sk-header">
          <div class="sk-dot"></div><div class="sk-dot"></div><div class="sk-dot"></div>
          <span class="sk-label ms-1">${escHtml(query.length > 55 ? query.slice(0,55)+'…' : query)} için analiz yapılıyor…</span>
        </div>
        <div class="sk-body">
          <div class="sk-line" style="width:85%;"></div>
          <div class="sk-line" style="width:65%;"></div>
          <div class="sk-line" style="width:75%;"></div>
          <div class="sk-line" style="width:50%;margin-bottom:0;"></div>
        </div>`;
      return el;
    }

    function escHtml(str) {
      const d = document.createElement('div');
      d.appendChild(document.createTextNode(str));
      return d.innerHTML;
    }

    // ── Agent badge updates ──────────────────────────────────────────────────
    function setAgentState(agentKey, state) {
      const el = document.getElementById(`agent-${agentKey}`);
      if (!el) return;
      const badge = el.querySelector('.agent-state');
      if (!badge) return;
      if (state === 'running') {
        badge.className = 'agent-status-badge bg-label-warning agent-state d-inline-flex align-items-center gap-1';
        badge.innerHTML = '<span class="agent-pulse"></span>Çalışıyor';
      } else if (state === 'done') {
        badge.className = 'agent-status-badge bg-label-success agent-state';
        badge.innerHTML = 'Tamamlandı';
      } else {
        badge.className = 'agent-status-badge bg-label-secondary agent-state';
        badge.innerHTML = 'Beklemede';
      }
    }

    function resetAllAgents() {
      document.querySelectorAll('.agent-state').forEach(el => {
        el.className = 'agent-status-badge bg-label-secondary agent-state';
        el.innerHTML = 'Beklemede';
      });
    }

    // ── Polling for running agents ──────────────────────────────────────────
    let pollTimer = null;

    function startPolling() {
      pollTimer = setInterval(async () => {
        try {
          const r = await fetch('{{ route("agent-chat.runs") }}', {
            headers: { Accept: 'application/json', 'X-CSRF-TOKEN': csrf }
          });
          const d = await r.json();
          (d.runs || []).slice(0, 5).forEach(run => {
            if (run.status === 'running') setAgentState(run.agent_name, 'running');
          });
          updateRunsList(d.runs || []);
        } catch (_) {}
      }, 2500);
    }

    function stopPolling() {
      clearInterval(pollTimer); pollTimer = null;
    }

    function updateRunsList(runs) {
      const list = document.getElementById('runs-list');
      if (!list || !runs.length) return;
      list.innerHTML = runs.slice(0, 10).map(r => {
        const dotColor = r.status === 'completed' ? 'bg-success' : r.status === 'failed' ? 'bg-danger' : 'bg-warning';
        const badgeColor = r.status === 'completed' ? 'bg-label-success' : r.status === 'failed' ? 'bg-label-danger' : 'bg-label-warning';
        const toks = (r.tokens_in || 0) + (r.tokens_out || 0);
        const dur  = r.duration_ms ? `· ${r.duration_ms}ms` : '';
        return `<div class="run-item">
          <div class="run-dot ${dotColor}"></div>
          <div class="flex-grow-1">
            <div class="run-name text-truncate" style="max-width:160px;">${escHtml(r.agent_name)}</div>
            <div class="run-meta">${escHtml(r.model_used || '—')} ${dur} · ${toks} tok</div>
          </div>
          <span class="badge ${badgeColor}" style="font-size:.62rem;">${r.status}</span>
        </div>`;
      }).join('');
    }

    // ── Send message ─────────────────────────────────────────────────────────
    async function sendMessage(query) {
      if (!query.trim()) return;
      cmdInput.value = '';
      cmdSend.disabled = true;

      emptyState?.classList.add('d-none');
      resetAllAgents();

      const skeleton = buildSkeleton(query);
      feed.insertBefore(skeleton, feed.firstChild);
      startPolling();

      try {
        const resp = await fetch('{{ route("agent-chat.send") }}', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': csrf,
            Accept: 'application/json',
          },
          body: JSON.stringify({ message: query, session_id: sessionId }),
        });

        stopPolling();
        const data = await resp.json();
        skeleton.remove();

        if (data.agents_used?.length) {
          data.agents_used.forEach(a => setAgentState(a, 'done'));
        }

        const content = data.status === 'error'
          ? (data.reply || 'Bir hata oluştu. Lütfen tekrar deneyin.')
          : data.reply;

        const card = buildAnalysisCard(query, content, data.agents_used || []);
        feed.insertBefore(card, feed.firstChild);

      } catch (err) {
        stopPolling();
        skeleton.remove();
        const card = buildAnalysisCard(query, 'Bağlantı hatası. İnternet bağlantınızı kontrol edip tekrar deneyin.', []);
        feed.insertBefore(card, feed.firstChild);
      } finally {
        cmdSend.disabled = false;
        cmdInput.focus();
      }
    }

    cmdSend.addEventListener('click', () => sendMessage(cmdInput.value.trim()));
    cmdInput.addEventListener('keydown', e => {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(cmdInput.value.trim()); }
    });

    // ── Dismiss insights ─────────────────────────────────────────────────────
    document.querySelectorAll('.btn-dismiss-insight').forEach(btn => {
      btn.addEventListener('click', function () {
        const url = this.dataset.url;
        const id  = this.dataset.id;
        fetch(url, { method: 'PATCH', headers: { 'X-CSRF-TOKEN': csrf } })
          .then(() => {
            const li = document.getElementById('insight-' + id);
            if (li) { li.style.opacity = 0; setTimeout(() => li.remove(), 200); }
          });
      });
    });
  })();
  </script>
  </x-slot>
</x-app-layout>
