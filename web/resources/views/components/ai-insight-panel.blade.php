{{--
    x-ai-insight-panel
    ──────────────────
    Props:
      $page     – page slug for /api/v1/agent/page-analyze
      $autoload – boolean, fetch insights automatically on page-load
      $title    – header label (default: "Paranette AI")
--}}
@php
    $panelId  = 'ai-panel-' . Str::random(8);
    $btnId    = 'ai-refresh-' . Str::random(8);
@endphp

<style>
/* ── AI Insight Panel styles (scoped with .ai-insight-panel) ────────── */
.ai-insight-panel {
    position: relative;
}
.ai-insight-panel .panel-header-gradient {
    background: linear-gradient(135deg, #7367F0 0%, #9E95F5 50%, #CE9FFC 100%);
    border-radius: .75rem .75rem 0 0;
    padding: .85rem 1.1rem;
    display: flex;
    align-items: center;
    gap: .65rem;
}
.ai-insight-panel .panel-ai-icon {
    width: 34px;
    height: 34px;
    border-radius: 50%;
    background: rgba(255,255,255,.22);
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
}
.ai-insight-panel .panel-title {
    flex: 1 1 0;
    color: #fff;
    font-weight: 700;
    font-size: .9rem;
    line-height: 1.2;
}
.ai-insight-panel .panel-title small {
    display: block;
    font-size: .68rem;
    font-weight: 400;
    opacity: .8;
}
.ai-insight-panel .btn-refresh {
    background: rgba(255,255,255,.18);
    border: 1px solid rgba(255,255,255,.35);
    color: #fff;
    border-radius: .5rem;
    padding: .3rem .6rem;
    font-size: .75rem;
    font-weight: 600;
    display: flex;
    align-items: center;
    gap: .3rem;
    cursor: pointer;
    transition: background .15s;
    flex-shrink: 0;
}
.ai-insight-panel .btn-refresh:hover {
    background: rgba(255,255,255,.3);
}
.ai-insight-panel .btn-refresh.loading .refresh-icon {
    animation: spin .8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* ── States ─────────────────────────────────────────────────────────── */
.ai-insight-panel .panel-body {
    min-height: 120px;
}

/* skeleton */
.ai-skeleton-row {
    height: 14px;
    border-radius: 8px;
    background: var(--bs-secondary-bg);
    position: relative;
    overflow: hidden;
}
.ai-skeleton-row::after {
    content: '';
    position: absolute;
    inset: 0;
    background: linear-gradient(90deg, transparent 0%, rgba(255,255,255,.07) 50%, transparent 100%);
    animation: shimmer 1.4s ease-in-out infinite;
}
@keyframes shimmer {
    0%   { transform: translateX(-100%); }
    100% { transform: translateX(100%); }
}

/* insight card */
.ai-insight-card {
    border-left: 3px solid transparent;
    border-radius: .45rem;
    padding: .7rem .85rem;
    margin-bottom: .5rem;
    background: var(--bs-secondary-bg);
    transition: box-shadow .14s;
}
.ai-insight-card:last-child { margin-bottom: 0; }
.ai-insight-card:hover { box-shadow: 0 2px 10px rgba(0,0,0,.08); }

.ai-insight-card.type-warning { border-left-color: #FF9F43; }
.ai-insight-card.type-alert   { border-left-color: #EA5455; }
.ai-insight-card.type-success { border-left-color: #28C76F; }
.ai-insight-card.type-tip     { border-left-color: #00CFE8; }
.ai-insight-card.type-info    { border-left-color: #7367F0; }

.ai-insight-icon {
    width: 28px;
    height: 28px;
    border-radius: .4rem;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
}
.ai-insight-icon.type-warning { background: rgba(255,159,67,.15);  color: #FF9F43; }
.ai-insight-icon.type-alert   { background: rgba(234,84,85,.15);   color: #EA5455; }
.ai-insight-icon.type-success { background: rgba(40,199,111,.15);  color: #28C76F; }
.ai-insight-icon.type-tip     { background: rgba(0,207,232,.15);   color: #00CFE8; }
.ai-insight-icon.type-info    { background: rgba(115,103,240,.15); color: #7367F0; }

.ai-insight-title {
    font-size: .8rem;
    font-weight: 700;
    color: var(--bs-heading-color);
    line-height: 1.2;
    margin-bottom: .18rem;
}
.ai-insight-body {
    font-size: .75rem;
    color: var(--bs-secondary-color);
    line-height: 1.45;
}
.ai-insight-action {
    margin-top: .4rem;
}
.ai-insight-action a {
    font-size: .72rem;
    font-weight: 600;
    text-decoration: none;
}

/* importance dot */
.imp-dot {
    display: inline-block;
    width: 6px;
    height: 6px;
    border-radius: 50%;
    margin-right: .3rem;
    vertical-align: middle;
}
.imp-critical { background: #EA5455; animation: pulse-imp 1.2s ease infinite; }
.imp-high     { background: #FF9F43; }
.imp-medium   { background: #7367F0; }
.imp-low      { background: #b4b7bd; }
@keyframes pulse-imp {
    0%, 100% { box-shadow: 0 0 0 0 rgba(234,84,85,.5); }
    50%       { box-shadow: 0 0 0 4px rgba(234,84,85,0); }
}

/* error state */
.ai-error-state {
    text-align: center;
    padding: 1.1rem .75rem;
}
.ai-empty-state {
    text-align: center;
    padding: 1.5rem .75rem;
}

/* footer */
.ai-panel-footer {
    border-top: 1px solid var(--bs-border-color);
    padding: .6rem 1rem;
    font-size: .74rem;
}
.ai-panel-footer a {
    color: var(--bs-primary);
    text-decoration: none;
    font-weight: 600;
}
.ai-panel-footer a:hover { text-decoration: underline; }
</style>

<div class="card shadow-sm mb-5 ai-insight-panel" id="{{ $panelId }}">

    {{-- ── Header ─────────────────────────────────────────────────────────── --}}
    <div class="panel-header-gradient">
        <div class="panel-ai-icon">
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24"
                 fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
            </svg>
        </div>
        <div class="panel-title">
            {{ $title }}
            <small>Yapay Zeka Destekli Analiz</small>
        </div>
        <button class="btn-refresh" id="{{ $btnId }}" type="button" aria-label="Analiz yenile">
            <svg class="refresh-icon" xmlns="http://www.w3.org/2000/svg" width="13" height="13"
                 viewBox="0 0 24 24" fill="none" stroke="currentColor"
                 stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="23 4 23 10 17 10"/>
                <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
            </svg>
            Yenile
        </button>
    </div>

    {{-- ── Body ────────────────────────────────────────────────────────────── --}}
    <div class="card-body panel-body p-3" id="{{ $panelId }}-body">

        {{-- Loading skeleton (default state) --}}
        <div class="ai-state-loading" id="{{ $panelId }}-loading" style="display:none;">
            @for($i = 0; $i < 3; $i++)
            <div class="mb-3">
                <div class="d-flex align-items-center gap-2 mb-2">
                    <div class="ai-skeleton-row" style="width:28px;height:28px;border-radius:.4rem;flex-shrink:0;"></div>
                    <div class="ai-skeleton-row flex-grow-1" style="height:12px;"></div>
                </div>
                <div class="ai-skeleton-row mb-1" style="height:10px;width:90%;"></div>
                <div class="ai-skeleton-row" style="height:10px;width:70%;"></div>
            </div>
            @endfor
        </div>

        {{-- Insights list --}}
        <div class="ai-state-insights" id="{{ $panelId }}-insights" style="display:none;">
            {{-- Populated by JS --}}
        </div>

        {{-- Error state --}}
        <div class="ai-state-error ai-error-state" id="{{ $panelId }}-error" style="display:none;">
            <div class="mb-2 d-flex justify-content-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24"
                     fill="none" stroke="#EA5455" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
            </div>
            <p class="text-muted small mb-2" id="{{ $panelId }}-error-msg">Analiz sırasında bir hata oluştu.</p>
            <button class="btn btn-sm btn-outline-secondary btn-retry-ai" data-panel="{{ $panelId }}" type="button">
                Tekrar Dene
            </button>
        </div>

        {{-- Empty state --}}
        <div class="ai-state-empty ai-empty-state" id="{{ $panelId }}-empty" style="display:none;">
            <div class="mb-2 d-flex justify-content-center">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24"
                     fill="none" stroke="var(--bs-secondary-color)" stroke-width="1.5"
                     stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="8" y1="12" x2="16" y2="12"/>
                </svg>
            </div>
            <p class="text-muted small mb-0">Şu an önerilen içerik yok.</p>
        </div>

        {{-- Initial idle state (before any fetch) --}}
        <div class="ai-state-idle ai-empty-state" id="{{ $panelId }}-idle">
            <div class="mb-3 d-flex justify-content-center">
                <div style="width:52px;height:52px;border-radius:50%;background:linear-gradient(135deg,#7367F0,#CE9FFC);display:flex;align-items:center;justify-content:center;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"
                         fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                    </svg>
                </div>
            </div>
            <p class="text-muted small mb-3">
                AI ajanı bu sayfayı analiz ederek kişiselleştirilmiş öneriler sunabilir.
            </p>
            <button class="btn btn-sm btn-primary btn-start-ai" data-panel="{{ $panelId }}" type="button">
                <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24"
                     fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"
                     stroke-linejoin="round" class="me-1">
                    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                </svg>
                Analiz Başlat
            </button>
        </div>

    </div>

    {{-- ── Footer ──────────────────────────────────────────────────────────── --}}
    <div class="ai-panel-footer">
        <a href="/agent-chat">
            Tüm öneriler için Paranette AI&rsquo;ya sor
            <svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24"
                 fill="none" stroke="currentColor" stroke-width="2.5"
                 stroke-linecap="round" stroke-linejoin="round" class="ms-1">
                <polyline points="9 18 15 12 9 6"/>
            </svg>
        </a>
    </div>

</div>

@php
    $jsPageSlug    = e($page);
    $jsPanelId     = e($panelId);
    $jsBtnId       = e($btnId);
    $jsAutoload    = $autoload ? 'true' : 'false';
    $jsAnalyzeUrl  = e(route('page-analyze'));
@endphp
<script>
(function () {
    'use strict';

    var PAGE_SLUG    = '{{ $jsPageSlug }}';
    var PANEL_ID     = '{{ $jsPanelId }}';
    var AUTOLOAD     = {{ $jsAutoload }};
    var ANALYZE_URL  = '{{ $jsAnalyzeUrl }}';

    var panel         = document.getElementById(PANEL_ID);
    var btnRefresh    = document.getElementById('{{ $jsBtnId }}');
    var bodyLoading   = document.getElementById(PANEL_ID + '-loading');
    var bodyInsights  = document.getElementById(PANEL_ID + '-insights');
    var bodyError     = document.getElementById(PANEL_ID + '-error');
    var bodyErrorMsg  = document.getElementById(PANEL_ID + '-error-msg');
    var bodyEmpty     = document.getElementById(PANEL_ID + '-empty');
    var bodyIdle      = document.getElementById(PANEL_ID + '-idle');

    // ── Helpers ────────────────────────────────────────────────────────────
    function showOnly(el) {
        [bodyLoading, bodyInsights, bodyError, bodyEmpty, bodyIdle].forEach(function (e) {
            if (e) e.style.display = 'none';
        });
        if (el) el.style.display = '';
    }

    var iconMap = {
        warning: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
        alert:   '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>',
        success: '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>',
        tip:     '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="2" x2="12" y2="6"/><line x1="12" y1="18" x2="12" y2="22"/><line x1="4.93" y1="4.93" x2="7.76" y2="7.76"/><line x1="16.24" y1="16.24" x2="19.07" y2="19.07"/><line x1="2" y1="12" x2="6" y2="12"/><line x1="18" y1="12" x2="22" y2="12"/><line x1="4.93" y1="19.07" x2="7.76" y2="16.24"/><line x1="16.24" y1="7.76" x2="19.07" y2="4.93"/></svg>',
        info:    '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>',
    };

    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    function renderInsights(insights) {
        if (!insights || insights.length === 0) {
            showOnly(bodyEmpty);
            return;
        }

        var html = '';
        insights.forEach(function (ins) {
            var type       = ins.type       || 'info';
            var importance = ins.importance || 'medium';
            var icon       = iconMap[type]  || iconMap['info'];
            var action     = ins.action;

            var actionHtml = '';
            if (action && action.label && action.url) {
                actionHtml = '<div class="ai-insight-action">' +
                    '<a href="' + escapeHtml(action.url) + '" class="text-primary">' +
                    escapeHtml(action.label) +
                    ' <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>' +
                    '</a></div>';
            }

            html += '<div class="ai-insight-card type-' + escapeHtml(type) + '">' +
                '<div class="d-flex align-items-start gap-2">' +
                    '<div class="ai-insight-icon type-' + escapeHtml(type) + '">' + icon + '</div>' +
                    '<div class="flex-grow-1 overflow-hidden">' +
                        '<div class="ai-insight-title">' +
                            '<span class="imp-dot imp-' + escapeHtml(importance) + '"></span>' +
                            escapeHtml(ins.title) +
                        '</div>' +
                        '<div class="ai-insight-body">' + escapeHtml(ins.body) + '</div>' +
                        actionHtml +
                    '</div>' +
                '</div>' +
            '</div>';
        });

        bodyInsights.innerHTML = html;
        showOnly(bodyInsights);
    }

    // ── Fetch ──────────────────────────────────────────────────────────────
    function fetchInsights() {
        showOnly(bodyLoading);
        if (btnRefresh) {
            btnRefresh.classList.add('loading');
            btnRefresh.disabled = true;
        }

        var csrfMeta  = document.querySelector('meta[name="csrf-token"]');
        var csrfToken = csrfMeta ? csrfMeta.content : '';

        fetch(ANALYZE_URL, {
            method: 'POST',
            headers: {
                'Content-Type':  'application/json',
                'X-CSRF-TOKEN':  csrfToken,
                'Accept':        'application/json',
            },
            credentials: 'same-origin',
            body: JSON.stringify({ page: PAGE_SLUG, limit: 3 }),
        })
        .then(function (res) {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
        })
        .then(function (data) {
            renderInsights(data.insights || []);
        })
        .catch(function (err) {
            showOnly(bodyError);
            if (bodyErrorMsg) {
                bodyErrorMsg.textContent = 'Analiz sırasında bir hata oluştu. Lütfen tekrar deneyin.';
            }
        })
        .finally(function () {
            if (btnRefresh) {
                btnRefresh.classList.remove('loading');
                btnRefresh.disabled = false;
            }
        });
    }

    // ── Event listeners ────────────────────────────────────────────────────
    if (btnRefresh) {
        btnRefresh.addEventListener('click', fetchInsights);
    }

    // "Analiz Başlat" button in idle state
    document.querySelectorAll('.btn-start-ai[data-panel="' + PANEL_ID + '"]').forEach(function (btn) {
        btn.addEventListener('click', fetchInsights);
    });

    // "Tekrar Dene" button in error state
    document.querySelectorAll('.btn-retry-ai[data-panel="' + PANEL_ID + '"]').forEach(function (btn) {
        btn.addEventListener('click', fetchInsights);
    });

    // ── Autoload ───────────────────────────────────────────────────────────
    if (AUTOLOAD) {
        // Small delay to allow page to fully render first
        setTimeout(fetchInsights, 600);
    }
})();
</script>
