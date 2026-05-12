<x-app-layout>
  <x-slot name="title">Kişisel Enflasyon</x-slot>

  {{-- ══ Page CSS ════════════════════════════════════════════════════════════ --}}
  <x-slot name="pageCss">
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/apex-charts/apex-charts.css') }}">
    <style>
      /* ── Hero comparison card ────────────────────────────────────────────── */
      .inflation-hero {
        background: linear-gradient(135deg, #1e1b4b 0%, #3730a3 40%, #7c3aed 100%);
        border-radius: .875rem;
        color: #fff;
        position: relative;
        overflow: hidden;
      }
      .inflation-hero::before {
        content: '';
        position: absolute;
        top: -70px; right: -70px;
        width: 240px; height: 240px;
        background: rgba(255,255,255,.06);
        border-radius: 50%;
        pointer-events: none;
      }
      .inflation-hero::after {
        content: '';
        position: absolute;
        bottom: -90px; left: 30%;
        width: 280px; height: 280px;
        background: rgba(255,255,255,.04);
        border-radius: 50%;
        pointer-events: none;
      }
      .hero-rate-personal {
        font-size: 3.8rem;
        font-weight: 800;
        line-height: 1;
        letter-spacing: -.03em;
      }
      .hero-rate-official {
        font-size: 2rem;
        font-weight: 700;
        line-height: 1;
        opacity: .75;
      }
      .hero-diff-badge {
        display: inline-flex;
        align-items: center;
        gap: .35rem;
        padding: .35rem .75rem;
        border-radius: 999px;
        font-size: .82rem;
        font-weight: 700;
        backdrop-filter: blur(8px);
      }
      .hero-diff-up   { background: rgba(234, 84, 85, .25); border: 1px solid rgba(234,84,85,.4); color: #ffb3b3; }
      .hero-diff-down { background: rgba(40,199,111,.25);   border: 1px solid rgba(40,199,111,.4); color: #b3ffd1; }
      .hero-diff-same { background: rgba(255,255,255,.12);  border: 1px solid rgba(255,255,255,.2); color: #fff; }
      .hero-divider {
        border: none;
        border-top: 1px solid rgba(255,255,255,.18);
        margin: 1rem 0;
      }

      /* ── Severity ring around gauge card ─────────────────────────────────── */
      .gauge-card {
        transition: box-shadow .2s;
      }
      .gauge-card:hover {
        box-shadow: 0 8px 28px rgba(115,103,240,.18) !important;
      }
      .gauge-severity-green  { border-top: 4px solid #28C76F !important; }
      .gauge-severity-yellow { border-top: 4px solid #FF9F43 !important; }
      .gauge-severity-red    { border-top: 4px solid #EA5455 !important; }

      /* ── Purchasing power widget ──────────────────────────────────────────── */
      .pp-widget {
        background: linear-gradient(135deg, #0f2027 0%, #203a43 50%, #2c5364 100%);
        border-radius: .875rem;
        color: #fff;
        position: relative;
        overflow: hidden;
      }
      .pp-widget::after {
        content: '';
        position: absolute;
        bottom: -60px; right: -60px;
        width: 180px; height: 180px;
        background: rgba(255,255,255,.04);
        border-radius: 50%;
        pointer-events: none;
      }
      .pp-amount-now  { font-size: 2rem; font-weight: 800; line-height: 1; }
      .pp-amount-was  { font-size: 1rem; opacity: .65; }
      .pp-loss-badge {
        display: inline-flex;
        align-items: center;
        gap: .3rem;
        padding: .3rem .65rem;
        border-radius: 999px;
        font-size: .78rem;
        font-weight: 600;
        background: rgba(234,84,85,.25);
        border: 1px solid rgba(234,84,85,.4);
        color: #ffb3b3;
      }

      /* ── Category contribution bar ────────────────────────────────────────── */
      .contrib-bar-bg   { background: var(--bs-secondary-bg); border-radius: 4px; height: 7px; overflow: hidden; }
      .contrib-bar-fill { height: 7px; border-radius: 4px; transition: width .55s ease; }
      .contrib-row { transition: background .15s; border-radius: .5rem; padding: .5rem .25rem; }
      .contrib-row:hover { background: var(--bs-tertiary-bg); }

      /* ── Stat mini cards ──────────────────────────────────────────────────── */
      .mini-stat { transition: transform .18s, box-shadow .18s; }
      .mini-stat:hover { transform: translateY(-3px); box-shadow: 0 8px 24px rgba(115,103,240,.14) !important; }

      /* ── Tips card ────────────────────────────────────────────────────────── */
      .tip-item { padding: .75rem 1rem; border-radius: .5rem; transition: background .15s; }
      .tip-item:hover { background: var(--bs-secondary-bg); }
      .tip-item + .tip-item { border-top: 1px solid var(--bs-border-color); }

      /* ── Dark mode tweaks ────────────────────────────────────────────────── */
      [data-bs-theme="dark"] .pp-widget {
        background: linear-gradient(135deg, #0d1117 0%, #161b22 50%, #1c2a36 100%);
      }
    </style>
  </x-slot>

  {{-- ══ Page Header ════════════════════════════════════════════════════════ --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Kişisel Enflasyon</h4>
      <p class="text-muted small mb-0">
        <i class="icon-base ti tabler-calendar-stats me-1"></i>
        {{ $periodLabel }} TÜİK verisiyle hesaplanan harcama profili
      </p>
    </div>
    <span class="badge bg-label-warning fs-6 fw-semibold">
      <i class="icon-base ti tabler-building-bank me-1"></i>TÜİK Kaynaklı
    </span>
  </div>

  @php
    /* ── Severity helpers ─────────────────────────────────────────────────── */
    $severity       = $personalRate < 30 ? 'green' : ($personalRate < 50 ? 'yellow' : 'red');
    $severityColor  = $severity === 'green' ? '#28C76F' : ($severity === 'yellow' ? '#FF9F43' : '#EA5455');
    $severityLabel  = $severity === 'green' ? 'Kontrol Altında' : ($severity === 'yellow' ? 'Dikkat Gerekiyor' : 'Yüksek Risk');
    $severityBadge  = $severity === 'green' ? 'success' : ($severity === 'yellow' ? 'warning' : 'danger');

    /* ── Purchasing power ─────────────────────────────────────────────────── */
    $baseTRY        = 10000;
    $ppNow          = round($baseTRY / (1 + $personalRate / 100), 2);
    $ppLoss         = $baseTRY - $ppNow;
    $ppLossPct      = round($ppLoss / $baseTRY * 100, 1);

    /* ── Category slug → human label map ─────────────────────────────────── */
    $slugLabels = [
      'gida-alkolsuz-icecekler'  => 'Gıda & İçecek',
      'konut-kira'               => 'Konut & Kira',
      'ulasim'                   => 'Ulaşım',
      'lokanta-otel'             => 'Lokanta & Otel',
      'egitim'                   => 'Eğitim',
      'saglik'                   => 'Sağlık',
      'giyim-ayakkabi'           => 'Giyim & Ayakkabı',
      'haberlesme'               => 'Haberleşme',
      'eglence-kultur'           => 'Eğlence & Kültür',
      'ev-esyalari'              => 'Ev Eşyaları',
      'alkol-tutun'              => 'Alkol & Tütün',
      'cesitli-mal-hizmet'       => 'Çeşitli Hizmetler',
      'diger'                    => 'Diğer',
    ];
    $getCatLabel = fn($slug) => $slugLabels[$slug] ?? ucwords(str_replace('-', ' ', $slug));

    /* ── Category slug → icon map ─────────────────────────────────────────── */
    $slugIcons = [
      'gida-alkolsuz-icecekler'  => 'tabler-salad',
      'konut-kira'               => 'tabler-home-2',
      'ulasim'                   => 'tabler-car',
      'lokanta-otel'             => 'tabler-tools-kitchen-2',
      'egitim'                   => 'tabler-school',
      'saglik'                   => 'tabler-heart-rate-monitor',
      'giyim-ayakkabi'           => 'tabler-shirt',
      'haberlesme'               => 'tabler-device-mobile',
      'eglence-kultur'           => 'tabler-device-tv',
      'ev-esyalari'              => 'tabler-armchair',
      'alkol-tutun'              => 'tabler-bottle',
      'cesitli-mal-hizmet'       => 'tabler-dots-circle-horizontal',
      'diger'                    => 'tabler-category-2',
    ];
    $getCatIcon = fn($slug) => $slugIcons[$slug] ?? 'tabler-tag';

    /* ── Top driver category ────────────────────────────────────────────────── */
    $topSlug = $topImpact['slug'] ?? null;
  @endphp

  {{-- ══ ROW 1 — Hero + Gauge ══════════════════════════════════════════════ --}}
  <div class="row g-5 mb-6">

    {{-- ── Hero comparison card ──────────────────────────────────────────── --}}
    <div class="col-xl-7">
      <div class="inflation-hero p-5 h-100">
        <div class="row g-4 align-items-center h-100">

          {{-- Personal rate --}}
          <div class="col-sm-6">
            <div class="small fw-semibold opacity-65 text-uppercase mb-2" style="letter-spacing:.06em;">
              <i class="icon-base ti tabler-user me-1"></i>Kişisel Enflasyonun
            </div>
            <div class="hero-rate-personal mb-3">
              %{{ number_format($personalRate, 1, ',', '.') }}
            </div>
            @if($personalDelta > 0)
              <span class="hero-diff-badge hero-diff-up">
                <i class="icon-base ti tabler-arrow-up-right"></i>
                TÜFE'den +%{{ number_format(abs($personalDelta), 2, ',', '.') }} yüksek
              </span>
            @elseif($personalDelta < 0)
              <span class="hero-diff-badge hero-diff-down">
                <i class="icon-base ti tabler-arrow-down-right"></i>
                TÜFE'den -%{{ number_format(abs($personalDelta), 2, ',', '.') }} düşük
              </span>
            @else
              <span class="hero-diff-badge hero-diff-same">
                <i class="icon-base ti tabler-equal"></i>
                TÜFE ile aynı seviyede
              </span>
            @endif
          </div>

          {{-- Divider (visible on sm+) --}}
          <div class="col-sm-auto d-none d-sm-flex align-items-center">
            <div style="width:1px;height:100px;background:rgba(255,255,255,.2);"></div>
          </div>
          <hr class="hero-divider d-sm-none">

          {{-- Official rate --}}
          <div class="col-sm">
            <div class="small fw-semibold opacity-65 text-uppercase mb-2" style="letter-spacing:.06em;">
              <i class="icon-base ti tabler-building-bank me-1"></i>Resmi TÜFE
            </div>
            <div class="hero-rate-official mb-2">
              %{{ number_format($headline, 2, ',', '.') }}
            </div>
            <div class="small opacity-65 mb-3">{{ $periodLabel }}</div>
            <div class="d-flex align-items-center gap-2">
              <span class="badge bg-label-{{ $severityBadge }} fw-semibold">
                <i class="icon-base ti tabler-shield me-1"></i>{{ $severityLabel }}
              </span>
            </div>
          </div>

        </div>

        <hr class="hero-divider mt-4">

        {{-- Bottom quick stats --}}
        <div class="row g-3">
          <div class="col-4">
            <div class="opacity-60" style="font-size:.73rem;">Analiz Dönemi</div>
            <div class="fw-semibold small">Son 90 gün</div>
          </div>
          <div class="col-4 text-center">
            <div class="opacity-60" style="font-size:.73rem;">Toplam Harcama</div>
            <div class="fw-semibold small">
              ₺{{ $totalSpend > 0 ? number_format($totalSpend, 0, ',', '.') : '—' }}
            </div>
          </div>
          <div class="col-4 text-end">
            <div class="opacity-60" style="font-size:.73rem;">Etkilenen Kategori</div>
            <div class="fw-semibold small">{{ count($personalBreakdown) > 0 ? count($personalBreakdown) . ' kategori' : '—' }}</div>
          </div>
        </div>
      </div>
    </div>

    {{-- ── Gauge + Purchasing power ────────────────────────────────────────── --}}
    <div class="col-xl-5">
      <div class="row g-5 h-100">

        {{-- Gauge card --}}
        <div class="col-12">
          <div class="card gauge-card gauge-severity-{{ $severity }} h-100">
            <div class="card-body d-flex flex-column align-items-center justify-content-center py-4">
              <div class="small fw-semibold text-muted text-uppercase mb-2" style="letter-spacing:.06em;">
                Kişisel Enflasyon Skoru
              </div>
              <div id="gaugeChart" style="min-height:180px;width:220px;"></div>
              <div class="mt-1 text-center">
                <span class="badge bg-label-{{ $severityBadge }} fs-6 px-3 py-2">
                  <i class="icon-base ti tabler-{{ $severity === 'green' ? 'circle-check' : ($severity === 'yellow' ? 'alert-triangle' : 'flame') }} me-1"></i>
                  {{ $severityLabel }}
                </span>
                <div class="text-muted small mt-2">
                  @if($severity === 'green')
                    Enflasyon baskısı düşük. Harcama profilin sağlıklı.
                  @elseif($severity === 'yellow')
                    Bazı kategoriler bütçeni zorlayabilir.
                  @else
                    Enflasyon baskısı yüksek — önlem almak önemli.
                  @endif
                </div>
              </div>
            </div>
          </div>
        </div>

        {{-- Purchasing power widget --}}
        <div class="col-12">
          <div class="pp-widget p-4">
            <div class="d-flex align-items-start justify-content-between mb-3">
              <div>
                <div class="small fw-semibold opacity-65 text-uppercase mb-1" style="letter-spacing:.06em;">
                  <i class="icon-base ti tabler-coin me-1"></i>Satın Alma Gücü
                </div>
                <div class="opacity-60 small">12 ay önceki ₺10.000 bugün</div>
              </div>
              <span class="pp-loss-badge">
                <i class="icon-base ti tabler-trending-down"></i>
                -%{{ $ppLossPct }}
              </span>
            </div>
            <div class="pp-amount-now mb-1">
              ₺{{ number_format($ppNow, 0, ',', '.') }}
            </div>
            <div class="pp-amount-was mb-3">değer kaybetti — ₺{{ number_format($ppLoss, 0, ',', '.') }} eridi</div>
            <div class="progress" style="height:6px;border-radius:6px;background:rgba(255,255,255,.12);">
              <div class="progress-bar"
                   style="width:{{ round($ppNow / $baseTRY * 100) }}%;
                          background:linear-gradient(90deg,{{ $severityColor }},rgba(255,255,255,.6));
                          border-radius:6px;height:6px;"></div>
            </div>
            <div class="d-flex justify-content-between opacity-55 mt-1" style="font-size:.72rem;">
              <span>₺0</span>
              <span>₺{{ number_format($baseTRY, 0, ',', '.') }}</span>
            </div>
          </div>
        </div>

      </div>
    </div>

  </div>

  {{-- ══ ROW 2 — Category breakdown + Official category chart ══════════════ --}}
  <div class="row g-5 mb-6">

    {{-- ── Personal category contribution (left) ──────────────────────────── --}}
    <div class="col-xl-5">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between py-3">
          <div>
            <h5 class="card-title mb-0">
              <i class="icon-base ti tabler-chart-bar-popular me-2 text-primary"></i>Kişisel Enflasyon Katkısı
            </h5>
            <small class="text-muted">Harcama ağırlıklı kategori etkisi</small>
          </div>
          @if(count($personalBreakdown))
            <span class="badge bg-label-primary">{{ count($personalBreakdown) }} kat.</span>
          @endif
        </div>
        <div class="card-body">
          @if(count($personalBreakdown))
            @php $maxImpact = collect($personalBreakdown)->max('impact') ?: 1; @endphp

            <div id="contribBarChart" style="min-height:260px;" class="mb-4"></div>

            <div class="mt-1">
              @foreach($personalBreakdown as $item)
              @php
                $impact     = $item['impact'];
                $barColor   = $impact > 15 ? '#EA5455' : ($impact > 8 ? '#FF9F43' : '#28C76F');
                $badgeClass = $impact > 15 ? 'danger'  : ($impact > 8 ? 'warning'  : 'success');
                $catLabel   = $getCatLabel($item['slug']);
                $catIcon    = $getCatIcon($item['slug']);
                $barWidth   = round($impact / $maxImpact * 100);
              @endphp
              <div class="contrib-row mb-1">
                <div class="d-flex align-items-center justify-content-between mb-1 gap-2">
                  <div class="d-flex align-items-center gap-2 overflow-hidden">
                    <span class="avatar avatar-xs flex-shrink-0">
                      <span class="avatar-initial rounded bg-label-{{ $badgeClass }}">
                        <i class="icon-base ti {{ $catIcon }}" style="font-size:.75rem;"></i>
                      </span>
                    </span>
                    <span class="fw-medium small text-truncate">{{ $catLabel }}</span>
                    <span class="badge bg-label-secondary flex-shrink-0" style="font-size:.65rem;">
                      %{{ number_format($item['weight'], 0) }}
                    </span>
                  </div>
                  <div class="d-flex align-items-center gap-2 flex-shrink-0">
                    <span class="text-muted small">%{{ number_format($item['rate'], 1, ',', '.') }}</span>
                    <span class="badge bg-label-{{ $badgeClass }} fw-bold" style="font-size:.68rem;">
                      +%{{ number_format($impact, 2, ',', '.') }}
                    </span>
                  </div>
                </div>
                <div class="contrib-bar-bg">
                  <div class="contrib-bar-fill" style="width:{{ $barWidth }}%;background:{{ $barColor }};"></div>
                </div>
              </div>
              @endforeach
            </div>

          @else
            <div class="d-flex flex-column align-items-center justify-content-center py-6 text-center">
              <div class="avatar avatar-lg mb-3">
                <span class="avatar-initial rounded-circle bg-label-secondary">
                  <i class="icon-base ti tabler-chart-bar icon-32px text-muted"></i>
                </span>
              </div>
              <h6 class="mb-1">Harcama Verisi Yok</h6>
              <p class="text-muted small mb-0">Son 90 günde kategorize edilmiş harcama bulunamadı.</p>
              <a href="{{ route('bank-connections.create') }}" class="btn btn-outline-primary btn-sm mt-3">
                <i class="icon-base ti tabler-building-bank me-1"></i>Banka Hesabı Bağla
              </a>
            </div>
          @endif
        </div>
      </div>
    </div>

    {{-- ── TÜİK official category bar chart (right) ────────────────────────── --}}
    <div class="col-xl-7">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between py-3">
          <div>
            <h5 class="card-title mb-0">
              <i class="icon-base ti tabler-chart-bar me-2 text-warning"></i>TÜİK Kategori Enflasyonları
            </h5>
            <small class="text-muted">{{ $periodLabel }} · Yıllık değişim %</small>
          </div>
          <span class="badge bg-label-warning">TÜİK Resmi</span>
        </div>
        <div class="card-body pt-2">
          @if($categoryRates->isNotEmpty())
            <div id="categoryChart" style="min-height:340px;"></div>
          @else
            <div class="d-flex flex-column align-items-center justify-content-center py-6 text-center">
              <i class="icon-base ti tabler-database-off icon-48px text-muted mb-3"></i>
              <p class="text-muted mb-0">Kategori verisi bulunamadı.</p>
            </div>
          @endif
        </div>
      </div>
    </div>

  </div>

  {{-- ══ ROW 3 — TÜFE Trend + Tips ═════════════════════════════════════════ --}}
  <div class="row g-5 mb-6">

    {{-- ── TÜFE historical trend (left) ────────────────────────────────────── --}}
    <div class="col-xl-8">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between py-3">
          <div>
            <h5 class="card-title mb-0">
              <i class="icon-base ti tabler-trending-up me-2 text-info"></i>Manşet TÜFE Tarihçesi
            </h5>
            <small class="text-muted">Son 12 ay · Yıllık değişim %</small>
          </div>
          @if($historical->isNotEmpty())
            @php
              $histFirst = $historical->first();
              $histLast  = $historical->last();
              $histDelta = round((float)$histLast->annual_change_rate - (float)$histFirst->annual_change_rate, 2);
            @endphp
            <span class="badge bg-label-{{ $histDelta <= 0 ? 'success' : 'danger' }}">
              <i class="icon-base ti tabler-arrow-{{ $histDelta <= 0 ? 'down' : 'up' }}-right me-1"></i>
              12ay: {{ $histDelta >= 0 ? '+' : '' }}%{{ $histDelta }}
            </span>
          @endif
        </div>
        <div class="card-body pt-0">
          @if($historical->isNotEmpty())
            <div id="historyChart" style="min-height:240px;"></div>
          @else
            <div class="d-flex flex-column align-items-center justify-content-center py-6 text-center">
              <i class="icon-base ti tabler-chart-line icon-48px text-muted mb-3"></i>
              <p class="text-muted mb-0">Tarihsel veri bulunamadı.</p>
            </div>
          @endif
        </div>
      </div>
    </div>

    {{-- ── Smart tips card (right) ──────────────────────────────────────────── --}}
    <div class="col-xl-4">
      <div class="card h-100">
        <div class="card-header py-3">
          <h5 class="card-title mb-0">
            <i class="icon-base ti tabler-bulb me-2 text-warning"></i>Akıllı Öneriler
          </h5>
          <small class="text-muted">Harcama profiline göre kişisel ipuçları</small>
        </div>
        <div class="card-body p-0">
          @php
            /* Build smart tips based on the top-impact categories */
            $tips = [];

            /* Always show top driver tip */
            if ($topImpact) {
              $tLabel = $getCatLabel($topImpact['slug']);
              $tips[] = [
                'icon'  => 'tabler-flame',
                'color' => 'danger',
                'title' => 'En Yüksek Etki: ' . $tLabel,
                'body'  => '"' . $tLabel . '" harcamaların %' . number_format($topImpact['weight'], 0)
                         . '\'ini oluşturuyor ve kişisel enflasyona +'
                         . number_format($topImpact['impact'], 2, ',', '.') . ' puan katkı sağlıyor.',
              ];
            }

            /* Purchasing power tip */
            $tips[] = [
              'icon'  => 'tabler-coin',
              'color' => 'warning',
              'title' => 'Satın Alma Gücü Kaybı',
              'body'  => '12 ay önce ayırdığın ₺10.000\'in bugünkü değeri ₺' . number_format($ppNow, 0, ',', '.') . '. '
                       . 'Enflasyonu aşan yatırım araçlarını değerlendirin.',
            ];

            /* Tip based on severity */
            if ($severity === 'red') {
              $tips[] = [
                'icon'  => 'tabler-alert-triangle',
                'color' => 'danger',
                'title' => 'Yüksek Enflasyon Baskısı',
                'body'  => 'Kişisel enflasyonun %' . number_format($personalRate, 1, ',', '.') . ' ile kritik eşiğin üzerinde. '
                         . 'Yüksek enflasyonlu kategorilerdeki harcamaları kısmayı değerlendirin.',
              ];
            } elseif ($severity === 'yellow') {
              $tips[] = [
                'icon'  => 'tabler-chart-line',
                'color' => 'warning',
                'title' => 'Orta Düzey Risk',
                'body'  => 'Enflasyondan etkilenme oranın ortalamanın üzerinde. Yüksek enflasyonlu kategorilerde alternatif tercihler tasarruf sağlayabilir.',
              ];
            } else {
              $tips[] = [
                'icon'  => 'tabler-circle-check',
                'color' => 'success',
                'title' => 'İyi Durumdayısın!',
                'body'  => 'Harcama profilin enflasyon baskısını düşük tutuyor. Bu dengeyi korumak için bütçe hedeflerini takip et.',
              ];
            }

            /* Resmi TÜFE vs personal delta tip */
            if ($personalDelta > 5) {
              $tips[] = [
                'icon'  => 'tabler-arrows-diff',
                'color' => 'info',
                'title' => 'TÜFE\'den Belirgin Fark',
                'body'  => 'Kişisel enflasyonun resmi TÜFE\'nin ' . number_format(abs($personalDelta), 1, ',', '.') . ' puan üzerinde. '
                         . 'Harcama sepetini çeşitlendirmek bu farkı azaltabilir.',
              ];
            }
          @endphp

          <ul class="list-unstyled mb-0">
            @foreach($tips as $tip)
            <li class="tip-item">
              <div class="d-flex align-items-start gap-3">
                <div class="avatar avatar-sm flex-shrink-0 mt-1">
                  <span class="avatar-initial rounded bg-label-{{ $tip['color'] }}">
                    <i class="icon-base ti {{ $tip['icon'] }} icon-16px"></i>
                  </span>
                </div>
                <div class="flex-grow-1">
                  <div class="fw-semibold small text-{{ $tip['color'] }} mb-1">{{ $tip['title'] }}</div>
                  <p class="text-muted mb-0" style="font-size:.78rem;line-height:1.45;">{{ $tip['body'] }}</p>
                </div>
              </div>
            </li>
            @endforeach
          </ul>

          <div class="p-3 border-top">
            <a href="{{ route('agent-chat.index') }}" class="btn btn-outline-warning btn-sm w-100">
              <i class="icon-base ti tabler-robot me-1"></i>Ajandan Daha Fazla Öneri Al
            </a>
          </div>
        </div>
      </div>
    </div>

  </div>

  {{-- ══ ROW 4 — Mini summary stat cards ════════════════════════════════════ --}}
  <div class="row row-cols-2 row-cols-xl-4 g-4 mb-2">

    {{-- Personal rate card --}}
    <div class="col">
      <div class="card mini-stat position-relative overflow-hidden h-100">
        <div class="accent-bar" style="height:3px;position:absolute;top:0;left:0;right:0;border-radius:3px 3px 0 0;background:{{ $severityColor }};"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Kişisel Enflasyon</span>
              <div class="h5 fw-bold mt-1 mb-0" style="color:{{ $severityColor }};">
                %{{ number_format($personalRate, 1, ',', '.') }}
              </div>
              <span class="small text-muted">Son 90 gün harcama</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded" style="background:rgba({{ $severity === 'green' ? '40,199,111' : ($severity === 'yellow' ? '255,159,67' : '234,84,85') }},.12);">
                <i class="icon-base ti tabler-user icon-22px" style="color:{{ $severityColor }};"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Official TÜFE card --}}
    <div class="col">
      <div class="card mini-stat position-relative overflow-hidden h-100">
        <div class="accent-bar" style="height:3px;position:absolute;top:0;left:0;right:0;border-radius:3px 3px 0 0;background:#FF9F43;"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Resmi TÜFE</span>
              <div class="h5 fw-bold mt-1 mb-0 text-warning">
                %{{ number_format($headline, 2, ',', '.') }}
              </div>
              <span class="small text-muted">{{ $periodLabel }}</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-warning">
                <i class="icon-base ti tabler-building-bank icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Delta card --}}
    <div class="col">
      @php $deltaPositive = $personalDelta > 0; @endphp
      <div class="card mini-stat position-relative overflow-hidden h-100">
        <div class="accent-bar" style="height:3px;position:absolute;top:0;left:0;right:0;border-radius:3px 3px 0 0;background:{{ $deltaPositive ? '#EA5455' : '#28C76F' }};"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">TÜFE Farkı</span>
              <div class="h5 fw-bold mt-1 mb-0 {{ $deltaPositive ? 'text-danger' : 'text-success' }}">
                {{ $personalDelta >= 0 ? '+' : '' }}%{{ number_format($personalDelta, 2, ',', '.') }}
              </div>
              <span class="small {{ $deltaPositive ? 'text-danger' : 'text-success' }}">
                {{ $deltaPositive ? 'Ortalamadan yüksek' : 'Ortalamadan düşük' }}
              </span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $deltaPositive ? 'danger' : 'success' }}">
                <i class="icon-base ti tabler-arrows-diff icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Purchasing power card --}}
    <div class="col">
      <div class="card mini-stat position-relative overflow-hidden h-100">
        <div class="accent-bar" style="height:3px;position:absolute;top:0;left:0;right:0;border-radius:3px 3px 0 0;background:#7367F0;"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Satın Alma Gücü</span>
              <div class="h5 fw-bold mt-1 mb-0 text-primary">
                ₺{{ number_format($ppNow, 0, ',', '.') }}
              </div>
              <span class="small text-muted">₺10.000 → bugün</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-coin icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>

  {{-- ══ ApexCharts + Page JS ════════════════════════════════════════════════ --}}
  <x-slot name="pageJs">
    <script src="{{ asset('assets/vendor/libs/apex-charts/apexcharts.js') }}"></script>
    <script>
    (function () {
      'use strict';

      /* ── Theme helpers ───────────────────────────────────────────────────── */
      const isDark    = document.documentElement.getAttribute('data-bs-theme') === 'dark';
      const fontFam   = "'Public Sans', sans-serif";
      const textColor = isDark ? '#b4b7bd' : '#6e6b7b';
      const gridColor = isDark ? 'rgba(255,255,255,.07)' : 'rgba(0,0,0,.05)';
      const cardBg    = isDark ? '#2b2c40' : '#fff';

      /* ── Palette ─────────────────────────────────────────────────────────── */
      const clrPrimary = '#7367F0';
      const clrSuccess = '#28C76F';
      const clrWarning = '#FF9F43';
      const clrDanger  = '#EA5455';
      const clrInfo    = '#00CFE8';

      /* ── 1. Radial gauge ─────────────────────────────────────────────────── */
      const gaugeEl = document.getElementById('gaugeChart');
      if (gaugeEl) {
        const rate     = {{ $personalRate }};
        const maxRate  = 100;
        const pct      = Math.min(100, Math.round(rate / maxRate * 100));
        const color    = '{{ $severityColor }}';

        new ApexCharts(gaugeEl, {
          chart: {
            type: 'radialBar',
            height: 180,
            fontFamily: fontFam,
            background: 'transparent',
            toolbar: { show: false },
            sparkline: { enabled: false },
          },
          series: [pct],
          colors: [color],
          plotOptions: {
            radialBar: {
              startAngle: -130,
              endAngle:   130,
              hollow: {
                size: '60%',
                background: 'transparent',
              },
              track: {
                background: isDark ? 'rgba(255,255,255,.06)' : 'rgba(0,0,0,.06)',
                strokeWidth: '100%',
              },
              dataLabels: {
                show: true,
                name: {
                  show: true,
                  offsetY: 22,
                  color: textColor,
                  fontSize: '11px',
                  fontFamily: fontFam,
                  formatter: () => 'Kişisel Enflasyon',
                },
                value: {
                  show: true,
                  offsetY: -8,
                  color: color,
                  fontSize: '2rem',
                  fontWeight: 800,
                  fontFamily: fontFam,
                  formatter: () => '%' + rate.toFixed(1).replace('.', ','),
                },
              },
            },
          },
          fill: {
            type: 'gradient',
            gradient: {
              shade: 'dark',
              type: 'horizontal',
              gradientToColors: [isDark ? 'rgba(255,255,255,.4)' : 'rgba(255,255,255,.7)'],
              stops: [0, 100],
            },
          },
          stroke: { lineCap: 'round' },
          labels: ['Kişisel Enflasyon'],
        }).render();
      }

      /* ── 2. Contribution horizontal bar (personal breakdown) ─────────────── */
      const contribEl = document.getElementById('contribBarChart');
      @if(count($personalBreakdown))
      @php
        $contribChartData = collect($personalBreakdown)
          ->map(fn($b) => [
            'label'  => $getCatLabel($b['slug']),
            'impact' => round($b['impact'], 2),
            'weight' => $b['weight'],
            'rate'   => $b['rate'],
          ])
          ->sortByDesc('impact')
          ->values()
          ->all();
      @endphp
      if (contribEl) {
        const bd = @json($contribChartData);

        const labels  = bd.map(d => d.label);
        const impacts = bd.map(d => d.impact);
        const colors  = impacts.map(v => v > 15 ? clrDanger : v > 8 ? clrWarning : clrSuccess);

        new ApexCharts(contribEl, {
          chart: {
            type: 'bar',
            height: 260,
            fontFamily: fontFam,
            background: 'transparent',
            toolbar: { show: false },
          },
          plotOptions: {
            bar: {
              horizontal: true,
              distributed: true,
              borderRadius: 4,
              barHeight: '60%',
              dataLabels: { position: 'bottom' },
            },
          },
          series: [{ name: 'Enflasyon Katkısı %', data: impacts }],
          xaxis: {
            categories: labels,
            labels: {
              formatter: v => '%' + parseFloat(v).toFixed(1),
              style: { colors: textColor, fontFamily: fontFam, fontSize: '11px' },
            },
            axisBorder: { show: false },
            axisTicks: { show: false },
          },
          yaxis: {
            labels: {
              style: { colors: textColor, fontFamily: fontFam, fontSize: '11px' },
            },
          },
          colors: colors,
          legend: { show: false },
          grid: { borderColor: gridColor, strokeDashArray: 4, xaxis: { lines: { show: true } } },
          dataLabels: {
            enabled: true,
            textAnchor: 'start',
            formatter: v => ' +%' + parseFloat(v).toFixed(2),
            style: { fontSize: '10px', fontFamily: fontFam, colors: [textColor] },
            offsetX: 0,
          },
          tooltip: {
            theme: isDark ? 'dark' : 'light',
            y: { formatter: v => '+%' + parseFloat(v).toFixed(2) + ' puan katkı' },
          },
        }).render();
      }
      @endif

      /* ── 3. TÜİK category bar chart ──────────────────────────────────────── */
      const catEl = document.getElementById('categoryChart');
      @if($categoryRates->isNotEmpty())
      if (catEl) {
        const catData = @json(
          $categoryRates
            ->map(fn($r) => [
              'slug' => ucwords(str_replace('-', ' ', $r->tuik_category_slug)),
              'rate' => round((float)$r->annual_change_rate, 2),
            ])
            ->sortByDesc('rate')
            ->values()
        );

        new ApexCharts(catEl, {
          chart: {
            type: 'bar',
            height: 340,
            fontFamily: fontFam,
            background: 'transparent',
            toolbar: { show: false },
          },
          plotOptions: {
            bar: {
              distributed: true,
              borderRadius: 5,
              columnWidth: '58%',
            },
          },
          series: [{ name: 'Yıllık Değişim %', data: catData.map(d => d.rate) }],
          xaxis: {
            categories: catData.map(d => d.slug),
            labels: {
              rotate: -35,
              rotateAlways: true,
              style: { fontSize: '9px', colors: textColor, fontFamily: fontFam },
            },
            axisBorder: { show: false },
            axisTicks: { show: false },
          },
          yaxis: {
            labels: {
              formatter: v => '%' + v,
              style: { colors: textColor, fontFamily: fontFam },
            },
          },
          colors: catData.map(d =>
            d.rate > 60 ? '#b91c1c' :
            d.rate > 45 ? clrDanger  :
            d.rate > 30 ? clrWarning :
                          clrSuccess
          ),
          dataLabels: {
            enabled: true,
            formatter: v => '%' + v,
            style: { fontSize: '9px', fontFamily: fontFam },
            offsetY: -4,
          },
          legend: { show: false },
          grid: { borderColor: gridColor, strokeDashArray: 4, padding: { top: -10 } },
          tooltip: {
            theme: isDark ? 'dark' : 'light',
            y: { formatter: v => '%' + v + ' yıllık değişim' },
          },
        }).render();
      }
      @endif

      /* ── 4. TÜFE historical area chart ──────────────────────────────────── */
      const histEl = document.getElementById('historyChart');
      @if($historical->isNotEmpty())
      if (histEl) {
        const monthNames = ['', 'Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'];
        const histRaw    = @json($historical->map(fn($r) => [
          'rate'  => round((float)$r->annual_change_rate, 2),
          'month' => $r->period_month,
          'year'  => $r->period_year,
        ])->values());

        const histLabels = histRaw.map(r => (monthNames[r.month] || r.month) + ' ' + String(r.year).slice(2));
        const histData   = histRaw.map(r => r.rate);

        /* gradient stops for fill */
        new ApexCharts(histEl, {
          chart: {
            type: 'area',
            height: 240,
            fontFamily: fontFam,
            background: 'transparent',
            toolbar: { show: false },
            zoom: { enabled: false },
          },
          series: [{ name: 'TÜFE %', data: histData }],
          colors: [clrInfo],
          stroke: { curve: 'smooth', width: 2.5 },
          fill: {
            type: 'gradient',
            gradient: {
              shadeIntensity: 1,
              opacityFrom: .35,
              opacityTo: .03,
              stops: [0, 95],
            },
          },
          xaxis: {
            categories: histLabels,
            labels: { style: { fontSize: '11px', colors: textColor, fontFamily: fontFam } },
            axisBorder: { show: false },
            axisTicks: { show: false },
          },
          yaxis: {
            labels: {
              formatter: v => '%' + v,
              style: { colors: textColor, fontFamily: fontFam },
            },
          },
          markers: {
            size: 4,
            colors: [clrInfo],
            strokeColors: isDark ? cardBg : '#fff',
            strokeWidth: 2,
            hover: { size: 6 },
          },
          annotations: {
            yaxis: [{
              y: {{ $headline }},
              borderColor: clrWarning,
              strokeDashArray: 4,
              label: {
                text: 'Güncel: %{{ $headline }}',
                style: {
                  color: '#fff',
                  background: clrWarning,
                  fontFamily: fontFam,
                  fontSize: '11px',
                },
              },
            }],
          },
          grid: { borderColor: gridColor, strokeDashArray: 4, padding: { top: 0 } },
          dataLabels: { enabled: false },
          tooltip: {
            theme: isDark ? 'dark' : 'light',
            y: { formatter: v => '%' + v + ' yıllık değişim' },
          },
        }).render();
      }
      @endif

      /* ── Reload on theme toggle ───────────────────────────────────────────── */
      new MutationObserver(() => location.reload())
        .observe(document.documentElement, { attributes: true, attributeFilter: ['data-bs-theme'] });

    }());
    </script>
  </x-slot>
</x-app-layout>
