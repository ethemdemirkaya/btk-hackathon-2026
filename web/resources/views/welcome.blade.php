<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Paranette — Akıllı Finansal Asistan</title>
  <meta name="description" content="Tüm banka hesaplarınızı tek platformda görün. Kişisel enflasyonunuzu ölçün. AI ajanlarıyla finansal kararlarınızı optimize edin." />

  <link rel="icon" type="image/x-icon" href="{{ asset('assets/img/favicon/favicon.ico') }}" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet" />

  {{-- Bootstrap 5 vanilla (no Vuexy theme) --}}
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" />
  {{-- Tabler Icons --}}
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.19.0/dist/tabler-icons.min.css" />

  <style>
  /* ═══════════════════════════════════════════════════════════════
     PARANETTE — Landing Page Design System
  ═══════════════════════════════════════════════════════════════ */
  :root {
    --ink:        #0A0F1E;
    --ink-2:      #111827;
    --blue:       #3B82F6;
    --blue-dk:    #1D4ED8;
    --green:      #10B981;
    --amber:      #F59E0B;
    --red:        #EF4444;
    --violet:     #8B5CF6;
    --violet-dk:  #6D28D9;
    --slate:      #94A3B8;
    --border:     rgba(255,255,255,.08);
    --card-bg:    rgba(255,255,255,.04);
    --radius:     16px;
    --font:       'Inter', system-ui, sans-serif;
  }

  *, *::before, *::after { box-sizing: border-box; }

  html { scroll-behavior: smooth; }

  body {
    font-family: var(--font);
    background: var(--ink);
    color: #E2E8F0;
    margin: 0;
    -webkit-font-smoothing: antialiased;
  }

  /* ── Noise texture overlay ── */
  body::before {
    content: '';
    position: fixed; inset: 0; z-index: 0;
    background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.03'/%3E%3C/svg%3E");
    pointer-events: none;
    opacity: .4;
  }

  /* ── Page wrapper above noise ── */
  .pn-page { position: relative; z-index: 1; }

  /* ═══════════════════════
     NAVBAR
  ═══════════════════════ */
  .pn-nav {
    position: sticky; top: 0; z-index: 100;
    display: flex; align-items: center;
    padding: 14px 40px;
    background: rgba(10,15,30,.7);
    backdrop-filter: blur(18px) saturate(1.4);
    -webkit-backdrop-filter: blur(18px) saturate(1.4);
    border-bottom: 1px solid var(--border);
    transition: background .3s;
  }
  .pn-nav-logo {
    display: flex; align-items: center; gap: 10px;
    text-decoration: none;
  }
  .pn-nav-logo-text {
    font-size: 1.25rem; font-weight: 800;
    color: #fff; letter-spacing: -.02em;
  }
  .pn-nav-actions { margin-left: auto; display: flex; gap: 10px; align-items: center; }
  .pn-btn-nav-ghost {
    padding: 7px 18px; border-radius: 8px;
    font-size: .82rem; font-weight: 500;
    background: transparent; color: rgba(255,255,255,.75);
    border: 1px solid rgba(255,255,255,.15); cursor: pointer;
    text-decoration: none; transition: all .15s;
  }
  .pn-btn-nav-ghost:hover { background: rgba(255,255,255,.07); color: #fff; }
  .pn-btn-nav-primary {
    padding: 7px 20px; border-radius: 8px;
    font-size: .82rem; font-weight: 600;
    background: var(--blue); color: #fff;
    border: none; cursor: pointer;
    text-decoration: none; transition: background .15s;
  }
  .pn-btn-nav-primary:hover { background: var(--blue-dk); color: #fff; }

  /* ═══════════════════════
     HERO
  ═══════════════════════ */
  .pn-hero {
    min-height: 92vh;
    display: flex; align-items: center;
    position: relative; overflow: hidden;
    padding: 80px 0 60px;
  }

  /* Mesh gradient background */
  .pn-hero::before {
    content: '';
    position: absolute; inset: 0;
    background:
      radial-gradient(ellipse 80% 60% at 10% 20%, rgba(59,130,246,.18) 0%, transparent 60%),
      radial-gradient(ellipse 60% 50% at 85% 70%, rgba(139,92,246,.15) 0%, transparent 55%),
      radial-gradient(ellipse 50% 40% at 50% 100%, rgba(16,185,129,.08) 0%, transparent 60%);
    pointer-events: none;
  }

  /* Grid lines decoration */
  .pn-hero::after {
    content: '';
    position: absolute; inset: 0;
    background-image:
      linear-gradient(rgba(255,255,255,.02) 1px, transparent 1px),
      linear-gradient(90deg, rgba(255,255,255,.02) 1px, transparent 1px);
    background-size: 60px 60px;
    pointer-events: none;
  }

  .pn-hero-content { position: relative; z-index: 2; }

  .pn-hero-eyebrow {
    display: inline-flex; align-items: center; gap: 7px;
    background: rgba(59,130,246,.12);
    border: 1px solid rgba(59,130,246,.25);
    color: #93C5FD;
    border-radius: 24px; padding: 5px 14px;
    font-size: .75rem; font-weight: 600;
    letter-spacing: .08em; text-transform: uppercase;
    margin-bottom: 22px;
  }

  .pn-hero-title {
    font-size: clamp(2.6rem, 6vw, 4.5rem);
    font-weight: 900;
    line-height: 1.05;
    letter-spacing: -.035em;
    color: #fff;
    margin-bottom: 20px;
  }

  .pn-hero-title .grad-text {
    background: linear-gradient(135deg, #60A5FA 0%, #A78BFA 50%, #34D399 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .pn-hero-sub {
    font-size: 1.1rem;
    color: rgba(255,255,255,.6);
    line-height: 1.7;
    max-width: 500px;
    margin-bottom: 36px;
  }

  .pn-hero-ctas { display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 52px; }

  .pn-btn-primary {
    display: inline-flex; align-items: center; gap: 7px;
    padding: 12px 28px; border-radius: 10px;
    font-size: .9rem; font-weight: 600;
    background: var(--blue); color: #fff;
    border: none; cursor: pointer;
    text-decoration: none;
    transition: all .2s;
    box-shadow: 0 4px 20px rgba(59,130,246,.35);
  }
  .pn-btn-primary:hover {
    background: var(--blue-dk); color: #fff;
    transform: translateY(-1px);
    box-shadow: 0 6px 28px rgba(59,130,246,.45);
  }

  .pn-btn-secondary {
    display: inline-flex; align-items: center; gap: 7px;
    padding: 12px 28px; border-radius: 10px;
    font-size: .9rem; font-weight: 500;
    background: rgba(255,255,255,.06); color: rgba(255,255,255,.8);
    border: 1px solid rgba(255,255,255,.12); cursor: pointer;
    text-decoration: none; transition: all .2s;
  }
  .pn-btn-secondary:hover { background: rgba(255,255,255,.1); color: #fff; }

  /* Stat pills row */
  .pn-stat-row { display: flex; flex-wrap: wrap; gap: 10px; }
  .pn-stat {
    display: flex; align-items: center; gap: 10px;
    background: rgba(255,255,255,.05);
    border: 1px solid rgba(255,255,255,.09);
    border-radius: 12px; padding: 10px 16px;
  }
  .pn-stat-ico { font-size: 22px; line-height: 1; }
  .pn-stat-val { font-size: 1rem; font-weight: 700; color: #fff; display: block; }
  .pn-stat-lbl { font-size: .72rem; color: var(--slate); display: block; }

  /* Hero right: dashboard mockup */
  .pn-mockup {
    background: rgba(255,255,255,.04);
    border: 1px solid rgba(255,255,255,.09);
    border-radius: 20px;
    overflow: hidden;
    backdrop-filter: blur(8px);
    box-shadow: 0 32px 80px rgba(0,0,0,.5), 0 0 0 1px rgba(255,255,255,.05);
  }
  .pn-mockup-bar {
    background: rgba(255,255,255,.04);
    border-bottom: 1px solid rgba(255,255,255,.06);
    padding: 10px 16px;
    display: flex; align-items: center; gap: 6px;
  }
  .pn-dot { width: 9px; height: 9px; border-radius: 50%; }
  .pn-mockup-body { padding: 16px; }

  .pn-mini-card {
    background: rgba(255,255,255,.05);
    border: 1px solid rgba(255,255,255,.07);
    border-radius: 10px; padding: 12px 14px;
    margin-bottom: 8px;
  }
  .pn-mini-card-lbl { font-size: .66rem; color: var(--slate); text-transform: uppercase; letter-spacing: .07em; margin-bottom: 4px; }
  .pn-mini-card-val { font-size: 1.05rem; font-weight: 700; color: #fff; }
  .pn-mini-bar {
    height: 3px; border-radius: 3px; margin-top: 6px;
    background: rgba(255,255,255,.08);
    overflow: hidden;
  }
  .pn-mini-bar-fill { height: 100%; border-radius: 3px; }

  /* Floating glow badge */
  .pn-glow-badge {
    position: absolute;
    background: rgba(16,185,129,.15);
    border: 1px solid rgba(16,185,129,.3);
    color: #6EE7B7;
    border-radius: 10px; padding: 8px 14px;
    font-size: .75rem; font-weight: 600;
    backdrop-filter: blur(8px);
    box-shadow: 0 8px 24px rgba(0,0,0,.3);
    display: flex; align-items: center; gap: 6px;
    white-space: nowrap;
  }

  /* ═══════════════════════
     SECTION COMMONS
  ═══════════════════════ */
  .pn-section { padding: 96px 0; }
  .pn-section-sm { padding: 64px 0; }

  .pn-section-eyebrow {
    display: inline-flex; align-items: center; gap: 6px;
    font-size: .72rem; font-weight: 700;
    letter-spacing: .1em; text-transform: uppercase;
    margin-bottom: 12px;
    padding: 4px 12px; border-radius: 20px;
  }
  .ey-blue   { background: rgba(59,130,246,.12); border: 1px solid rgba(59,130,246,.2); color: #93C5FD; }
  .ey-amber  { background: rgba(245,158,11,.12); border: 1px solid rgba(245,158,11,.2); color: #FCD34D; }
  .ey-green  { background: rgba(16,185,129,.12); border: 1px solid rgba(16,185,129,.2); color: #6EE7B7; }
  .ey-violet { background: rgba(139,92,246,.12); border: 1px solid rgba(139,92,246,.2); color: #C4B5FD; }

  .pn-section-title {
    font-size: clamp(1.9rem, 4vw, 2.8rem);
    font-weight: 800;
    color: #fff;
    line-height: 1.15;
    letter-spacing: -.03em;
    margin-bottom: 14px;
  }
  .pn-section-sub {
    font-size: 1rem; color: rgba(255,255,255,.5);
    line-height: 1.7; max-width: 520px;
  }

  /* ═══════════════════════
     DIVIDER
  ═══════════════════════ */
  .pn-divider {
    height: 1px;
    background: linear-gradient(90deg, transparent, rgba(255,255,255,.08) 30%, rgba(255,255,255,.08) 70%, transparent);
    margin: 0;
  }

  /* ═══════════════════════
     TRUST BAR
  ═══════════════════════ */
  .pn-trust {
    padding: 28px 0;
    background: rgba(255,255,255,.02);
    border-top: 1px solid rgba(255,255,255,.05);
    border-bottom: 1px solid rgba(255,255,255,.05);
  }
  .pn-trust-row {
    display: flex; align-items: center; justify-content: center;
    flex-wrap: wrap; gap: 40px;
  }
  .pn-trust-item { display: flex; align-items: center; gap: 10px; }
  .pn-trust-ico { font-size: 22px; color: var(--slate); }
  .pn-trust-text { font-size: .82rem; color: rgba(255,255,255,.5); }
  .pn-trust-num { font-weight: 700; color: rgba(255,255,255,.85); }

  /* ═══════════════════════
     FEATURES GRID
  ═══════════════════════ */
  .pn-feat-card {
    background: rgba(255,255,255,.03);
    border: 1px solid rgba(255,255,255,.07);
    border-radius: var(--radius);
    padding: 28px;
    height: 100%;
    transition: transform .2s, border-color .2s, background .2s;
    position: relative; overflow: hidden;
  }
  .pn-feat-card::before {
    content: '';
    position: absolute; inset: 0;
    border-radius: var(--radius);
    opacity: 0;
    transition: opacity .3s;
  }
  .pn-feat-card:hover {
    transform: translateY(-3px);
    border-color: rgba(255,255,255,.13);
    background: rgba(255,255,255,.05);
  }
  .pn-feat-card.fc-blue:hover::before   { background: radial-gradient(circle at 50% 0%, rgba(59,130,246,.08) 0%, transparent 70%); opacity: 1; }
  .pn-feat-card.fc-amber:hover::before  { background: radial-gradient(circle at 50% 0%, rgba(245,158,11,.08) 0%, transparent 70%); opacity: 1; }
  .pn-feat-card.fc-green:hover::before  { background: radial-gradient(circle at 50% 0%, rgba(16,185,129,.08) 0%, transparent 70%); opacity: 1; }
  .pn-feat-card.fc-red:hover::before    { background: radial-gradient(circle at 50% 0%, rgba(239,68,68,.08) 0%, transparent 70%); opacity: 1; }
  .pn-feat-card.fc-violet:hover::before { background: radial-gradient(circle at 50% 0%, rgba(139,92,246,.08) 0%, transparent 70%); opacity: 1; }
  .pn-feat-card.fc-cyan:hover::before   { background: radial-gradient(circle at 50% 0%, rgba(6,182,212,.08) 0%, transparent 70%); opacity: 1; }

  .pn-feat-ico {
    width: 52px; height: 52px; border-radius: 14px;
    display: flex; align-items: center; justify-content: center;
    font-size: 22px; margin-bottom: 18px;
    position: relative; z-index: 1;
  }
  .fi-blue   { background: rgba(59,130,246,.15);  color: #60A5FA; }
  .fi-amber  { background: rgba(245,158,11,.15);  color: #FCD34D; }
  .fi-green  { background: rgba(16,185,129,.15);  color: #6EE7B7; }
  .fi-red    { background: rgba(239,68,68,.15);   color: #FCA5A5; }
  .fi-violet { background: rgba(139,92,246,.15);  color: #C4B5FD; }
  .fi-cyan   { background: rgba(6,182,212,.15);   color: #67E8F9; }

  .pn-feat-title {
    font-size: .95rem; font-weight: 700; color: #fff;
    margin-bottom: 8px; position: relative; z-index: 1;
  }
  .pn-feat-body {
    font-size: .8rem; color: rgba(255,255,255,.45);
    line-height: 1.65; margin: 0; position: relative; z-index: 1;
  }

  /* ═══════════════════════
     INFLATION HIGHLIGHT
  ═══════════════════════ */
  .pn-inf-section {
    background:
      radial-gradient(ellipse 60% 80% at 0% 50%, rgba(245,158,11,.1) 0%, transparent 60%),
      radial-gradient(ellipse 50% 60% at 100% 30%, rgba(239,68,68,.08) 0%, transparent 55%),
      rgba(255,255,255,.02);
    border: 1px solid rgba(245,158,11,.12);
    border-radius: 24px;
    padding: 56px 52px;
    position: relative; overflow: hidden;
  }
  .pn-inf-section::before {
    content: '';
    position: absolute; right: -80px; top: -80px;
    width: 300px; height: 300px;
    background: radial-gradient(circle, rgba(245,158,11,.06) 0%, transparent 70%);
    pointer-events: none;
  }
  .pn-inf-big-num {
    font-size: 5rem; font-weight: 900;
    background: linear-gradient(135deg, #F59E0B, #FDE68A);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    line-height: 1; letter-spacing: -.04em;
    margin-bottom: 4px;
  }
  .pn-inf-legend {
    display: flex; gap: 16px; flex-wrap: wrap; margin-top: 16px;
  }
  .pn-inf-leg-item { display: flex; align-items: center; gap: 6px; font-size: .78rem; }
  .pn-inf-leg-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
  .pn-cat-list { margin-top: 20px; }
  .pn-cat-row { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }
  .pn-cat-name { font-size: .78rem; color: rgba(255,255,255,.5); width: 120px; flex-shrink: 0; }
  .pn-cat-track { flex: 1; height: 4px; background: rgba(255,255,255,.08); border-radius: 4px; overflow: hidden; }
  .pn-cat-fill  { height: 100%; border-radius: 4px; background: linear-gradient(90deg, #F59E0B, #FDE68A); }
  .pn-cat-pct  { font-size: .75rem; font-weight: 600; color: #FCD34D; width: 40px; text-align: right; }

  /* ═══════════════════════
     AI SECTION
  ═══════════════════════ */
  .pn-ai-arch {
    background: rgba(255,255,255,.02);
    border: 1px solid rgba(255,255,255,.07);
    border-radius: 24px; padding: 40px;
  }
  .pn-agent-chip {
    display: inline-flex; align-items: center; gap: 7px;
    background: rgba(255,255,255,.05);
    border: 1px solid rgba(255,255,255,.09);
    border-radius: 24px; padding: 7px 14px;
    font-size: .78rem; color: rgba(255,255,255,.7);
    margin: 4px;
  }
  .pn-agent-chip i { font-size: 14px; }

  /* Chat mockup */
  .pn-chat {
    background: rgba(255,255,255,.03);
    border: 1px solid rgba(255,255,255,.08);
    border-radius: 16px; overflow: hidden;
  }
  .pn-chat-header {
    background: rgba(255,255,255,.04);
    border-bottom: 1px solid rgba(255,255,255,.07);
    padding: 12px 18px;
    display: flex; align-items: center; gap: 10px;
  }
  .pn-chat-avatar {
    width: 30px; height: 30px; border-radius: 50%;
    background: linear-gradient(135deg, var(--blue), var(--violet));
    display: flex; align-items: center; justify-content: center;
    font-size: 13px; color: #fff; flex-shrink: 0;
  }
  .pn-chat-name { font-size: .8rem; font-weight: 600; color: #fff; }
  .pn-online-dot {
    width: 7px; height: 7px; border-radius: 50%;
    background: var(--green);
    margin-left: auto;
    box-shadow: 0 0 6px var(--green);
  }
  .pn-chat-body { padding: 18px; }
  .pn-msg { margin-bottom: 14px; }
  .pn-msg-user {
    background: rgba(59,130,246,.15);
    border: 1px solid rgba(59,130,246,.2);
    border-radius: 12px 12px 3px 12px;
    padding: 10px 14px; font-size: .8rem;
    color: #93C5FD; margin-left: 20%;
  }
  .pn-msg-agent-wrap { display: flex; gap: 8px; }
  .pn-msg-agent-ico {
    width: 26px; height: 26px; border-radius: 50%;
    background: rgba(139,92,246,.2); color: #C4B5FD;
    display: flex; align-items: center; justify-content: center;
    font-size: 11px; flex-shrink: 0; margin-top: 2px;
  }
  .pn-msg-agent {
    background: rgba(255,255,255,.05);
    border: 1px solid rgba(255,255,255,.08);
    border-radius: 3px 12px 12px 12px;
    padding: 10px 14px; font-size: .78rem;
    color: rgba(255,255,255,.7); line-height: 1.6;
    flex: 1;
  }
  .pn-msg-agent strong { color: rgba(255,255,255,.9); }
  .pn-agents-used {
    display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 10px;
  }
  .pn-tag {
    font-size: .66rem; font-weight: 600; padding: 2px 8px; border-radius: 20px;
  }
  .tag-blue   { background: rgba(59,130,246,.15); color: #93C5FD; }
  .tag-amber  { background: rgba(245,158,11,.15); color: #FCD34D; }
  .tag-violet { background: rgba(139,92,246,.15); color: #C4B5FD; }

  /* ═══════════════════════
     CTA SECTION
  ═══════════════════════ */
  .pn-cta {
    background: linear-gradient(135deg, rgba(59,130,246,.15) 0%, rgba(139,92,246,.12) 50%, rgba(16,185,129,.08) 100%);
    border: 1px solid rgba(255,255,255,.08);
    border-radius: 24px;
    padding: 72px 48px;
    text-align: center;
    position: relative; overflow: hidden;
  }
  .pn-cta::before {
    content: '';
    position: absolute; inset: 0;
    background: radial-gradient(ellipse 60% 60% at 50% 100%, rgba(59,130,246,.12) 0%, transparent 70%);
    pointer-events: none;
  }
  .pn-cta-title {
    font-size: clamp(1.8rem, 4vw, 2.8rem);
    font-weight: 900; color: #fff;
    letter-spacing: -.03em; margin-bottom: 14px;
    position: relative; z-index: 1;
  }
  .pn-cta-sub {
    font-size: .95rem; color: rgba(255,255,255,.55);
    margin-bottom: 36px; position: relative; z-index: 1;
  }
  .pn-cta-actions { position: relative; z-index: 1; display: flex; gap: 12px; justify-content: center; flex-wrap: wrap; }

  /* ═══════════════════════
     FOOTER
  ═══════════════════════ */
  .pn-footer {
    padding: 32px 40px;
    border-top: 1px solid rgba(255,255,255,.05);
    display: flex; align-items: center; justify-content: space-between;
    flex-wrap: wrap; gap: 12px;
  }
  .pn-footer-brand { display: flex; align-items: center; gap: 8px; }
  .pn-footer-text { font-size: .78rem; color: rgba(255,255,255,.3); }
  .pn-footer-stack { display: flex; gap: 8px; flex-wrap: wrap; }
  .pn-stack-tag {
    font-size: .68rem; font-weight: 600; padding: 3px 9px; border-radius: 20px;
    background: rgba(255,255,255,.05); color: rgba(255,255,255,.4);
    border: 1px solid rgba(255,255,255,.07);
  }

  /* ═══════════════════════
     UTILITIES
  ═══════════════════════ */
  .container-xl { max-width: 1200px; margin: 0 auto; padding: 0 24px; }
  @media (max-width: 768px) {
    .pn-nav { padding: 12px 20px; }
    .pn-inf-section { padding: 32px 24px; }
    .pn-ai-arch { padding: 24px; }
    .pn-cta { padding: 48px 24px; }
    .pn-footer { flex-direction: column; text-align: center; }
    .pn-hero-title { font-size: 2.4rem; }
    .pn-inf-big-num { font-size: 3.5rem; }
  }
  </style>
</head>

<body>
<div class="pn-page">

  {{-- ══════════════════════════════════════════════════════════
       NAVBAR
  ═══════════════════════════════════════════════════════════ --}}
  <nav class="pn-nav">
    <a href="{{ url('/') }}" class="pn-nav-logo">
      <svg width="26" height="18" viewBox="0 0 32 22" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path fill-rule="evenodd" clip-rule="evenodd"
              d="M0.00172773 0V6.85398C0.00172773 6.85398 -0.133178 9.01207 1.98092 10.8388L13.6912 21.9964L19.7809 21.9181L18.8042 9.88248L16.4951 7.17289L9.23799 0H0.00172773Z"
              fill="#10B981"/>
        <path fill-rule="evenodd" clip-rule="evenodd"
              d="M7.77295 16.3566L23.6563 0H32V6.88383C32 6.88383 31.8262 9.17836 30.6591 10.4057L19.7824 22H13.6938L7.77295 16.3566Z"
              fill="#10B981"/>
      </svg>
      <span class="pn-nav-logo-text">Paranette</span>
    </a>
    <div class="pn-nav-actions">
      @auth
        <a href="{{ route('dashboard') }}" class="pn-btn-nav-primary">Panele Git</a>
      @else
        <a href="{{ route('login') }}" class="pn-btn-nav-ghost">Giriş Yap</a>
        <a href="{{ route('register') }}" class="pn-btn-nav-primary">Ücretsiz Başla</a>
      @endauth
    </div>
  </nav>

  {{-- ══════════════════════════════════════════════════════════
       HERO
  ═══════════════════════════════════════════════════════════ --}}
  <section class="pn-hero">
    <div class="container-xl pn-hero-content w-100">
      <div class="row align-items-center g-5">

        {{-- Left: Copy --}}
        <div class="col-lg-5">
          <div class="pn-hero-eyebrow">
            <i class="ti ti-sparkles" style="font-size:12px"></i>
            TEKNOFEST Hackathon 2026
          </div>
          <h1 class="pn-hero-title">
            Paranızı<br>
            <span class="grad-text">Yapay Zeka</span><br>
            ile Yönetin
          </h1>
          <p class="pn-hero-sub">
            Tüm banka hesaplarınızı tek platformda görün. Kişisel enflasyonunuzu gerçek TÜİK verileriyle ölçün. AI ajanlarıyla finansal kararlarınızı optimize edin.
          </p>
          <div class="pn-hero-ctas">
            @auth
              <a href="{{ route('dashboard') }}" class="pn-btn-primary">
                <i class="ti ti-layout-dashboard" style="font-size:16px"></i> Panele Git
              </a>
            @else
              <a href="{{ route('register') }}" class="pn-btn-primary">
                <i class="ti ti-rocket" style="font-size:16px"></i> Ücretsiz Başla
              </a>
              <a href="{{ route('login') }}" class="pn-btn-secondary">Giriş Yap</a>
            @endauth
          </div>
          <div class="pn-stat-row">
            <div class="pn-stat">
              <span class="pn-stat-ico">🏦</span>
              <div>
                <span class="pn-stat-val">8 Banka</span>
                <span class="pn-stat-lbl">Destekleniyor</span>
              </div>
            </div>
            <div class="pn-stat">
              <span class="pn-stat-ico">🤖</span>
              <div>
                <span class="pn-stat-val">5 AI Ajan</span>
                <span class="pn-stat-lbl">Paralel Çalışır</span>
              </div>
            </div>
            <div class="pn-stat">
              <span class="pn-stat-ico">📊</span>
              <div>
                <span class="pn-stat-val">TÜİK Verisi</span>
                <span class="pn-stat-lbl">Gerçek Zamanlı</span>
              </div>
            </div>
          </div>
        </div>

        {{-- Right: Dashboard mockup --}}
        <div class="col-lg-7 d-none d-lg-block" style="position:relative;">
          <div class="pn-mockup">
            <div class="pn-mockup-bar">
              <div class="pn-dot" style="background:#EF4444"></div>
              <div class="pn-dot" style="background:#F59E0B"></div>
              <div class="pn-dot" style="background:#10B981"></div>
              <div style="flex:1;text-align:center;font-size:.68rem;color:rgba(255,255,255,.3)">Paranette — Finansal Panel</div>
            </div>
            <div class="pn-mockup-body">
              <div class="row g-2 mb-3">
                <div class="col-6">
                  <div class="pn-mini-card">
                    <div class="pn-mini-card-lbl">Toplam Bakiye</div>
                    <div class="pn-mini-card-val" style="color:#34D399">₺48.240</div>
                    <div class="pn-mini-bar"><div class="pn-mini-bar-fill" style="background:#10B981;width:72%"></div></div>
                  </div>
                </div>
                <div class="col-6">
                  <div class="pn-mini-card">
                    <div class="pn-mini-card-lbl">Kişisel Enflasyon</div>
                    <div class="pn-mini-card-val" style="color:#FCD34D">%42.8</div>
                    <div class="pn-mini-bar"><div class="pn-mini-bar-fill" style="background:#F59E0B;width:58%"></div></div>
                  </div>
                </div>
                <div class="col-6">
                  <div class="pn-mini-card">
                    <div class="pn-mini-card-lbl">Finansal Sağlık</div>
                    <div class="pn-mini-card-val" style="color:#60A5FA">74/100</div>
                    <div class="pn-mini-bar"><div class="pn-mini-bar-fill" style="background:#3B82F6;width:74%"></div></div>
                  </div>
                </div>
                <div class="col-6">
                  <div class="pn-mini-card">
                    <div class="pn-mini-card-lbl">Net Varlık</div>
                    <div class="pn-mini-card-val" style="color:#34D399">₺31.540</div>
                    <div class="pn-mini-bar"><div class="pn-mini-bar-fill" style="background:#10B981;width:65%"></div></div>
                  </div>
                </div>
              </div>

              {{-- Mini chart mockup bars --}}
              <div style="background:rgba(255,255,255,.03);border:1px solid rgba(255,255,255,.06);border-radius:10px;padding:14px;margin-bottom:8px">
                <div style="font-size:.66rem;color:var(--slate);margin-bottom:10px;">Nakit Akışı — Son 6 Ay</div>
                <div style="display:flex;align-items:flex-end;gap:8px;height:48px;">
                  @foreach([38,55,44,72,60,84] as $h)
                  <div style="flex:1;border-radius:4px 4px 0 0;background:rgba(59,130,246,.3);height:{{ $h }}%"></div>
                  @endforeach
                  @foreach([28,45,38,52,40,62] as $h)
                  <div style="flex:1;border-radius:4px 4px 0 0;background:rgba(239,68,68,.25);height:{{ $h }}%"></div>
                  @endforeach
                </div>
              </div>

              {{-- AI insight preview --}}
              <div style="background:rgba(139,92,246,.08);border:1px solid rgba(139,92,246,.15);border-radius:10px;padding:10px 12px;display:flex;align-items:center;gap:8px;">
                <i class="ti ti-sparkles" style="font-size:14px;color:#C4B5FD"></i>
                <span style="font-size:.72rem;color:rgba(255,255,255,.55)">AI: <strong style="color:rgba(255,255,255,.8)">Bu ay lokanta harcamaların %31 arttı</strong></span>
              </div>
            </div>
          </div>

          {{-- Floating badges --}}
          <div class="pn-glow-badge" style="top:-18px;right:40px;">
            <i class="ti ti-robot" style="font-size:14px"></i> 5 Ajan Aktif
          </div>
          <div class="pn-glow-badge" style="bottom:-16px;left:20px;background:rgba(59,130,246,.15);border-color:rgba(59,130,246,.3);color:#93C5FD">
            <i class="ti ti-building-bank" style="font-size:14px"></i> 4 Banka Bağlı
          </div>
        </div>

      </div>
    </div>
  </section>

  {{-- Trust bar --}}
  <div class="pn-trust">
    <div class="container-xl">
      <div class="pn-trust-row">
        <div class="pn-trust-item">
          <i class="ti ti-shield-check pn-trust-ico"></i>
          <span class="pn-trust-text"><span class="pn-trust-num">Mock Banka API</span> — Gerçekçi Test Verisi</span>
        </div>
        <div class="pn-trust-item">
          <i class="ti ti-brain pn-trust-ico"></i>
          <span class="pn-trust-text"><span class="pn-trust-num">Gemini 2.5 Pro</span> & Flash Destekli</span>
        </div>
        <div class="pn-trust-item">
          <i class="ti ti-chart-infographic pn-trust-ico"></i>
          <span class="pn-trust-text"><span class="pn-trust-num">TÜİK EVDS</span> Gerçek Enflasyon Verisi</span>
        </div>
        <div class="pn-trust-item">
          <i class="ti ti-device-mobile pn-trust-ico"></i>
          <span class="pn-trust-text"><span class="pn-trust-num">Flutter</span> Mobil Uygulama</span>
        </div>
      </div>
    </div>
  </div>

  {{-- ══════════════════════════════════════════════════════════
       FEATURES GRID
  ═══════════════════════════════════════════════════════════ --}}
  <section class="pn-section">
    <div class="container-xl">
      <div class="text-center mb-5">
        <div class="pn-section-eyebrow ey-blue" style="display:inline-flex">
          <i class="ti ti-layout-grid" style="font-size:12px"></i> Özellikler
        </div>
        <h2 class="pn-section-title">Her Şey Bir Arada</h2>
        <p class="pn-section-sub mx-auto">Finansal hayatınızı yönetmek için ihtiyacınız olan tüm araçlar tek platformda</p>
      </div>

      <div class="row g-4">
        <div class="col-md-6 col-lg-4">
          <div class="pn-feat-card fc-blue">
            <div class="pn-feat-ico fi-blue"><i class="ti ti-building-bank"></i></div>
            <h3 class="pn-feat-title">Banka Hesap Takibi</h3>
            <p class="pn-feat-body">Tüm banka hesaplarınızı, kredi kartlarınızı ve kredilerinizi tek ekranda görün. Ziraat, Garanti, İşbank, Akbank desteği. Anlık bakiye senkronizasyonu.</p>
          </div>
        </div>
        <div class="col-md-6 col-lg-4">
          <div class="pn-feat-card fc-amber">
            <div class="pn-feat-ico fi-amber"><i class="ti ti-trending-up"></i></div>
            <h3 class="pn-feat-title">Kişisel Enflasyon</h3>
            <p class="pn-feat-body">TÜİK kategori verileriyle harcama profilinizi eşleştirerek gerçek kişisel enflasyonunuzu hesaplayın. Manşet TÜFE'den nasıl farklılaştığınızı görün.</p>
          </div>
        </div>
        <div class="col-md-6 col-lg-4">
          <div class="pn-feat-card fc-green">
            <div class="pn-feat-ico fi-green"><i class="ti ti-adjustments-horizontal"></i></div>
            <h3 class="pn-feat-title">Karar Simülatörü</h3>
            <p class="pn-feat-body">"Gelirimi %20 artırsam ne olur?" Kaydırıcılarla farklı senaryolar oluşturun, bakiye projeksiyonunuzu ve finansal sağlık skorunuzu anında görün.</p>
          </div>
        </div>
        <div class="col-md-6 col-lg-4">
          <div class="pn-feat-card fc-red">
            <div class="pn-feat-ico fi-red"><i class="ti ti-message-2-dollar"></i></div>
            <h3 class="pn-feat-title">Pazarlık Ajanı</h3>
            <p class="pn-feat-body">Faiz indirimi veya kredi yeniden yapılandırma için Gemini Pro, finansal durumunuza özel resmi müzakere mektubu hazırlar. Banka müzakerelerinde üstünlük sağlayın.</p>
          </div>
        </div>
        <div class="col-md-6 col-lg-4">
          <div class="pn-feat-card fc-cyan">
            <div class="pn-feat-ico fi-cyan"><i class="ti ti-receipt"></i></div>
            <h3 class="pn-feat-title">OCR Fiş Tarayıcı</h3>
            <p class="pn-feat-body">Fişinizi fotoğraflayın, Gemini Vision otomatik olarak tutarı, kategoriyi ve garanti bilgilerini çıkarsın. Nakit harcamalarınızı da takip edin.</p>
          </div>
        </div>
        <div class="col-md-6 col-lg-4">
          <div class="pn-feat-card fc-violet">
            <div class="pn-feat-ico fi-violet"><i class="ti ti-robot"></i></div>
            <h3 class="pn-feat-title">Çok-Ajan Asistan</h3>
            <p class="pn-feat-body">5 uzman AI ajanı paralel çalışır: Satın Alma Planlayıcı, Bütçe Danışmanı, Enflasyon Analisti, Anomali Dedektörü ve İşlem Sınıflandırıcı.</p>
          </div>
        </div>
      </div>
    </div>
  </section>

  <div class="pn-divider"></div>

  {{-- ══════════════════════════════════════════════════════════
       KİŞİSEL ENFLASYON HIGHLIGHT
  ═══════════════════════════════════════════════════════════ --}}
  <section class="pn-section">
    <div class="container-xl">
      <div class="pn-inf-section">
        <div class="row align-items-center g-5">
          <div class="col-lg-5">
            <div class="pn-section-eyebrow ey-amber" style="display:inline-flex;margin-bottom:16px">
              <i class="ti ti-flame" style="font-size:12px"></i> Killer Feature
            </div>
            <div class="pn-inf-big-num">%42.8</div>
            <div style="font-size:1rem;font-weight:700;color:rgba(255,255,255,.8);margin-bottom:8px">Senin Gerçek Enflasyonun</div>
            <p style="font-size:.85rem;color:rgba(255,255,255,.45);line-height:1.7;margin-bottom:16px">
              Manşet TÜFE <strong style="color:#FCD34D">%37.9</strong> gösterse de harcama alışkanlıklarınıza göre siz <strong style="color:#FCA5A5">4.9 puan daha fazla</strong> etkileniyorsunuz. Konut ve eğitim harcamalarınız yüksek ağırlık taşıyor.
            </p>
            <div class="pn-inf-legend">
              <div class="pn-inf-leg-item">
                <div class="pn-inf-leg-dot" style="background:#FCD34D"></div>
                <span style="color:rgba(255,255,255,.5)">Kişisel <strong style="color:#FCD34D">%42.8</strong></span>
              </div>
              <div class="pn-inf-leg-item">
                <div class="pn-inf-leg-dot" style="background:rgba(255,255,255,.3)"></div>
                <span style="color:rgba(255,255,255,.5)">TÜFE <strong style="color:rgba(255,255,255,.6)">%37.9</strong></span>
              </div>
            </div>
          </div>
          <div class="col-lg-7">
            <div style="font-size:.68rem;font-weight:600;color:rgba(255,255,255,.35);text-transform:uppercase;letter-spacing:.09em;margin-bottom:14px">
              Harcama Kategorisi × TÜİK Enflasyonu
            </div>
            @php
              $infCats = [
                ['name'=>'Konut & Kira',    'pct'=>82, 'rate'=>59.1],
                ['name'=>'Eğitim',          'pct'=>75, 'rate'=>75.3],
                ['name'=>'Lokanta & Kafe',  'pct'=>60, 'rate'=>43.5],
                ['name'=>'Alkol / Sigara',  'pct'=>42, 'rate'=>42.3],
                ['name'=>'Ulaşım',          'pct'=>38, 'rate'=>31.6],
                ['name'=>'Genel TÜFE',      'pct'=>37, 'rate'=>37.9],
              ];
            @endphp
            <div class="pn-cat-list">
              @foreach($infCats as $cat)
              <div class="pn-cat-row">
                <span class="pn-cat-name">{{ $cat['name'] }}</span>
                <div class="pn-cat-track"><div class="pn-cat-fill" style="width:{{ $cat['pct'] }}%"></div></div>
                <span class="pn-cat-pct">%{{ number_format($cat['rate'],1,',','.') }}</span>
              </div>
              @endforeach
            </div>
            <a href="{{ route('inflation.index') }}" class="pn-btn-secondary mt-4" style="font-size:.8rem;padding:9px 20px;display:inline-flex">
              <i class="ti ti-chart-bar" style="font-size:15px"></i> Kişisel Enflasyonumu Hesapla
            </a>
          </div>
        </div>
      </div>
    </div>
  </section>

  <div class="pn-divider"></div>

  {{-- ══════════════════════════════════════════════════════════
       AI MİMARİSİ
  ═══════════════════════════════════════════════════════════ --}}
  <section class="pn-section">
    <div class="container-xl">
      <div class="row align-items-center g-5">

        <div class="col-lg-5">
          <div class="pn-section-eyebrow ey-violet" style="display:inline-flex;margin-bottom:16px">
            <i class="ti ti-brain" style="font-size:12px"></i> Yapay Zeka Mimarisi
          </div>
          <h2 class="pn-section-title">Paralel Çalışan<br>Uzman Ajanlar</h2>
          <p class="pn-section-sub mb-4">
            Google Gemini 2.5 Pro & Flash tabanlı orkestratör sorgunuzu analiz eder, en uygun uzman ajanları paralel tetikler. Saniyeler içinde kapsamlı finansal analiz.
          </p>
          <div style="margin-bottom:8px">
            <span class="pn-agent-chip">
              <i class="ti ti-shopping-cart" style="color:#60A5FA"></i> Satın Alma Planlayıcı
            </span>
            <span class="pn-agent-chip">
              <i class="ti ti-chart-pie" style="color:#6EE7B7"></i> Bütçe Danışmanı
            </span>
            <span class="pn-agent-chip">
              <i class="ti ti-trending-up" style="color:#FCD34D"></i> Enflasyon Analisti
            </span>
            <span class="pn-agent-chip">
              <i class="ti ti-alert-triangle" style="color:#FCA5A5"></i> Anomali Dedektörü
            </span>
            <span class="pn-agent-chip">
              <i class="ti ti-tag" style="color:#67E8F9"></i> İşlem Sınıflandırıcı
            </span>
          </div>

          {{-- Orchestrator flow --}}
          <div class="pn-ai-arch mt-4" style="padding:20px 24px">
            <div style="font-size:.7rem;font-weight:600;color:rgba(255,255,255,.35);text-transform:uppercase;letter-spacing:.08em;margin-bottom:12px">Akış</div>
            <div style="display:flex;align-items:center;gap:10px;font-size:.78rem;flex-wrap:wrap">
              <div style="background:rgba(59,130,246,.15);border:1px solid rgba(59,130,246,.25);border-radius:8px;padding:5px 10px;color:#93C5FD">Kullanıcı Sorusu</div>
              <i class="ti ti-arrow-right" style="color:var(--slate)"></i>
              <div style="background:rgba(139,92,246,.15);border:1px solid rgba(139,92,246,.25);border-radius:8px;padding:5px 10px;color:#C4B5FD">Orkestratör</div>
              <i class="ti ti-arrow-right" style="color:var(--slate)"></i>
              <div style="background:rgba(16,185,129,.12);border:1px solid rgba(16,185,129,.2);border-radius:8px;padding:5px 10px;color:#6EE7B7">Uzman Ajanlar</div>
              <i class="ti ti-arrow-right" style="color:var(--slate)"></i>
              <div style="background:rgba(245,158,11,.12);border:1px solid rgba(245,158,11,.2);border-radius:8px;padding:5px 10px;color:#FCD34D">Yanıt</div>
            </div>
          </div>
        </div>

        {{-- Chat demo --}}
        <div class="col-lg-7">
          <div class="pn-chat">
            <div class="pn-chat-header">
              <div class="pn-chat-avatar"><i class="ti ti-robot"></i></div>
              <div>
                <div class="pn-chat-name">Paranette AI</div>
                <div style="font-size:.65rem;color:var(--slate)">Gemini 2.5 Pro</div>
              </div>
              <div class="pn-online-dot" style="margin-left:auto"></div>
            </div>
            <div class="pn-chat-body">
              <div class="pn-msg">
                <div class="pn-msg-user">50.000 TL'ye iPhone almak istiyorum, uygun mu?</div>
              </div>
              <div class="pn-msg">
                <div class="pn-agents-used">
                  <span class="pn-tag tag-blue">Satın Alma Planlayıcı</span>
                  <span class="pn-tag tag-amber">Bütçe Danışmanı</span>
                  <span class="pn-tag tag-violet">Anomali Dedektörü</span>
                </div>
                <div class="pn-msg-agent-wrap">
                  <div class="pn-msg-agent-ico"><i class="ti ti-robot"></i></div>
                  <div class="pn-msg-agent">
                    Mevcut aylık tasarruf oranınız <strong>%14.2</strong>. Bu alım <strong>3.8 aylık</strong> birikiminize eşit. Acil fonunuz minimum seviyenin üzerinde olsa da 12 taksit seçeneği ile <strong>%31 daha az faiz yükü</strong> oluşur.<br><br>
                    Alternatif: 6 ay bekleyip <strong style="color:#6EE7B7">₺8.200 tasarruf</strong> edin veya fiyat düşüşünü bekleyin. Kişisel enflasyonunuz <strong style="color:#FCD34D">%42.8</strong> olduğundan ertelemek riskli olabilir.
                  </div>
                </div>
              </div>
              <div style="text-align:center;font-size:.68rem;color:rgba(255,255,255,.2);padding-top:4px">
                Paralel ajan süresi: 1.4 saniye
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  </section>

  <div class="pn-divider"></div>

  {{-- ══════════════════════════════════════════════════════════
       CTA
  ═══════════════════════════════════════════════════════════ --}}
  <section class="pn-section-sm">
    <div class="container-xl">
      <div class="pn-cta">
        <h2 class="pn-cta-title">Finansal Özgürlüğe<br>Bugün Başlayın</h2>
        <p class="pn-cta-sub">Banka hesaplarınızı bağlayın · AI ajanlarınızı aktive edin · Hedeflerinize ulaşın</p>
        <div class="pn-cta-actions">
          @auth
            <a href="{{ route('dashboard') }}" class="pn-btn-primary" style="font-size:.9rem;padding:12px 32px">
              <i class="ti ti-layout-dashboard" style="font-size:16px"></i> Panele Git
            </a>
          @else
            <a href="{{ route('register') }}" class="pn-btn-primary" style="font-size:.9rem;padding:12px 32px">
              <i class="ti ti-rocket" style="font-size:16px"></i> Ücretsiz Başla
            </a>
            <a href="{{ route('login') }}" class="pn-btn-secondary" style="font-size:.9rem;padding:12px 28px">Giriş Yap</a>
          @endauth
        </div>
      </div>
    </div>
  </section>

  {{-- ══════════════════════════════════════════════════════════
       FOOTER
  ═══════════════════════════════════════════════════════════ --}}
  <footer class="pn-footer">
    <div class="pn-footer-brand">
      <svg width="20" height="14" viewBox="0 0 32 22" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path fill-rule="evenodd" clip-rule="evenodd" d="M0.00172773 0V6.85398C0.00172773 6.85398 -0.133178 9.01207 1.98092 10.8388L13.6912 21.9964L19.7809 21.9181L18.8042 9.88248L16.4951 7.17289L9.23799 0H0.00172773Z" fill="#10B981"/>
        <path fill-rule="evenodd" clip-rule="evenodd" d="M7.77295 16.3566L23.6563 0H32V6.88383C32 6.88383 31.8262 9.17836 30.6591 10.4057L19.7824 22H13.6938L7.77295 16.3566Z" fill="#10B981"/>
      </svg>
      <span class="pn-footer-text"><strong style="color:rgba(255,255,255,.5)">Paranette</strong> &copy; {{ date('Y') }} — TEKNOFEST Hackathon 2026</span>
    </div>
    <div class="pn-footer-stack">
      <span class="pn-stack-tag">Laravel 13</span>
      <span class="pn-stack-tag">PHP 8.3</span>
      <span class="pn-stack-tag">Gemini 2.5</span>
      <span class="pn-stack-tag">TÜİK EVDS</span>
      <span class="pn-stack-tag">Flutter</span>
    </div>
  </footer>

</div>{{-- .pn-page --}}

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
