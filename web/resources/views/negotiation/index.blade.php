<x-app-layout>
  <x-slot name="title">Pazarlık Ajanı</x-slot>

  <x-slot name="pageCss">
  <style>
    .target-option input[type=radio] { display: none; }
    .target-option .target-card {
      border: 2px solid var(--bs-border-color);
      border-radius: 10px;
      padding: .9rem 1rem;
      cursor: pointer;
      transition: border-color .2s, background .2s;
    }
    .target-option input:checked + .target-card {
      border-color: var(--bs-primary);
      background: rgba(var(--bs-primary-rgb), .06);
    }
    .letter-body {
      font-family: 'Georgia', serif;
      font-size: .93rem;
      line-height: 1.8;
      white-space: pre-wrap;
      background: var(--bs-secondary-bg);
      border: 1px solid var(--bs-border-color);
      border-radius: 8px;
      padding: 1.5rem;
      min-height: 240px;
    }
    .argument-badge {
      display: inline-flex; align-items: center; gap: .4rem;
      background: rgba(var(--bs-success-rgb),.1);
      color: var(--bs-success);
      border-radius: 20px;
      padding: .25rem .75rem;
      font-size: .78rem; font-weight: 500;
    }
    .chance-badge { font-size: 1rem; font-weight: 700; }
    .gen-loading-box {
      background: var(--bs-secondary-bg);
      border: 1px solid var(--bs-border-color);
      border-radius: .5rem;
      padding: .75rem 1rem;
    }
  </style>
  </x-slot>

  {{-- Header --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">Pazarlık Ajanı</h4>
      <p class="text-muted mb-0">Bankan veya kurumlarla müzakere için Gemini Pro resmi mektup yazar</p>
    </div>
  </div>

  {{-- Stat cards --}}
  @php
    $sentCount    = $drafts->where('status', 'sent')->count();
    $draftCount   = $drafts->where('status', 'draft')->count();
    $acceptedCount= $drafts->where('status', 'accepted')->count();
  @endphp
  @if($drafts->isNotEmpty())
  <div class="row g-4 mb-6">
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-primary"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Taslak</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">{{ $drafts->count() }}</div>
              <span class="small text-muted">{{ $draftCount }} beklemede</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-file-text icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-info"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Gönderilen</span>
              <div class="h5 fw-bold mt-1 mb-0 text-info">{{ $sentCount }}</div>
              <span class="small text-muted">kuruma iletildi</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-info">
                <i class="icon-base ti tabler-send icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-success"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Kabul Edildi</span>
              <div class="h5 fw-bold mt-1 mb-0 text-success">{{ $acceptedCount }}</div>
              <span class="small text-muted">başarılı müzakere</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-success">
                <i class="icon-base ti tabler-trophy icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  @endif

  <div class="row g-6">

    {{-- LEFT: Generator form --}}
    <div class="col-xl-5">
      <div class="card">
        <div class="card-header pb-3">
          <h5 class="card-title mb-0">
            <i class="icon-base ti tabler-sparkles me-2 text-primary"></i>Mektup Oluştur
          </h5>
        </div>
        <div class="card-body">

          {{-- Target type grid --}}
          <div class="mb-5">
            <label class="form-label fw-medium mb-3">Ne hakkında pazarlık etmek istiyorsun?</label>
            <div class="row g-3">
              @foreach($targetLabels as $key => $label)
                @php
                  $icons = [
                    'card_interest'      => 'tabler-credit-card',
                    'loan_restructure'   => 'tabler-file-invoice',
                    'bank_fee_waiver'    => 'tabler-coins',
                    'subscription_cancel'=> 'tabler-repeat-off',
                    'insurance_discount' => 'tabler-shield',
                    'salary_raise'       => 'tabler-trending-up',
                    'other'              => 'tabler-dots',
                  ];
                  $icon = $icons[$key] ?? 'tabler-dots';
                @endphp
                <div class="col-6">
                  <label class="target-option w-100">
                    <input type="radio" name="target" value="{{ $key }}" {{ $key === 'card_interest' ? 'checked' : '' }}>
                    <div class="target-card h-100">
                      <i class="icon-base ti {{ $icon }} me-2 text-primary"></i>
                      <span class="small fw-medium">{{ $label }}</span>
                    </div>
                  </label>
                </div>
              @endforeach
            </div>
          </div>

          {{-- Recipient + context --}}
          <div class="mb-4">
            <label class="form-label fw-medium">Alıcı / Kurum Adı</label>
            <input type="text" class="form-control" id="recipientInput"
                   placeholder="örn: Ziraat Bankası, Müşteri Hizmetleri">
          </div>
          <div class="mb-5">
            <label class="form-label fw-medium">Ek Bilgi <span class="text-muted fw-normal small">(isteğe bağlı)</span></label>
            <textarea class="form-control" id="extraContext" rows="3"
                      placeholder="örn: 2 yıldır müşteriyim, faiz oranım %4.5, rakip bankalar %3.2 teklif etti…"></textarea>
          </div>

          <button type="button" class="btn btn-primary w-100" id="generateBtn">
            <i class="icon-base ti tabler-wand me-2"></i>Gemini ile Mektup Yaz
          </button>
          <div id="genLoading" class="d-none mt-3">
            <div class="gen-loading-box d-flex align-items-center gap-3">
              <div class="spinner-border spinner-border-sm text-primary" role="status"></div>
              <div>
                <div class="fw-medium small">Gemini Pro mektup yazıyor…</div>
                <div class="text-muted" style="font-size:.75rem;">Finansal verileriniz analiz ediliyor</div>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>

    {{-- RIGHT: Result + drafts --}}
    <div class="col-xl-7">

      {{-- Generated letter card (hidden until result) --}}
      <div id="resultCard" class="card mb-6 d-none">
        <div class="card-header d-flex align-items-center justify-content-between pb-3">
          <h5 class="card-title mb-0" id="resultSubject">—</h5>
          <div class="d-flex align-items-center gap-2">
            <span id="chanceLabel" class="chance-badge text-success d-none"></span>
            <button class="btn btn-sm btn-outline-primary" id="copyBtn">
              <i class="icon-base ti tabler-copy me-1"></i>Kopyala
            </button>
          </div>
        </div>
        <div class="card-body">
          {{-- Arguments --}}
          <div id="argumentsWrap" class="mb-4 d-none">
            <div class="fw-medium small mb-2">
              <i class="icon-base ti tabler-shield-check text-success me-1"></i>Güçlü Argümanlar
            </div>
            <div id="argumentsList" class="d-flex flex-wrap gap-2"></div>
          </div>

          {{-- Letter body --}}
          <div class="letter-body" id="letterBody"></div>

          {{-- Tips --}}
          <div id="tipsWrap" class="mt-4 d-none">
            <div class="fw-medium small mb-2">
              <i class="icon-base ti tabler-bulb text-warning me-1"></i>Başarı İpuçları
            </div>
            <ul id="tipsList" class="ps-4 mb-0 small text-muted"></ul>
          </div>

          {{-- Actions --}}
          <div class="d-flex gap-2 mt-4 flex-wrap">
            <button class="btn btn-outline-success btn-sm" id="markSentBtn">
              <i class="icon-base ti tabler-send me-1"></i>Gönderildi Olarak İşaretle
            </button>
            <button class="btn btn-outline-danger btn-sm" id="deleteCurrentBtn">
              <i class="icon-base ti tabler-trash me-1"></i>Sil
            </button>
          </div>
        </div>
      </div>

      {{-- Drafts list --}}
      <div class="card">
        <div class="card-header pb-3">
          <h5 class="card-title mb-0">Geçmiş Taslaklar</h5>
        </div>
        <div class="card-body p-0">
          @if($drafts->isEmpty())
            <div class="text-center py-6" id="emptyDrafts">
              <i class="icon-base ti tabler-mail-off icon-48px text-muted mb-3 d-block"></i>
              <p class="text-muted small mb-0">Henüz mektup oluşturulmadı.</p>
            </div>
          @else
            <div class="list-group list-group-flush" id="draftList">
              @foreach($drafts as $draft)
                <div class="list-group-item px-4 py-3" id="draft-{{ $draft->id }}">
                  <div class="d-flex align-items-start justify-content-between gap-3">
                    <div class="flex-grow-1">
                      <div class="d-flex align-items-center gap-2 mb-1 flex-wrap">
                        <span class="fw-semibold small">{{ $draft->subject }}</span>
                        {!! $draft->status_badge !!}
                      </div>
                      <div class="text-muted" style="font-size:.75rem;">
                        {{ $draft->target_label }}
                        @if($draft->recipient_name) &mdash; {{ $draft->recipient_name }} @endif
                        &nbsp;·&nbsp; {{ $draft->created_at->diffForHumans() }}
                      </div>
                    </div>
                    <div class="d-flex gap-1 flex-shrink-0">
                      <button class="btn btn-icon btn-sm btn-text-primary btn-view-draft"
                              data-id="{{ $draft->id }}"
                              data-subject="{{ $draft->subject }}"
                              data-body="{{ $draft->body }}"
                              title="Görüntüle">
                        <i class="icon-base ti tabler-eye icon-18px"></i>
                      </button>
                      <button class="btn btn-icon btn-sm btn-text-danger btn-delete-draft"
                              data-id="{{ $draft->id }}"
                              data-url="{{ route('negotiation.destroy', $draft) }}"
                              title="Sil">
                        <i class="icon-base ti tabler-trash icon-18px"></i>
                      </button>
                    </div>
                  </div>
                </div>
              @endforeach
            </div>
          @endif
        </div>
      </div>

    </div>
  </div>

  <x-slot name="pageJs">
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"></script>
  <script>
  (function () {
    const csrfToken  = document.querySelector('meta[name="csrf-token"]').content;
    const resultCard = document.getElementById('resultCard');
    const letterBody = document.getElementById('letterBody');
    const genLoading = document.getElementById('genLoading');
    let currentDraftId = null;

    // ---- Generate ----
    document.getElementById('generateBtn').addEventListener('click', async () => {
      const target    = document.querySelector('input[name="target"]:checked')?.value;
      const recipient = document.getElementById('recipientInput').value.trim();
      const extra     = document.getElementById('extraContext').value.trim();

      if (!target) { alert('Lütfen bir konu seçin.'); return; }

      document.getElementById('generateBtn').disabled = true;
      genLoading.classList.remove('d-none');
      resultCard.classList.add('d-none');

      try {
        const res  = await fetch('{{ route('negotiation.generate') }}', {
          method : 'POST',
          headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrfToken, 'Accept': 'application/json' },
          body   : JSON.stringify({ target, recipient_name: recipient, extra_context: extra }),
        });
        const data = await res.json();

        genLoading.classList.add('d-none');
        document.getElementById('generateBtn').disabled = false;

        if (!data.success) {
          Swal.fire({ icon: 'error', title: 'Hata', text: data.error || 'Mektup oluşturulamadı.' });
          return;
        }

        const draft = data.draft;
        currentDraftId = draft.id;

        document.getElementById('resultSubject').textContent = draft.subject;
        letterBody.textContent = draft.body;

        // Arguments
        const argsWrap = document.getElementById('argumentsWrap');
        const argsList = document.getElementById('argumentsList');
        if (data.key_arguments?.length) {
          argsList.innerHTML = data.key_arguments
            .map(a => '<span class="argument-badge"><i class="icon-base ti tabler-check"></i>' + a + '</span>')
            .join('');
          argsWrap.classList.remove('d-none');
        } else {
          argsWrap.classList.add('d-none');
        }

        // Tips
        const tipsWrap = document.getElementById('tipsWrap');
        const tipsList = document.getElementById('tipsList');
        if (data.success_tips?.length) {
          tipsList.innerHTML = data.success_tips.map(t => '<li>' + t + '</li>').join('');
          tipsWrap.classList.remove('d-none');
        } else {
          tipsWrap.classList.add('d-none');
        }

        // Chance
        const chanceLabel = document.getElementById('chanceLabel');
        if (data.estimated_chance) {
          chanceLabel.textContent = data.estimated_chance;
          chanceLabel.classList.remove('d-none');
        } else {
          chanceLabel.classList.add('d-none');
        }

        resultCard.classList.remove('d-none');

        // Prepend to draft list
        prependDraftRow(draft);

      } catch(err) {
        genLoading.classList.add('d-none');
        document.getElementById('generateBtn').disabled = false;
        Swal.fire({ icon: 'error', title: 'Bağlantı Hatası', text: err.message });
      }
    });

    // ---- Copy ----
    document.getElementById('copyBtn').addEventListener('click', () => {
      navigator.clipboard.writeText(letterBody.textContent).then(() => {
        Swal.fire({ icon: 'success', title: 'Kopyalandı!', timer: 1200, showConfirmButton: false });
      });
    });

    // ---- Mark sent ----
    document.getElementById('markSentBtn').addEventListener('click', async () => {
      if (!currentDraftId) return;
      const res  = await fetch('/negotiation/' + currentDraftId + '/status', {
        method : 'PATCH',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrfToken, 'Accept': 'application/json' },
        body   : JSON.stringify({ status: 'sent' }),
      });
      const data = await res.json();
      if (data.success) {
        Swal.fire({ icon: 'success', title: 'İşaretlendi', timer: 1200, showConfirmButton: false });
        const badge = document.querySelector('#draft-' + currentDraftId + ' .badge');
        if (badge) { badge.className = 'badge bg-label-info'; badge.textContent = 'Gönderildi'; }
      }
    });

    // ---- Delete current ----
    document.getElementById('deleteCurrentBtn').addEventListener('click', () => {
      if (!currentDraftId) return;
      deleteDraft(currentDraftId, '/negotiation/' + currentDraftId, () => {
        resultCard.classList.add('d-none');
        currentDraftId = null;
      });
    });

    // ---- View from list ----
    document.querySelectorAll('.btn-view-draft').forEach(btn => btn.addEventListener('click', function() {
      document.getElementById('resultSubject').textContent = this.dataset.subject;
      letterBody.textContent = this.dataset.body;
      document.getElementById('argumentsWrap').classList.add('d-none');
      document.getElementById('tipsWrap').classList.add('d-none');
      document.getElementById('chanceLabel').classList.add('d-none');
      currentDraftId = this.dataset.id;
      resultCard.classList.remove('d-none');
      resultCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }));

    // ---- Delete from list ----
    document.querySelectorAll('.btn-delete-draft').forEach(btn => btn.addEventListener('click', function() {
      deleteDraft(this.dataset.id, this.dataset.url);
    }));

    function deleteDraft(id, url, onSuccess) {
      Swal.fire({
        title: 'Taslağı sil', text: 'Bu mektup taslağı kalıcı olarak silinecek.',
        icon: 'warning', showCancelButton: true,
        confirmButtonColor: '#d33', cancelButtonColor: '#6c757d',
        confirmButtonText: 'Sil', cancelButtonText: 'İptal', reverseButtons: true,
      }).then(async result => {
        if (!result.isConfirmed) return;
        const res  = await fetch(url, { method: 'DELETE', headers: { 'X-CSRF-TOKEN': csrfToken, 'Accept': 'application/json' } });
        const data = await res.json();
        if (data.success) {
          document.getElementById('draft-' + id)?.remove();
          onSuccess?.();
        }
      });
    }

    function prependDraftRow(draft) {
      document.getElementById('emptyDrafts')?.remove();
      let list = document.getElementById('draftList');
      if (!list) {
        list = document.createElement('div');
        list.className = 'list-group list-group-flush';
        list.id = 'draftList';
        document.querySelector('.card-body.p-0').appendChild(list);
      }

      const row = document.createElement('div');
      row.className = 'list-group-item px-4 py-3';
      row.id = 'draft-' + draft.id;
      row.innerHTML = `
        <div class="d-flex align-items-start justify-content-between gap-3">
          <div class="flex-grow-1">
            <div class="d-flex align-items-center gap-2 mb-1">
              <span class="fw-semibold small">${draft.subject}</span>
              <span class="badge bg-label-warning">Taslak</span>
            </div>
            <div class="text-muted" style="font-size:.75rem;">Az önce oluşturuldu</div>
          </div>
          <div class="d-flex gap-1 flex-shrink-0">
            <button class="btn btn-icon btn-sm btn-text-primary btn-view-draft"
                    data-id="${draft.id}"
                    data-subject="${draft.subject}"
                    data-body="${(draft.body || '').replace(/"/g,'&quot;')}"
                    title="Görüntüle">
              <i class="icon-base ti tabler-eye icon-18px"></i>
            </button>
            <button class="btn btn-icon btn-sm btn-text-danger btn-delete-draft"
                    data-id="${draft.id}"
                    data-url="/negotiation/${draft.id}"
                    title="Sil">
              <i class="icon-base ti tabler-trash icon-18px"></i>
            </button>
          </div>
        </div>`;

      list.prepend(row);

      row.querySelector('.btn-view-draft').addEventListener('click', function() {
        document.getElementById('resultSubject').textContent = this.dataset.subject;
        letterBody.textContent = this.dataset.body;
        document.getElementById('argumentsWrap').classList.add('d-none');
        document.getElementById('tipsWrap').classList.add('d-none');
        document.getElementById('chanceLabel').classList.add('d-none');
        currentDraftId = this.dataset.id;
        resultCard.classList.remove('d-none');
        resultCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
      });
      row.querySelector('.btn-delete-draft').addEventListener('click', function() {
        deleteDraft(this.dataset.id, this.dataset.url);
      });
    }

  })();
  </script>
  </x-slot>
</x-app-layout>
