<x-app-layout>
  <x-slot name="title">Abonelikler</x-slot>

  <x-slot name="pageCss">
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/select2/select2.css') }}">
    <link rel="stylesheet" href="{{ asset('assets/vendor/libs/flatpickr/flatpickr.css') }}">
  </x-slot>

  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Abonelikler</h4>
      <p class="text-muted small mb-0">Tekrarlayan ödemeler ve dijital abonelikler</p>
    </div>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
      <i class="icon-base ti tabler-plus me-1"></i>Abonelik Ekle
    </button>
  </div>

  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  {{-- Premium stat cards --}}
  @if($totalMonthly > 0)
  <div class="row g-4 mb-6">
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-info"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Aylık Toplam</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">₺{{ number_format($totalMonthly, 0, ',', '.') }}</div>
              <span class="small text-muted">{{ $subscriptions->count() }} aktif abonelik</span>
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
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-warning"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Yıllık Toplam</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">₺{{ number_format($totalMonthly * 12, 0, ',', '.') }}</div>
              <span class="small text-muted">Yıllık projeksiyon</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-warning">
                <i class="icon-base ti tabler-calendar-repeat icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        @php $monthlyPct = auth()->user()->monthly_income > 0 ? round($totalMonthly / auth()->user()->monthly_income * 100, 1) : 0; @endphp
        <div class="accent-bar {{ $monthlyPct > 10 ? 'bg-danger' : ($monthlyPct > 5 ? 'bg-warning' : 'bg-success') }}"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Gelirin %'si</span>
              <div class="h5 fw-bold mt-1 mb-0 {{ $monthlyPct > 10 ? 'text-danger' : ($monthlyPct > 5 ? 'text-warning' : 'text-success') }}">
                %{{ $monthlyPct }}
              </div>
              <span class="small text-muted">{{ $monthlyPct > 10 ? 'Fazla! Gözden geçir' : 'Makul seviye' }}</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $monthlyPct > 10 ? 'danger' : ($monthlyPct > 5 ? 'warning' : 'success') }}">
                <i class="icon-base ti tabler-percentage icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  @endif

  {{-- Market Price Comparison Widget --}}
  @if($subscriptions->isNotEmpty())
  @php
    $marketPrices = config('subscription_prices.list');
    $pricesLastUpdated = config('subscription_prices.last_updated');

    // Find user subscriptions by fuzzy name match
    $userSubNames = $subscriptions->pluck('name')->map(fn ($n) => mb_strtolower($n));
    $matched = collect($marketPrices)->map(function ($market) use ($subscriptions) {
      $userSub = $subscriptions->first(fn ($s) =>
        str_contains(mb_strtolower($s->name), mb_strtolower(explode(' ', $market['name'])[0]))
        || str_contains(mb_strtolower($market['name']), mb_strtolower(explode(' ', $s->name)[0]))
      );
      $market['user_price'] = $userSub
        ? match($userSub->billing_cycle) {
            'yearly' => (float)$userSub->amount / 12,
            'weekly' => (float)$userSub->amount * 4.33,
            default  => (float)$userSub->amount,
          }
        : null;
      $market['subscribed'] = $userSub !== null;
      return $market;
    })->filter(fn ($m) => $m['subscribed']); // Only show services user actually subscribes to
  @endphp
  @if($matched->isNotEmpty())
  <div class="card mb-6 shadow-sm">
    <div class="card-header d-flex align-items-center justify-content-between">
      <div>
        <h5 class="card-title mb-0">
          <i class="icon-base ti tabler-chart-bar me-2 text-primary"></i>Piyasa Fiyat Karşılaştırması
        </h5>
        <small class="text-muted">Aboneliklerini Türkiye piyasa fiyatlarıyla karşılaştır</small>
      </div>
      <span class="badge bg-label-primary">{{ now()->format('M Y') }}</span>
    </div>
    <div class="card-body pb-2">
      <div class="row g-3">
        @foreach($matched as $m)
        @php
          $userPr = $m['user_price'];
          $mktPr  = $m['price'];
          $diff   = $userPr !== null ? $userPr - $mktPr : null;
          $pct    = $mktPr > 0 && $diff !== null ? round(abs($diff) / $mktPr * 100) : 0;
          $status = $diff === null ? 'none' : ($diff < -0.5 ? 'cheaper' : ($diff > 0.5 ? 'expensive' : 'equal'));
        @endphp
        <div class="col-sm-6 col-xl-4">
          <div class="p-3 rounded border d-flex align-items-center gap-3"
               style="background:var(--bs-secondary-bg);">
            <div class="avatar flex-shrink-0">
              <span class="avatar-initial rounded bg-label-{{ $m['color'] }}">
                <i class="icon-base ti {{ $m['icon'] }} icon-20px"></i>
              </span>
            </div>
            <div class="flex-grow-1 min-w-0">
              <div class="fw-medium small text-truncate">{{ $m['name'] }}</div>
              <div class="text-muted" style="font-size:.72rem;">
                Piyasa: ₺{{ number_format($mktPr, 2, ',', '.') }}/ay
              </div>
            </div>
            <div class="text-end flex-shrink-0">
              @if($userPr !== null)
                <div class="fw-bold small">₺{{ number_format($userPr, 2, ',', '.') }}</div>
                @if($status === 'cheaper')
                  <span class="badge bg-label-success" style="font-size:.65rem;">
                    <i class="icon-base ti tabler-arrow-down icon-10px"></i> %{{ $pct }} ucuz
                  </span>
                @elseif($status === 'expensive')
                  <span class="badge bg-label-danger" style="font-size:.65rem;">
                    <i class="icon-base ti tabler-arrow-up icon-10px"></i> %{{ $pct }} pahalı
                  </span>
                @else
                  <span class="badge bg-label-secondary" style="font-size:.65rem;">Piyasa fiyatı</span>
                @endif
              @else
                <span class="badge bg-label-secondary" style="font-size:.65rem;">Abonelik yok</span>
              @endif
            </div>
          </div>
        </div>
        @endforeach
      </div>
      <p class="text-muted small mt-3 mb-1">
        <i class="icon-base ti tabler-info-circle me-1"></i>
        Referans fiyatlar son olarak {{ \Carbon\Carbon::parse($pricesLastUpdated)->translatedFormat('d F Y') }} tarihinde güncellendi. Kampanya ve paket indirimleri farklılık gösterebilir.
      </p>
    </div>
  </div>
  @endif
  @endif

  {{-- Auto-detected candidates --}}
  @if($candidates->isNotEmpty())
  <div class="card mb-6 shadow-sm">
    <div class="card-header d-flex align-items-center gap-2">
      <h5 class="card-title mb-0">
        <i class="icon-base ti tabler-sparkles me-2 text-warning"></i>Otomatik Tespit Edilenler
      </h5>
      <span class="badge bg-label-warning">{{ $candidates->count() }} aday</span>
    </div>
    <div class="card-body">
      <p class="text-muted small mb-4">İşlemlerinde tekrar eden bu ödemeler abonelik olabilir:</p>
      <div class="row g-3">
        @foreach($candidates as $c)
        <div class="col-sm-6 col-xl-3">
          <div class="border rounded p-3 d-flex align-items-center gap-3">
            <div class="avatar flex-shrink-0">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-repeat icon-20px"></i>
              </span>
            </div>
            <div class="flex-grow-1 min-w-0">
              <div class="fw-medium small text-truncate">{{ $c->merchant_name ?: $c->description }}</div>
              <div class="text-muted" style="font-size:.75rem;">
                ~₺{{ number_format($c->avg_amount, 2, ',', '.') }} · {{ $c->occurrences }}× görüldü
              </div>
            </div>
            <button type="button"
                    class="btn btn-sm btn-outline-primary flex-shrink-0 btn-convert-candidate"
                    data-name="{{ $c->merchant_name ?: ucwords(mb_strtolower($c->description)) }}"
                    data-merchant="{{ $c->merchant_name }}"
                    data-amount="{{ number_format($c->avg_amount, 2, '.', '') }}"
                    title="Abonelik olarak ekle">
              <i class="icon-base ti tabler-plus icon-14px"></i>
            </button>
          </div>
        </div>
        @endforeach
      </div>
    </div>
  </div>
  @endif

  {{-- Subscriptions list --}}
  @if($subscriptions->isEmpty())
  <div class="card">
    <div class="card-body text-center py-6">
      <div class="d-flex justify-content-center mb-4">
        <i class="icon-base ti tabler-repeat-off icon-64px text-muted"></i>
      </div>
      <h5 class="mb-2">Abonelik eklenmedi</h5>
      <p class="text-muted mb-4">Dijital aboneliklerini ve tekrarlayan ödemelerini takip et.</p>
      <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addModal">
        <i class="icon-base ti tabler-plus me-1"></i>İlk Aboneliği Ekle
      </button>
    </div>
  </div>
  @else

  {{-- ═══ AI Insight Panel ══════════════════════════════════════════════════ --}}
  <x-ai-insight-panel page="subscriptions" :autoload="false" title="Abonelik Avcısı" />

  @php
    $subIcons = ['tabler-brand-netflix','tabler-brand-spotify','tabler-brand-youtube','tabler-device-tv','tabler-cloud','tabler-package','tabler-star'];
    $subColors = ['danger','success','danger','info','primary','warning','secondary'];
  @endphp
  <div class="row g-4">
    @foreach($subscriptions as $i => $sub)
    @php
      $si = $i % count($subIcons);
      $monthlyEq = match($sub->billing_cycle) { 'yearly' => $sub->amount / 12, 'weekly' => $sub->amount * 4.33, default => $sub->amount };
      $daysToNext = (int) round(\Carbon\Carbon::now()->startOfDay()->diffInDays(\Carbon\Carbon::parse($sub->next_billing_date)->startOfDay(), false));
    @endphp
    <div class="col-md-6 col-xl-4">
      <div class="card h-100 shadow-sm">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between mb-3">
            <div class="d-flex align-items-center gap-3">
              <div class="avatar">
                <span class="avatar-initial rounded bg-label-{{ $subColors[$si] }}">
                  <i class="icon-base ti {{ $subIcons[$si] }} icon-22px"></i>
                </span>
              </div>
              <div>
                <div class="fw-semibold">{{ $sub->name }}</div>
                <div class="text-muted small">{{ $sub->merchant_name ?: '—' }}</div>
              </div>
            </div>
            <div class="text-end">
              <div class="fw-bold text-primary">₺{{ number_format($sub->amount, 2, ',', '.') }}</div>
              <div class="text-muted small">
                {{ match($sub->billing_cycle) { 'monthly' => '/ay', 'yearly' => '/yıl', 'weekly' => '/hafta', default => '' } }}
              </div>
            </div>
          </div>

          @if($sub->billing_cycle !== 'monthly')
          <div class="text-muted small mb-2">
            <i class="icon-base ti tabler-calculator me-1"></i>
            Aylık denk: ₺{{ number_format($monthlyEq, 2, ',', '.') }}
          </div>
          @endif

          <div class="d-flex align-items-center justify-content-between mt-3">
            <span class="badge bg-label-{{ $daysToNext <= 3 ? 'danger' : ($daysToNext <= 7 ? 'warning' : 'secondary') }}">
              <i class="icon-base ti tabler-calendar icon-12px me-1"></i>
              {{ $daysToNext <= 0 ? 'Bugün!' : "{$daysToNext} gün sonra" }}
            </span>
            <form action="{{ route('subscriptions.destroy', $sub->id) }}" method="POST" class="d-inline">
              @csrf @method('DELETE')
              <button type="button" class="btn btn-icon btn-sm btn-text-danger btn-swal-delete"
                      data-name="{{ $sub->name }}" title="İptal">
                <i class="icon-base ti tabler-x icon-18px"></i>
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>
    @endforeach
  </div>
  @endif

  {{-- Add modal --}}
  <div class="modal fade" id="addModal" tabindex="-1">
    <div class="modal-dialog">
      <form action="{{ route('subscriptions.store') }}" method="POST">
        @csrf
        <div class="modal-content">
          <div class="modal-header border-0">
            <h5 class="modal-title">Abonelik Ekle</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body pt-0">
            @if($errors->any())
            <div class="alert alert-danger alert-dismissible mb-4" role="alert">
              <ul class="mb-0 ps-3">
                @foreach($errors->all() as $error)
                  <li>{{ $error }}</li>
                @endforeach
              </ul>
              <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
            @endif
            <div class="mb-4">
              <label class="form-label">Abonelik Adı <span class="text-danger">*</span></label>
              <input type="text" name="name" class="form-control @error('name') is-invalid @enderror"
                     placeholder="örn: Spotify Premium" value="{{ old('name') }}" required>
              @error('name') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </div>
            <div class="mb-4">
              <label class="form-label">Mağaza / Hizmet</label>
              <input type="text" name="merchant_name" class="form-control @error('merchant_name') is-invalid @enderror"
                     placeholder="örn: Spotify AB" value="{{ old('merchant_name') }}">
              @error('merchant_name') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </div>
            <div class="row g-4">
              <div class="col-6">
                <label class="form-label">Tutar <span class="text-danger">*</span></label>
                <input type="number" name="amount" class="form-control @error('amount') is-invalid @enderror"
                       step="0.01" min="0" value="{{ old('amount') }}" required>
                @error('amount') <div class="invalid-feedback">{{ $message }}</div> @enderror
              </div>
              <div class="col-6">
                <label class="form-label">Döngü</label>
                <select id="billingCycleSelect" name="billing_cycle"
                        class="form-select @error('billing_cycle') is-invalid @enderror">
                  <option value="monthly" {{ old('billing_cycle', 'monthly') === 'monthly' ? 'selected' : '' }}>Aylık</option>
                  <option value="yearly"  {{ old('billing_cycle') === 'yearly'  ? 'selected' : '' }}>Yıllık</option>
                  <option value="weekly"  {{ old('billing_cycle') === 'weekly'  ? 'selected' : '' }}>Haftalık</option>
                </select>
                @error('billing_cycle') <div class="invalid-feedback">{{ $message }}</div> @enderror
              </div>
            </div>
            <div class="mt-4">
              <label class="form-label">Sonraki Ödeme <span class="text-danger">*</span></label>
              <input type="text" id="nextBillingDatePicker" name="next_billing_date"
                     class="form-control @error('next_billing_date') is-invalid @enderror"
                     placeholder="GG.AA.YYYY"
                     value="{{ old('next_billing_date') ? \Carbon\Carbon::parse(old('next_billing_date'))->format('d.m.Y') : now()->addMonth()->format('d.m.Y') }}"
                     autocomplete="off" required readonly>
              @error('next_billing_date') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </div>
          </div>
          <div class="modal-footer border-0">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-primary">Ekle</button>
          </div>
        </div>
      </form>
    </div>
  </div>

  <x-slot name="pageJs">
  <script src="{{ asset('assets/vendor/libs/select2/select2.js') }}"></script>
  <script src="{{ asset('assets/vendor/libs/flatpickr/flatpickr.js') }}"></script>
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
  <script>
  // ── Turkish locale for Flatpickr ─────────────────────────────────────────
  const fpTurkish = {
    weekdays: {
      shorthand: ['Paz','Pzt','Sal','Çar','Per','Cum','Cmt'],
      longhand:  ['Pazar','Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi'],
    },
    months: {
      shorthand: ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'],
      longhand:  ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'],
    },
    firstDayOfWeek: 1,
    rangeSeparator: ' - ',
    weekAbbreviation: 'Hf',
    scrollTitle: 'Kaydırarak artır',
    toggleTitle: 'AM/PM\'e tıkla',
    amPM: ['ÖÖ','ÖS'],
    yearAriaLabel: 'Yıl',
    monthAriaLabel: 'Ay',
    hourAriaLabel: 'Saat',
    minuteAriaLabel: 'Dakika',
    time_24hr: true,
  };

  let billingCycleSelect2 = null;
  let nextBillingFlatpickr = null;

  // ── Initialize Select2 + Flatpickr on modal show ─────────────────────────
  const addModal = document.getElementById('addModal');

  addModal.addEventListener('shown.bs.modal', function () {
    // Select2
    if (!billingCycleSelect2) {
      billingCycleSelect2 = $('#billingCycleSelect').select2({
        dropdownParent: $(addModal),
        minimumResultsForSearch: Infinity,
        width: '100%',
      });
    }

    // Flatpickr
    if (!nextBillingFlatpickr) {
      nextBillingFlatpickr = flatpickr('#nextBillingDatePicker', {
        locale: fpTurkish,
        dateFormat: 'd.m.Y',
        allowInput: false,
        disableMobile: true,
        defaultDate: document.getElementById('nextBillingDatePicker').value || null,
        appendTo: addModal,
      });
    }
  });

  addModal.addEventListener('hidden.bs.modal', function () {
    // Destroy on hide so they re-init cleanly next open (handles DOM reuse)
    if (billingCycleSelect2) {
      $('#billingCycleSelect').select2('destroy');
      billingCycleSelect2 = null;
    }
    if (nextBillingFlatpickr) {
      nextBillingFlatpickr.destroy();
      nextBillingFlatpickr = null;
    }
  });

  // ── Re-open add modal if validation failed ────────────────────────────────
  @if($errors->any())
  bootstrap.Modal.getOrCreateInstance(addModal).show();
  @endif

  // ── SweetAlert delete confirmation ───────────────────────────────────────
  document.querySelectorAll('.btn-swal-delete').forEach(function (btn) {
    btn.addEventListener('click', function () {
      Swal.fire({
        title: '"' + this.dataset.name + '" aboneliğini iptal et?',
        text: 'Bu abonelik iptal edilecek.',
        icon: 'warning', showCancelButton: true,
        confirmButtonColor: '#d33', cancelButtonColor: '#6c757d',
        confirmButtonText: 'Evet, iptal et', cancelButtonText: 'Vazgeç', reverseButtons: true,
      }).then(result => { if (result.isConfirmed) this.closest('form').submit(); });
    });
  });

  // ── Auto-fill from candidate cards ───────────────────────────────────────
  const nameInput  = addModal.querySelector('[name="name"]');
  const merchantIn = addModal.querySelector('[name="merchant_name"]');
  const amountIn   = addModal.querySelector('[name="amount"]');

  document.querySelectorAll('.btn-convert-candidate').forEach(function (btn) {
    btn.addEventListener('click', function () {
      nameInput.value  = this.dataset.name;
      merchantIn.value = this.dataset.merchant;
      amountIn.value   = this.dataset.amount;
      bootstrap.Modal.getOrCreateInstance(addModal).show();
    });
  });
  </script>
  </x-slot>
</x-app-layout>
