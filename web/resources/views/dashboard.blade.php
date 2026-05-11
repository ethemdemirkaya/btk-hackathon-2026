<x-app-layout>
  <x-slot name="title">Dashboard</x-slot>

  {{-- Apex Charts CSS --}}
  <x-slot name="pageCss">
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/apex-charts/apex-charts.css') }}" />
  </x-slot>

  {{-- ══ Page header with report download ══════════════════════════════ --}}
  <div class="d-flex align-items-center justify-content-between mb-5">
    <div>
      <h4 class="fw-bold mb-0">Ana Sayfa</h4>
      <p class="text-muted mb-0 small">Finansal özet ve analiz</p>
    </div>
    <a href="{{ route('report.monthly') }}" class="btn btn-outline-primary btn-sm" target="_blank">
      <i class="icon-base ti tabler-file-type-pdf me-1"></i>Aylık Rapor PDF
    </a>
  </div>

  {{-- ══ ROW 1 — 5 Metrik Kart ══════════════════════════════════════════ --}}
  <div class="row row-cols-2 row-cols-xl-5 g-4 mb-6">
    {{-- Toplam Bakiye --}}
    <div class="col">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Toplam Bakiye</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2">₺{{ number_format($summary['total_balance'], 2, ',', '.') }}</h4>
                @if($bankConnections->isNotEmpty())
                  <span class="badge bg-label-success">Canlı</span>
                @endif
              </div>
              <small class="text-muted">{{ $bankConnections->sum(fn($c) => $c->accounts->count()) }} hesap</small>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-building-bank icon-26px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Kart Borcu --}}
    <div class="col">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Kart Borcu</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2 @if($summary['total_card_debt'] > 0) text-danger @endif">
                  ₺{{ number_format($summary['total_card_debt'], 2, ',', '.') }}
                </h4>
              </div>
              <small class="text-muted">Tüm kredi kartları</small>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-danger">
                <i class="icon-base ti tabler-credit-card icon-26px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Aktif Kredi --}}
    <div class="col">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Aktif Kredi</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2">₺{{ number_format($summary['total_loan'], 2, ',', '.') }}</h4>
              </div>
              <small class="text-muted">Kalan bakiye</small>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-warning">
                <i class="icon-base ti tabler-file-invoice icon-26px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Finansal Sağlık --}}
    <div class="col">
      <div class="card h-100 {{ $summary['health_score'] ? 'cursor-pointer' : '' }}"
           @if($summary['health_score']) data-bs-toggle="modal" data-bs-target="#healthModal" @endif
           style="{{ $summary['health_score'] ? 'cursor:pointer;' : '' }}">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Finansal Sağlık</span>
              <div class="d-flex align-items-center my-1">
                @if($summary['health_score'])
                  <h4 class="mb-0 me-2 @if($summary['health_score'] >= 70) text-success @elseif($summary['health_score'] >= 40) text-warning @else text-danger @endif">
                    {{ $summary['health_score'] }}/100
                  </h4>
                @else
                  <h4 class="mb-0 me-2 text-muted">--/100</h4>
                @endif
              </div>
              <small class="text-muted">{{ $summary['health_score'] ? 'Detay için tıkla' : 'Sağlık skoru' }}</small>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-success">
                <i class="icon-base ti tabler-heart-rate-monitor icon-26px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    {{-- Net Varlık --}}
    <div class="col">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Net Varlık</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2 @if(($summary['net_worth'] ?? 0) >= 0) text-success @else text-danger @endif">
                  ₺{{ number_format($summary['net_worth'] ?? 0, 2, ',', '.') }}
                </h4>
              </div>
              <small class="text-muted">Bakiye − Borçlar</small>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded @if(($summary['net_worth'] ?? 0) >= 0) bg-label-success @else bg-label-danger @endif">
                <i class="icon-base ti tabler-scale icon-26px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- ══ Kişisel Enflasyon Kartı (Killer Feature) ═══════════════════════ --}}
  <div class="card mb-6 border-warning">
    <div class="card-body">
      <div class="row align-items-center g-4">
        <div class="col-md-1 text-center d-none d-md-block">
          <i class="icon-base ti tabler-flame icon-48px text-warning"></i>
        </div>
        <div class="col-md-5">
          <div class="d-flex align-items-center gap-2 mb-1">
            <h5 class="fw-bold mb-0">Kişisel Enflasyonun</h5>
            <span class="badge bg-warning text-dark">TÜİK Verisi</span>
          </div>
          @if($personalInflation['personal_rate'] !== null)
            <div class="d-flex align-items-end gap-3">
              <div class="display-5 fw-bold text-danger">%{{ number_format($personalInflation['personal_rate'], 1, ',', '.') }}</div>
              <div class="mb-2">
                <div class="text-muted small">TÜFE: <strong class="text-warning">%{{ number_format($personalInflation['tufe_rate'], 2, ',', '.') }}</strong></div>
                @if($personalInflation['diff'] !== null)
                  <div class="{{ $personalInflation['diff'] > 0 ? 'text-danger' : 'text-success' }} fw-semibold small">
                    {{ $personalInflation['diff'] > 0 ? '+' : '' }}%{{ number_format($personalInflation['diff'], 2, ',', '.') }} fark
                  </div>
                @endif
              </div>
            </div>
            <p class="text-muted small mb-0">
              Harcama alışkanlıklarına göre hesaplanan yıllık enflasyon oranın.
              @if($personalInflation['diff'] > 0)
                Genel enflasyonun <strong>{{ number_format($personalInflation['diff'], 1, ',', '.') }} puan üstünde</strong> etkileniyorsun.
              @else
                Genel enflasyonun altında etkileniyorsun — finansal kararların etkili.
              @endif
            </p>
          @else
            <div class="display-5 fw-bold text-muted">
              TÜFE: %{{ number_format($personalInflation['tufe_rate'], 2, ',', '.') }}
            </div>
            <p class="text-muted small mb-0 mt-1">
              Harcamalarını kategorize ettikten sonra <strong>kişisel enflasyonun</strong> hesaplanacak.
              Genel enflasyon manşet TÜFE: %{{ number_format($personalInflation['tufe_rate'], 2, ',', '.') }}.
            </p>
          @endif
        </div>
        @if($personalInflation['personal_rate'] !== null && count($personalInflation['breakdown']) > 0)
        <div class="col-md-6">
          <div class="small fw-semibold text-muted mb-2">Harcama Ağırlığı × Enflasyon (En Etkili 4)</div>
          @foreach(array_slice($personalInflation['breakdown'], 0, 4) as $b)
          <div class="d-flex align-items-center gap-2 mb-1">
            <span class="text-muted" style="width:130px;font-size:.78rem;">{{ $b['category'] }}</span>
            <div class="flex-grow-1 progress" style="height:5px;">
              <div class="progress-bar bg-warning" style="width:{{ min(100, $b['weight_pct']) }}%"></div>
            </div>
            <span style="font-size:.78rem;width:48px;" class="text-end text-muted">%{{ number_format($b['weight_pct'], 0) }}</span>
            <span style="font-size:.78rem;width:52px;" class="text-end fw-semibold text-danger">%{{ number_format($b['tuik_rate'], 1, ',', '.') }}</span>
          </div>
          @endforeach
        </div>
        @else
        <div class="col-md-6">
          <div class="small fw-semibold text-muted mb-2">Güncel TÜİK Kategori Enflasyonları</div>
          @php
            $tuikSample = [
              'Konut' => 59.08, 'Eğitim' => 75.33, 'Lokanta' => 43.51,
              'Alkol/Sigara' => 42.30, 'Genel TÜFE' => 37.86,
            ];
          @endphp
          @foreach($tuikSample as $cat => $rate)
          <div class="d-flex align-items-center gap-2 mb-1">
            <span class="text-muted" style="width:130px;font-size:.78rem;">{{ $cat }}</span>
            <div class="flex-grow-1 progress" style="height:5px;">
              <div class="progress-bar bg-warning" style="width:{{ min(100, $rate) }}%"></div>
            </div>
            <span style="font-size:.78rem;width:52px;" class="text-end fw-semibold text-danger">%{{ number_format($rate, 2, ',', '.') }}</span>
          </div>
          @endforeach
        </div>
        @endif
      </div>
    </div>
  </div>

  {{-- ══ Smart Alerts ═════════════════════════════════════════════════════ --}}
  @if(count($smartAlerts) > 0)
  <div class="row g-4 mb-6">
    @foreach($smartAlerts as $alert)
    <div class="col-md-6 col-xl-3">
      <div class="card border-{{ $alert['type'] }} h-100">
        <div class="card-body py-3 d-flex align-items-center gap-3">
          <div class="avatar flex-shrink-0">
            <span class="avatar-initial rounded bg-label-{{ $alert['type'] }}">
              <i class="icon-base ti {{ $alert['icon'] }} icon-22px"></i>
            </span>
          </div>
          <div class="flex-grow-1 overflow-hidden">
            <div class="fw-semibold small text-{{ $alert['type'] }}">{{ $alert['title'] }}</div>
            <div class="text-muted" style="font-size:.75rem;">{{ $alert['body'] }}</div>
          </div>
          <a href="{{ $alert['link'] }}" class="text-{{ $alert['type'] }} flex-shrink-0">
            <i class="icon-base ti tabler-chevron-right icon-18px"></i>
          </a>
        </div>
      </div>
    </div>
    @endforeach
  </div>
  @endif

  {{-- ══ ROW 2 — Nakit Akışı + Kategori Donut ════════════════════════════ --}}
  <div class="row g-6 mb-6">
    {{-- Nakit Akışı Alan Grafik --}}
    <div class="col-xl-8">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between pb-0">
          <h5 class="card-title mb-0">Nakit Akışı — Son 6 Ay</h5>
          <small class="text-muted">₺ TRY</small>
        </div>
        <div class="card-body">
          <div id="cashFlowChart"></div>
        </div>
      </div>
    </div>

    {{-- Kategori Harcama Donut --}}
    <div class="col-xl-4">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between pb-0">
          <h5 class="card-title mb-0">Harcama Dağılımı</h5>
          <small class="text-muted">Son 30 gün</small>
        </div>
        <div class="card-body d-flex align-items-center justify-content-center">
          @if(count($categorySpend) > 0)
            <div id="categoryDonutChart" class="w-100"></div>
          @else
            <div class="text-center">
              <i class="icon-base ti tabler-chart-donut-3 icon-48px text-muted mb-3 d-block"></i>
              <p class="text-muted small mb-0">Henüz kategori verisi yok.</p>
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- ══ ROW 3 — Enflasyon Karşılaştırma + Banka Hesapları ══════════════ --}}
  <div class="row g-6 mb-6">
    {{-- Kişisel Enflasyon vs TÜFE --}}
    <div class="col-xl-5">
      <div class="card border-primary h-100">
        <div class="card-header d-flex align-items-center">
          <h5 class="card-title mb-0 me-auto">Kişisel Enflasyon vs TÜFE</h5>
          <span class="badge bg-label-warning">TÜİK</span>
        </div>
        <div class="card-body d-flex align-items-center justify-content-center">
          @if(count($inflationData) > 0)
            <div id="inflationBarChart" class="w-100"></div>
          @else
            <div class="text-center">
              <i class="icon-base ti tabler-chart-bar icon-48px text-muted mb-3 d-block"></i>
              <p class="text-muted small mb-0">
                Banka hesapları bağlandıktan sonra kişisel enflasyon hesaplanacak.
              </p>
            </div>
          @endif
        </div>
      </div>
    </div>

    {{-- Banka Hesapları Tablosu --}}
    <div class="col-xl-7">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between">
          <h5 class="card-title mb-0">Banka Hesapları</h5>
          <a href="{{ route('bank-connections.create') }}" class="btn btn-sm btn-primary">
            <i class="icon-base ti tabler-plus me-1"></i> Banka Bağla
          </a>
        </div>
        <div class="card-body p-0">
          @if($bankConnections->isNotEmpty())
            <div class="table-responsive">
              <table class="table table-hover mb-0">
                <thead class="table-light">
                  <tr>
                    <th>Banka</th>
                    <th>Tür</th>
                    <th>IBAN</th>
                    <th class="text-end">Bakiye</th>
                    <th class="text-end">Müsait</th>
                  </tr>
                </thead>
                <tbody>
                  @foreach($bankConnections as $conn)
                    @foreach($conn->accounts as $acct)
                      <tr>
                        <td>
                          <div class="d-flex align-items-center gap-2">
                            <span class="badge bg-label-secondary">{{ strtoupper($conn->bank->slug) }}</span>
                            <span>{{ $conn->bank->name }}</span>
                          </div>
                        </td>
                        <td>
                          @if($acct->account_type === 'checking')
                            <span class="badge bg-label-primary">Vadesiz</span>
                          @elseif($acct->account_type === 'savings')
                            <span class="badge bg-label-info">Birikimli</span>
                          @else
                            <span class="badge bg-label-secondary">{{ $acct->account_type }}</span>
                          @endif
                        </td>
                        <td><small class="text-muted font-monospace">{{ Str::mask($acct->iban ?? '—', '*', 4, -4) }}</small></td>
                        <td class="text-end fw-medium">₺{{ number_format($acct->balance, 2, ',', '.') }}</td>
                        <td class="text-end text-success">₺{{ number_format($acct->available_balance, 2, ',', '.') }}</td>
                      </tr>
                    @endforeach
                  @endforeach
                </tbody>
              </table>
            </div>
          @else
            <div class="text-center py-6">
              <i class="icon-base ti tabler-building-bank icon-48px text-muted mb-3 d-block"></i>
              <p class="text-muted mb-3">Henüz banka hesabı bağlanmamış.</p>
              <a href="{{ route('bank-connections.create') }}" class="btn btn-outline-primary">
                <i class="icon-base ti tabler-plus me-1"></i> Banka Bağla
              </a>
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- ══ ROW 3b — Bu Ay Bütçe Durumu ══════════════════════════════════ --}}
  @if(count($budgetSummary) > 0)
  <div class="card mb-6">
    <div class="card-header d-flex align-items-center justify-content-between pb-2">
      <h5 class="card-title mb-0">
        <i class="icon-base ti tabler-chart-pie me-2 text-primary"></i>Bu Ay Bütçe Durumu
      </h5>
      <a href="{{ route('budgets.index') }}" class="btn btn-sm btn-outline-secondary">Bütçeleri Yönet</a>
    </div>
    <div class="card-body">
      <div class="row g-4">
        @foreach($budgetSummary as $b)
        <div class="col-sm-6 col-xl-3">
          <div class="d-flex justify-content-between align-items-center mb-1">
            <span class="fw-medium small">{{ $b['name'] }}</span>
            @if($b['over_budget'])
              <span class="badge bg-label-danger" style="font-size:.7rem;">Aşıldı</span>
            @else
              <span class="text-muted small">%{{ $b['pct'] }}</span>
            @endif
          </div>
          <div class="progress mb-1" style="height:6px;">
            <div class="progress-bar {{ $b['over_budget'] ? 'bg-danger' : ($b['pct'] >= 80 ? 'bg-warning' : 'bg-success') }}"
                 style="width:{{ $b['pct'] }}%"></div>
          </div>
          <div class="d-flex justify-content-between" style="font-size:.73rem;">
            <span class="text-muted">₺{{ number_format($b['spent'], 0, ',', '.') }} harcandı</span>
            <span class="{{ $b['over_budget'] ? 'text-danger fw-semibold' : 'text-muted' }}">
              / ₺{{ number_format($b['amount'], 0, ',', '.') }}
            </span>
          </div>
        </div>
        @endforeach
      </div>
    </div>
  </div>
  @endif

  {{-- ══ ROW 4 — Son İşlemler + Ajan Asistan ════════════════════════════ --}}
  <div class="row g-6">
    {{-- Son İşlemler --}}
    <div class="col-xl-8">
      <div class="card">
        <div class="card-header d-flex align-items-center justify-content-between">
          <h5 class="card-title mb-0">Son İşlemler</h5>
          <a href="{{ route('transactions.index') }}" class="btn btn-sm btn-outline-secondary">Tümünü Gör</a>
        </div>
        <div class="card-body p-0">
          @if($recentTxns->isNotEmpty())
            <div class="table-responsive">
              <table class="table table-hover mb-0">
                <thead class="table-light">
                  <tr>
                    <th>İşlem</th>
                    <th>Banka</th>
                    <th>Tarih</th>
                    <th class="text-end">Tutar</th>
                  </tr>
                </thead>
                <tbody>
                  @foreach($recentTxns as $tx)
                    <tr>
                      <td>
                        <div>
                          <span class="fw-medium">{{ Str::limit($tx->description, 38) }}</span>
                          @if($tx->merchant_name)
                            <br><small class="text-muted">{{ $tx->merchant_name }}</small>
                          @endif
                        </div>
                      </td>
                      <td>
                        @if($tx->account?->bankConnection?->bank)
                          <span class="badge bg-label-secondary">
                            {{ strtoupper($tx->account->bankConnection->bank->slug) }}
                          </span>
                        @endif
                      </td>
                      <td>
                        <small class="text-muted">
                          {{ \Carbon\Carbon::parse($tx->posted_at)->format('d.m.Y') }}
                        </small>
                      </td>
                      <td class="text-end fw-semibold @if($tx->amount >= 0) text-success @else text-danger @endif">
                        @if($tx->amount >= 0)+@endif₺{{ number_format(abs($tx->amount), 2, ',', '.') }}
                      </td>
                    </tr>
                  @endforeach
                </tbody>
              </table>
            </div>
          @else
            <div class="text-center py-5">
              <i class="icon-base ti tabler-receipt-2 icon-48px text-muted mb-3 d-block"></i>
              <p class="text-muted mb-0">İşlem geçmişi bulunamadı.</p>
            </div>
          @endif
        </div>
      </div>
    </div>

    {{-- Ajan Asistan --}}
    <div class="col-xl-4">
      <div class="card h-100">
        <div class="card-header d-flex align-items-center justify-content-between">
          <h5 class="card-title mb-0">
            <i class="icon-base ti tabler-bulb me-2 text-warning"></i>AI Öngörüler
          </h5>
          <a href="{{ route('agent-chat.index') }}" class="btn btn-sm btn-outline-primary">
            <i class="icon-base ti tabler-message-2 me-1"></i>Sohbet
          </a>
        </div>
        <div class="card-body d-flex flex-column p-0">
          @if($aiInsights->isNotEmpty())
            <ul class="list-group list-group-flush flex-grow-1" id="insights-list">
              @foreach($aiInsights as $insight)
                <li class="list-group-item px-4 py-3" id="insight-{{ $insight->id }}">
                  <div class="d-flex align-items-start justify-content-between gap-2">
                    <div class="fw-semibold small mb-1">{{ $insight->title }}</div>
                    <button type="button"
                            class="btn btn-icon btn-text-secondary btn-sm flex-shrink-0 btn-dismiss-insight"
                            data-id="{{ $insight->id }}"
                            data-url="{{ route('agent-chat.insight-dismiss', $insight->id) }}"
                            title="Kapat" style="margin-top:-4px;">
                      <i class="icon-base ti tabler-x icon-14px"></i>
                    </button>
                  </div>
                  <p class="text-muted small mb-0">{{ \Illuminate\Support\Str::limit($insight->body, 110) }}</p>
                  @if($insight->action_link)
                    <a href="{{ $insight->action_link }}" class="text-primary" style="font-size:.78rem;">
                      Detay <i class="icon-base ti tabler-chevron-right"></i>
                    </a>
                  @endif
                </li>
              @endforeach
            </ul>
            <div class="p-3 border-top">
              <a href="{{ route('agent-chat.index') }}" class="btn btn-primary w-100 btn-sm">
                <i class="icon-base ti tabler-robot me-2"></i>Ajana Daha Fazla Sor
              </a>
            </div>
          @else
            <div class="flex-grow-1 d-flex flex-column justify-content-center p-4">
              <p class="text-muted small mb-4">
                Yapay zeka ajanları finansal durumunuzu analiz ederek öneriler üretebilir.
              </p>
              <div class="bg-label-primary rounded p-3 mb-4 small">
                <strong>Hızlı sorular:</strong>
                <ul class="mb-0 mt-1 ps-3">
                  <li>Bu ay ne kadar harcadım?</li>
                  <li>Birikim önerilerin neler?</li>
                  <li>Harcamalarımda anormallik var mı?</li>
                </ul>
              </div>
              <button id="btn-quick-analyze" class="btn btn-outline-warning mb-3">
                <i class="icon-base ti tabler-sparkles me-2"></i>Hızlı AI Analiz Yap
              </button>
              <div id="quick-analyze-status" class="d-none alert alert-info py-2 small mb-3"></div>
              <a href="{{ route('agent-chat.index') }}" class="btn btn-primary">
                <i class="icon-base ti tabler-message-2 me-2"></i>Ajana Sor
              </a>
            </div>
          @endif
        </div>
      </div>
    </div>
  </div>

  {{-- ══ Türkiye Ekonomik Göstergeler Widget ════════════════════════════ --}}
  @php
    $macroLabels = [
      'tufe'                  => ['label' => 'TÜFE', 'unit' => '%', 'icon' => 'tabler-flame'],
      'unemployment'          => ['label' => 'İşsizlik', 'unit' => '%', 'icon' => 'tabler-briefcase'],
      'gdp_growth'            => ['label' => 'GSYH Büyüme', 'unit' => '%', 'icon' => 'tabler-trending-up'],
      'industrial_production' => ['label' => 'Sanayi Üretim', 'unit' => '%', 'icon' => 'tabler-building-factory'],
      'consumer_confidence'   => ['label' => 'Tüketici Güven', 'unit' => '', 'icon' => 'tabler-mood-smile'],
      'population'            => ['label' => 'Nüfus', 'unit' => 'M', 'icon' => 'tabler-users'],
    ];
  @endphp
  @if($macroIndicators->isNotEmpty())
  <div class="card mt-6 mb-0">
    <div class="card-header d-flex align-items-center pb-2">
      <h5 class="card-title mb-0 me-auto">
        <i class="icon-base ti tabler-chart-infographic me-2 text-info"></i>Türkiye Ekonomik Göstergeler
      </h5>
      <span class="badge bg-label-info">TÜİK</span>
    </div>
    <div class="card-body py-3">
      <div class="row g-3">
        @foreach($macroLabels as $type => $meta)
          @if($macroIndicators->has($type))
          @php $ind = $macroIndicators->get($type); @endphp
          <div class="col-6 col-md-4 col-xl-2">
            <div class="d-flex align-items-center gap-2">
              <div class="avatar avatar-sm flex-shrink-0">
                <span class="avatar-initial rounded bg-label-{{ $ind->trend === 'up' ? 'success' : ($ind->trend === 'down' ? 'danger' : 'secondary') }}">
                  <i class="icon-base ti {{ $meta['icon'] }} icon-16px"></i>
                </span>
              </div>
              <div class="flex-grow-1 overflow-hidden">
                <div class="text-muted" style="font-size:.72rem;">{{ $meta['label'] }}</div>
                <div class="fw-bold small">
                  {{ number_format($ind->value, $ind->value > 10 ? 1 : 2, ',', '.') }}{{ $meta['unit'] }}
                  @if($ind->trend === 'up') <i class="icon-base ti tabler-arrow-up-right text-success icon-14px"></i>
                  @elseif($ind->trend === 'down') <i class="icon-base ti tabler-arrow-down-right text-danger icon-14px"></i>
                  @endif
                </div>
              </div>
            </div>
          </div>
          @endif
        @endforeach
      </div>
    </div>
  </div>
  @endif

  {{-- ══ Finansal Sağlık Modal ══════════════════════════════════════════ --}}
  @if($healthDetails)
  <div class="modal fade" id="healthModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">
            <i class="icon-base ti tabler-heart-rate-monitor me-2 text-success"></i>Finansal Sağlık Skoru
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          {{-- Total score --}}
          <div class="text-center mb-5">
            <div class="display-4 fw-bold @if($healthDetails->score >= 70) text-success @elseif($healthDetails->score >= 40) text-warning @else text-danger @endif">
              {{ $healthDetails->score }}<span class="fs-4 text-muted">/100</span>
            </div>
            <div class="text-muted small mt-1">
              @if($healthDetails->score >= 70) Sağlıklı Finansal Durum
              @elseif($healthDetails->score >= 40) Geliştirilmesi Gerekiyor
              @else Risk Altında — Dikkat!
              @endif
            </div>
          </div>

          {{-- Component bars --}}
          @php
            $components = [
              ['label' => 'Borç Oranı',          'score' => $healthDetails->debt_ratio_score,          'icon' => 'tabler-trending-down', 'color' => 'danger',  'tip' => 'Toplam borcun yıllık gelire oranı'],
              ['label' => 'Tasarruf Oranı',       'score' => $healthDetails->savings_rate_score,        'icon' => 'tabler-piggy-bank',    'color' => 'success', 'tip' => 'Aylık tasarruf / gelir oranı'],
              ['label' => 'Acil Fon',             'score' => $healthDetails->emergency_fund_score,      'icon' => 'tabler-shield',        'color' => 'info',    'tip' => 'Bakiyenin aylık gidere oranı (hedef: 6 ay)'],
              ['label' => 'Harcama Tutarlılığı',  'score' => $healthDetails->expense_consistency_score, 'icon' => 'tabler-chart-line',    'color' => 'warning', 'tip' => 'Aylık giderlerin değişkenliği'],
            ];
          @endphp
          <div class="row g-4">
            @foreach($components as $c)
            <div class="col-sm-6">
              <div class="d-flex align-items-center gap-2 mb-1">
                <i class="icon-base ti {{ $c['icon'] }} text-{{ $c['color'] }} icon-18px"></i>
                <span class="fw-medium small">{{ $c['label'] }}</span>
                <span class="ms-auto fw-bold small">{{ $c['score'] }}/100</span>
              </div>
              <div class="progress" style="height:6px;">
                <div class="progress-bar bg-{{ $c['color'] }}" style="width:{{ $c['score'] }}%"></div>
              </div>
              <div class="text-muted mt-1" style="font-size:.72rem;">{{ $c['tip'] }}</div>
            </div>
            @endforeach
          </div>

          <div class="alert alert-light mt-4 mb-0 small text-muted">
            <i class="icon-base ti tabler-clock me-1"></i>
            Son güncelleme: {{ \Carbon\Carbon::parse($healthDetails->calculated_at)->diffForHumans() }}
          </div>
        </div>
        <div class="modal-footer">
          <a href="{{ route('simulator.index') }}" class="btn btn-primary">
            <i class="icon-base ti tabler-calculator me-1"></i>Simülatörde Dene
          </a>
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
        </div>
      </div>
    </div>
  </div>
  @endif

  {{-- ══ Apex Charts JS ══════════════════════════════════════════════════ --}}
  <x-slot name="pageJs">
    <script src="{{ asset('assets/vendor/libs/apex-charts/apexcharts.js') }}"></script>
    <script>
    (function () {
      'use strict';

      const isDark    = document.documentElement.getAttribute('data-bs-theme') === 'dark';
      const primary   = '#7367F0';
      const success   = '#28C76F';
      const danger    = '#EA5455';
      const warning   = '#FF9F43';
      const info      = '#00CFE8';
      const gridColor = isDark ? 'rgba(255,255,255,.08)' : 'rgba(0,0,0,.05)';
      const textColor = isDark ? '#b4b7bd' : '#6e6b7b';
      const fontFam   = "'Public Sans', sans-serif";

      // ── 1. Nakit Akışı Alan Grafik ────────────────────────────────────
      const cfData = @json($cashFlow);

      if (document.getElementById('cashFlowChart')) {
        if (cfData.length > 0) {
          new ApexCharts(document.getElementById('cashFlowChart'), {
            chart: { type: 'area', height: 240, toolbar: { show: false }, fontFamily: fontFam },
            series: [
              { name: 'Gelir', data: cfData.map(r => r.income) },
              { name: 'Gider', data: cfData.map(r => r.expense) },
            ],
            colors: [success, danger],
            fill:   { type: 'gradient', gradient: { shadeIntensity: 1, opacityFrom: 0.35, opacityTo: 0.05 } },
            stroke: { curve: 'smooth', width: 2 },
            xaxis: {
              categories: cfData.map(r => r.month),
              labels: { style: { colors: textColor, fontFamily: fontFam } },
              axisBorder: { show: false }, axisTicks: { show: false },
            },
            yaxis: {
              labels: {
                formatter: v => v >= 1000 ? '₺' + (v/1000).toFixed(0) + 'B' : '₺' + v,
                style: { colors: textColor, fontFamily: fontFam },
              },
            },
            grid: { borderColor: gridColor, padding: { top: -15 } },
            dataLabels: { enabled: false },
            legend: { position: 'top', horizontalAlign: 'right', fontFamily: fontFam, markers: { radius: 50 } },
            tooltip: { y: { formatter: v => '₺ ' + v.toLocaleString('tr-TR', { minimumFractionDigits: 2 }) } },
          }).render();
        } else {
          document.getElementById('cashFlowChart').innerHTML =
            '<div class="text-center py-5 text-muted"><i class="icon-base ti tabler-chart-area icon-48px d-block mb-2"></i><p class="small mb-0">Nakit akışı verisi bulunamadı.</p></div>';
        }
      }

      // ── 2. Kategori Harcama Donut ─────────────────────────────────────
      const catData = @json($categorySpend);

      if (document.getElementById('categoryDonutChart') && catData.length > 0) {
        new ApexCharts(document.getElementById('categoryDonutChart'), {
          chart: { type: 'donut', height: 280, fontFamily: fontFam },
          series: catData.map(r => r.total),
          labels: catData.map(r => r.category),
          colors: [primary, success, warning, danger, info, '#38B2AC', '#ED64A6', '#9F7AEA'],
          legend: { position: 'bottom', fontFamily: fontFam, fontSize: '12px' },
          dataLabels: { enabled: false },
          plotOptions: {
            pie: { donut: { size: '65%', labels: {
              show: true,
              total: {
                show: true, label: 'Toplam', fontFamily: fontFam, fontSize: '12px', color: textColor,
                formatter: w => '₺' + w.globals.seriesTotals
                  .reduce((a, b) => a + b, 0)
                  .toLocaleString('tr-TR', { maximumFractionDigits: 0 }),
              },
            }}},
          },
          tooltip: { y: { formatter: v => '₺ ' + v.toLocaleString('tr-TR', { minimumFractionDigits: 2 }) } },
        }).render();
      }

      // ── 3. Enflasyon Karşılaştırma Bar Grafik ─────────────────────────
      const infData = @json($inflationData);

      if (document.getElementById('inflationBarChart') && infData.length > 0) {
        new ApexCharts(document.getElementById('inflationBarChart'), {
          chart: { type: 'bar', height: 220, toolbar: { show: false }, fontFamily: fontFam },
          series: [
            { name: 'Kişisel Enflasyon', data: infData.map(r => r.personal) },
            { name: 'TÜFE',              data: infData.map(r => r.tufe) },
          ],
          colors: [danger, warning],
          xaxis: {
            categories: infData.map(r => r.month),
            labels: { style: { colors: textColor, fontFamily: fontFam } },
          },
          yaxis: {
            labels: { formatter: v => v + '%', style: { colors: textColor, fontFamily: fontFam } },
          },
          grid: { borderColor: gridColor },
          dataLabels: { enabled: false },
          legend: { position: 'top', fontFamily: fontFam },
          tooltip: { y: { formatter: v => v + '%' } },
          plotOptions: { bar: { columnWidth: '50%', borderRadius: 4 } },
        }).render();
      }
    })();

    // ── Dismiss insight ─────────────────────────────────────────────────
    document.querySelectorAll('.btn-dismiss-insight').forEach(function (btn) {
      btn.addEventListener('click', function () {
        const id  = this.dataset.id;
        const url = this.dataset.url;
        fetch(url, {
          method: 'PATCH',
          headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content },
        }).then(() => {
          const li = document.getElementById('insight-' + id);
          if (li) li.remove();
          const list = document.getElementById('insights-list');
          if (list && list.children.length === 0) location.reload();
        });
      });
    });

    // ── Quick AI Analysis ───────────────────────────────────────────────
    const btnAnalyze = document.getElementById('btn-quick-analyze');
    if (btnAnalyze) {
      btnAnalyze.addEventListener('click', function () {
        const statusBox = document.getElementById('quick-analyze-status');
        btnAnalyze.disabled = true;
        btnAnalyze.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Analiz yapılıyor…';
        statusBox.className = 'alert alert-info py-2 small mb-3';
        statusBox.textContent = 'Yapay zeka ajanları analiz ediyor, lütfen bekleyin…';

        fetch('{{ route("agent-chat.quick-analyze") }}', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
          },
        })
        .then(r => r.json())
        .then(data => {
          if (data.status === 'ok') {
            statusBox.className = 'alert alert-success py-2 small mb-3';
            statusBox.textContent = 'Analiz tamamlandı! Sayfayı yenileyerek önerileri görün.';
            setTimeout(() => location.reload(), 2000);
          } else {
            statusBox.className = 'alert alert-warning py-2 small mb-3';
            statusBox.textContent = 'Analiz sırasında hata: ' + (data.message || 'Bilinmiyor');
            btnAnalyze.disabled = false;
            btnAnalyze.innerHTML = '<i class="icon-base ti tabler-sparkles me-2"></i>Tekrar Dene';
          }
        })
        .catch(() => {
          statusBox.className = 'alert alert-danger py-2 small mb-3';
          statusBox.textContent = 'Bağlantı hatası. Lütfen tekrar deneyin.';
          btnAnalyze.disabled = false;
          btnAnalyze.innerHTML = '<i class="icon-base ti tabler-sparkles me-2"></i>Tekrar Dene';
        });
      });
    }
    </script>
  </x-slot>
</x-app-layout>
