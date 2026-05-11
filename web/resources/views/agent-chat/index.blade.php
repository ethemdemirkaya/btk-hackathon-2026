<x-app-layout>
  <x-slot name="title">Finansal Zeka Merkezi</x-slot>

  <x-slot name="pageCss">
    {{-- Markdown renderer (lightweight) --}}
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/github-markdown-css@5/github-markdown.min.css">
  <style>
    /* ── Markdown content inside analysis cards ─────────────────────────── */
    .markdown-body {
      font-size: .86rem !important;
      line-height: 1.7 !important;
      background: transparent !important;
      color: var(--bs-body-color) !important;
    }
    .markdown-body h1,.markdown-body h2,.markdown-body h3 {
      font-size: 1rem !important; font-weight: 700 !important;
      margin: .9rem 0 .4rem !important; color: var(--bs-heading-color) !important;
      border-bottom: 1px solid var(--bs-border-color) !important;
      padding-bottom: .25rem !important;
    }
    .markdown-body h4,.markdown-body h5 { font-size: .9rem !important; font-weight: 700 !important; margin: .7rem 0 .3rem !important; }
    .markdown-body ul,.markdown-body ol { padding-left: 1.3rem !important; margin: .4rem 0 !important; }
    .markdown-body li { margin-bottom: .2rem !important; }
    .markdown-body strong { color: var(--bs-heading-color) !important; }
    .markdown-body code {
      font-size: .8rem !important; padding: .1rem .35rem !important;
      border-radius: 4px !important;
      background: var(--bs-secondary-bg) !important;
      color: #e95d5d !important; border: none !important;
    }
    .markdown-body pre {
      background: var(--bs-secondary-bg) !important;
      border-radius: 8px !important; padding: .75rem 1rem !important;
      border: 1px solid var(--bs-border-color) !important;
    }
    .markdown-body pre code { color: var(--bs-body-color) !important; background: transparent !important; }
    .markdown-body blockquote {
      border-left: 3px solid #7367F0 !important;
      padding-left: .75rem !important; margin: .5rem 0 !important;
      color: var(--bs-secondary-color) !important;
    }
    .markdown-body table { font-size: .8rem !important; width: 100% !important; }
    .markdown-body table th { background: var(--bs-secondary-bg) !important; }
    .markdown-body table th, .markdown-body table td {
      padding: .3rem .6rem !important;
      border: 1px solid var(--bs-border-color) !important;
    }
    .markdown-body hr { border-color: var(--bs-border-color) !important; }
    .markdown-body p { margin-bottom: .5rem !important; }

    /* ── Command bar ──────────────────────────────────────────────────────── */
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
      border: none !important; box-shadow: none !important;
      background: transparent !important;
      font-size: .95rem; padding: .85rem 1rem .85rem 1.1rem;
    }
    .command-bar .cmd-send {
      border-radius: 0 12px 12px 0; padding: .75rem 1.25rem;
      border: none; background: #7367F0; color: #fff;
      font-size: .85rem; font-weight: 600; transition: background .14s; flex-shrink: 0;
    }
    .command-bar .cmd-send:hover    { background: #5f53e5; }
    .command-bar .cmd-send:disabled { background: var(--bs-secondary-bg); color: var(--bs-secondary-color); cursor: not-allowed; }

    /* ── Hero command bar (in empty state) ───────────────────────────────── */
    .hero-command-bar {
      border: 2px solid rgba(115,103,240,.3) !important;
    }
    .hero-command-bar:focus-within {
      border-color: #7367F0 !important;
      box-shadow: 0 0 0 4px rgba(115,103,240,.15) !important;
    }

    /* ── Quick trigger pills ─────────────────────────────────────────────── */
    .trigger-pills { display: flex; gap: .5rem; flex-wrap: wrap; }
    .trigger-pill {
      cursor: pointer; border-radius: 20px; padding: .3rem .8rem;
      font-size: .75rem; font-weight: 500;
      border: 1px solid var(--bs-border-color);
      color: var(--bs-secondary-color); background: var(--bs-body-bg);
      transition: all .15s; user-select: none;
    }
    .trigger-pill:hover {
      border-color: #7367F0; color: #7367F0;
      background: rgba(115,103,240,.06);
    }
    .trigger-pill i { font-size: 13px; vertical-align: middle; margin-right: 3px; }

    /* ── Analysis result card ───────────────────────────────────────────── */
    .analysis-card {
      border: 1px solid var(--bs-border-color); border-radius: 12px;
      overflow: hidden; transition: box-shadow .18s; background: var(--bs-body-bg);
    }
    .analysis-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,.08); }
    .analysis-card .ac-header {
      background: var(--bs-tertiary-bg); border-bottom: 1px solid var(--bs-border-color);
      padding: .6rem 1rem;
      display: flex; align-items: center; justify-content: space-between; gap: .5rem; flex-wrap: wrap;
    }
    .query-label {
      font-size: .7rem; font-weight: 600; color: var(--bs-secondary-color);
      background: var(--bs-secondary-bg); border: 1px solid var(--bs-border-color);
      border-radius: 10px; padding: .15rem .55rem;
      max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
    }
    .ac-agents { display: flex; gap: .3rem; flex-wrap: wrap; }
    .ac-agent-badge {
      font-size: .62rem; font-weight: 700; letter-spacing: .02em;
      padding: .15rem .5rem; border-radius: 10px;
    }
    .ac-time { font-size: .68rem; color: var(--bs-tertiary-color); flex-shrink: 0; margin-left: auto; }
    .ac-body { padding: .9rem 1rem; }

    /* ── Action suggestion buttons in card footer ─────────────────────── */
    .ac-actions {
      padding: .6rem 1rem;
      border-top: 1px solid var(--bs-border-color);
      background: var(--bs-tertiary-bg);
      display: flex; gap: .5rem; flex-wrap: wrap; align-items: center;
    }
    .ac-actions .action-label {
      font-size: .7rem; color: var(--bs-secondary-color); font-weight: 600; margin-right: .25rem;
    }

    /* ── Skeleton loading card ───────────────────────────────────────────── */
    .skeleton-card {
      border: 1px solid var(--bs-border-color); border-radius: 12px;
      overflow: hidden; background: var(--bs-body-bg);
    }
    .skeleton-card .sk-header {
      background: var(--bs-tertiary-bg); border-bottom: 1px solid var(--bs-border-color);
      padding: .65rem 1rem; display: flex; align-items: center; gap: .75rem;
    }
    .sk-dot {
      width: 7px; height: 7px; border-radius: 50%;
      background: #7367F0; flex-shrink: 0;
      animation: skPulse 1.2s ease-in-out infinite;
    }
    .sk-dot:nth-child(2) { animation-delay: .2s; }
    .sk-dot:nth-child(3) { animation-delay: .4s; }
    @@keyframes skPulse {
      0%,100% { opacity: 1; transform: scale(1); }
      50%      { opacity: .3; transform: scale(.6); }
    }
    .sk-label { font-size: .75rem; color: var(--bs-secondary-color); font-weight: 600; }
    .sk-body { padding: .9rem 1rem; }
    .sk-line {
      height: 9px; border-radius: 5px; background: var(--bs-secondary-bg);
      margin-bottom: .55rem; animation: skShimmer 1.6s ease-in-out infinite;
    }
    @@keyframes skShimmer { 0%,100% { opacity: .5; } 50% { opacity: 1; } }

    /* ── Empty state (hero) ──────────────────────────────────────────────── */
    .hero-empty {
      padding: 2.5rem 2rem 2rem;
      text-align: center;
    }
    .ei-glow {
      width: 90px; height: 90px; border-radius: 50%;
      background: radial-gradient(circle, rgba(115,103,240,.18) 0%, rgba(115,103,240,.04) 70%);
      display: flex; align-items: center; justify-content: center; margin: 0 auto 1.25rem;
    }

    /* ── Agent status sidebar ────────────────────────────────────────────── */
    .agent-li {
      display: flex; align-items: center; gap: .65rem;
      padding: .6rem .9rem; border-bottom: 1px solid var(--bs-border-color);
      transition: background .1s;
    }
    .agent-li:last-child { border-bottom: none; }
    .agent-li:hover { background: var(--bs-secondary-bg); }
    .agent-name { font-size: .78rem; font-weight: 500; color: var(--bs-heading-color); line-height: 1.2; }
    .agent-status-badge {
      font-size: .62rem; font-weight: 700; border-radius: 10px;
      padding: .15rem .5rem; white-space: nowrap; flex-shrink: 0;
    }
    .agent-pulse {
      width: 7px; height: 7px; border-radius: 50%; background: #ff9f43; flex-shrink: 0;
      animation: agentPulse 1.1s ease-in-out infinite;
    }
    @@keyframes agentPulse { 0%,100% { opacity:1; transform:scale(1); } 50% { opacity:.4; transform:scale(.65); } }

    /* ── Run timeline ────────────────────────────────────────────────────── */
    .run-item {
      padding: .55rem .9rem; border-bottom: 1px solid var(--bs-border-color);
      display: flex; align-items: flex-start; gap: .6rem;
    }
    .run-item:last-child { border-bottom: none; }
    .run-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; margin-top: 4px; }
    .run-name { font-size: .76rem; font-weight: 500; line-height: 1.2; }
    .run-meta { font-size: .67rem; color: var(--bs-secondary-color); margin-top: 1px; }

    /* ── Insight cards ───────────────────────────────────────────────────── */
    .insight-li { padding: .65rem .9rem; border-bottom: 1px solid var(--bs-border-color); }
    .insight-li:last-child { border-bottom: none; }
    .insight-title { font-size: .78rem; font-weight: 600; color: var(--bs-heading-color); }
    .insight-body  { font-size: .72rem; color: var(--bs-secondary-color); margin-top: 2px; }

    /* ── Compact top bar (visible only when results exist) ───────────────── */
    #compact-bar { display: none; }
    #compact-bar.visible { display: flex; }
  </style>
  </x-slot>

  {{-- ══ Page Header ════════════════════════════════════════════════════════════ --}}
  <div class="d-flex align-items-center justify-content-between mb-4 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">
        <i class="icon-base ti tabler-brain text-primary me-2"></i>Finansal Zeka Merkezi
      </h4>
      <p class="text-muted mb-0 small">Yapay zeka ajanları finansal durumunuzu analiz ediyor &amp; yönetiyor</p>
    </div>
    <div class="d-flex gap-2 flex-wrap">
      <button type="button" class="btn btn-sm btn-outline-secondary" id="btn-clear-session">
        <i class="icon-base ti tabler-refresh me-1"></i>Yeni Analiz
      </button>
    </div>
  </div>

  {{-- ══ Compact command bar (shown when results exist) ══════════════════════════ --}}
  <div id="compact-bar" class="command-bar mb-3 shadow-sm align-items-center">
    <input type="text" id="cmd-input-top" placeholder="Yeni sorgu veya eylem…" autocomplete="off">
    <button class="cmd-send" id="cmd-send-top" type="button">
      <i class="icon-base ti tabler-arrow-up me-1" style="font-size:14px;"></i>Gönder
    </button>
  </div>

  {{-- ══ Quick triggers (always visible) ══════════════════════════════════════════ --}}
  <div class="trigger-pills mb-4" id="trigger-pills-area">
    <span class="trigger-pill" data-msg="Son harcamalarımda anormal bir durum var mı? Ayrıntılı analiz yap.">
      <i class="icon-base ti tabler-radar"></i>Anomali Tara
    </span>
    <span class="trigger-pill" data-msg="Bu ayki bütçe durumumu analiz et ve nerede tasarruf yapabileceğimi göster.">
      <i class="icon-base ti tabler-chart-pie"></i>Bütçe Analizi
    </span>
    <span class="trigger-pill" data-msg="Önümüzdeki 6 ay için nakit akışımı ve birikimimi tahmin et.">
      <i class="icon-base ti tabler-chart-line"></i>6 Aylık Tahmin
    </span>
    <span class="trigger-pill" data-msg="Kredi kartı borçlarımı en hızlı şekilde kapatmak için strateji öner ve bana yardım et.">
      <i class="icon-base ti tabler-credit-card"></i>Borç Stratejisi
    </span>
    <span class="trigger-pill" data-msg="Gereksiz veya pahalı aboneliklerim var mı? Tespit et ve optimize et.">
      <i class="icon-base ti tabler-repeat"></i>Abonelik Tara
    </span>
    <span class="trigger-pill" data-msg="Enflasyon birikimimi ve satın alma gücümü nasıl etkiliyor? Ne yapmalıyım?">
      <i class="icon-base ti tabler-flame"></i>Enflasyon Etkisi
    </span>
  </div>

  <input type="hidden" id="session-id" value="{{ $sessionId }}">

  <div class="row g-5">

    {{-- ══ MAIN FEED ══════════════════════════════════════════════════════════════ --}}
    <div class="col-xl-8">
      <div id="results-feed">

        {{-- Empty / hero state --}}
        <div id="empty-state" class="{{ $history->where('role','assistant')->isNotEmpty() ? 'd-none' : '' }}">
          <div class="card shadow-sm">
            <div class="hero-empty">
              <div class="ei-glow">
                <i class="icon-base ti tabler-sparkles icon-40px text-primary"></i>
              </div>
              <h5 class="fw-semibold mb-2">Ne yapmamı istersin?</h5>
              <p class="text-muted mb-4" style="max-width:420px;margin:0 auto 1.5rem;">
                Finansal durumunu analiz edeyim, hedef koyayım, bütçeni optimize edeyim
                veya herhangi bir işlemi gerçekleştireyim.
              </p>

              {{-- Hero command bar --}}
              <div class="command-bar hero-command-bar d-flex align-items-center mb-4" style="max-width:560px;margin:0 auto 1.5rem;">
                <input type="text" id="cmd-input-hero" placeholder="Bana ne yaptırayım? (örn: hedef koy, bütçe analizi yap…)" autocomplete="off" style="font-size:.93rem;">
                <button class="cmd-send" id="cmd-send-hero" type="button">
                  <i class="icon-base ti tabler-arrow-up me-1" style="font-size:14px;"></i>Gönder
                </button>
              </div>

              {{-- Trust badges --}}
              <div class="d-flex gap-4 justify-content-center flex-wrap">
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
                  Arka planda asenkron
                </div>
              </div>
            </div>
          </div>
        </div>

        {{-- Historical results --}}
        @php $prevQuery = null; @endphp
        @foreach($history as $msg)
          @if($msg->role === 'user')
            @php $prevQuery = $msg->content; @endphp
          @elseif($msg->role === 'assistant')
            @php
              $isPending  = ($msg->metadata['status'] ?? '') === 'pending';
              $agentsUsed = $msg->metadata['agents_used'] ?? [];
              $agentColorMap = [
                'purchase_planner'=>'primary','budget_advisor'=>'success',
                'inflation_aware'=>'warning','anomaly_detector'=>'danger',
                'transaction_classifier'=>'info','forecaster'=>'info',
                'debt_optimizer'=>'danger','subscription_hunter'=>'secondary',
                'receipt_ocr'=>'primary','critic'=>'secondary',
              ];
              $agentLabelMap = [
                'purchase_planner'=>'Satın Alma','budget_advisor'=>'Bütçe',
                'inflation_aware'=>'Enflasyon','anomaly_detector'=>'Anomali',
                'transaction_classifier'=>'Sınıf.','forecaster'=>'Tahmin',
                'debt_optimizer'=>'Borç','subscription_hunter'=>'Abonelik',
                'receipt_ocr'=>'OCR','critic'=>'Eleştirmen',
              ];
            @endphp
            @if($isPending)
              <div class="skeleton-card mb-4" id="skeleton-{{ $msg->id }}" data-message-id="{{ $msg->id }}">
                <div class="sk-header">
                  <div class="sk-dot"></div><div class="sk-dot"></div><div class="sk-dot"></div>
                  <span class="sk-label ms-1">{{ $prevQuery ? \Illuminate\Support\Str::limit($prevQuery, 55) . '…' : 'Analiz yapılıyor…' }}</span>
                </div>
                <div class="sk-body">
                  <div class="sk-line" style="width:82%;"></div>
                  <div class="sk-line" style="width:61%;"></div>
                  <div class="sk-line" style="width:73%;"></div>
                  <div class="sk-line" style="width:48%;margin-bottom:0;"></div>
                </div>
              </div>
            @else
              <div class="analysis-card mb-4">
                <div class="ac-header">
                  @if($prevQuery)
                    <span class="query-label" title="{{ $prevQuery }}">
                      <i class="icon-base ti tabler-message-2 icon-12px me-1"></i>{{ \Illuminate\Support\Str::limit($prevQuery, 60) }}
                    </span>
                  @endif
                  <div class="ac-agents">
                    @foreach($agentsUsed as $a)
                      @php $c=$agentColorMap[$a]??'secondary'; $lbl=$agentLabelMap[$a]??$a; @endphp
                      <span class="ac-agent-badge bg-label-{{ $c }} text-{{ $c }}">{{ $lbl }}</span>
                    @endforeach
                  </div>
                  <span class="ac-time">{{ \Carbon\Carbon::parse($msg->created_at)->format('d.m H:i') }}</span>
                </div>
                <div class="ac-body">
                  <div class="markdown-body" data-raw="{{ e($msg->content) }}"></div>
                </div>
              </div>
            @endif
            @php $prevQuery = null; @endphp
          @endif
        @endforeach

      </div>
    </div>

    {{-- ══ SIDEBAR ══════════════════════════════════════════════════════════════ --}}
    <div class="col-xl-4">

      {{-- Agent Status --}}
      <div class="card mb-4 shadow-sm">
        <div class="card-header py-3 d-flex align-items-center justify-content-between">
          <h6 class="card-title mb-0 fw-semibold">
            <i class="icon-base ti tabler-cpu me-2 text-primary"></i>Uzman Ajanlar
          </h6>
          <span class="badge bg-label-success agent-global-status" style="font-size:.68rem;">Hazır</span>
        </div>
        <div id="agent-status-list">
          @foreach([
            'purchase_planner'       => ['Satın Alma Planlayıcı',  'tabler-shopping-cart',  'primary'],
            'budget_advisor'         => ['Bütçe Danışmanı',         'tabler-chart-pie',      'success'],
            'inflation_aware'        => ['Enflasyon Analisti',      'tabler-flame',          'warning'],
            'anomaly_detector'       => ['Anomali Dedektörü',       'tabler-radar',          'danger'],
            'transaction_classifier' => ['İşlem Sınıflandırıcı',   'tabler-tag',            'info'],
            'forecaster'             => ['Tahmin & Projeksiyon',    'tabler-chart-line',     'info'],
            'debt_optimizer'         => ['Borç Optimizasyonu',      'tabler-credit-card',    'danger'],
            'subscription_hunter'    => ['Abonelik Avcısı',         'tabler-repeat',         'secondary'],
            'receipt_ocr'            => ['Fiş & OCR Analizi',       'tabler-receipt',        'primary'],
          ] as $key => [$label, $icon, $color])
          <div class="agent-li" id="agent-{{ $key }}">
            <div class="avatar avatar-sm flex-shrink-0">
              <span class="avatar-initial rounded bg-label-{{ $color }}">
                <i class="icon-base ti {{ $icon }} text-{{ $color }}" style="font-size:13px;"></i>
              </span>
            </div>
            <div class="flex-grow-1"><div class="agent-name">{{ $label }}</div></div>
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
            <div class="run-dot {{ $run->status === 'completed' ? 'bg-success' : ($run->status === 'failed' ? 'bg-danger' : 'bg-warning') }}"></div>
            <div class="flex-grow-1">
              <div class="run-name text-truncate" style="max-width:160px;">{{ $run->agent_name }}</div>
              <div class="run-meta">
                {{ $run->model_used ?? '—' }}
                @if($run->duration_ms) · {{ $run->duration_ms }}ms @endif
                · {{ ($run->tokens_in ?? 0) + ($run->tokens_out ?? 0) }} tok
              </div>
            </div>
            <span class="badge {{ $run->status === 'completed' ? 'bg-label-success' : ($run->status === 'failed' ? 'bg-label-danger' : 'bg-label-warning') }}" style="font-size:.62rem;">{{ $run->status }}</span>
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
        @php $ic = ['warning'=>'warning','opportunity'=>'success','tip'=>'info','anomaly'=>'danger'][$insight->type] ?? 'secondary'; @endphp
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
    <script src="https://cdn.jsdelivr.net/npm/marked@12/marked.min.js"></script>
  <script>
  (function () {
    'use strict';

    // ── Marked.js config ─────────────────────────────────────────────────────
    marked.setOptions({ breaks: true, gfm: true });

    function renderMarkdown(el) {
      const raw = el.getAttribute('data-raw');
      if (!raw) return;
      el.innerHTML = marked.parse(raw);
    }

    // Render all existing markdown bodies on page load
    document.querySelectorAll('.markdown-body[data-raw]').forEach(renderMarkdown);

    // ── Constants ────────────────────────────────────────────────────────────
    const sessionId = document.getElementById('session-id').value;
    const csrf      = document.querySelector('meta[name=csrf-token]').content;
    const feed      = document.getElementById('results-feed');
    const emptyState = document.getElementById('empty-state');
    const compactBar = document.getElementById('compact-bar');

    const POLL_URL = '/chat/poll/'; // + message_id
    const RUNS_URL = '{{ route("agent-chat.runs") }}';

    const agentLabelMap = {
      purchase_planner:'Satın Alma', budget_advisor:'Bütçe',
      inflation_aware:'Enflasyon', anomaly_detector:'Anomali',
      transaction_classifier:'Sınıf.', forecaster:'Tahmin',
      debt_optimizer:'Borç', subscription_hunter:'Abonelik',
      receipt_ocr:'OCR', critic:'Eleştirmen',
    };
    const agentColorMap = {
      purchase_planner:'primary', budget_advisor:'success',
      inflation_aware:'warning', anomaly_detector:'danger',
      transaction_classifier:'info', forecaster:'info',
      debt_optimizer:'danger', subscription_hunter:'secondary',
      receipt_ocr:'primary', critic:'secondary',
    };

    // ── Action detection ─────────────────────────────────────────────────────
    // Detect actionable keywords in AI response and generate action buttons
    function detectActions(text) {
      const actions = [];
      const lower = text.toLowerCase();
      if (/hedef\s*(belirle|ekle|koy|oluştur)/i.test(text) || /yeni hedef/i.test(text))
        actions.push({ label: 'Hedef Ekle', icon: 'tabler-target', color: 'success', href: '/goals' });
      if (/bütçe\s*(oluştur|ekle|belirle|kur)/i.test(text) || /bütçe\s*ayarla/i.test(text))
        actions.push({ label: 'Bütçe Kur', icon: 'tabler-chart-pie', color: 'primary', href: '/budgets' });
      if (/abonelik\s*(iptal|kaldır|sil)/i.test(text))
        actions.push({ label: 'Abonelikleri Gör', icon: 'tabler-repeat', color: 'warning', href: '/subscriptions' });
      if (/borç\s*(öde|kapat|azalt)/i.test(text) || /kart\s*borcunu/i.test(text))
        actions.push({ label: 'Kartları Gör', icon: 'tabler-credit-card', color: 'danger', href: '/cards' });
      if (/simülasyon|simülatör|hesapla/i.test(text))
        actions.push({ label: 'Simülatörü Aç', icon: 'tabler-calculator', color: 'info', href: '/simulator' });
      if (/işlemlere\s*bak|işlemleri\s*incele/i.test(text))
        actions.push({ label: 'İşlemler', icon: 'tabler-arrows-exchange', color: 'secondary', href: '/transactions' });
      if (/yatırım|portföy/i.test(lower))
        actions.push({ label: 'Yatırımlar', icon: 'tabler-trending-up', color: 'success', href: '/investments' });
      return actions;
    }

    // ── Build analysis card ───────────────────────────────────────────────────
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

      const actions = detectActions(content);
      const actionsHtml = actions.length
        ? `<div class="ac-actions">
             <span class="action-label"><i class="icon-base ti tabler-player-play icon-12px me-1"></i>Ajan önerisi:</span>
             ${actions.map(a => `<a href="${a.href}" class="btn btn-sm btn-outline-${a.color}" style="font-size:.72rem;padding:.2rem .6rem;">
               <i class="icon-base ti ${a.icon} me-1"></i>${a.label}</a>`).join('')}
           </div>`
        : '';

      const el = document.createElement('div');
      el.className = 'analysis-card mb-4';
      el.innerHTML = `
        <div class="ac-header">
          ${qLabel}
          <div class="ac-agents">${badges}</div>
          <span class="ac-time">${now}</span>
        </div>
        <div class="ac-body">
          <div class="markdown-body" data-raw="${escAttr(content)}"></div>
        </div>
        ${actionsHtml}`;

      // Render markdown in the new card
      const mdEl = el.querySelector('.markdown-body');
      if (mdEl) renderMarkdown(mdEl);

      return el;
    }

    function buildSkeleton(query, messageId) {
      const el = document.createElement('div');
      el.className = 'skeleton-card mb-4';
      el.id = messageId ? `skeleton-${messageId}` : 'skeleton-loading';
      if (messageId) el.setAttribute('data-message-id', messageId);
      el.innerHTML = `
        <div class="sk-header">
          <div class="sk-dot"></div><div class="sk-dot"></div><div class="sk-dot"></div>
          <span class="sk-label ms-1">${escHtml(query.length > 55 ? query.slice(0,55)+'…' : query)} analiz ediliyor…</span>
        </div>
        <div class="sk-body">
          <div class="sk-line" style="width:82%;"></div>
          <div class="sk-line" style="width:60%;"></div>
          <div class="sk-line" style="width:73%;"></div>
          <div class="sk-line" style="width:47%;margin-bottom:0;"></div>
        </div>`;
      return el;
    }

    function escHtml(str) {
      const d = document.createElement('div');
      d.appendChild(document.createTextNode(str));
      return d.innerHTML;
    }
    function escAttr(str) {
      return str.replace(/&/g,'&amp;').replace(/"/g,'&quot;').replace(/'/g,'&#39;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
    }

    // ── Show / hide UI elements ───────────────────────────────────────────────
    function showResultsMode() {
      emptyState?.classList.add('d-none');
      compactBar.classList.add('visible');
    }

    // Check on load if there are results
    if (!emptyState || emptyState.classList.contains('d-none')) showResultsMode();

    // ── Polling running skeletons on page load ────────────────────────────────
    document.querySelectorAll('.skeleton-card[data-message-id]').forEach(sk => {
      const mid = sk.getAttribute('data-message-id');
      if (mid) startPolling(mid, sk, null);
    });

    // ── Poll for a specific message ───────────────────────────────────────────
    function startPolling(messageId, skeletonEl, query) {
      const timer = setInterval(async () => {
        try {
          const r = await fetch(POLL_URL + messageId, {
            headers: { Accept: 'application/json', 'X-CSRF-TOKEN': csrf }
          });
          const d = await r.json();

          if (d.status === 'completed' || d.status === 'error') {
            clearInterval(timer);
            const card = buildAnalysisCard(query, d.reply || '(Yanıt alınamadı)', d.agents_used || []);
            if (skeletonEl.parentNode) skeletonEl.replaceWith(card);
            if (d.agents_used?.length) d.agents_used.forEach(a => setAgentState(a, 'done'));
            resetAgentsAfter(3000);
          }
        } catch (_) {}
      }, 2500);
    }

    // ── Agent badge helpers ───────────────────────────────────────────────────
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
        el.textContent = 'Beklemede';
      });
      const gs = document.querySelector('.agent-global-status');
      if (gs) { gs.className = 'badge bg-label-success agent-global-status'; gs.textContent = 'Hazır'; }
    }

    function resetAgentsAfter(ms) {
      setTimeout(resetAllAgents, ms);
    }

    function setGlobalRunning() {
      const gs = document.querySelector('.agent-global-status');
      if (gs) { gs.className = 'badge bg-label-warning agent-global-status'; gs.textContent = 'Çalışıyor'; }
    }

    // ── Agent run polling sidebar ─────────────────────────────────────────────
    let runsTimer = null;
    function startRunsPolling() {
      runsTimer = setInterval(async () => {
        try {
          const r = await fetch(RUNS_URL, { headers: { Accept: 'application/json', 'X-CSRF-TOKEN': csrf } });
          const d = await r.json();
          (d.runs || []).slice(0, 5).forEach(run => {
            if (run.status === 'running') setAgentState(run.agent_name, 'running');
          });
          updateRunsList(d.runs || []);
        } catch (_) {}
      }, 3000);
    }

    function stopRunsPolling() { clearInterval(runsTimer); runsTimer = null; }

    function updateRunsList(runs) {
      const list = document.getElementById('runs-list');
      if (!list || !runs.length) return;
      list.innerHTML = runs.slice(0, 10).map(r => {
        const dotColor   = r.status === 'completed' ? 'bg-success' : r.status === 'failed' ? 'bg-danger' : 'bg-warning';
        const badgeColor = r.status === 'completed' ? 'bg-label-success' : r.status === 'failed' ? 'bg-label-danger' : 'bg-label-warning';
        const toks = (r.tokens_in || 0) + (r.tokens_out || 0);
        const dur  = r.duration_ms ? `· ${r.duration_ms}ms` : '';
        return `<div class="run-item">
          <div class="run-dot ${dotColor}"></div>
          <div class="flex-grow-1">
            <div class="run-name text-truncate" style="max-width:160px;">${escHtml(r.agent_name)}</div>
            <div class="run-meta">${escHtml(r.model_used||'—')} ${dur} · ${toks} tok</div>
          </div>
          <span class="badge ${badgeColor}" style="font-size:.62rem;">${r.status}</span>
        </div>`;
      }).join('');
    }

    // ── Send message ──────────────────────────────────────────────────────────
    async function sendMessage(query) {
      if (!query.trim()) return;

      // Clear all inputs
      ['cmd-input-hero','cmd-input-top'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.value = '';
      });
      disableSendButtons(true);
      showResultsMode();
      resetAllAgents();
      setGlobalRunning();

      const skeleton = buildSkeleton(query);
      feed.insertBefore(skeleton, feed.firstChild);
      startRunsPolling();

      try {
        const resp = await fetch('{{ route("agent-chat.send") }}', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrf, Accept: 'application/json' },
          body: JSON.stringify({ message: query, session_id: sessionId }),
        });

        const data = await resp.json();
        stopRunsPolling();

        if (data.status === 'pending' && data.message_id) {
          // Job queued — attach message_id to skeleton and start polling
          skeleton.id = `skeleton-${data.message_id}`;
          skeleton.setAttribute('data-message-id', data.message_id);
          startPolling(data.message_id, skeleton, query);
          // Re-enable UI immediately — user can navigate away
          disableSendButtons(false);
          return;
        }

        // Fallback: synchronous response (QUEUE_CONNECTION=sync)
        skeleton.remove();
        const content = data.reply || '(Yanıt alınamadı)';
        const card = buildAnalysisCard(query, content, data.agents_used || []);
        feed.insertBefore(card, feed.firstChild);
        if (data.agents_used?.length) data.agents_used.forEach(a => setAgentState(a, 'done'));
        resetAgentsAfter(3000);

      } catch (err) {
        stopRunsPolling();
        skeleton.remove();
        const card = buildAnalysisCard(query, 'Bağlantı hatası. İnternet bağlantınızı kontrol edip tekrar deneyin.', []);
        feed.insertBefore(card, feed.firstChild);
      } finally {
        disableSendButtons(false);
      }
    }

    function disableSendButtons(disabled) {
      ['cmd-send-hero','cmd-send-top'].forEach(id => {
        const btn = document.getElementById(id);
        if (btn) btn.disabled = disabled;
      });
    }

    // ── Wire up all send buttons / inputs ─────────────────────────────────────
    ['hero','top'].forEach(suffix => {
      const input = document.getElementById(`cmd-input-${suffix}`);
      const btn   = document.getElementById(`cmd-send-${suffix}`);
      if (btn)   btn.addEventListener('click',  () => sendMessage(getActiveInput()));
      if (input) input.addEventListener('keydown', e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(input.value.trim()); } });
    });

    function getActiveInput() {
      const hero = document.getElementById('cmd-input-hero');
      const top  = document.getElementById('cmd-input-top');
      if (hero && hero.value.trim()) return hero.value.trim();
      if (top  && top.value.trim())  return top.value.trim();
      return '';
    }

    // ── Quick trigger pills ───────────────────────────────────────────────────
    document.querySelectorAll('.trigger-pill').forEach(pill => {
      pill.addEventListener('click', () => {
        const activeInput = emptyState?.classList.contains('d-none')
          ? document.getElementById('cmd-input-top')
          : document.getElementById('cmd-input-hero');
        if (activeInput) { activeInput.value = pill.dataset.msg; activeInput.focus(); }
      });
    });

    // ── New session ───────────────────────────────────────────────────────────
    document.getElementById('btn-clear-session')?.addEventListener('click', () => {
      window.location.href = '{{ route("agent-chat.index") }}';
    });

    // ── Dismiss insights ──────────────────────────────────────────────────────
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
