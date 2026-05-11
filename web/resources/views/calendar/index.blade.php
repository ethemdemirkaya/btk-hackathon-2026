<x-app-layout>
  <x-slot name="title">Ödeme Takvimi</x-slot>

  <x-slot name="pageCss">
  <style>
    .cal-grid {
      display: grid;
      grid-template-columns: repeat(7, 1fr);
      border-top: 1px solid var(--bs-border-color);
      border-left: 1px solid var(--bs-border-color);
    }
    .cal-weekday {
      padding: .5rem;
      font-size: .7rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: .05em;
      color: var(--bs-secondary-color);
      background: rgba(115,103,240,.04);
      text-align: center;
      border-right: 1px solid var(--bs-border-color);
      border-bottom: 1px solid var(--bs-border-color);
    }
    .cal-day {
      min-height: 110px;
      padding: .4rem .5rem;
      border-right: 1px solid var(--bs-border-color);
      border-bottom: 1px solid var(--bs-border-color);
      vertical-align: top;
    }
    .cal-day.empty {
      background: var(--bs-secondary-bg);
      opacity: .5;
    }
    .cal-day.today {
      background: rgba(115,103,240,.06);
    }
    .cal-day.today .cal-day-num {
      background: #7367F0;
      color: var(--bs-white, #fff);
      border-radius: 50%;
      width: 24px;
      height: 24px;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: .75rem;
    }
    .cal-day-num {
      font-size: .78rem;
      font-weight: 600;
      color: var(--bs-body-color);
      line-height: 24px;
      margin-bottom: .25rem;
    }
    .cal-event {
      display: block;
      font-size: .65rem;
      padding: .15rem .4rem;
      border-radius: 4px;
      margin-bottom: 2px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      max-width: 100%;
      cursor: default;
    }
    .cal-event-bill         { background:rgba(255,159,67,.15); color:#FF9F43; }
    .cal-event-subscription { background:rgba(0,207,232,.12);  color:#00CFE8; }
    .cal-event-loan         { background:rgba(234,84,85,.12);  color:#EA5455; }
    .cal-event:hover { filter:brightness(.9); }
    [data-bs-theme="dark"] .cal-event-bill         { background:rgba(255,159,67,.22); }
    [data-bs-theme="dark"] .cal-event-subscription { background:rgba(0,207,232,.20); }
    [data-bs-theme="dark"] .cal-event-loan         { background:rgba(234,84,85,.22); }

    .legend-dot { width:10px; height:10px; border-radius:2px; flex-shrink:0; }
  </style>
  </x-slot>

  {{-- Header --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Ödeme Takvimi</h4>
      <p class="text-muted small mb-0">Fatura, abonelik ve kredi ödemelerini tek ekranda gör</p>
    </div>
    <div class="d-flex gap-2 flex-wrap">
      <a href="{{ route('calendar.index', ['month' => $prevMonth]) }}" class="btn btn-outline-secondary btn-sm">
        <i class="icon-base ti tabler-chevron-left icon-16px"></i>
      </a>
      <span class="btn btn-sm btn-outline-primary disabled" style="min-width:130px;pointer-events:none;">
        @php
          $aylar = ['', 'Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
                       'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];
        @endphp
        {{ $aylar[$mon] }} {{ $year }}
      </span>
      <a href="{{ route('calendar.index', ['month' => $nextMonth]) }}" class="btn btn-outline-secondary btn-sm">
        <i class="icon-base ti tabler-chevron-right icon-16px"></i>
      </a>
      <a href="{{ route('calendar.index') }}" class="btn btn-outline-primary btn-sm">
        <i class="icon-base ti tabler-calendar me-1"></i>Bugün
      </a>
    </div>
  </div>

  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  @if(session('error'))
    <div class="alert alert-danger alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-alert-circle me-2"></i>{{ session('error') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  {{-- Summary Stats --}}
  <div class="row g-4 mb-5">
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-danger"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Bu Ay Toplam Ödeme</span>
              <div class="h5 fw-bold mt-1 mb-0 text-danger">₺{{ number_format($totalMonthlyPayments, 0, ',', '.') }}</div>
              <span class="small text-muted">{{ $eventCount }} ödeme planlandı</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-danger">
                <i class="icon-base ti tabler-calendar-dollar icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      @php
        $billCount = collect($events)->flatten(1)->where('type', 'bill')->count();
        $billTotal = collect($events)->flatten(1)->where('type', 'bill')->sum('amount');
      @endphp
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-warning"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Fatura</span>
              <div class="h5 fw-bold mt-1 mb-0 text-warning">₺{{ number_format($billTotal, 0, ',', '.') }}</div>
              <span class="small text-muted">{{ $billCount }} fatura</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-warning">
                <i class="icon-base ti tabler-file-invoice icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      @php
        $subCount = collect($events)->flatten(1)->where('type', 'subscription')->count();
        $loanCount = collect($events)->flatten(1)->where('type', 'loan')->count();
        $loanTotal = collect($events)->flatten(1)->where('type', 'loan')->sum('amount');
      @endphp
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-info"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Abonelik + Kredi</span>
              <div class="h5 fw-bold mt-1 mb-0 text-info">₺{{ number_format($totalMonthlyPayments - $billTotal, 0, ',', '.') }}</div>
              <span class="small text-muted">{{ $subCount }} abonelik, {{ $loanCount }} kredi</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-info">
                <i class="icon-base ti tabler-repeat icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- Calendar + Legend --}}
  <div class="row g-4">
    <div class="col-xl-9">
      <div class="card shadow-sm">
        <div class="card-body p-0">
          <div class="cal-grid">
            {{-- Weekday headers --}}
            @foreach(['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'] as $wd)
              <div class="cal-weekday">{{ $wd }}</div>
            @endforeach

            {{-- Blank offset cells --}}
            @for($o = 0; $o < $firstDayOfWeek; $o++)
              <div class="cal-day empty"></div>
            @endfor

            {{-- Day cells --}}
            @for($d = 1; $d <= $endOfMonth->day; $d++)
              @php
                $isToday  = ($year === (int) now()->year && $mon === (int) now()->month && $d === (int) now()->day);
                $dayEvents = $events[$d] ?? [];
              @endphp
              <div class="cal-day {{ $isToday ? 'today' : '' }}">
                <div class="cal-day-num">{{ $d }}</div>
                @foreach(array_slice($dayEvents, 0, 4) as $ev)
                  <a href="{{ $ev['link'] }}" class="cal-event cal-event-{{ $ev['type'] }} text-decoration-none"
                     title="{{ $ev['title'] }}{{ $ev['amount'] ? ' · ₺' . number_format($ev['amount'], 0, ',', '.') : '' }}">
                    <i class="icon-base ti {{ $ev['icon'] }}" style="font-size:.58rem;"></i>
                    {{ \Illuminate\Support\Str::limit($ev['title'], 14) }}
                  </a>
                @endforeach
                @if(count($dayEvents) > 4)
                  <div class="text-muted" style="font-size:.6rem;">+{{ count($dayEvents) - 4 }} daha</div>
                @endif
              </div>
            @endfor

            {{-- Trailing blank cells to complete final row --}}
            @php
              $totalCells = $firstDayOfWeek + $endOfMonth->day;
              $trailing   = (7 - ($totalCells % 7)) % 7;
            @endphp
            @for($t = 0; $t < $trailing; $t++)
              <div class="cal-day empty"></div>
            @endfor
          </div>
        </div>
      </div>
    </div>

    {{-- Sidebar: Legend + Payment list --}}
    <div class="col-xl-3">
      <div class="card shadow-sm mb-4">
        <div class="card-body py-3">
          <h6 class="fw-semibold mb-3">Gösterge</h6>
          <div class="d-flex align-items-center gap-2 mb-2">
            <div class="legend-dot" style="background:#FF9F43;"></div>
            <span class="small">Fatura</span>
          </div>
          <div class="d-flex align-items-center gap-2 mb-2">
            <div class="legend-dot" style="background:#00CFE8;"></div>
            <span class="small">Abonelik</span>
          </div>
          <div class="d-flex align-items-center gap-2">
            <div class="legend-dot" style="background:#EA5455;"></div>
            <span class="small">Kredi Ödemesi</span>
          </div>
        </div>
      </div>

      <div class="card shadow-sm">
        <div class="card-header py-3">
          <h6 class="card-title mb-0 fw-semibold">Bu Ay Ödemeler</h6>
        </div>
        <div class="card-body p-0" style="max-height:480px;overflow-y:auto;">
          @php
            $flatEvents = [];
            foreach ($events as $day => $dayEvs) {
              foreach ($dayEvs as $ev) {
                $flatEvents[] = array_merge($ev, ['day' => $day]);
              }
            }
            usort($flatEvents, fn($a, $b) => $a['day'] - $b['day']);
          @endphp
          @if(empty($flatEvents))
            <div class="text-center py-5 text-muted">
              <i class="icon-base ti tabler-calendar-off icon-32px d-block mb-2"></i>
              <p class="small mb-0">Bu ay planlanmış ödeme yok.</p>
            </div>
          @else
            <ul class="list-group list-group-flush">
              @foreach($flatEvents as $ev)
              <li class="list-group-item px-3 py-2 d-flex align-items-center gap-2">
                <div class="avatar avatar-xs flex-shrink-0">
                  <span class="avatar-initial rounded bg-label-{{ $ev['color'] }}" style="width:24px;height:24px;">
                    <i class="icon-base ti {{ $ev['icon'] }}" style="font-size:.65rem;"></i>
                  </span>
                </div>
                <div class="flex-grow-1 overflow-hidden">
                  <div class="small fw-medium text-truncate">{{ $ev['title'] }}</div>
                  <div class="text-muted" style="font-size:.68rem;">{{ $ev['day'] }}. {{ $aylar[$mon] }}</div>
                </div>
                @if($ev['amount'])
                  <div class="text-{{ $ev['color'] }} fw-semibold" style="font-size:.78rem;white-space:nowrap;">
                    ₺{{ number_format($ev['amount'], 0, ',', '.') }}
                  </div>
                @endif
              </li>
              @endforeach
            </ul>
          @endif
        </div>
        @if(!empty($flatEvents))
        <div class="card-footer py-2 px-3 d-flex justify-content-between">
          <span class="small text-muted">Toplam</span>
          <span class="small fw-bold text-danger">₺{{ number_format($totalMonthlyPayments, 0, ',', '.') }}</span>
        </div>
        @endif
      </div>

      @if($eventCount === 0)
      <div class="mt-4">
        <div class="card border-0 shadow-sm" style="background:var(--bs-secondary-bg);">
          <div class="card-body text-center py-4">
            <i class="icon-base ti tabler-calendar-plus icon-32px text-primary mb-2 d-block"></i>
            <h6 class="fw-semibold mb-1">Takvim boş</h6>
            <p class="small text-muted mb-3">Fatura, abonelik veya kredi ekleyerek takvimi doldurun.</p>
            <a href="{{ route('bills.index') }}" class="btn btn-sm btn-outline-warning me-2">Fatura Ekle</a>
            <a href="{{ route('subscriptions.index') }}" class="btn btn-sm btn-outline-info">Abonelik</a>
          </div>
        </div>
      </div>
      @endif
    </div>
  </div>
</x-app-layout>
