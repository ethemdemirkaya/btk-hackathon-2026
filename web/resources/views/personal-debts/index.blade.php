<x-app-layout>
<x-slot name="title">Kişisel Borç Takibi</x-slot>

{{-- ── Page Header ────────────────────────────────────────────────────────── --}}
<div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
  <div>
    <h4 class="fw-bold mb-0">Kişisel Borç Takibi</h4>
    <p class="text-muted small mb-0">Arkadaş ve aile borçlarını yönet · AI ile otomatik tespit</p>
  </div>
  <div class="d-flex gap-2 flex-wrap">
    <button class="btn btn-outline-primary btn-sm" id="aiDetectBtn">
      <i class="icon-base ti tabler-sparkles me-1"></i>AI ile Tara
    </button>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addDebtModal">
      <i class="icon-base ti tabler-plus me-1"></i>Borç Ekle
    </button>
  </div>
</div>

{{-- ── Flash Alerts ───────────────────────────────────────────────────────── --}}
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

{{-- ── Stat Cards ──────────────────────────────────────────────────────────── --}}
<div class="row g-4 mb-5">

  <div class="col-sm-6 col-xl-3">
    <div class="card stat-card position-relative overflow-hidden h-100">
      <div class="accent-bar bg-success"></div>
      <div class="card-body pt-4">
        <div class="d-flex align-items-start justify-content-between">
          <div>
            <span class="text-muted small">Toplam Alacak</span>
            <div class="h5 fw-bold mt-1 mb-0 text-success">₺{{ number_format($givenActive, 2, ',', '.') }}</div>
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

  <div class="col-sm-6 col-xl-3">
    <div class="card stat-card position-relative overflow-hidden h-100">
      <div class="accent-bar bg-danger"></div>
      <div class="card-body pt-4">
        <div class="d-flex align-items-start justify-content-between">
          <div>
            <span class="text-muted small">Toplam Borç</span>
            <div class="h5 fw-bold mt-1 mb-0 text-danger">₺{{ number_format($receivedActive, 2, ',', '.') }}</div>
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

  @php
    $netBg   = $netPosition >= 0 ? 'primary' : 'warning';
    $netSign = $netPosition >= 0 ? '+' : '';
  @endphp
  <div class="col-sm-6 col-xl-3">
    <div class="card stat-card position-relative overflow-hidden h-100">
      <div class="accent-bar bg-{{ $netBg }}"></div>
      <div class="card-body pt-4">
        <div class="d-flex align-items-start justify-content-between">
          <div>
            <span class="text-muted small">Net Pozisyon</span>
            <div class="h5 fw-bold mt-1 mb-0 text-{{ $netBg }}">
              {{ $netSign }}₺{{ number_format(abs($netPosition), 2, ',', '.') }}
            </div>
            <span class="small text-muted">{{ $netPosition >= 0 ? 'Net alacaklısın' : 'Net borçlusun' }}</span>
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

  <div class="col-sm-6 col-xl-3">
    <div class="card stat-card position-relative overflow-hidden h-100">
      <div class="accent-bar bg-secondary"></div>
      <div class="card-body pt-4">
        <div class="d-flex align-items-start justify-content-between">
          <div>
            <span class="text-muted small">Kapatılan</span>
            <div class="h5 fw-bold mt-1 mb-0 text-heading">{{ $settledCount }}</div>
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

{{-- ═══ AI Insight Panel ═══════════════════════════════════════════════════ --}}
<x-ai-insight-panel page="personal_debts" :autoload="false" title="Borç Optimizörü" />

{{-- ── Debt List Card ──────────────────────────────────────────────────────── --}}
<div class="card">
  <div class="card-header d-flex align-items-center justify-content-between gap-3 flex-wrap">
    <ul class="nav nav-tabs card-header-tabs mb-0" id="debtFilterTabs">
      <li class="nav-item">
        <button class="nav-link active" type="button" data-filter="all">
          Tümü
          <span class="badge bg-label-secondary ms-1">{{ $debts->count() }}</span>
        </button>
      </li>
      <li class="nav-item">
        <button class="nav-link" type="button" data-filter="active">
          Aktif
          <span class="badge bg-label-primary ms-1">{{ $debts->where('is_settled', false)->count() }}</span>
        </button>
      </li>
      <li class="nav-item">
        <button class="nav-link" type="button" data-filter="settled">
          Kapatılan
          <span class="badge bg-label-secondary ms-1">{{ $settledCount }}</span>
        </button>
      </li>
    </ul>
  </div>

  @if($debts->isEmpty())
  <div class="card-body text-center py-8">
    <i class="icon-base ti tabler-users icon-64px text-muted mb-4 d-block"></i>
    <h5 class="mb-2">Henüz borç kaydı yok</h5>
    <p class="text-muted mb-4">Arkadaş veya aile ile borç alışverişlerini takip et.<br>
      Dilersan <strong>AI ile Tara</strong> butonuyla işlemlerini otomatik analiz et.</p>
    <button class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#addDebtModal">
      <i class="icon-base ti tabler-plus me-1"></i>İlk Kaydı Ekle
    </button>
  </div>
  @else
  <div class="card-body p-0">
    <ul class="list-group list-group-flush" id="debtList">
      @foreach($debts as $debt)
      @php
        $initials = collect(explode(' ', $debt->contact_name))
                      ->filter()->map(fn($w) => mb_strtoupper(mb_substr($w, 0, 1, 'UTF-8'), 'UTF-8'))->take(2)->implode('');
        $isGiven  = $debt->direction === 'given';
        $color    = $debt->is_settled ? 'secondary' : ($isGiven ? 'success' : 'danger');
      @endphp
      <li class="list-group-item px-4 py-3 debt-item {{ $debt->is_settled ? 'opacity-75' : '' }}"
          data-filter="{{ $debt->is_settled ? 'settled' : 'active' }}">
        <div class="d-flex align-items-start gap-3">

          {{-- Avatar --}}
          <div class="avatar flex-shrink-0">
            <span class="avatar-initial rounded-circle bg-label-{{ $color }}" style="font-size:.78rem;">
              {{ $initials ?: '?' }}
            </span>
          </div>

          {{-- Details --}}
          <div class="flex-grow-1 overflow-hidden">
            <div class="d-flex align-items-center gap-2 flex-wrap mb-1">
              <span class="fw-semibold {{ $debt->is_settled ? 'text-muted text-decoration-line-through' : 'text-heading' }}">
                {{ $debt->contact_name }}
              </span>
              <span class="badge bg-label-{{ $isGiven ? 'success' : 'danger' }}" style="font-size:.68rem;">
                {{ $isGiven ? 'Alacak' : 'Borç' }}
              </span>
              @if($debt->is_settled)
                <span class="badge bg-label-secondary" style="font-size:.68rem;">Kapatıldı</span>
              @endif
              @if($debt->is_auto_detected)
                <span class="badge bg-label-primary" style="font-size:.68rem;">AI</span>
              @endif
            </div>
            @if($debt->note)
            <p class="text-muted small mb-1 text-truncate" style="max-width:360px;" title="{{ $debt->note }}">
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
            <span class="fw-bold {{ $debt->is_settled ? 'text-muted' : ($isGiven ? 'text-success' : 'text-danger') }}"
                  style="font-size:.95rem;">
              {{ $isGiven ? '+' : '−' }}₺{{ number_format($debt->amount, 2, ',', '.') }}
            </span>
            @if(!$debt->is_settled)
            <div class="d-flex gap-1">
              <button type="button" class="btn btn-xs btn-outline-success btn-settle"
                      data-id="{{ $debt->id }}" data-name="{{ $debt->contact_name }}" title="Kapat">
                <i class="icon-base ti tabler-check icon-12px me-1"></i>Kapat
              </button>
              <button type="button" class="btn btn-xs btn-outline-danger btn-delete"
                      data-id="{{ $debt->id }}" data-name="{{ $debt->contact_name }}" title="Sil">
                <i class="icon-base ti tabler-trash icon-12px"></i>
              </button>
            </div>
            @else
            <button type="button" class="btn btn-xs btn-text-danger btn-delete"
                    data-id="{{ $debt->id }}" data-name="{{ $debt->contact_name }}" title="Sil">
              <i class="icon-base ti tabler-trash icon-12px"></i>
            </button>
            @endif
          </div>

        </div>
      </li>
      @endforeach
    </ul>
    <div id="emptyFilterState" class="text-center py-6 d-none">
      <i class="icon-base ti tabler-filter-off icon-48px text-muted mb-3 d-block"></i>
      <p class="text-muted mb-0" id="emptyFilterText">Bu filtrede kayıt yok.</p>
    </div>
  </div>
  @endif
</div>

{{-- ── Add Debt Modal ──────────────────────────────────────────────────────── --}}
<div class="modal fade" id="addDebtModal" tabindex="-1">
  <div class="modal-dialog">
    <form action="{{ route('personal-debts.store') }}" method="POST" novalidate>
      @csrf
      <div class="modal-content">
        <div class="modal-header border-0">
          <h5 class="modal-title"><i class="icon-base ti tabler-plus me-2"></i>Borç Ekle</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body pt-0">
          @if($errors->any())
          <div class="alert alert-danger alert-dismissible mb-4" role="alert">
            <ul class="mb-0 ps-3">
              @foreach($errors->all() as $e) <li>{{ $e }}</li> @endforeach
            </ul>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
          </div>
          @endif
          <div class="mb-4">
            <label class="form-label fw-semibold">İşlem Yönü <span class="text-danger">*</span></label>
            <div class="d-flex gap-4">
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
          </div>
          <div class="mb-4">
            <label class="form-label fw-semibold">Kişi Adı <span class="text-danger">*</span></label>
            <input type="text" name="contact_name"
                   class="form-control @error('contact_name') is-invalid @enderror"
                   placeholder="örn: Ahmet Yılmaz"
                   value="{{ old('contact_name') }}" maxlength="120" required>
            @error('contact_name') <div class="invalid-feedback">{{ $message }}</div> @enderror
          </div>
          <div class="mb-4">
            <label class="form-label fw-semibold">Tutar (₺) <span class="text-danger">*</span></label>
            <div class="input-group">
              <span class="input-group-text">₺</span>
              <input type="number" name="amount"
                     class="form-control @error('amount') is-invalid @enderror"
                     placeholder="0,00" step="0.01" min="0.01"
                     value="{{ old('amount') }}" required>
              @error('amount') <div class="invalid-feedback">{{ $message }}</div> @enderror
            </div>
          </div>
          <div>
            <label class="form-label fw-semibold">
              Not <span class="text-muted small">(isteğe bağlı)</span>
            </label>
            <textarea name="note" class="form-control @error('note') is-invalid @enderror"
                      rows="3" placeholder="Ödünç nedeni, hatırlatma…" maxlength="500">{{ old('note') }}</textarea>
          </div>
        </div>
        <div class="modal-footer border-0">
          <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
          <button type="submit" class="btn btn-primary">
            <i class="icon-base ti tabler-device-floppy me-1"></i>Kaydet
          </button>
        </div>
      </div>
    </form>
  </div>
</div>

{{-- ── AI Detect Modal ─────────────────────────────────────────────────────── --}}
<div class="modal fade" id="aiDetectModal" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header border-0">
        <h5 class="modal-title">
          <i class="icon-base ti tabler-sparkles me-2 text-primary"></i>AI Borç Tespiti
        </h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body pt-0">

        <div id="aiLoadState" class="text-center py-6">
          <div class="spinner-border text-primary mb-3" role="status"></div>
          <p class="text-muted mb-0">Son 90 günün işlemleri taranıyor…</p>
        </div>

        <div id="aiErrorState" class="d-none">
          <div class="alert alert-danger mb-0">
            <i class="icon-base ti tabler-alert-circle me-2"></i>
            <span id="aiErrorText">Bir hata oluştu.</span>
          </div>
        </div>

        <div id="aiEmptyState" class="d-none text-center py-6">
          <i class="icon-base ti tabler-mood-happy icon-64px text-muted mb-3 d-block"></i>
          <h6 class="mb-2">Tespit edilecek borç bulunamadı</h6>
          <p class="text-muted small mb-0">Son 90 günde borç ile ilgili işlem tespit edilemedi.</p>
        </div>

        <div id="aiResultsState" class="d-none">
          <div id="debtSuggestionsSection">
            <h6 class="fw-semibold mb-3 d-flex align-items-center gap-2">
              <span class="badge bg-label-warning">Yeni Tespit</span>
              Borç gibi görünen işlemler
            </h6>
            <div id="debtSuggestionsList" class="d-flex flex-column gap-2 mb-5"></div>
          </div>
          <div id="repaymentSuggestionsSection">
            <h6 class="fw-semibold mb-3 d-flex align-items-center gap-2">
              <span class="badge bg-label-success">Geri Ödeme</span>
              Mevcut borçlara geri ödeme olabilecek işlemler
            </h6>
            <div id="repaymentSuggestionsList" class="d-flex flex-column gap-2"></div>
          </div>
        </div>

      </div>
      <div class="modal-footer border-0">
        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
      </div>
    </div>
  </div>
</div>

{{-- ── Confirm Detected Modal ──────────────────────────────────────────────── --}}
<div class="modal fade" id="confirmDebtModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header border-0">
        <h5 class="modal-title">
          <i class="icon-base ti tabler-check me-2 text-success"></i>Borç Olarak Kaydet
        </h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body pt-0">
        <p class="text-muted small mb-4">
          AI tarafından tespit edilen işlemi borç kaydı olarak kaydet. Bilgileri düzenleyebilirsin.
        </p>
        <input type="hidden" id="cfTransactionId">
        <div class="mb-4">
          <label class="form-label fw-semibold">Kişi Adı <span class="text-danger">*</span></label>
          <input type="text" id="cfContactName" class="form-control"
                 placeholder="örn: Ahmet Yılmaz" maxlength="120">
        </div>
        <div class="mb-4">
          <label class="form-label fw-semibold">Tutar (₺) <span class="text-danger">*</span></label>
          <div class="input-group">
            <span class="input-group-text">₺</span>
            <input type="number" id="cfAmount" class="form-control" step="0.01" min="0.01">
          </div>
        </div>
        <div class="mb-4">
          <label class="form-label fw-semibold">İşlem Yönü</label>
          <select id="cfDirection" class="form-select">
            <option value="given">Ben verdim (alacaklıyım)</option>
            <option value="received">Ben aldım (borçluyum)</option>
          </select>
        </div>
        <div>
          <label class="form-label fw-semibold">Not</label>
          <textarea id="cfNote" class="form-control" rows="2" placeholder="İşlem açıklaması…"></textarea>
        </div>
      </div>
      <div class="modal-footer border-0">
        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
        <button type="button" class="btn btn-primary" id="cfSaveBtn">
          <i class="icon-base ti tabler-device-floppy me-1"></i>Kaydet
        </button>
      </div>
    </div>
  </div>
</div>

{{-- ── Mark Repayment Modal ─────────────────────────────────────────────────── --}}
<div class="modal fade" id="repaymentModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header border-0">
        <h5 class="modal-title">
          <i class="icon-base ti tabler-coins me-2 text-success"></i>Geri Ödeme Onayla
        </h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body pt-0">
        <div class="alert alert-info mb-4">
          <i class="icon-base ti tabler-info-circle me-2"></i>
          <span id="rpDebtInfo"></span>
        </div>
        <input type="hidden" id="rpDebtId">
        <input type="hidden" id="rpTransactionId">
        <div>
          <label class="form-label fw-semibold">Geri Ödeme Tutarı (₺)</label>
          <div class="input-group">
            <span class="input-group-text">₺</span>
            <input type="number" id="rpAmount" class="form-control" step="0.01" min="0.01">
          </div>
        </div>
      </div>
      <div class="modal-footer border-0">
        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">İptal</button>
        <button type="button" class="btn btn-success" id="rpConfirmBtn">
          <i class="icon-base ti tabler-check me-1"></i>Ödendi, Borcu Kapat
        </button>
      </div>
    </div>
  </div>
</div>

<x-slot name="pageJs">
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
<script>
const CSRF = document.querySelector('meta[name=csrf-token]').content;

// Re-open add modal if validation failed
@if($errors->any())
bootstrap.Modal.getOrCreateInstance(document.getElementById('addDebtModal')).show();
@endif

// ── Filter tabs ──────────────────────────────────────────────────────────
(function () {
  const tabs     = document.querySelectorAll('#debtFilterTabs .nav-link');
  const items    = document.querySelectorAll('.debt-item');
  const empty    = document.getElementById('emptyFilterState');
  const emptyTxt = document.getElementById('emptyFilterText');

  tabs.forEach(function (tab) {
    tab.addEventListener('click', function () {
      tabs.forEach(function (t) { t.classList.remove('active'); });
      this.classList.add('active');
      const filter  = this.dataset.filter;
      let   visible = 0;
      items.forEach(function (item) {
        const show = filter === 'all' || item.dataset.filter === filter;
        item.style.display = show ? '' : 'none';
        if (show) visible++;
      });
      if (empty) {
        if (visible === 0) {
          empty.classList.remove('d-none');
          emptyTxt.textContent = filter === 'active' ? 'Aktif borç kaydı yok.' : 'Kapatılmış kayıt yok.';
        } else {
          empty.classList.add('d-none');
        }
      }
    });
  });
})();

// ── Settle ───────────────────────────────────────────────────────────────
document.querySelectorAll('.btn-settle').forEach(function (btn) {
  btn.addEventListener('click', function () {
    const id   = this.dataset.id;
    const name = this.dataset.name;
    Swal.fire({
      title: '"' + name + '" borcu kapatılsın mı?',
      text:  'Bu borç ödenmiş olarak işaretlenecek.',
      icon:  'question',
      showCancelButton:     true,
      confirmButtonColor:   '#28c76f',
      cancelButtonColor:    '#6c757d',
      confirmButtonText:    'Evet, kapat',
      cancelButtonText:     'Vazgeç',
      reverseButtons:       true,
    }).then(function (result) {
      if (!result.isConfirmed) return;
      fetch('/personal-debts/' + id + '/settle', {
        method: 'PATCH',
        headers: { 'X-CSRF-TOKEN': CSRF, 'Accept': 'application/json', 'Content-Type': 'application/json' },
      })
      .then(function (r) { return r.json(); })
      .then(function () {
        Swal.fire({ icon: 'success', title: 'Kapatıldı!', timer: 1200, showConfirmButton: false });
        setTimeout(function () { location.reload(); }, 1300);
      })
      .catch(function () {
        Swal.fire({ icon: 'error', title: 'Hata', text: 'İşlem başarısız.', confirmButtonColor: '#7367f0' });
      });
    });
  });
});

// ── Delete ───────────────────────────────────────────────────────────────
document.querySelectorAll('.btn-delete').forEach(function (btn) {
  btn.addEventListener('click', function () {
    const id   = this.dataset.id;
    const name = this.dataset.name;
    Swal.fire({
      title:  '"' + name + '" kaydı silinsin mi?',
      text:   'Bu işlem geri alınamaz.',
      icon:   'warning',
      showCancelButton:     true,
      confirmButtonColor:   '#ea5455',
      cancelButtonColor:    '#6c757d',
      confirmButtonText:    'Evet, sil',
      cancelButtonText:     'Vazgeç',
      reverseButtons:       true,
    }).then(function (result) {
      if (!result.isConfirmed) return;
      fetch('/personal-debts/' + id, {
        method: 'DELETE',
        headers: { 'X-CSRF-TOKEN': CSRF, 'Accept': 'application/json', 'Content-Type': 'application/json' },
      })
      .then(function (r) { return r.json(); })
      .then(function () {
        Swal.fire({ icon: 'success', title: 'Silindi!', timer: 1200, showConfirmButton: false });
        setTimeout(function () { location.reload(); }, 1300);
      })
      .catch(function () {
        Swal.fire({ icon: 'error', title: 'Hata', text: 'İşlem başarısız.', confirmButtonColor: '#7367f0' });
      });
    });
  });
});

// ── AI Detection ─────────────────────────────────────────────────────────
(function () {
  const aiDetectBtn            = document.getElementById('aiDetectBtn');
  const loadState              = document.getElementById('aiLoadState');
  const errorState             = document.getElementById('aiErrorState');
  const errorText              = document.getElementById('aiErrorText');
  const emptyState             = document.getElementById('aiEmptyState');
  const resultsState           = document.getElementById('aiResultsState');
  const debtSuggestionsSection = document.getElementById('debtSuggestionsSection');
  const repSuggestionsSection  = document.getElementById('repaymentSuggestionsSection');
  const debtList               = document.getElementById('debtSuggestionsList');
  const repList                = document.getElementById('repaymentSuggestionsList');

  function showState(el) {
    [loadState, errorState, emptyState, resultsState].forEach(function (s) { s.classList.add('d-none'); });
    el.classList.remove('d-none');
  }

  aiDetectBtn.addEventListener('click', function () {
    debtList.innerHTML = '';
    repList.innerHTML  = '';
    showState(loadState);
    bootstrap.Modal.getOrCreateInstance(document.getElementById('aiDetectModal')).show();

    fetch('{{ route("personal-debts.ai-detect") }}', {
      headers: { 'Accept': 'application/json', 'X-CSRF-TOKEN': CSRF },
    })
    .then(function (r) {
      if (!r.ok) return r.json().then(function (e) { throw new Error(e.error || 'Sunucu hatası.'); });
      return r.json();
    })
    .then(function (data) {
      const debts = data.debt_suggestions      || [];
      const reps  = data.repayment_suggestions || [];

      if (debts.length === 0 && reps.length === 0) {
        showState(emptyState);
        return;
      }

      if (debts.length > 0) {
        debtSuggestionsSection.classList.remove('d-none');
        debts.forEach(function (s) { debtList.appendChild(buildDebtCard(s)); });
      } else {
        debtSuggestionsSection.classList.add('d-none');
      }

      if (reps.length > 0) {
        repSuggestionsSection.classList.remove('d-none');
        reps.forEach(function (s) { repList.appendChild(buildRepCard(s)); });
      } else {
        repSuggestionsSection.classList.add('d-none');
      }

      showState(resultsState);
    })
    .catch(function (err) {
      errorText.textContent = err.message || 'Bir hata oluştu.';
      showState(errorState);
    });
  });

  function buildDebtCard(s) {
    const div        = document.createElement('div');
    const isGiven    = s.direction === 'given';
    const color      = isGiven ? 'success' : 'danger';
    const dirLabel   = isGiven ? 'Ben verdim (alacaklı)' : 'Ben aldım (borçlu)';
    const amount     = parseFloat(s.amount).toLocaleString('tr-TR', { minimumFractionDigits: 2 });
    const date       = s.transaction_date ? s.transaction_date.substring(0, 10) : '';
    const isAi       = s.source === 'ai';
    const confColor  = s.confidence === 'high' ? 'success' : 'warning';
    const confLabel  = s.confidence === 'high' ? 'Yüksek güven' : 'Orta güven';
    div.className    = 'card border' + (isAi ? ' border-primary border-opacity-25' : '');
    div.innerHTML    =
      '<div class="card-body py-3 px-4">' +
        '<div class="d-flex align-items-start justify-content-between gap-3">' +
          '<div class="flex-grow-1">' +
            '<div class="d-flex align-items-center flex-wrap gap-2 mb-1">' +
              '<span class="badge bg-label-' + color + '">' + dirLabel + '</span>' +
              (isAi
                ? '<span class="badge bg-label-primary" title="Yapay zeka tespiti">' +
                    '<i class="icon-base ti tabler-sparkles icon-10px me-1"></i>AI</span>' +
                  '<span class="badge bg-label-' + confColor + '">' + confLabel + '</span>'
                : '') +
              (s.is_repayment_hint ? '<span class="badge bg-label-info">Geri ödeme olabilir</span>' : '') +
            '</div>' +
            '<p class="fw-semibold mb-1 text-heading">' + esc(s.description || '—') + '</p>' +
            '<small class="text-muted">' +
              (s.suggested_contact ? 'Kişi: <strong>' + esc(s.suggested_contact) + '</strong> &middot; ' : '') + date +
            '</small>' +
            (isAi && s.ai_reason
              ? '<div class="mt-2 d-flex align-items-start gap-1">' +
                  '<i class="icon-base ti tabler-brain icon-12px text-primary mt-1 flex-shrink-0"></i>' +
                  '<small class="text-primary">' + esc(s.ai_reason) + '</small>' +
                '</div>'
              : '') +
          '</div>' +
          '<div class="text-end flex-shrink-0">' +
            '<div class="fw-bold text-' + color + ' mb-2">₺' + amount + '</div>' +
            '<button class="btn btn-sm btn-primary" ' +
              'data-tx-id="' + escAttr(s.transaction_id) + '" ' +
              'data-amount="' + s.amount + '" ' +
              'data-direction="' + s.direction + '" ' +
              'data-contact="' + escAttr(s.suggested_contact || '') + '" ' +
              'data-desc="' + escAttr(s.description || '') + '" ' +
              'onclick="openConfirmModal(this)">' +
              '<i class="icon-base ti tabler-plus me-1"></i>Kaydet' +
            '</button>' +
          '</div>' +
        '</div>' +
      '</div>';
    return div;
  }

  function buildRepCard(s) {
    const div        = document.createElement('div');
    const amount     = parseFloat(s.repayment_amount).toLocaleString('tr-TR', { minimumFractionDigits: 2 });
    const debtAmt    = parseFloat(s.debt_amount).toLocaleString('tr-TR', { minimumFractionDigits: 2 });
    const date       = s.transaction_date ? s.transaction_date.substring(0, 10) : '';
    div.className    = 'card border';
    div.innerHTML    =
      '<div class="card-body py-3 px-4">' +
        '<div class="d-flex align-items-start justify-content-between gap-3">' +
          '<div class="flex-grow-1">' +
            '<p class="fw-semibold mb-1 text-heading">' + esc(s.description || '—') + '</p>' +
            '<small class="text-muted">' +
              esc(s.debt_contact) + ' &middot; Orijinal borç: ₺' + debtAmt + ' &middot; ' + date +
            '</small>' +
          '</div>' +
          '<div class="text-end flex-shrink-0">' +
            '<div class="fw-bold text-success mb-2">₺' + amount + '</div>' +
            '<button class="btn btn-sm btn-outline-success" ' +
              'data-debt-id="' + s.debt_id + '" ' +
              'data-tx-id="' + escAttr(s.transaction_id) + '" ' +
              'data-amount="' + s.repayment_amount + '" ' +
              'data-contact="' + escAttr(s.debt_contact) + '" ' +
              'data-debt-amount="' + s.debt_amount + '" ' +
              'onclick="openRepaymentModal(this)">' +
              '<i class="icon-base ti tabler-check me-1"></i>Kapat' +
            '</button>' +
          '</div>' +
        '</div>' +
      '</div>';
    return div;
  }

  function esc(str) {
    const d = document.createElement('div');
    d.appendChild(document.createTextNode(String(str)));
    return d.innerHTML;
  }
  function escAttr(str) {
    return String(str).replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }
})();

// ── Confirm Detected Modal ───────────────────────────────────────────────
function openConfirmModal(btn) {
  document.getElementById('cfTransactionId').value = btn.dataset.txId  || '';
  document.getElementById('cfAmount').value        = btn.dataset.amount || '';
  document.getElementById('cfDirection').value     = btn.dataset.direction || 'given';
  document.getElementById('cfContactName').value   = btn.dataset.contact || '';
  document.getElementById('cfNote').value          = btn.dataset.desc   || '';
  bootstrap.Modal.getOrCreateInstance(document.getElementById('confirmDebtModal')).show();
}

document.getElementById('cfSaveBtn').addEventListener('click', function () {
  const contactName = document.getElementById('cfContactName').value.trim();
  const amount      = parseFloat(document.getElementById('cfAmount').value);
  if (!contactName) {
    Swal.fire({ icon: 'warning', title: 'Kişi adı zorunlu', confirmButtonColor: '#7367f0' });
    return;
  }
  if (!amount || amount <= 0) {
    Swal.fire({ icon: 'warning', title: 'Geçerli bir tutar girin', confirmButtonColor: '#7367f0' });
    return;
  }

  const btn       = this;
  btn.disabled    = true;
  btn.innerHTML   = '<span class="spinner-border spinner-border-sm me-1" style="width:.85rem;height:.85rem;"></span>Kaydediliyor…';

  fetch('{{ route("personal-debts.confirm-detected") }}', {
    method:  'POST',
    headers: { 'X-CSRF-TOKEN': CSRF, 'Content-Type': 'application/json', 'Accept': 'application/json' },
    body:    JSON.stringify({
      contact_name:   contactName,
      amount:         amount,
      direction:      document.getElementById('cfDirection').value,
      note:           document.getElementById('cfNote').value,
      transaction_id: document.getElementById('cfTransactionId').value || null,
    }),
  })
  .then(function (r) {
    if (!r.ok) return r.json().then(function (e) { throw new Error(e.message || 'Hata.'); });
    return r.json();
  })
  .then(function () {
    bootstrap.Modal.getInstance(document.getElementById('confirmDebtModal'))?.hide();
    bootstrap.Modal.getInstance(document.getElementById('aiDetectModal'))?.hide();
    Swal.fire({ icon: 'success', title: 'Borç kaydedildi!', timer: 1400, showConfirmButton: false });
    setTimeout(function () { location.reload(); }, 1500);
  })
  .catch(function (err) {
    btn.disabled  = false;
    btn.innerHTML = '<i class="icon-base ti tabler-device-floppy me-1"></i>Kaydet';
    Swal.fire({ icon: 'error', title: 'Hata', text: err.message, confirmButtonColor: '#7367f0' });
  });
});

// ── Mark Repayment Modal ─────────────────────────────────────────────────
function openRepaymentModal(btn) {
  document.getElementById('rpDebtId').value       = btn.dataset.debtId;
  document.getElementById('rpTransactionId').value = btn.dataset.txId;
  document.getElementById('rpAmount').value        = btn.dataset.amount;
  const debtAmt = parseFloat(btn.dataset.debtAmount).toLocaleString('tr-TR', { minimumFractionDigits: 2 });
  document.getElementById('rpDebtInfo').textContent =
    btn.dataset.contact + ' — ₺' + debtAmt + ' borcu geri ödeme ile kapatılacak.';
  bootstrap.Modal.getOrCreateInstance(document.getElementById('repaymentModal')).show();
}

document.getElementById('rpConfirmBtn').addEventListener('click', function () {
  const debtId = document.getElementById('rpDebtId').value;
  const txId   = document.getElementById('rpTransactionId').value;
  const amount = parseFloat(document.getElementById('rpAmount').value);
  if (!amount || amount <= 0) {
    Swal.fire({ icon: 'warning', title: 'Geçerli tutar girin', confirmButtonColor: '#7367f0' });
    return;
  }

  const btn     = this;
  btn.disabled  = true;
  btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1" style="width:.85rem;height:.85rem;"></span>İşleniyor…';

  fetch('/personal-debts/' + debtId + '/mark-repayment', {
    method:  'POST',
    headers: { 'X-CSRF-TOKEN': CSRF, 'Content-Type': 'application/json', 'Accept': 'application/json' },
    body:    JSON.stringify({ transaction_id: txId, repayment_amount: amount }),
  })
  .then(function (r) {
    if (!r.ok) return r.json().then(function (e) { throw new Error(e.message || 'Hata.'); });
    return r.json();
  })
  .then(function (data) {
    bootstrap.Modal.getInstance(document.getElementById('repaymentModal'))?.hide();
    bootstrap.Modal.getInstance(document.getElementById('aiDetectModal'))?.hide();
    const msg = data.profit > 0
      ? '₺' + parseFloat(data.profit).toFixed(2) + ' TL kar ile borç kapatıldı!'
      : 'Borç başarıyla kapatıldı.';
    Swal.fire({ icon: 'success', title: msg, timer: 1800, showConfirmButton: false });
    setTimeout(function () { location.reload(); }, 1900);
  })
  .catch(function (err) {
    btn.disabled  = false;
    btn.innerHTML = '<i class="icon-base ti tabler-check me-1"></i>Ödendi, Borcu Kapat';
    Swal.fire({ icon: 'error', title: 'Hata', text: err.message, confirmButtonColor: '#7367f0' });
  });
});
</script>
</x-slot>

</x-app-layout>
