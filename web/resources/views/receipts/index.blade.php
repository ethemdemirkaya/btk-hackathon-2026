<x-app-layout>
  <x-slot name="title">Fişler & OCR</x-slot>

  <x-slot name="pageCss">
  <style>
    .drop-zone {
      border: 2px dashed var(--bs-primary);
      border-radius: 12px;
      padding: 3rem 2rem;
      text-align: center;
      cursor: pointer;
      transition: background .2s, border-color .2s;
      position: relative;
      background: var(--bs-tertiary-bg);
    }
    .drop-zone.dragover {
      background: rgba(var(--bs-primary-rgb), .06);
      border-color: var(--bs-primary);
    }
    .drop-zone input[type=file] {
      position: absolute; inset: 0; opacity: 0; cursor: pointer; width: 100%; height: 100%;
    }
    .receipt-img-wrap {
      width: 56px; height: 56px; flex-shrink: 0;
      border-radius: 8px; overflow: hidden;
      background: var(--bs-secondary-bg);
      display: flex; align-items: center; justify-content: center;
    }
    .receipt-img-wrap img { width: 100%; height: 100%; object-fit: cover; }
    .item-badge { font-size: .72rem; }
    .ocr-status-processing { animation: paranette-pulse 1.2s infinite; }
    @@keyframes paranette-pulse { 0%,100%{opacity:1} 50%{opacity:.4} }
    .preview-img { max-height: 200px; border-radius: 8px; margin-top: 1rem; object-fit: contain; }
    .upload-status-box {
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
      <h4 class="fw-bold mb-0">Fişler &amp; OCR</h4>
      <p class="text-muted mb-0">Fiş veya fatura yükle — Gemini Vision otomatik analiz eder</p>
    </div>
  </div>

  {{-- Stat cards --}}
  @if($receipts->isNotEmpty())
  @php
    $totalSpent    = $receipts->sum(fn($r) => (float)($r->total_amount ?? 0));
    $withWarranty  = $receipts->filter(fn($r) => !empty($r->warranty_until))->count();
    $avgAmount     = $receipts->count() > 0 ? $totalSpent / $receipts->count() : 0;
  @endphp
  <div class="row g-4 mb-6">
    <div class="col-sm-4">
      <div class="card stat-card position-relative overflow-hidden h-100">
        <div class="accent-bar bg-primary"></div>
        <div class="card-body pt-4">
          <div class="d-flex align-items-start justify-content-between">
            <div>
              <span class="text-muted small">Toplam Harcama</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">₺{{ number_format($totalSpent, 0, ',', '.') }}</div>
              <span class="small text-muted">{{ $receipts->count() }} fiş</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-primary">
                <i class="icon-base ti tabler-receipt icon-22px"></i>
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
              <span class="text-muted small">Ortalama Fiş</span>
              <div class="h5 fw-bold mt-1 mb-0 text-heading">₺{{ number_format($avgAmount, 0, ',', '.') }}</div>
              <span class="small text-muted">Gemini ile analiz edildi</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-info">
                <i class="icon-base ti tabler-robot icon-22px"></i>
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
              <span class="text-muted small">Garanti Takibi</span>
              <div class="h5 fw-bold mt-1 mb-0 text-success">{{ $withWarranty }}</div>
              <span class="small text-muted">ürünün garantisi aktif</span>
            </div>
            <div class="avatar">
              <span class="avatar-initial rounded bg-label-success">
                <i class="icon-base ti tabler-shield-check icon-22px"></i>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  @endif

  {{-- Flash messages --}}
  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-6" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif
  @if(session('error'))
    <div class="alert alert-danger alert-dismissible mb-6" role="alert">
      <i class="icon-base ti tabler-alert-circle me-2"></i>{{ session('error') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  <div class="row g-6">

    {{-- Upload card --}}
    <div class="col-xl-5">
      <div class="card h-100">
        <div class="card-header pb-3">
          <h5 class="card-title mb-0">
            <i class="icon-base ti tabler-upload me-2 text-primary"></i>Fiş Yükle
          </h5>
        </div>
        <div class="card-body d-flex flex-column">

          <div class="drop-zone mb-4" id="dropZone">
            <input type="file" id="fileInput" accept="image/*,.pdf">
            <i class="icon-base ti tabler-camera-plus icon-48px text-primary mb-3 d-block"></i>
            <h6 class="mb-1">Fişi buraya sürükle veya tıkla</h6>
            <p class="text-muted small mb-0">JPG, PNG, PDF — max 10 MB</p>
            <div id="previewWrap" class="d-none">
              <img id="previewImg" src="#" alt="Önizleme" class="preview-img">
              <p id="previewName" class="text-muted small mt-2 mb-0"></p>
            </div>
          </div>

          {{-- Progress / status --}}
          <div id="uploadStatus" class="d-none mb-4">
            <div class="upload-status-box d-flex align-items-center gap-3">
              <div class="spinner-border spinner-border-sm text-primary" role="status"></div>
              <div>
                <div class="fw-medium small" id="statusText">Gemini Vision analiz ediyor…</div>
                <div class="text-muted" style="font-size:.75rem;">Bu işlem birkaç saniye sürebilir</div>
              </div>
            </div>
          </div>

          {{-- OCR result preview (AJAX) --}}
          <div id="ocrResult" class="d-none mb-4">
            <div class="alert alert-success mb-0">
              <div class="fw-semibold mb-2"><i class="icon-base ti tabler-sparkles me-1"></i>Analiz Tamamlandı</div>
              <div id="ocrSummary" class="small"></div>
            </div>
          </div>

          {{-- Camera capture button (mobile only) --}}
          <button type="button" class="btn btn-outline-secondary w-100 mb-2 d-md-none" id="cameraBtn">
            <i class="icon-base ti tabler-camera me-2"></i>Fotoğraf Çek
          </button>
          <input type="file" id="receiptCameraInput" accept="image/*" capture="environment" class="d-none">

          <button type="button" class="btn btn-primary w-100 mt-auto" id="uploadBtn" disabled>
            <i class="icon-base ti tabler-robot me-2"></i>Gemini ile Analiz Et
          </button>

        </div>
      </div>
    </div>

    {{-- Receipts list --}}
    <div class="col-xl-7">
      <div class="card">
        <div class="card-header d-flex align-items-center justify-content-between pb-3">
          <h5 class="card-title mb-0">Yüklenen Fişler</h5>
        </div>
        <div class="card-body p-0">

          @if($receipts->isEmpty())
            <div class="text-center py-8">
              <i class="icon-base ti tabler-receipt-off icon-48px text-muted mb-3 d-block"></i>
              <p class="text-muted mb-0">Henüz fiş yüklenmedi. Soldaki alandan bir fiş yükleyin.</p>
            </div>
          @else
            <div class="list-group list-group-flush" id="receiptList">
              @foreach($receipts as $receipt)
                <div class="list-group-item px-4 py-3" id="receipt-{{ $receipt->id }}">
                  <div class="d-flex align-items-start gap-3">

                    {{-- Thumbnail --}}
                    <div class="receipt-img-wrap">
                      @php $ext = strtolower(pathinfo($receipt->image_path, PATHINFO_EXTENSION)); @endphp
                      @if(in_array($ext, ['jpg','jpeg','png','gif','webp']))
                        <img src="{{ Storage::url($receipt->image_path) }}" alt="Fiş">
                      @else
                        <i class="icon-base ti tabler-file-type-pdf text-danger icon-24px"></i>
                      @endif
                    </div>

                    {{-- Details --}}
                    <div class="flex-grow-1 min-width-0">
                      <div class="d-flex align-items-start justify-content-between gap-2">
                        <div>
                          <div class="fw-semibold text-truncate" style="max-width:220px;">
                            {{ $receipt->merchant_name ?? 'Tanımlanamadı' }}
                          </div>
                          <div class="text-muted small">
                            {{ $receipt->purchased_at?->format('d.m.Y H:i') ?? $receipt->created_at->format('d.m.Y H:i') }}
                          </div>
                        </div>
                        <div class="text-end flex-shrink-0">
                          @if($receipt->total_amount)
                            <div class="fw-bold text-primary">₺{{ number_format((float)$receipt->total_amount, 2, ',', '.') }}</div>
                          @endif
                          @if($receipt->ocr_extracted)
                            @php $cat = $receipt->ocr_extracted['category'] ?? null; @endphp
                            @if($cat)
                              <span class="badge bg-label-info item-badge mt-1">{{ strtoupper($cat) }}</span>
                            @endif
                          @else
                            <span class="badge bg-label-warning item-badge mt-1 ocr-status-processing" style="animation:paranette-pulse 1.2s infinite;">İşleniyor…</span>
                          @endif
                        </div>
                      </div>

                      {{-- Items summary --}}
                      @if($receipt->items && count($receipt->items))
                        <div class="mt-2 d-flex flex-wrap gap-1">
                          @foreach(array_slice($receipt->items, 0, 3) as $item)
                            <span class="badge bg-label-secondary item-badge">
                              {{ $item['name'] ?? '' }}
                              @if(!empty($item['total_price'])) — ₺{{ number_format((float)$item['total_price'], 2, ',', '.') }} @endif
                            </span>
                          @endforeach
                          @if(count($receipt->items) > 3)
                            <span class="badge bg-label-secondary item-badge">+{{ count($receipt->items) - 3 }} daha</span>
                          @endif
                        </div>
                      @endif

                      {{-- KDV / warranty --}}
                      <div class="mt-1 d-flex gap-3">
                        @if($receipt->vat_amount)
                          <span class="text-muted" style="font-size:.75rem;">KDV: ₺{{ number_format((float)$receipt->vat_amount, 2, ',', '.') }}</span>
                        @endif
                        @if($receipt->warranty_until)
                          <span class="text-success" style="font-size:.75rem;">
                            <i class="icon-base ti tabler-shield-check me-1"></i>Garanti: {{ \Carbon\Carbon::parse($receipt->warranty_until)->format('d.m.Y') }}
                          </span>
                        @endif
                      </div>
                    </div>

                    {{-- Delete --}}
                    <button type="button"
                            class="btn btn-icon btn-sm btn-text-danger btn-delete-receipt flex-shrink-0"
                            data-id="{{ $receipt->id }}"
                            data-name="{{ $receipt->merchant_name ?? 'bu fiş' }}"
                            data-url="{{ route('receipts.destroy', $receipt) }}"
                            title="Sil">
                      <i class="icon-base ti tabler-trash icon-18px"></i>
                    </button>

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
    const dropZone        = document.getElementById('dropZone');
    const fileInput       = document.getElementById('fileInput');
    const cameraBtn       = document.getElementById('cameraBtn');
    const cameraInput     = document.getElementById('receiptCameraInput');
    const uploadBtn       = document.getElementById('uploadBtn');
    const previewWrap= document.getElementById('previewWrap');
    const previewImg = document.getElementById('previewImg');
    const previewName= document.getElementById('previewName');
    const uploadStatus = document.getElementById('uploadStatus');
    const statusText   = document.getElementById('statusText');
    const ocrResult    = document.getElementById('ocrResult');
    const ocrSummary   = document.getElementById('ocrSummary');
    const receiptList  = document.getElementById('receiptList');
    const csrfToken    = document.querySelector('meta[name="csrf-token"]').content;

    let selectedFile = null;

    // ---- Drag & drop ----
    ['dragenter','dragover'].forEach(evt =>
      dropZone.addEventListener(evt, e => { e.preventDefault(); dropZone.classList.add('dragover'); })
    );
    ['dragleave','drop'].forEach(evt =>
      dropZone.addEventListener(evt, e => { e.preventDefault(); dropZone.classList.remove('dragover'); })
    );
    dropZone.addEventListener('drop', e => {
      const f = e.dataTransfer.files[0];
      if (f) setFile(f);
    });
    fileInput.addEventListener('change', () => {
      if (fileInput.files[0]) setFile(fileInput.files[0]);
    });

    // Camera capture (mobile) — feeds photo into the main drop-zone flow
    cameraBtn.addEventListener('click', () => cameraInput.click());
    cameraInput.addEventListener('change', () => {
      if (cameraInput.files[0]) setFile(cameraInput.files[0]);
    });

    function setFile(file) {
      selectedFile = file;
      previewName.textContent = file.name + ' (' + (file.size / 1024).toFixed(0) + ' KB)';
      uploadBtn.disabled = false;
      previewWrap.classList.remove('d-none');
      ocrResult.classList.add('d-none');

      if (file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onload = e => { previewImg.src = e.target.result; previewImg.classList.remove('d-none'); };
        reader.readAsDataURL(file);
      } else {
        previewImg.classList.add('d-none');
      }
    }

    // ---- Upload + OCR ----
    uploadBtn.addEventListener('click', async () => {
      if (!selectedFile) return;

      uploadBtn.disabled = true;
      uploadStatus.classList.remove('d-none');
      ocrResult.classList.add('d-none');
      statusText.textContent = 'Gemini Vision analiz ediyor…';

      const formData = new FormData();
      formData.append('image', selectedFile);
      formData.append('_token', csrfToken);

      try {
        const res = await fetch('{{ route('receipts.store') }}', {
          method: 'POST',
          headers: { 'Accept': 'application/json', 'X-CSRF-TOKEN': csrfToken },
          body: formData,
        });
        const data = await res.json();

        uploadStatus.classList.add('d-none');

        if (data.success && data.receipt) {
          const r = data.receipt;
          const merchant = r.merchant_name || 'Tanımlanamadı';
          const amount   = r.total_amount ? '₺' + parseFloat(r.total_amount).toLocaleString('tr-TR', {minimumFractionDigits:2}) : '';
          const cat      = r.ocr_extracted?.category ? r.ocr_extracted.category.toUpperCase() : '';

          ocrSummary.innerHTML =
            '<strong>' + merchant + '</strong>' +
            (amount ? ' &mdash; ' + amount : '') +
            (cat    ? ' <span class="badge bg-label-info">' + cat + '</span>' : '') +
            (r.purchased_at ? '<br><small class="text-muted">' + r.purchased_at + '</small>' : '');

          ocrResult.classList.remove('d-none');

          // Prepend to list
          prependReceiptRow(r);

          // Reset form
          selectedFile = null;
          fileInput.value = '';
          previewWrap.classList.add('d-none');
          uploadBtn.disabled = true;

        } else {
          showError(data.error || 'OCR analizi başarısız.');
          uploadBtn.disabled = false;
        }

      } catch (err) {
        uploadStatus.classList.add('d-none');
        showError('Bağlantı hatası: ' + err.message);
        uploadBtn.disabled = false;
      }
    });

    function prependReceiptRow(r) {
      // Remove empty-state message if visible
      const emptyMsg = document.querySelector('.text-center.py-8');
      if (emptyMsg) emptyMsg.remove();

      // Build a minimal row (full data shown on next page load)
      const merchant = r.merchant_name || 'Tanımlanamadı';
      const amount   = r.total_amount ? '₺' + parseFloat(r.total_amount).toLocaleString('tr-TR', {minimumFractionDigits:2}) : '';
      const cat      = r.ocr_extracted?.category ? r.ocr_extracted.category.toUpperCase() : '';

      const row = document.createElement('div');
      row.className = 'list-group-item px-4 py-3';
      row.id = 'receipt-' + r.id;
      row.innerHTML = `
        <div class="d-flex align-items-start gap-3">
          <div class="receipt-img-wrap">
            <i class="icon-base ti tabler-receipt icon-24px text-primary"></i>
          </div>
          <div class="flex-grow-1">
            <div class="d-flex align-items-start justify-content-between">
              <div>
                <div class="fw-semibold">${merchant}</div>
                <div class="text-muted small">Az önce</div>
              </div>
              <div class="text-end">
                ${amount ? '<div class="fw-bold text-primary">' + amount + '</div>' : ''}
                ${cat    ? '<span class="badge bg-label-info item-badge mt-1">' + cat + '</span>' : ''}
              </div>
            </div>
          </div>
          <button type="button"
            class="btn btn-icon btn-sm btn-text-danger btn-delete-receipt flex-shrink-0"
            data-id="${r.id}"
            data-name="${merchant}"
            data-url="/receipts/${r.id}"
            title="Sil">
            <i class="icon-base ti tabler-trash icon-18px"></i>
          </button>
        </div>`;

      if (receiptList) {
        receiptList.prepend(row);
      } else {
        // Create list if it didn't exist
        const card = document.querySelector('.card-body.p-0');
        const list = document.createElement('div');
        list.className = 'list-group list-group-flush';
        list.id = 'receiptList';
        list.appendChild(row);
        card.appendChild(list);
      }

      // Bind delete for new row
      row.querySelector('.btn-delete-receipt').addEventListener('click', handleDelete);
    }

    function showError(msg) {
      Swal.fire({ icon: 'error', title: 'Hata', text: msg, confirmButtonColor: '#7367f0' });
    }

    // ---- Delete ----
    function handleDelete() {
      const btn    = this;
      const id     = btn.dataset.id;
      const name   = btn.dataset.name;
      const url    = btn.dataset.url;

      Swal.fire({
        title: 'Fişi sil',
        text: name + ' fişini silmek istiyor musunuz?',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#d33',
        cancelButtonColor: '#6c757d',
        confirmButtonText: 'Evet, sil',
        cancelButtonText: 'İptal',
        reverseButtons: true,
      }).then(async result => {
        if (!result.isConfirmed) return;

        const res = await fetch(url, {
          method: 'DELETE',
          headers: { 'X-CSRF-TOKEN': csrfToken, 'Accept': 'application/json' },
        });
        const data = await res.json();

        if (data.success) {
          const row = document.getElementById('receipt-' + id);
          row?.remove();
        } else {
          showError('Silme işlemi başarısız.');
        }
      });
    }

    document.querySelectorAll('.btn-delete-receipt').forEach(btn =>
      btn.addEventListener('click', handleDelete)
    );

  })();
  </script>
  </x-slot>
</x-app-layout>
