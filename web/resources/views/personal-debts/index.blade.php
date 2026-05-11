<x-app-layout>
<x-slot name="title">Kişisel Borç Takibi</x-slot>

{{-- ── Page header ──────────────────────────────────────────────────────────── --}}
<div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
  <div>
    <h4 class="fw-bold mb-0">Kişisel Borç Takibi</h4>
    <p class="text-muted mb-0">Arkadaş ve aile borçlarını takip et</p>
  </div>
  <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addDebtModal">
    <i class="icon-base ti tabler-plus me-1"></i>Borç Ekle
  </button>
</div>

{{-- ── Flash alerts ─────────────────────────────────────────────────────────── --}}
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

{{-- ── Stat cards ────────────────────────────────────────────────────────────── --}}
<div class="row g-4 mb-5">

  {{-- Toplam Alacak --}}
  <div class="col-sm-6 col-xl-3">
    <div class="card stat-card position-relative overflow-hidden h-100">
      <div class="accent-bar bg-success"></div>
      <div class="card-body pt-4">
        <div class="d-flex align-items-start justify-content-between">
          <div>
            <span class="text-muted small">Toplam Alacak</span>
            <div class="h5 fw-bold mt-1 mb-0 text-heading">
              ₺{{ number_format($givenActive, 2, ',', '.') }}
            </div>
            <span class="small text-muted">Aktif alacaklarım</span>
          </div>
          <div class="avatar">
            <span class="avatar-initial rounded bg-label-success">
              <i class="icon-base ti tabler-arrow-up-circle icon-22px"></i>
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- Toplam Borç --}}
  <div class="col-sm-6 col-xl-3">
    <div class="card stat-card position-relative overflow-hidden h-100">
      <div class="accent-bar bg-danger"></div>
      <div class="card-body pt-4">
        <div class="d-flex align-items-start justify-content-between">
          <div>
            <span class="text-muted small">Toplam Borç</span>
            <div class="h5 fw-bold mt-1 mb-0 text-heading">
              ₺{{ number_format($receivedActive, 2, ',', '.') }}
            </div>
            <span class="small text-muted">Aktif borçlarım</span>
          </div>
          <div class="avatar">
            <span class="avatar-initial rounded bg-label-danger">
              <i class="icon-base ti tabler-arrow-down-circle icon-22px"></i>
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- Net Pozisyon --}}
  @php
    $netBg    = $netPosition >= 0 ? 'primary' : 'warning';
    $netLabel = $netPosition >= 0 ? '+' : '';
  @endphp
  <div class="col-sm-6 col-xl-3">
    <div class="card stat-card position-relative overflow-hidden h-100">
      <div class="accent-bar bg-{{ $netBg }}"></div>
      <div class="card-body pt-4">
        <div class="d-flex align-items-start justify-content-between">
          <div>
            <span class="text-muted small">Net Pozisyon</span>
            <div class="h5 fw-bold mt-1 mb-0 text-heading">
              {{ $netLabel }}₺{{ number_format(abs($netPosition), 2, ',', '.') }}
            </div>
            <span class="small text-muted">
              {{ $netPosition >= 0 ? 'Net alacaklısın' : 'Net borçlusun' }}
            </span>
          </div>
          <div class="avatar">
            <span class="avatar-initial rounded bg-label-{{ $netBg }}">
              <i class="icon-base ti tabler-scale icon-22px"></i>
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>

  {{-- Kapatılan --}}
  <div class="col-sm-6 col-xl-3">
    <div class="card stat-card position-relative overflow-hidden h-100">
      <div class="accent-bar bg-secondary"></div>
      <div class="card-body pt-4">
        <div class="d-flex align-items-start justify-content-between">
          <div>
            <span class="text-muted small">Kapatılan</span>
            <div class="h5 fw-bold mt-1 mb-0 text-heading">
              {{ $settledCount }}
            </div>
            <span class="small text-muted">kayıt kapandı</span>
          </div>
          <div class="avatar">
            <span class="avatar-initial rounded bg-label-secondary">
              <i class="icon-base ti tabler-circle-check icon-22px"></i>
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>

</div>

{{-- ── Two-column debt lists ─────────────────────────────────────────────────── --}}
<div class="row g-5">

  {{-- ── Left: Benim Alacaklarım (given) ──────────────────────────────────── --}}
  <div class="col-lg-6">
    <div class="card h-100" style="border-left: 3px solid var(--bs-warning);">
      <div class="card-header d-flex align-items-center justify-content-between pb-3">
        <div class="d-flex align-items-center gap-2">
          <i class="icon-base ti tabler-arrow-up-circle text-warning icon-20px"></i>
          <h5 class="mb-0 fw-semibold">Benim Alacaklarım</h5>
        </div>
        <span class="badge bg-label-warning">{{ $given->count() }} kayıt</span>
      </div>

      @if($given->isEmpty())
      <div class="card-body text-center py-8">
        <div class="d-flex justify-content-center mb-3">
          <i class="icon-base ti tabler-mood-happy icon-48px text-muted"></i>
        </div>
        <p class="text-muted mb-0">Henüz alacak kaydı yok.</p>
      </div>
      @else
      <div class="card-body p-0">
        <ul class="list-group list-group-flush">
          @foreach($given as $debt)
          @php
            $initials = collect(explode(' ', $debt->contact_name))
                          ->filter()->map(fn($w) => strtoupper($w[0]))->take(2)->implode('');
          @endphp
          <li class="list-group-item px-4 py-3 {{ $debt->is_settled ? 'bg-body-secondary' : '' }}">
            <div class="d-flex align-items-start gap-3">

              {{-- Avatar --}}
              <div class="avatar flex-shrink-0">
                <span class="avatar-initial rounded-circle bg-label-{{ $debt->is_settled ? 'secondary' : 'warning' }}"
                      style="font-size:.78rem;">
                  {{ $initials }}
                </span>
              </div>

              {{-- Details --}}
              <div class="flex-grow-1 overflow-hidden">
                <div class="d-flex align-items-center gap-2 flex-wrap">
                  <span class="fw-semibold {{ $debt->is_settled ? 'text-muted text-decoration-line-through' : 'text-heading' }}">
                    {{ $debt->contact_name }}
                  </span>
                  @if($debt->is_settled)
                    <span class="badge bg-label-secondary" style="font-size:.68rem;">Kapatıldı</span>
                  @else
                    <span class="badge bg-label-warning" style="font-size:.68rem;">Açık</span>
                  @endif
                </div>
                @if($debt->note)
                <p class="text-muted small mb-1 text-truncate" style="max-width:220px;" title="{{ $debt->note }}">
                  {{ $debt->note }}
                </p>
                @endif
                <small class="text-muted">
                  <i class="icon-base ti tabler-calendar icon-12px me-1"></i>
                  {{ \Carbon\Carbon::parse($debt->created_at)->format('d.m.Y') }}
                  @if($debt->is_settled && $debt->settled_at)
                    &middot; Kapandı: {{ \Carbon\Carbon::parse($debt->settled_at)->format('d.m.Y') }}
                  @endif
                </small>
              </div>

              {{-- Amount + Actions --}}
              <div class="d-flex flex-column align-items-end gap-2 flex-shrink-0">
                <span class="badge bg-{{ $debt->is_settled ? 'label-secondary' : 'label-success' }} fw-bold"
                      style="font-size:.8rem;">
                  ₺{{ number_format($debt->amount, 2, ',', '.') }}
                </span>
                @if(!$debt->is_settled)
                <div class="d-flex gap-1">
                  <form method="POST" action="{{ route('personal-debts.settle', $debt->id) }}" class="d-inline">
                    @csrf @method('PATCH')
                    <button type="submit" class="btn btn-xs btn-outline-success" title="Kapat">
                      <i class="icon-base ti tabler-check icon-12px me-1"></i>Kapat
                    </button>
                  </form>
                  <form method="POST" action="{{ route('personal-debts.destroy', $debt->id) }}" class="d-inline"
                        onsubmit="return confirm('Bu alacak kaydı silinsin mi?')">
                    @csrf @method('DELETE')
                    <button type="submit" class="btn btn-xs btn-outline-danger" title="Sil">
                      <i class="icon-base ti tabler-trash icon-12px"></i>
                    </button>
                  </form>
                </div>
                @else
                <form method="POST" action="{{ route('personal-debts.destroy', $debt->id) }}" class="d-inline"
                      onsubmit="return confirm('Bu kayıt silinsin mi?')">
                  @csrf @method('DELETE')
                  <button type="submit" class="btn btn-xs btn-text-danger" title="Sil">
                    <i class="icon-base ti tabler-trash icon-12px"></i>
                  </button>
                </form>
                @endif
              </div>

            </div>
          </li>
          @endforeach
        </ul>
      </div>
      @endif
    </div>
  </div>

  {{-- ── Right: Benim Borçlarım (received) ─────────────────────────────────── --}}
  <div class="col-lg-6">
    <div class="card h-100" style="border-left: 3px solid var(--bs-danger);">
      <div class="card-header d-flex align-items-center justify-content-between pb-3">
        <div class="d-flex align-items-center gap-2">
          <i class="icon-base ti tabler-arrow-down-circle text-danger icon-20px"></i>
          <h5 class="mb-0 fw-semibold">Benim Borçlarım</h5>
        </div>
        <span class="badge bg-label-danger">{{ $received->count() }} kayıt</span>
      </div>

      @if($received->isEmpty())
      <div class="card-body text-center py-8">
        <div class="d-flex justify-content-center mb-3">
          <i class="icon-base ti tabler-mood-happy icon-48px text-muted"></i>
        </div>
        <p class="text-muted mb-0">Henüz borç kaydı yok.</p>
      </div>
      @else
      <div class="card-body p-0">
        <ul class="list-group list-group-flush">
          @foreach($received as $debt)
          @php
            $initials = collect(explode(' ', $debt->contact_name))
                          ->filter()->map(fn($w) => strtoupper($w[0]))->take(2)->implode('');
          @endphp
          <li class="list-group-item px-4 py-3 {{ $debt->is_settled ? 'bg-body-secondary' : '' }}">
            <div class="d-flex align-items-start gap-3">

              {{-- Avatar --}}
              <div class="avatar flex-shrink-0">
                <span class="avatar-initial rounded-circle bg-label-{{ $debt->is_settled ? 'secondary' : 'danger' }}"
                      style="font-size:.78rem;">
                  {{ $initials }}
                </span>
              </div>

              {{-- Details --}}
              <div class="flex-grow-1 overflow-hidden">
                <div class="d-flex align-items-center gap-2 flex-wrap">
                  <span class="fw-semibold {{ $debt->is_settled ? 'text-muted text-decoration-line-through' : 'text-heading' }}">
                    {{ $debt->contact_name }}
                  </span>
                  @if($debt->is_settled)
                    <span class="badge bg-label-secondary" style="font-size:.68rem;">Kapatıldı</span>
                  @else
                    <span class="badge bg-label-danger" style="font-size:.68rem;">Açık</span>
                  @endif
                </div>
                @if($debt->note)
                <p class="text-muted small mb-1 text-truncate" style="max-width:220px;" title="{{ $debt->note }}">
                  {{ $debt->note }}
                </p>
                @endif
                <small class="text-muted">
                  <i class="icon-base ti tabler-calendar icon-12px me-1"></i>
                  {{ \Carbon\Carbon::parse($debt->created_at)->format('d.m.Y') }}
                  @if($debt->is_settled && $debt->settled_at)
                    &middot; Kapandı: {{ \Carbon\Carbon::parse($debt->settled_at)->format('d.m.Y') }}
                  @endif
                </small>
              </div>

              {{-- Amount + Actions --}}
              <div class="d-flex flex-column align-items-end gap-2 flex-shrink-0">
                <span class="badge bg-{{ $debt->is_settled ? 'label-secondary' : 'label-danger' }} fw-bold"
                      style="font-size:.8rem;">
                  ₺{{ number_format($debt->amount, 2, ',', '.') }}
                </span>
                @if(!$debt->is_settled)
                <div class="d-flex gap-1">
                  <form method="POST" action="{{ route('personal-debts.settle', $debt->id) }}" class="d-inline">
                    @csrf @method('PATCH')
                    <button type="submit" class="btn btn-xs btn-outline-success" title="Kapat">
                      <i class="icon-base ti tabler-check icon-12px me-1"></i>Kapat
                    </button>
                  </form>
                  <form method="POST" action="{{ route('personal-debts.destroy', $debt->id) }}" class="d-inline"
                        onsubmit="return confirm('Bu borç kaydı silinsin mi?')">
                    @csrf @method('DELETE')
                    <button type="submit" class="btn btn-xs btn-outline-danger" title="Sil">
                      <i class="icon-base ti tabler-trash icon-12px"></i>
                    </button>
                  </form>
                </div>
                @else
                <form method="POST" action="{{ route('personal-debts.destroy', $debt->id) }}" class="d-inline"
                      onsubmit="return confirm('Bu kayıt silinsin mi?')">
                  @csrf @method('DELETE')
                  <button type="submit" class="btn btn-xs btn-text-danger" title="Sil">
                    <i class="icon-base ti tabler-trash icon-12px"></i>
                  </button>
                </form>
                @endif
              </div>

            </div>
          </li>
          @endforeach
        </ul>
      </div>
      @endif
    </div>
  </div>

</div>

{{-- ── Add Debt Modal ────────────────────────────────────────────────────────── --}}
<div class="modal fade" id="addDebtModal" tabindex="-1" aria-labelledby="addDebtModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <form action="{{ route('personal-debts.store') }}" method="POST" novalidate>
      @csrf
      <div class="modal-content">

        <div class="modal-header">
          <h5 class="modal-title" id="addDebtModalLabel">
            <i class="icon-base ti tabler-plus me-2"></i>Borç Ekle
          </h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Kapat"></button>
        </div>

        <div class="modal-body">

          {{-- Validation errors --}}
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

          {{-- Direction --}}
          <div class="mb-4">
            <label class="form-label fw-semibold">İşlem Yönü <span class="text-danger">*</span></label>
            <div class="d-flex gap-3">
              <div class="form-check">
                <input class="form-check-input" type="radio" name="direction" id="dirGiven"
                       value="given" {{ old('direction', 'given') === 'given' ? 'checked' : '' }} required>
                <label class="form-check-label" for="dirGiven">
                  Ben verdim 💸 <span class="text-muted small">(alacaklıyım)</span>
                </label>
              </div>
              <div class="form-check">
                <input class="form-check-input" type="radio" name="direction" id="dirReceived"
                       value="received" {{ old('direction') === 'received' ? 'checked' : '' }} required>
                <label class="form-check-label" for="dirReceived">
                  Ben aldım 📥 <span class="text-muted small">(borçluyum)</span>
                </label>
              </div>
            </div>
            @error('direction')
              <div class="text-danger small mt-1">{{ $message }}</div>
            @enderror
          </div>

          {{-- Contact name --}}
          <div class="mb-4">
            <label for="contactName" class="form-label fw-semibold">
              Kişi Adı <span class="text-danger">*</span>
            </label>
            <input type="text"
                   id="contactName"
                   name="contact_name"
                   class="form-control @error('contact_name') is-invalid @enderror"
                   placeholder="örn: Ahmet Yılmaz"
                   value="{{ old('contact_name') }}"
                   maxlength="120"
                   required>
            @error('contact_name')
              <div class="invalid-feedback">{{ $message }}</div>
            @enderror
          </div>

          {{-- Amount --}}
          <div class="mb-4">
            <label for="debtAmount" class="form-label fw-semibold">
              Tutar (₺) <span class="text-danger">*</span>
            </label>
            <div class="input-group">
              <span class="input-group-text">₺</span>
              <input type="number"
                     id="debtAmount"
                     name="amount"
                     class="form-control @error('amount') is-invalid @enderror"
                     placeholder="0,00"
                     step="0.01"
                     min="0.01"
                     value="{{ old('amount') }}"
                     required>
              @error('amount')
                <div class="invalid-feedback">{{ $message }}</div>
              @enderror
            </div>
          </div>

          {{-- Note --}}
          <div class="mb-2">
            <label for="debtNote" class="form-label fw-semibold">Not <span class="text-muted small">(isteğe bağlı)</span></label>
            <textarea id="debtNote"
                      name="note"
                      class="form-control @error('note') is-invalid @enderror"
                      rows="3"
                      placeholder="Ödünç nedeni, tarih, hatırlatma..."
                      maxlength="500">{{ old('note') }}</textarea>
            @error('note')
              <div class="invalid-feedback">{{ $message }}</div>
            @enderror
            <div class="text-muted small mt-1">Maks. 500 karakter</div>
          </div>

        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
          <button type="submit" class="btn btn-primary">
            <i class="icon-base ti tabler-device-floppy me-1"></i>Kaydet
          </button>
        </div>

      </div>
    </form>
  </div>
</div>

<x-slot name="pageJs">
<script>
// Re-open modal if validation failed
@if($errors->any())
(function () {
  var modal = document.getElementById('addDebtModal');
  if (modal) bootstrap.Modal.getOrCreateInstance(modal).show();
})();
@endif
</script>
</x-slot>

</x-app-layout>
