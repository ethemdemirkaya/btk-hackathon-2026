<x-app-layout>
  <x-slot name="title">Kur & Altın Alarmları</x-slot>

  {{-- Page Header --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Kur & Altın Alarmları</h4>
      <p class="text-muted small mb-0">Belirlediğin kur seviyelerine ulaşıldığında seni uyarır</p>
    </div>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addAlarmModal">
      <i class="icon-base ti tabler-bell-plus me-1"></i>Alarm Ekle
    </button>
  </div>

  {{-- Flash alerts --}}
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

  {{-- Rate overview cards --}}
  <div class="row g-4 mb-6">
    @php
      $rateCards = [
        ['key' => 'USD', 'label' => 'USD/TRY', 'icon' => 'tabler-currency-dollar',    'color' => 'success'],
        ['key' => 'EUR', 'label' => 'EUR/TRY', 'icon' => 'tabler-currency-euro',      'color' => 'primary'],
        ['key' => 'GBP', 'label' => 'GBP/TRY', 'icon' => 'tabler-currency-pound',    'color' => 'warning'],
        ['key' => 'XAU', 'label' => 'Altın/TRY (gr)', 'icon' => 'tabler-coins',      'color' => 'danger'],
      ];
    @endphp

    @foreach($rateCards as $card)
    <div class="col-6 col-xl-3">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-{{ $card['color'] }}"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">{{ $card['label'] }}</span>
              @if(isset($rates[$card['key']]))
                <div class="h5 fw-bold mt-1 mb-0 text-heading">
                  ₺{{ number_format((float) $rates[$card['key']]->rate_to_try, 2, ',', '.') }}
                </div>
                <span class="small text-muted">{{ \Carbon\Carbon::parse($rates[$card['key']]->date)->format('d.m.Y') }}</span>
              @else
                <div class="h5 fw-bold mt-1 mb-0 text-muted">—</div>
                <span class="small text-muted">Veri yok</span>
              @endif
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-{{ $card['color'] }}">
                <i class="icon-base ti {{ $card['icon'] }} icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    @endforeach
  </div>

  {{-- Alert list --}}
  <div class="card">
    <div class="card-header d-flex align-items-center justify-content-between py-3">
      <h6 class="mb-0 fw-semibold">Aktif Alarmlar</h6>
      <span class="badge bg-label-primary">{{ $alerts->count() }}</span>
    </div>

    @if($alerts->isEmpty())
      <div class="card-body text-center py-8">
        <i class="icon-base ti tabler-bell-off icon-64px text-muted mb-4 d-block"></i>
        <h5 class="mb-2">Henüz alarm eklenmedi</h5>
        <p class="text-muted mb-4">USD, EUR, GBP veya Altın için bir eşik fiyat belirle,<br>hedef aşıldığında burada görünsün.</p>
        <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addAlarmModal">
          <i class="icon-base ti tabler-bell-plus me-1"></i>İlk Alarmı Ekle
        </button>
      </div>
    @else
      <div class="table-responsive">
        <table class="table table-hover mb-0">
          <thead class="paranette-thead">
            <tr>
              <th class="ps-4 py-3">Kur</th>
              <th class="py-3">Koşul</th>
              <th class="py-3">Eşik Fiyat</th>
              <th class="py-3">Güncel Kur</th>
              <th class="py-3">Durum</th>
              <th class="py-3">Son Kontrol</th>
              <th class="py-3 pe-4 text-end">Sil</th>
            </tr>
          </thead>
          <tbody>
            @foreach($alerts as $alert)
            @php
              $currencyLabel = match($alert->currency) {
                'USD'  => 'USD/TRY',
                'EUR'  => 'EUR/TRY',
                'GBP'  => 'GBP/TRY',
                'XAU'  => 'Altın/TRY',
                'GOLD' => 'Altın/TRY',
                default => $alert->currency . '/TRY',
              };
              $currencyColor = match($alert->currency) {
                'USD'  => 'success',
                'EUR'  => 'primary',
                'GBP'  => 'warning',
                'XAU', 'GOLD' => 'danger',
                default => 'secondary',
              };
              $currencyIcon = match($alert->currency) {
                'USD'  => 'tabler-currency-dollar',
                'EUR'  => 'tabler-currency-euro',
                'GBP'  => 'tabler-currency-pound',
                'XAU', 'GOLD' => 'tabler-coins',
                default => 'tabler-currency',
              };
            @endphp
            <tr>
              <td class="ps-4 py-3">
                <div class="d-flex align-items-center gap-2">
                  <span class="avatar avatar-xs">
                    <span class="avatar-initial rounded bg-label-{{ $currencyColor }}">
                      <i class="icon-base ti {{ $currencyIcon }} icon-14px"></i>
                    </span>
                  </span>
                  <span class="fw-semibold small">{{ $currencyLabel }}</span>
                </div>
              </td>
              <td class="py-3">
                @if($alert->condition === 'above')
                  <span class="badge bg-label-danger">
                    <i class="icon-base ti tabler-arrow-up icon-12px me-1"></i>Üstüne Geçince
                  </span>
                @else
                  <span class="badge bg-label-info">
                    <i class="icon-base ti tabler-arrow-down icon-12px me-1"></i>Altına Düşünce
                  </span>
                @endif
              </td>
              <td class="py-3 fw-semibold">
                ₺{{ number_format((float) $alert->threshold, 2, ',', '.') }}
              </td>
              <td class="py-3 text-muted small">
                @if($alert->current_rate !== null)
                  ₺{{ number_format($alert->current_rate, 2, ',', '.') }}
                @else
                  <span class="text-muted">—</span>
                @endif
              </td>
              <td class="py-3">
                @if($alert->is_triggered)
                  <span class="badge bg-danger">
                    <i class="icon-base ti tabler-bell-ringing icon-12px me-1"></i>Tetiklendi
                  </span>
                @else
                  <span class="badge bg-success">
                    <i class="icon-base ti tabler-bell icon-12px me-1"></i>Aktif
                  </span>
                @endif
              </td>
              <td class="py-3 text-muted small">
                @if($alert->triggered_at)
                  {{ $alert->triggered_at->format('d.m.Y H:i') }}
                @else
                  <span class="text-muted">—</span>
                @endif
              </td>
              <td class="py-3 pe-4 text-end">
                <form action="{{ route('fx-alerts.destroy', $alert->id) }}" method="POST" class="d-inline">
                  @csrf @method('DELETE')
                  <button type="button"
                          class="btn btn-icon btn-sm btn-text-danger btn-swal-delete"
                          data-name="{{ $currencyLabel }}"
                          title="Sil">
                    <i class="icon-base ti tabler-trash icon-18px"></i>
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

  {{-- Add Alarm Modal --}}
  <div class="modal fade" id="addAlarmModal" tabindex="-1">
    <div class="modal-dialog">
      <form action="{{ route('fx-alerts.store') }}" method="POST">
        @csrf
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">
              <i class="icon-base ti tabler-bell-plus me-2 text-primary"></i>Alarm Ekle
            </h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body">

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

            {{-- Currency select --}}
            <div class="mb-4">
              <label class="form-label fw-semibold">Kur / Emtia <span class="text-danger">*</span></label>
              <select name="currency" class="form-select @error('currency') is-invalid @enderror" required>
                <option value="" disabled {{ old('currency') ? '' : 'selected' }}>Seç...</option>
                <option value="USD" {{ old('currency') === 'USD' ? 'selected' : '' }}>🇺🇸 USD/TRY — Amerikan Doları</option>
                <option value="EUR" {{ old('currency') === 'EUR' ? 'selected' : '' }}>🇪🇺 EUR/TRY — Euro</option>
                <option value="GBP" {{ old('currency') === 'GBP' ? 'selected' : '' }}>🇬🇧 GBP/TRY — İngiliz Sterlini</option>
                <option value="XAU" {{ old('currency') === 'XAU' ? 'selected' : '' }}>🥇 Altın/TRY — Gram Altın</option>
              </select>
              @error('currency') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </div>

            {{-- Condition (radio) --}}
            <div class="mb-4">
              <label class="form-label fw-semibold">Koşul <span class="text-danger">*</span></label>
              <div class="d-flex gap-4 mt-1">
                <div class="form-check">
                  <input class="form-check-input" type="radio" name="condition" id="condAbove" value="above"
                         {{ old('condition', 'above') === 'above' ? 'checked' : '' }} required>
                  <label class="form-check-label" for="condAbove">
                    <i class="icon-base ti tabler-arrow-up text-danger me-1"></i>Üstüne Geçince
                  </label>
                </div>
                <div class="form-check">
                  <input class="form-check-input" type="radio" name="condition" id="condBelow" value="below"
                         {{ old('condition') === 'below' ? 'checked' : '' }}>
                  <label class="form-check-label" for="condBelow">
                    <i class="icon-base ti tabler-arrow-down text-info me-1"></i>Altına Düşünce
                  </label>
                </div>
              </div>
              @error('condition') <div class="text-danger small mt-1">{{ $message }}</div> @enderror
            </div>

            {{-- Threshold --}}
            <div class="mb-4">
              <label class="form-label fw-semibold">Eşik Fiyat (₺) <span class="text-danger">*</span></label>
              <div class="input-group">
                <span class="input-group-text">₺</span>
                <input type="number"
                       name="threshold"
                       class="form-control @error('threshold') is-invalid @enderror"
                       step="0.01"
                       min="0.01"
                       placeholder="örn: 34.50"
                       value="{{ old('threshold') }}"
                       required>
                @error('threshold') <div class="invalid-feedback">{{ $message }}</div> @enderror
              </div>
              <div class="form-text text-muted">Kur bu seviyeyi geçtiğinde alarm tetiklenecek.</div>
            </div>

          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
            <button type="submit" class="btn btn-primary">
              <i class="icon-base ti tabler-bell-plus me-1"></i>Alarm Ekle
            </button>
          </div>
        </div>
      </form>
    </div>
  </div>

  <x-slot name="pageJs">
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
  <script>
  // Re-open add modal if validation failed
  @if($errors->any())
  bootstrap.Modal.getOrCreateInstance(document.getElementById('addAlarmModal')).show();
  @endif

  // Confirm delete
  document.querySelectorAll('.btn-swal-delete').forEach(function (btn) {
    btn.addEventListener('click', function () {
      const name = this.dataset.name;
      Swal.fire({
        title: '"' + name + '" alarmını sil?',
        text: 'Bu işlem geri alınamaz.',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#6c757d',
        confirmButtonText: 'Evet, sil',
        cancelButtonText: 'Vazgeç',
        reverseButtons: true,
      }).then(function (result) {
        if (result.isConfirmed) btn.closest('form').submit();
      });
    });
  });
  </script>
  </x-slot>
</x-app-layout>
