<x-app-layout>
  <x-slot name="title">Finansal Zeka Merkezi</x-slot>

  <x-slot name="pageCss">
  <style>
    /* ══════════════════════════════════════════════════════════════════════
       CHAT LAYOUT — full-height, no page scroll
    ══════════════════════════════════════════════════════════════════════ */
    html, body { height: 100%; }

    /* Neutralise Vuexy's content-wrapper padding so we can go full-height */
    .chat-root {
      display: flex;
      height: calc(100vh - var(--header-height, 64px));
      min-height: 500px;
      margin: -1.5rem -1.5rem 0;   /* cancel page padding */
      overflow: hidden;
      border-top: 1px solid var(--bs-border-color);
    }

    /* ── LEFT SIDEBAR ─────────────────────────────────────────────────── */
    .chat-left {
      width: 260px;
      flex-shrink: 0;
      border-right: 1px solid var(--bs-border-color);
      background: var(--bs-body-bg);
      display: flex;
      flex-direction: column;
      overflow: hidden;
      transition: width .25s ease;
    }
    .chat-left.collapsed { width: 0; border-right: none; }

    .chat-left-header {
      padding: .85rem 1rem;
      border-bottom: 1px solid var(--bs-border-color);
      display: flex;
      align-items: center;
      gap: .6rem;
      flex-shrink: 0;
    }
    .chat-left-header .brand-icon {
      width: 32px; height: 32px; border-radius: 10px;
      background: linear-gradient(135deg, #7367F0 0%, #CE9FFC 100%);
      display: flex; align-items: center; justify-content: center; flex-shrink: 0;
    }
    .chat-left-header .brand-title {
      font-size: .8rem; font-weight: 700; color: var(--bs-heading-color); line-height: 1.2;
    }
    .chat-left-header .brand-sub {
      font-size: .67rem; color: var(--bs-secondary-color);
    }

    .chat-left-body { flex: 1; overflow-y: auto; }
    .chat-left-body::-webkit-scrollbar { width: 3px; }
    .chat-left-body::-webkit-scrollbar-thumb { background: var(--bs-border-color); border-radius: 3px; }

    /* New chat button */
    .btn-new-chat {
      margin: .75rem .85rem;
      display: flex; align-items: center; gap: .5rem;
      padding: .5rem .85rem; border-radius: 10px;
      font-size: .78rem; font-weight: 600;
      background: rgba(115,103,240,.1);
      color: #7367F0;
      border: 1px dashed rgba(115,103,240,.35);
      cursor: pointer; transition: all .15s;
    }
    .btn-new-chat:hover { background: rgba(115,103,240,.18); border-style: solid; }

    /* Section headings inside sidebar */
    .sidebar-section-title {
      font-size: .64rem; font-weight: 700; letter-spacing: .07em;
      text-transform: uppercase; color: var(--bs-secondary-color);
      padding: .6rem 1rem .3rem;
    }

    /* Agent list items */
    .agent-li {
      display: flex; align-items: center; gap: .6rem;
      padding: .5rem 1rem;
      border-bottom: 1px solid transparent;
      transition: background .1s;
    }
    .agent-li:hover { background: var(--bs-secondary-bg); }
    .agent-li .agent-avatar {
      width: 28px; height: 28px; border-radius: 8px; flex-shrink: 0;
      display: flex; align-items: center; justify-content: center;
    }
    .agent-li .agent-name { font-size: .76rem; font-weight: 500; color: var(--bs-heading-color); line-height: 1.2; flex: 1; min-width: 0; }
    .agent-status-badge {
      font-size: .6rem; font-weight: 700; border-radius: 8px;
      padding: .12rem .45rem; white-space: nowrap; flex-shrink: 0;
    }
    .agent-pulse {
      width: 6px; height: 6px; border-radius: 50%; background: #ff9f43; flex-shrink: 0;
      animation: agentPulse 1.1s ease-in-out infinite;
    }
    @@keyframes agentPulse { 0%,100% { opacity:1; transform:scale(1); } 50% { opacity:.4; transform:scale(.65); } }

    /* ── CENTER: CHAT AREA ───────────────────────────────────────────── */
    .chat-center {
      flex: 1; display: flex; flex-direction: column; min-width: 0;
      background: var(--bs-body-bg);
    }

    /* Top bar */
    .chat-topbar {
      padding: .7rem 1.25rem;
      border-bottom: 1px solid var(--bs-border-color);
      display: flex; align-items: center; gap: .75rem; flex-shrink: 0;
      background: var(--bs-body-bg);
    }
    .chat-topbar .topbar-toggle {
      width: 30px; height: 30px; border-radius: 8px; cursor: pointer;
      display: flex; align-items: center; justify-content: center;
      color: var(--bs-secondary-color);
      border: none; background: transparent; transition: background .1s;
    }
    .chat-topbar .topbar-toggle:hover { background: var(--bs-secondary-bg); }
    .chat-topbar .topbar-title {
      font-size: .92rem; font-weight: 700; color: var(--bs-heading-color); flex: 1;
      display: flex; align-items: center; gap: .45rem;
    }
    .chat-topbar .topbar-title .live-badge {
      font-size: .58rem; font-weight: 700; letter-spacing: .05em;
      background: rgba(40,199,111,.12); color: #28c76f;
      border-radius: 8px; padding: .12rem .4rem;
      display: inline-flex; align-items: center; gap: .25rem;
    }
    .chat-topbar .topbar-title .live-dot {
      width: 5px; height: 5px; border-radius: 50%; background: #28c76f;
      animation: ldot 1.5s ease-in-out infinite;
    }
    @@keyframes ldot { 0%,100%{opacity:1} 50%{opacity:.25} }
    .chat-topbar .agent-global-status {
      font-size: .62rem; font-weight: 700;
    }

    /* Messages scroll area */
    .chat-messages {
      flex: 1; overflow-y: auto; padding: 1.25rem 1.25rem 0;
      display: flex; flex-direction: column; gap: .85rem;
    }
    .chat-messages::-webkit-scrollbar { width: 4px; }
    .chat-messages::-webkit-scrollbar-thumb { background: var(--bs-border-color); border-radius: 4px; }

    /* ── EMPTY / HERO STATE ─────────────────────────────────────────── */
    .hero-center {
      flex: 1; display: flex; flex-direction: column;
      align-items: center; justify-content: center;
      text-align: center; padding: 2rem 1.5rem;
    }
    .hero-glow {
      width: 80px; height: 80px; border-radius: 50%;
      background: radial-gradient(circle, rgba(115,103,240,.22) 0%, rgba(115,103,240,.04) 70%);
      display: flex; align-items: center; justify-content: center; margin-bottom: 1.1rem;
    }
    .hero-chips {
      display: grid; grid-template-columns: 1fr 1fr; gap: .65rem;
      max-width: 480px; width: 100%; margin: 1rem auto;
    }
    .quick-chip {
      display: flex; align-items: center; gap: .6rem;
      padding: .7rem .9rem; border-radius: 12px;
      border: 1px solid var(--bs-border-color);
      background: var(--bs-body-bg); cursor: pointer;
      transition: border-color .15s, box-shadow .15s, background .15s;
      text-align: left;
    }
    .quick-chip:hover {
      border-color: #7367F0;
      box-shadow: 0 4px 18px rgba(115,103,240,.12);
      background: rgba(115,103,240,.03);
    }
    .quick-chip:active { transform: scale(.975); }
    .quick-chip .chip-icon {
      width: 32px; height: 32px; border-radius: 9px;
      display: flex; align-items: center; justify-content: center; flex-shrink: 0;
    }
    .quick-chip .chip-text { font-size: .78rem; font-weight: 500; color: var(--bs-heading-color); line-height: 1.3; }

    /* ── MESSAGE BUBBLES ─────────────────────────────────────────────── */
    .msg-row { display: flex; gap: .65rem; }
    .msg-row.msg-user { flex-direction: row-reverse; }

    .msg-avatar {
      width: 32px; height: 32px; border-radius: 10px; flex-shrink: 0; margin-top: 2px;
      display: flex; align-items: center; justify-content: center;
    }
    .msg-avatar.ai-avatar {
      background: linear-gradient(135deg, #7367F0 0%, #CE9FFC 100%);
    }
    .msg-avatar.user-avatar {
      background: var(--bs-secondary-bg);
      border: 1px solid var(--bs-border-color);
    }

    .msg-bubble {
      max-width: min(560px, 76%); display: flex; flex-direction: column; gap: .3rem;
    }
    .msg-row.msg-user .msg-bubble { align-items: flex-end; }

    .msg-content {
      padding: .7rem 1rem;
      border-radius: 14px;
      line-height: 1.6;
      font-size: .875rem;
    }
    /* AI message */
    .msg-ai .msg-content {
      background: var(--bs-secondary-bg);
      border: 1px solid var(--bs-border-color);
      border-top-left-radius: 4px;
      color: var(--bs-body-color);
    }
    /* User message */
    .msg-user .msg-content {
      background: linear-gradient(135deg, #7367F0 0%, #9180f4 100%);
      color: #fff;
      border-bottom-right-radius: 4px;
    }

    .msg-meta {
      font-size: .64rem; color: var(--bs-secondary-color);
      display: flex; align-items: center; gap: .35rem;
      padding: 0 .25rem;
    }

    /* Agent badges inside AI message footer */
    .msg-agent-badges { display: flex; gap: .25rem; flex-wrap: wrap; }
    .msg-agent-badge {
      font-size: .58rem; font-weight: 700; border-radius: 8px;
      padding: .1rem .4rem;
    }

    /* Typing indicator */
    .typing-indicator {
      display: flex; align-items: center; gap: 5px;
      padding: .75rem 1rem;
      background: var(--bs-secondary-bg);
      border: 1px solid var(--bs-border-color);
      border-radius: 14px; border-top-left-radius: 4px;
      width: fit-content;
    }
    .typing-dot {
      width: 7px; height: 7px; border-radius: 50%;
      background: #7367F0; opacity: .6;
      animation: typingBounce .9s ease-in-out infinite;
    }
    .typing-dot:nth-child(2) { animation-delay: .15s; }
    .typing-dot:nth-child(3) { animation-delay: .3s; }
    @@keyframes typingBounce {
      0%,60%,100% { transform: translateY(0); opacity: .6; }
      30% { transform: translateY(-5px); opacity: 1; }
    }

    /* ── Markdown inside AI messages ────────────────────────────────── */
    .markdown-body {
      font-size: .86rem !important; line-height: 1.7 !important;
      background: transparent !important; color: var(--bs-body-color) !important;
    }
    .markdown-body h1,.markdown-body h2,.markdown-body h3 {
      font-size: 1rem !important; font-weight: 700 !important;
      margin: .9rem 0 .4rem !important; color: var(--bs-heading-color) !important;
      border-bottom: 1px solid var(--bs-border-color) !important; padding-bottom: .25rem !important;
    }
    .markdown-body h4,.markdown-body h5 { font-size: .9rem !important; font-weight: 700 !important; margin: .7rem 0 .3rem !important; }
    .markdown-body ul,.markdown-body ol { padding-left: 1.3rem !important; margin: .4rem 0 !important; }
    .markdown-body li { margin-bottom: .2rem !important; }
    .markdown-body strong { color: var(--bs-heading-color) !important; }
    .markdown-body code {
      font-size: .8rem !important; padding: .1rem .35rem !important; border-radius: 4px !important;
      background: rgba(0,0,0,.12) !important; color: #e95d5d !important; border: none !important;
    }
    .markdown-body pre {
      background: rgba(0,0,0,.15) !important; border-radius: 8px !important;
      padding: .75rem 1rem !important; border: 1px solid var(--bs-border-color) !important;
    }
    .markdown-body pre code { color: var(--bs-body-color) !important; background: transparent !important; }
    .markdown-body blockquote {
      border-left: 3px solid #7367F0 !important; padding-left: .75rem !important;
      margin: .5rem 0 !important; color: var(--bs-secondary-color) !important;
    }
    .markdown-body table { font-size: .8rem !important; width: 100% !important; }
    .markdown-body table th { background: var(--bs-secondary-bg) !important; }
    .markdown-body table th, .markdown-body table td {
      padding: .3rem .6rem !important; border: 1px solid var(--bs-border-color) !important;
    }
    .markdown-body hr { border-color: var(--bs-border-color) !important; }
    .markdown-body p { margin-bottom: .5rem !important; }

    /* ── Action proposal forms ──────────────────────────────────────── */
    .action-proposal-form { width: 100%; }
    .agent-action-form {
      padding: .6rem .75rem; border-radius: 8px; margin-top: .5rem;
      background: var(--bs-body-bg); border: 1px solid var(--bs-border-color);
    }
    .agent-action-form .form-label-sm { font-size: .72rem; font-weight: 600; color: var(--bs-secondary-color); }
    .action-result .alert { border-radius: 8px; font-size: .78rem; }

    /* Action bar below AI message */
    .msg-actions {
      padding: .45rem .75rem;
      background: var(--bs-tertiary-bg);
      border: 1px solid var(--bs-border-color);
      border-top: none;
      border-radius: 0 0 14px 14px;
      display: flex; gap: .4rem; flex-wrap: wrap; align-items: center;
    }
    .msg-actions .action-label {
      font-size: .67rem; color: var(--bs-secondary-color); font-weight: 600; margin-right: .2rem;
      display: flex; align-items: center; gap: .2rem;
    }

    /* ── COMMAND BAR (bottom) ───────────────────────────────────────── */
    .chat-bottom {
      padding: .85rem 1.25rem 1rem;
      background: var(--bs-body-bg);
      border-top: 1px solid var(--bs-border-color);
      flex-shrink: 0;
    }

    /* Quick trigger pills */
    .trigger-pills { display: flex; gap: .4rem; flex-wrap: wrap; margin-bottom: .65rem; }
    .trigger-pill {
      cursor: pointer; border-radius: 18px; padding: .28rem .75rem;
      font-size: .72rem; font-weight: 500;
      border: 1px solid var(--bs-border-color);
      color: var(--bs-secondary-color); background: var(--bs-body-bg);
      transition: all .15s; user-select: none; white-space: nowrap;
      display: inline-flex; align-items: center; gap: .25rem;
    }
    .trigger-pill:hover { border-color: #7367F0; color: #7367F0; background: rgba(115,103,240,.06); }
    .trigger-pill i { font-size: 12px; }

    /* ── Input composer (Vuexy-aligned) ─────────────────────────────── */
    .composer-wrap {
      background: var(--bs-secondary-bg);
      border: 1.5px solid var(--bs-border-color);
      border-radius: 16px; overflow: hidden;
      transition: border-color .18s, box-shadow .18s;
    }
    .composer-wrap:focus-within {
      border-color: #7367F0;
      box-shadow: 0 0 0 3px rgba(115,103,240,.12);
    }
    .composer-textarea {
      display: block; width: 100%;
      border: none !important; outline: none !important; box-shadow: none !important;
      background: transparent !important; resize: none; overflow-y: auto;
      font-size: .92rem; line-height: 1.6; color: var(--bs-body-color);
      padding: .9rem 1.15rem .55rem;
      min-height: 46px; max-height: 130px;
    }
    .composer-textarea::placeholder { color: var(--bs-secondary-color); opacity: 1; }
    .composer-footer {
      display: flex; align-items: center; justify-content: space-between;
      padding: .32rem .55rem .4rem .75rem;
      border-top: 1px solid var(--bs-border-color);
    }
    .composer-icon-btn {
      width: 30px; height: 30px; border-radius: 8px;
      border: none; background: transparent; padding: 0;
      color: var(--bs-secondary-color);
      display: inline-flex; align-items: center; justify-content: center;
      cursor: pointer; transition: background .15s, color .15s; font-size: 15px;
    }
    .composer-icon-btn:hover:not(:disabled) { background: rgba(115,103,240,.10); color: #7367F0; }
    .composer-icon-btn:disabled { opacity: .30; cursor: not-allowed; }
    .char-badge { font-size: .65rem; color: var(--bs-secondary-color); margin-left: .2rem; transition: color .15s; }
    .char-badge.near-limit { color: #ff9f43; }
    .cmd-send {
      background: linear-gradient(135deg, #7367F0 0%, #9180f4 100%);
      color: #fff; border: none; border-radius: 10px;
      padding: .45rem 1rem .45rem .85rem;
      font-size: .82rem; font-weight: 600; white-space: nowrap;
      cursor: pointer;
      display: inline-flex; align-items: center; gap: .35rem;
      transition: opacity .14s, transform .1s;
    }
    .cmd-send:hover:not(:disabled) { opacity: .88; transform: scale(1.02); }
    .cmd-send:disabled { background: var(--bs-tertiary-bg); color: var(--bs-secondary-color); cursor: not-allowed; transform: none; }

    .chat-bottom-hint {
      font-size: .65rem; color: var(--bs-secondary-color);
      text-align: center; margin-top: .45rem;
    }

    /* ── RIGHT SIDEBAR ──────────────────────────────────────────────── */
    .chat-right {
      width: 240px; flex-shrink: 0;
      border-left: 1px solid var(--bs-border-color);
      background: var(--bs-body-bg);
      display: flex; flex-direction: column; overflow: hidden;
    }
    .chat-right-header {
      padding: .75rem 1rem;
      border-bottom: 1px solid var(--bs-border-color);
      font-size: .75rem; font-weight: 700; color: var(--bs-heading-color);
      display: flex; align-items: center; gap: .4rem; flex-shrink: 0;
    }
    .chat-right-body { flex: 1; overflow-y: auto; }
    .chat-right-body::-webkit-scrollbar { width: 3px; }
    .chat-right-body::-webkit-scrollbar-thumb { background: var(--bs-border-color); border-radius: 3px; }

    /* Recent runs in right sidebar */
    .run-item {
      padding: .5rem .9rem; border-bottom: 1px solid var(--bs-border-color);
      display: flex; align-items: flex-start; gap: .55rem;
    }
    .run-item:last-child { border-bottom: none; }
    .run-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; margin-top: 4px; }
    .run-name { font-size: .72rem; font-weight: 500; line-height: 1.2; }
    .run-meta { font-size: .63rem; color: var(--bs-secondary-color); margin-top: 1px; }

    /* Insight cards in right sidebar */
    .insight-li { padding: .6rem .9rem; border-bottom: 1px solid var(--bs-border-color); }
    .insight-li:last-child { border-bottom: none; }
    .insight-title { font-size: .74rem; font-weight: 600; color: var(--bs-heading-color); }
    .insight-body  { font-size: .68rem; color: var(--bs-secondary-color); margin-top: 2px; }

    /* ── Responsive ─────────────────────────────────────────────────── */
    @media (max-width: 991px) {
      .chat-left { position: absolute; z-index: 200; height: 100%; top: 0; left: 0; box-shadow: 4px 0 20px rgba(0,0,0,.15); }
      .chat-left.collapsed { width: 0; box-shadow: none; }
      .chat-right { display: none; }
    }
    @media (max-width: 575px) {
      .hero-chips { grid-template-columns: 1fr; }
      .chat-root { margin: -1rem -1rem 0; }
      .chat-messages { padding: .85rem .85rem 0; }
      .chat-bottom { padding: .65rem .85rem .85rem; }
    }
  </style>
  </x-slot>

  {{-- ══════════════════════════════════════════════════════════════════════
       HIDDEN DATA
  ══════════════════════════════════════════════════════════════════════ --}}
  <input type="hidden" id="session-id" value="{{ $sessionId }}">

  {{-- ══════════════════════════════════════════════════════════════════════
       CHAT ROOT
  ══════════════════════════════════════════════════════════════════════ --}}
  <div class="chat-root">

    {{-- ── LEFT SIDEBAR ──────────────────────────────────────────────────── --}}
    <div class="chat-left" id="chat-left">
      <div class="chat-left-header">
        <div class="brand-icon">
          <i class="ti tabler-sparkles" style="color:#fff;font-size:15px;"></i>
        </div>
        <div>
          <div class="brand-title">Finansal Zeka</div>
          <div class="brand-sub">9 uzman ajan</div>
        </div>
      </div>

      <div class="chat-left-body">
        <button class="btn-new-chat" id="btn-clear-session" type="button">
          <i class="ti tabler-plus" style="font-size:14px;"></i>Yeni Analiz
        </button>

        <div class="sidebar-section-title">Uzman Ajanlar</div>

        <div id="agent-status-list">
          @foreach([
            'purchase_planner'       => ['Satın Alma Planlayıcı',  'tabler-shopping-cart', 'primary'],
            'budget_advisor'         => ['Bütçe Danışmanı',         'tabler-chart-pie',     'success'],
            'inflation_aware'        => ['Enflasyon Analisti',      'tabler-flame',         'warning'],
            'anomaly_detector'       => ['Anomali Dedektörü',       'tabler-radar',         'danger'],
            'transaction_classifier' => ['İşlem Sınıflandırıcı',   'tabler-tag',           'info'],
            'forecaster'             => ['Tahmin & Projeksiyon',    'tabler-chart-line',    'info'],
            'debt_optimizer'         => ['Borç Optimizasyonu',      'tabler-credit-card',   'danger'],
            'subscription_hunter'    => ['Abonelik Avcısı',         'tabler-repeat',        'secondary'],
            'receipt_ocr'            => ['Fiş & OCR Analizi',       'tabler-receipt',       'primary'],
          ] as $key => [$label, $icon, $color])
          <div class="agent-li" id="agent-{{ $key }}">
            <div class="agent-avatar bg-label-{{ $color }}">
              <i class="ti {{ $icon }} text-{{ $color }}" style="font-size:12px;"></i>
            </div>
            <div class="agent-name">{{ $label }}</div>
            <span class="agent-status-badge bg-label-secondary agent-state">Beklemede</span>
          </div>
          @endforeach
        </div>
      </div>
    </div>

    {{-- ── CENTER ────────────────────────────────────────────────────────── --}}
    <div class="chat-center">

      {{-- Top bar --}}
      <div class="chat-topbar">
        <button class="topbar-toggle" id="btn-toggle-sidebar" title="Kenar çubuğu">
          <i class="ti tabler-layout-sidebar" style="font-size:16px;"></i>
        </button>
        <div class="topbar-title">
          <i class="ti tabler-brain text-primary" style="font-size:17px;"></i>
          Finansal Zeka Merkezi
          <span class="live-badge">
            <span class="live-dot"></span>Canlı
          </span>
        </div>
        <span class="badge bg-label-success agent-global-status" style="font-size:.62rem;">Hazır</span>
      </div>

      {{-- Messages area --}}
      <div class="chat-messages" id="chat-messages">

        {{-- Empty / hero state --}}
        <div id="empty-state" class="{{ $history->where('role','assistant')->isNotEmpty() ? 'd-none' : 'hero-center' }}">
          <div class="hero-glow">
            <i class="ti tabler-sparkles text-primary" style="font-size:34px;"></i>
          </div>
          <h5 class="fw-bold mb-1">Ne yapmamı istersin?</h5>
          <p class="text-muted small mb-0" style="max-width:360px;">
            Bir konuya tıkla veya aşağıya yaz — yapay zeka ajanları hemen analiz etsin.
          </p>
          <div class="hero-chips">
            <div class="quick-chip" data-msg="Bu ay nereye harcadım? Kategorilere göre ayrıntılı analiz yap.">
              <span class="chip-icon bg-label-primary"><i class="ti tabler-chart-pie text-primary" style="font-size:15px;"></i></span>
              <span class="chip-text">Bu ay nereye harcadım?</span>
            </div>
            <div class="quick-chip" data-msg="Hedefe ne kadar ayırabilirim? Mevcut gelir ve giderlerime göre tasarruf kapasitemi hesapla.">
              <span class="chip-icon bg-label-success"><i class="ti tabler-target text-success" style="font-size:15px;"></i></span>
              <span class="chip-text">Hedefe ne kadar ayırabilirim?</span>
            </div>
            <div class="quick-chip" data-msg="Son harcamalarımda anormal bir durum var mı? Anomalileri göster ve ayrıntılı analiz yap.">
              <span class="chip-icon bg-label-danger"><i class="ti tabler-radar text-danger" style="font-size:15px;"></i></span>
              <span class="chip-text">Anomalileri göster</span>
            </div>
            <div class="quick-chip" data-msg="Bu ayki harcama alışkanlıklarıma göre bana aylık bütçe öner. Kategori bazlı limitler belirle.">
              <span class="chip-icon bg-label-warning"><i class="ti tabler-sparkles text-warning" style="font-size:15px;"></i></span>
              <span class="chip-text">Bütçe öner</span>
            </div>
          </div>
          <div class="d-flex gap-4 justify-content-center flex-wrap mt-1">
            <div class="d-flex align-items-center gap-1 text-muted" style="font-size:.7rem;">
              <i class="ti tabler-shield-check text-success" style="font-size:12px;"></i>Verileriniz güvende
            </div>
            <div class="d-flex align-items-center gap-1 text-muted" style="font-size:.7rem;">
              <i class="ti tabler-cpu text-primary" style="font-size:12px;"></i>9 uzman ajan
            </div>
            <div class="d-flex align-items-center gap-1 text-muted" style="font-size:.7rem;">
              <i class="ti tabler-bolt text-info" style="font-size:12px;"></i>Asenkron
            </div>
          </div>
        </div>

        {{-- ── Historical messages ──────────────────────────────────────── --}}
        @php $prevQuery = null; @endphp
        @foreach($history as $msg)
          @if($msg->role === 'user')
            @php $prevQuery = $msg->content; @endphp
            {{-- User message bubble --}}
            <div class="msg-row msg-user">
              <div class="msg-avatar user-avatar">
                <i class="ti tabler-user" style="font-size:14px;color:var(--bs-secondary-color);"></i>
              </div>
              <div class="msg-bubble">
                <div class="msg-content">{{ $msg->content }}</div>
                <div class="msg-meta">
                  {{ \Carbon\Carbon::parse($msg->created_at)->format('d.m H:i') }}
                </div>
              </div>
            </div>
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
              {{-- Skeleton/typing row --}}
              <div class="msg-row msg-ai skeleton-card" id="skeleton-{{ $msg->id }}" data-message-id="{{ $msg->id }}">
                <div class="msg-avatar ai-avatar">
                  <i class="ti tabler-sparkles" style="font-size:14px;color:#fff;"></i>
                </div>
                <div class="msg-bubble" style="max-width:min(480px,76%);">
                  <div class="typing-indicator">
                    <div class="typing-dot"></div>
                    <div class="typing-dot"></div>
                    <div class="typing-dot"></div>
                    <span style="font-size:.75rem;color:var(--bs-secondary-color);margin-left:.4rem;">
                      {{ $prevQuery ? \Illuminate\Support\Str::limit($prevQuery, 40).'…' : 'Analiz yapılıyor…' }}
                    </span>
                  </div>
                </div>
              </div>
            @else
              {{-- AI message bubble --}}
              <div class="msg-row msg-ai">
                <div class="msg-avatar ai-avatar">
                  <i class="ti tabler-sparkles" style="font-size:14px;color:#fff;"></i>
                </div>
                <div class="msg-bubble" style="max-width:min(640px,84%);">
                  <div class="msg-content">
                    <div class="markdown-body" data-raw="{{ e($msg->content) }}"></div>
                  </div>
                  <div class="msg-meta">
                    <span>{{ \Carbon\Carbon::parse($msg->created_at)->format('d.m H:i') }}</span>
                    @if(count($agentsUsed))
                    <div class="msg-agent-badges">
                      @foreach($agentsUsed as $a)
                        @php $c=$agentColorMap[$a]??'secondary'; $lbl=$agentLabelMap[$a]??$a; @endphp
                        <span class="msg-agent-badge bg-label-{{ $c }} text-{{ $c }}">{{ $lbl }}</span>
                      @endforeach
                    </div>
                    @endif
                  </div>
                </div>
              </div>
            @endif
            @php $prevQuery = null; @endphp
          @endif
        @endforeach

      </div>{{-- /chat-messages --}}

      {{-- Bottom command bar --}}
      <div class="chat-bottom">
        <div class="trigger-pills" id="trigger-pills-area">
          <span class="trigger-pill" data-msg="Son harcamalarımda anormal bir durum var mı? Ayrıntılı analiz yap.">
            <i class="ti tabler-radar"></i>Anomali Tara
          </span>
          <span class="trigger-pill" data-msg="Bu ayki bütçe durumumu analiz et ve nerede tasarruf yapabileceğimi göster.">
            <i class="ti tabler-chart-pie"></i>Bütçe Analizi
          </span>
          <span class="trigger-pill" data-msg="Önümüzdeki 6 ay için nakit akışımı ve birikimimi tahmin et.">
            <i class="ti tabler-chart-line"></i>6 Aylık Tahmin
          </span>
          <span class="trigger-pill" data-msg="Kredi kartı borçlarımı en hızlı şekilde kapatmak için strateji öner ve bana yardım et.">
            <i class="ti tabler-credit-card"></i>Borç Stratejisi
          </span>
          <span class="trigger-pill" data-msg="Gereksiz veya pahalı aboneliklerim var mı? Tespit et ve optimize et.">
            <i class="ti tabler-repeat"></i>Abonelik Tara
          </span>
          <span class="trigger-pill" data-msg="Enflasyon birikimimi ve satın alma gücümü nasıl etkiliyor? Ne yapmalıyım?">
            <i class="ti tabler-flame"></i>Enflasyon Etkisi
          </span>
        </div>

        <div class="composer-wrap">
          <textarea id="cmd-input" class="composer-textarea" rows="1"
            placeholder="Bir şeyler sor… (örn: hedef koy, bütçe analizi yap)"
            autocomplete="off"></textarea>
          <div class="composer-footer">
            <div class="d-flex align-items-center gap-1">
              <button class="composer-icon-btn" type="button" title="Dosya ekle" disabled>
                <i class="ti tabler-paperclip"></i>
              </button>
              <button class="composer-icon-btn" type="button" title="Emoji" disabled>
                <i class="ti tabler-mood-smile"></i>
              </button>
              <span id="char-badge" class="char-badge"></span>
            </div>
            <button class="cmd-send" id="cmd-send" type="button">
              <i class="ti tabler-arrow-up" style="font-size:14px;"></i>Gönder
            </button>
          </div>
        </div>
        <div class="chat-bottom-hint">
          Enter ile gönder &nbsp;·&nbsp; Shift+Enter yeni satır
        </div>
      </div>

    </div>{{-- /chat-center --}}

    {{-- ── RIGHT SIDEBAR ─────────────────────────────────────────────────── --}}
    <div class="chat-right">

      {{-- Recent Runs --}}
      <div class="chat-right-header">
        <i class="ti tabler-history" style="font-size:14px;color:var(--bs-secondary-color);"></i>Son Çalışmalar
      </div>
      <div class="chat-right-body">
        <div id="runs-list">
          @forelse($recentRuns as $run)
          <div class="run-item">
            <div class="run-dot {{ $run->status === 'completed' ? 'bg-success' : ($run->status === 'failed' ? 'bg-danger' : 'bg-warning') }}"></div>
            <div class="flex-grow-1">
              <div class="run-name text-truncate" style="max-width:140px;">{{ $run->agent_name }}</div>
              <div class="run-meta">
                {{ $run->model_used ?? '—' }}
                @if($run->duration_ms) · {{ $run->duration_ms }}ms @endif
                · {{ ($run->tokens_in ?? 0) + ($run->tokens_out ?? 0) }} tok
              </div>
            </div>
            <span class="badge {{ $run->status === 'completed' ? 'bg-label-success' : ($run->status === 'failed' ? 'bg-label-danger' : 'bg-label-warning') }}" style="font-size:.58rem;">{{ $run->status }}</span>
          </div>
          @empty
          <div class="text-muted small text-center py-4">Henüz çalışma yok</div>
          @endforelse
        </div>

        {{-- Active Insights --}}
        @if($insights->isNotEmpty())
        <div class="chat-right-header border-top" style="margin-top:.5rem;">
          <i class="ti tabler-bulb" style="font-size:14px;color:#ff9f43;"></i>Öngörüler
          <span class="badge bg-label-warning ms-auto" style="font-size:.6rem;">{{ $insights->count() }}</span>
        </div>
        @foreach($insights as $insight)
        @php $ic = ['warning'=>'warning','opportunity'=>'success','tip'=>'info','anomaly'=>'danger'][$insight->type] ?? 'secondary'; @endphp
        <div class="insight-li" id="insight-{{ $insight->id }}">
          <div class="d-flex align-items-start gap-2">
            <span class="avatar avatar-xs bg-label-{{ $ic }} flex-shrink-0 mt-1">
              <i class="ti tabler-bulb text-{{ $ic }}" style="font-size:10px;"></i>
            </span>
            <div class="flex-grow-1">
              <div class="insight-title">{{ $insight->title }}</div>
              <div class="insight-body">{{ \Illuminate\Support\Str::limit($insight->body, 80) }}</div>
            </div>
            <button type="button"
                    class="btn btn-icon btn-text-secondary btn-sm flex-shrink-0 btn-dismiss-insight"
                    data-id="{{ $insight->id }}"
                    data-url="{{ route('agent-chat.insight-dismiss', $insight->id) }}"
                    style="width:18px;height:18px;margin-top:-2px;">
              <i class="ti tabler-x icon-10px"></i>
            </button>
          </div>
        </div>
        @endforeach
        @endif

      </div>
    </div>{{-- /chat-right --}}

  </div>{{-- /chat-root --}}

  <x-slot name="pageJs">
  <script>
  (function () {
    'use strict';

    // ── Inline markdown parser ──────────────────────────────────────────
    function hesc(s) {
      return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
    }

    function parseMarkdown(raw) {
      if (!raw) return '';
      const blocks = [];
      let t = raw.replace(/```([\w]*)\n?([\s\S]*?)```/g, (_, lang, code) => {
        blocks.push('<pre><code>' + hesc(code.trim()) + '</code></pre>');
        return '\x02B' + (blocks.length - 1) + '\x03';
      });
      t = t.split(/(\x02B\d+\x03)/).map(p =>
        /^\x02B\d+\x03$/.test(p) ? p : hesc(p)
      ).join('');
      t = t.replace(/^###\s+(.+)$/gm, '<h3>$1</h3>');
      t = t.replace(/^##\s+(.+)$/gm,  '<h2>$1</h2>');
      t = t.replace(/^#\s+(.+)$/gm,   '<h1>$1</h1>');
      t = t.replace(/^[-*]{3,}$/gm, '<hr>');
      t = t.replace(/\*\*\*([^*\n]+)\*\*\*/g, '<strong><em>$1</em></strong>');
      t = t.replace(/\*\*([^*\n]+)\*\*/g,     '<strong>$1</strong>');
      t = t.replace(/__([^_\n]+)__/g,          '<strong>$1</strong>');
      t = t.replace(/\*([^*\n]+)\*/g,          '<em>$1</em>');
      t = t.replace(/_([^_\n]+)_/g,            '<em>$1</em>');
      t = t.replace(/`([^`\n]+)`/g, '<code>$1</code>');
      t = t.replace(/^&gt;\s*(.+)$/gm, '<blockquote>$1</blockquote>');
      const lines = t.split('\n'), out = [];
      let inUl = false, inOl = false;
      for (const ln of lines) {
        const ul = ln.match(/^[-*+]\s+(.+)/);
        const ol = ln.match(/^\d+\.\s+(.+)/);
        if (ul) {
          if (inOl) { out.push('</ol>'); inOl = false; }
          if (!inUl) { out.push('<ul>'); inUl = true; }
          out.push('<li>' + ul[1] + '</li>');
        } else if (ol) {
          if (inUl) { out.push('</ul>'); inUl = false; }
          if (!inOl) { out.push('<ol>'); inOl = true; }
          out.push('<li>' + ol[1] + '</li>');
        } else {
          if (inUl) { out.push('</ul>'); inUl = false; }
          if (inOl) { out.push('</ol>'); inOl = false; }
          out.push(ln);
        }
      }
      if (inUl) out.push('</ul>');
      if (inOl) out.push('</ol>');
      t = out.join('\n');
      t = t.split(/\n{2,}/).map(para => {
        const p = para.trim();
        if (!p) return '';
        if (/^<(h[1-6]|ul|ol|blockquote|hr|pre|\x02)/.test(p)) return p;
        return '<p>' + p.replace(/\n/g, '<br>') + '</p>';
      }).filter(Boolean).join('\n');
      t = t.replace(/\x02B(\d+)\x03/g, (_, i) => blocks[+i]);
      return t;
    }

    document.querySelectorAll('.markdown-body[data-raw]').forEach(el => {
      const raw = el.getAttribute('data-raw');
      if (raw) el.innerHTML = parseMarkdown(raw);
    });

    // ── Constants ────────────────────────────────────────────────────────
    const sessionId  = document.getElementById('session-id').value;
    const csrf       = document.querySelector('meta[name=csrf-token]').content;
    const messages   = document.getElementById('chat-messages');
    const emptyState = document.getElementById('empty-state');

    const POLL_URL   = '/chat/poll/';
    const RUNS_URL   = '{{ route("agent-chat.runs") }}';
    const ACTION_URL = '{{ route("agent-chat.action") }}';

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

    // ── Sidebar toggle ────────────────────────────────────────────────────
    const chatLeft = document.getElementById('chat-left');
    document.getElementById('btn-toggle-sidebar')?.addEventListener('click', () => {
      chatLeft?.classList.toggle('collapsed');
    });

    // ── Auto-resize textarea + char count ────────────────────────────────
    const cmdInput    = document.getElementById('cmd-input');
    const charBadgeEl = document.getElementById('char-badge');
    if (cmdInput) {
      cmdInput.addEventListener('input', function () {
        this.style.height = 'auto';
        this.style.height = Math.min(this.scrollHeight, 130) + 'px';
        const len = this.value.length;
        if (charBadgeEl) {
          charBadgeEl.textContent = len > 0 ? len + ' k' : '';
          charBadgeEl.classList.toggle('near-limit', len > 400);
        }
      });
    }

    // ── Scroll to bottom of chat ──────────────────────────────────────────
    function scrollBottom() {
      if (messages) messages.scrollTop = messages.scrollHeight;
    }
    scrollBottom();

    // ── Show results mode (hide hero) ─────────────────────────────────────
    function showResultsMode() {
      if (emptyState) {
        emptyState.classList.remove('hero-center');
        emptyState.classList.add('d-none');
      }
    }
    if (!emptyState || emptyState.classList.contains('d-none')) showResultsMode();

    // ── Action detection ──────────────────────────────────────────────────
    function detectActions(text) {
      const actions = [];
      function extractAmount() {
        const m = text.match(/([\d]{1,3}(?:[.]\d{3})*(?:[,]\d{1,2})?|\d+)\s*TL/);
        if (!m) return null;
        const n = parseFloat(m[1].replace(/\./g, '').replace(',', '.'));
        return isNaN(n) ? null : n;
      }
      if (/hedef\s*(oluştur|koy|ekle|belirle|oluşturay|kuray)/i.test(text)
          || /tasarruf\s*hedef/i.test(text) || /birikim\s*hedef/i.test(text)) {
        actions.push({ type:'create_goal', label:'Hedef Oluştur',
          icon:'tabler-target', color:'success', suggestedAmount: extractAmount() });
      }
      if (/bütçe\s*(oluştur|belirle|kur|ayarla|limit|koyalım)/i.test(text)) {
        actions.push({ type:'create_budget', label:'Bütçe Kur',
          icon:'tabler-chart-pie', color:'primary', suggestedAmount: extractAmount() });
      }
      if (/abonelik\s*(iptal|kaldır|sil)/i.test(text))
        actions.push({ type:'link', label:'Abonelikleri Gör', icon:'tabler-repeat', color:'warning', href:'/subscriptions' });
      if (/borç\s*(öde|kapat|azalt)/i.test(text) || /kart\s*borcun/i.test(text))
        actions.push({ type:'link', label:'Kartları Gör', icon:'tabler-credit-card', color:'danger', href:'/cards' });
      if (/simülasyon|simülatör/i.test(text))
        actions.push({ type:'link', label:'Simülatörü Aç', icon:'tabler-calculator', color:'info', href:'/simulator' });
      if (/yatırım|portföy/i.test(text))
        actions.push({ type:'link', label:'Yatırımlar', icon:'tabler-trending-up', color:'success', href:'/investments' });
      return actions;
    }

    // ── Action form HTML builders ─────────────────────────────────────────
    let _cardIdx = 0;

    function buildActionForm(action) {
      if (action.type === 'create_goal') {
        return '<div class="agent-action-form" data-action="create_goal">'
          + '<div class="d-flex gap-2 flex-wrap align-items-end">'
          + '<div><label class="form-label-sm mb-1 d-block">Hedef adı</label>'
          + '<input type="text" class="form-control form-control-sm action-field" name="name" placeholder="Örn: Tatil Fonu" style="min-width:130px;max-width:180px;"></div>'
          + '<div><label class="form-label-sm mb-1 d-block">Tutar (TL)</label>'
          + '<input type="number" class="form-control form-control-sm action-field" name="target_amount" value="' + (action.suggestedAmount || '') + '" placeholder="15000" min="1" style="min-width:90px;max-width:130px;"></div>'
          + '<div><label class="form-label-sm mb-1 d-block">Aylık katkı</label>'
          + '<input type="number" class="form-control form-control-sm action-field" name="monthly_contribution" placeholder="1000" min="0" style="min-width:90px;max-width:130px;"></div>'
          + '<button type="button" class="btn btn-sm btn-success execute-action-btn" style="font-size:.75rem;"><i class="ti tabler-check me-1"></i>Oluştur</button>'
          + '<button type="button" class="btn btn-sm btn-text-secondary cancel-action-btn" style="font-size:.75rem;">İptal</button>'
          + '</div><div class="action-result mt-2" style="display:none;"></div></div>';
      }
      if (action.type === 'create_budget') {
        const cats = ['Market','Restoran & Kafe','Online Yemek','Ulaşım','Yakıt','Faturalar',
          'Sağlık','Eğitim','Eğlence','Giyim & Aksesuar','Ev & Yaşam','Elektronik',
          'Dijital Abonelik','Spor','Diğer'];
        const opts = cats.map(c => '<option value="' + c + '">' + c + '</option>').join('');
        return '<div class="agent-action-form" data-action="create_budget">'
          + '<div class="d-flex gap-2 flex-wrap align-items-end">'
          + '<div><label class="form-label-sm mb-1 d-block">Kategori</label>'
          + '<select class="form-select form-select-sm action-field" name="category_name" style="min-width:150px;">' + opts + '</select></div>'
          + '<div><label class="form-label-sm mb-1 d-block">Aylık limit (TL)</label>'
          + '<input type="number" class="form-control form-control-sm action-field" name="amount" value="' + (action.suggestedAmount || '') + '" placeholder="2000" min="1" style="min-width:90px;max-width:130px;"></div>'
          + '<button type="button" class="btn btn-sm btn-primary execute-action-btn" style="font-size:.75rem;"><i class="ti tabler-check me-1"></i>Bütçe Kur</button>'
          + '<button type="button" class="btn btn-sm btn-text-secondary cancel-action-btn" style="font-size:.75rem;">İptal</button>'
          + '</div><div class="action-result mt-2" style="display:none;"></div></div>';
      }
      return '';
    }

    function buildActionsHtml(actions) {
      if (!actions.length) return '';
      const id = 'ac-' + (++_cardIdx);
      const btns = actions.map((a, i) => {
        if (a.type === 'link') {
          return '<a href="' + a.href + '" class="btn btn-sm btn-outline-' + a.color + '" style="font-size:.72rem;padding:.2rem .6rem;">'
            + '<i class="ti ' + a.icon + ' me-1"></i>' + a.label + '</a>';
        }
        const fId = id + '-f' + i;
        return '<button type="button" class="btn btn-sm btn-outline-' + a.color + ' action-toggle-btn" style="font-size:.72rem;padding:.2rem .6rem;" data-form="' + fId + '">'
          + '<i class="ti ' + a.icon + ' me-1"></i>' + a.label + '</button>'
          + '<div id="' + fId + '" class="action-proposal-form" style="display:none;">' + buildActionForm(a) + '</div>';
      }).join('');
      return '<div class="msg-actions">'
        + '<span class="action-label"><i class="ti tabler-sparkles icon-12px"></i>Ajan önerisi:</span>'
        + '<div class="d-flex flex-wrap gap-2 align-items-start flex-grow-1">' + btns + '</div>'
        + '</div>';
    }

    // ── Build AI message row ──────────────────────────────────────────────
    function buildAiRow(query, content, agentsUsed, timestamp) {
      const now = timestamp || new Date().toLocaleString('tr-TR', { day:'2-digit', month:'2-digit', hour:'2-digit', minute:'2-digit' });
      const badges = (agentsUsed || []).map(a => {
        const c   = agentColorMap[a] || 'secondary';
        const lbl = agentLabelMap[a] || a;
        return '<span class="msg-agent-badge bg-label-' + c + ' text-' + c + '">' + lbl + '</span>';
      }).join('');
      const el = document.createElement('div');
      el.className = 'msg-row msg-ai';
      const actionsHtml = buildActionsHtml(detectActions(content));
      // Wrap content + actions together for border-radius
      const hasActions = actionsHtml !== '';
      el.innerHTML = '<div class="msg-avatar ai-avatar">'
        + '<i class="ti tabler-sparkles" style="font-size:14px;color:#fff;"></i>'
        + '</div>'
        + '<div class="msg-bubble" style="max-width:min(640px,84%);">'
        + '<div class="msg-content" style="' + (hasActions ? 'border-radius:14px 14px 0 0;' : '') + '">'
        + '<div class="markdown-body"></div>'
        + '</div>'
        + actionsHtml
        + '<div class="msg-meta">'
        + '<span>' + now + '</span>'
        + (badges ? '<div class="msg-agent-badges">' + badges + '</div>' : '')
        + '</div>'
        + '</div>';
      el.querySelector('.markdown-body').innerHTML = parseMarkdown(content);
      return el;
    }

    // Build user message row
    function buildUserRow(query) {
      const el = document.createElement('div');
      el.className = 'msg-row msg-user';
      el.innerHTML = '<div class="msg-avatar user-avatar">'
        + '<i class="ti tabler-user" style="font-size:14px;color:var(--bs-secondary-color);"></i>'
        + '</div>'
        + '<div class="msg-bubble">'
        + '<div class="msg-content">' + escHtml(query) + '</div>'
        + '<div class="msg-meta">' + new Date().toLocaleString('tr-TR', { day:'2-digit', month:'2-digit', hour:'2-digit', minute:'2-digit' }) + '</div>'
        + '</div>';
      return el;
    }

    // Build typing/skeleton row
    function buildSkeleton(query, messageId) {
      const el = document.createElement('div');
      el.className = 'msg-row msg-ai skeleton-card';
      el.id = messageId ? 'skeleton-' + messageId : 'skeleton-loading';
      if (messageId) el.setAttribute('data-message-id', messageId);
      const label = query && query.length > 40 ? query.slice(0, 40) + '…' : (query || 'Analiz yapılıyor…');
      el.innerHTML = '<div class="msg-avatar ai-avatar">'
        + '<i class="ti tabler-sparkles" style="font-size:14px;color:#fff;"></i>'
        + '</div>'
        + '<div class="msg-bubble" style="max-width:min(480px,76%);">'
        + '<div class="typing-indicator">'
        + '<div class="typing-dot"></div>'
        + '<div class="typing-dot"></div>'
        + '<div class="typing-dot"></div>'
        + '<span style="font-size:.75rem;color:var(--bs-secondary-color);margin-left:.4rem;">' + escHtml(label) + '</span>'
        + '</div>'
        + '</div>';
      return el;
    }

    function escHtml(str) {
      const d = document.createElement('div');
      d.appendChild(document.createTextNode(str));
      return d.innerHTML;
    }

    // ── Post-load: inject action proposals into server-rendered messages ──
    document.querySelectorAll('.msg-ai .markdown-body[data-raw]').forEach(mdEl => {
      const raw = mdEl.getAttribute('data-raw');
      if (!raw) return;
      const actions = detectActions(raw);
      if (!actions.length) return;
      const bubble = mdEl.closest('.msg-bubble');
      if (!bubble || bubble.querySelector('.msg-actions')) return;
      const msgContent = bubble.querySelector('.msg-content');
      if (msgContent) {
        msgContent.style.borderRadius = '14px 14px 0 0';
        msgContent.insertAdjacentHTML('afterend', buildActionsHtml(actions));
      }
    });

    // ── Poll running skeletons on page load ───────────────────────────────
    document.querySelectorAll('.skeleton-card[data-message-id]').forEach(sk => {
      const mid = sk.getAttribute('data-message-id');
      if (mid) startPolling(mid, sk, null);
    });

    // ── Poll a specific message ───────────────────────────────────────────
    function startPolling(messageId, skeletonEl, query) {
      const timer = setInterval(async () => {
        try {
          const r = await fetch(POLL_URL + messageId, {
            headers: { Accept: 'application/json', 'X-CSRF-TOKEN': csrf }
          });
          const d = await r.json();
          if (d.status === 'completed' || d.status === 'error') {
            clearInterval(timer);
            const row = buildAiRow(query, d.reply || '(Yanıt alınamadı)', d.agents_used || []);
            if (skeletonEl.parentNode) skeletonEl.replaceWith(row);
            if (d.agents_used && d.agents_used.length) d.agents_used.forEach(a => setAgentState(a, 'done'));
            resetAgentsAfter(3000);
            scrollBottom();
          }
        } catch (_) {}
      }, 2500);
    }

    // ── Agent badge helpers ───────────────────────────────────────────────
    function setAgentState(agentKey, state) {
      const el = document.getElementById('agent-' + agentKey);
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
    function resetAgentsAfter(ms) { setTimeout(resetAllAgents, ms); }
    function setGlobalRunning() {
      const gs = document.querySelector('.agent-global-status');
      if (gs) { gs.className = 'badge bg-label-warning agent-global-status'; gs.textContent = 'Çalışıyor'; }
    }

    // ── Runs polling sidebar ──────────────────────────────────────────────
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
        const dur  = r.duration_ms ? '· ' + r.duration_ms + 'ms' : '';
        return '<div class="run-item">'
          + '<div class="run-dot ' + dotColor + '"></div>'
          + '<div class="flex-grow-1">'
          + '<div class="run-name text-truncate" style="max-width:140px;">' + escHtml(r.agent_name) + '</div>'
          + '<div class="run-meta">' + escHtml(r.model_used || '—') + ' ' + dur + ' · ' + toks + ' tok</div>'
          + '</div>'
          + '<span class="badge ' + badgeColor + '" style="font-size:.58rem;">' + r.status + '</span>'
          + '</div>';
      }).join('');
    }

    // ── Execute agent action ──────────────────────────────────────────────
    async function executeAgentAction(action, data, formEl) {
      const resultEl = formEl.querySelector('.action-result');
      const btn      = formEl.querySelector('.execute-action-btn');
      if (btn) { btn.disabled = true; btn.innerHTML = '<span class="spinner-border spinner-border-sm" style="width:.8rem;height:.8rem;"></span>'; }
      try {
        const resp = await fetch(ACTION_URL, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrf, Accept: 'application/json' },
          body: JSON.stringify({ action, data }),
        });
        const d = await resp.json();
        if (resp.ok && d.status === 'ok') {
          if (resultEl) {
            resultEl.style.display = 'block';
            resultEl.innerHTML = '<div class="alert alert-success py-2 px-3 mb-0">'
              + '<i class="ti tabler-circle-check me-1"></i>' + escHtml(d.message || 'Başarıyla oluşturuldu!')
              + (d.redirect ? '&nbsp;<a href="' + d.redirect + '" class="alert-link fw-semibold">Görüntüle →</a>' : '')
              + '</div>';
          }
          if (btn) btn.style.display = 'none';
        } else {
          if (resultEl) {
            resultEl.style.display = 'block';
            resultEl.innerHTML = '<div class="alert alert-danger py-2 px-3 mb-0">' + escHtml(d.message || 'Bir hata oluştu.') + '</div>';
          }
          if (btn) { btn.disabled = false; btn.innerHTML = '<i class="ti tabler-refresh me-1"></i>Tekrar Dene'; }
        }
      } catch (_) {
        if (resultEl) { resultEl.style.display = 'block'; resultEl.innerHTML = '<div class="alert alert-danger py-2 px-3 mb-0">Bağlantı hatası.</div>'; }
        if (btn) { btn.disabled = false; }
      }
    }

    // ── Event delegation for action forms ────────────────────────────────
    document.addEventListener('click', function (e) {
      const toggleBtn = e.target.closest('.action-toggle-btn');
      if (toggleBtn) {
        const form = document.getElementById(toggleBtn.dataset.form);
        if (form) form.style.display = form.style.display === 'none' ? 'block' : 'none';
        return;
      }
      if (e.target.closest('.cancel-action-btn')) {
        const wrapper = e.target.closest('.action-proposal-form');
        if (wrapper) wrapper.style.display = 'none';
        return;
      }
      const execBtn = e.target.closest('.execute-action-btn');
      if (execBtn) {
        const formEl = execBtn.closest('.agent-action-form');
        if (!formEl) return;
        const data = {};
        formEl.querySelectorAll('.action-field').forEach(f => { data[f.name] = f.value; });
        executeAgentAction(formEl.dataset.action, data, formEl);
      }
    });

    // ── Send message ──────────────────────────────────────────────────────
    async function sendMessage(query) {
      if (!query.trim()) return;
      if (cmdInput) { cmdInput.value = ''; cmdInput.style.height = 'auto'; }
      disableSend(true);
      showResultsMode();
      resetAllAgents();
      setGlobalRunning();

      // Append user bubble
      const userRow = buildUserRow(query);
      messages.appendChild(userRow);

      // Append typing skeleton
      const skeleton = buildSkeleton(query);
      messages.appendChild(skeleton);
      scrollBottom();

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
          skeleton.id = 'skeleton-' + data.message_id;
          skeleton.setAttribute('data-message-id', data.message_id);
          startPolling(data.message_id, skeleton, query);
          disableSend(false);
          return;
        }
        skeleton.remove();
        const aiRow = buildAiRow(query, data.reply || '(Yanıt alınamadı)', data.agents_used || []);
        messages.appendChild(aiRow);
        scrollBottom();
        if (data.agents_used && data.agents_used.length) data.agents_used.forEach(a => setAgentState(a, 'done'));
        resetAgentsAfter(3000);
      } catch (_) {
        stopRunsPolling();
        skeleton.remove();
        const aiRow = buildAiRow(query, 'Bağlantı hatası. İnternet bağlantınızı kontrol edip tekrar deneyin.', []);
        messages.appendChild(aiRow);
        scrollBottom();
      } finally {
        disableSend(false);
      }
    }

    function disableSend(disabled) {
      const btn = document.getElementById('cmd-send');
      if (btn) btn.disabled = disabled;
    }

    // ── Wire up send button / input ───────────────────────────────────────
    const cmdSend = document.getElementById('cmd-send');
    if (cmdSend) cmdSend.addEventListener('click', () => sendMessage(cmdInput ? cmdInput.value.trim() : ''));
    if (cmdInput) {
      cmdInput.addEventListener('keydown', e => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          sendMessage(cmdInput.value.trim());
        }
      });
    }

    // ── Quick trigger pills ───────────────────────────────────────────────
    document.querySelectorAll('.trigger-pill').forEach(pill => {
      pill.addEventListener('click', () => {
        if (cmdInput) { cmdInput.value = pill.dataset.msg; cmdInput.focus(); }
      });
    });

    // ── Quick-action chips (hero) ─────────────────────────────────────────
    document.querySelectorAll('.quick-chip').forEach(chip => {
      chip.addEventListener('click', () => {
        const msg = chip.dataset.msg;
        if (msg) sendMessage(msg);
      });
    });

    // ── New session ───────────────────────────────────────────────────────
    document.getElementById('btn-clear-session')?.addEventListener('click', () => {
      window.location.href = '{{ route("agent-chat.index") }}';
    });

    // ── Dismiss insights ──────────────────────────────────────────────────
    document.querySelectorAll('.btn-dismiss-insight').forEach(btn => {
      btn.addEventListener('click', function () {
        const url = this.dataset.url, id = this.dataset.id;
        fetch(url, { method: 'PATCH', headers: { 'X-CSRF-TOKEN': csrf } }).then(() => {
          const li = document.getElementById('insight-' + id);
          if (li) { li.style.opacity = 0; setTimeout(() => li.remove(), 200); }
        });
      });
    });

  })();
  </script>
  </x-slot>
</x-app-layout>
