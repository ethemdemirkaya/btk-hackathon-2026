<x-app-layout>
  <x-slot name="title">CSV İçe Aktar</x-slot>

  <x-slot name="pageCss">
  <style>
    .drop-zone {
      border: 2px dashed var(--bs-border-color);
      border-radius: .75rem;
      transition: border-color .2s, background .2s;
      cursor: pointer;
      min-height: 160px;
    }
    .drop-zone.drag-over, .drop-zone:hover {
      border-color: #7367F0;
      background: rgba(115,103,240,.04);
    }
    .drop-zone input[type="file"] { display:none; }
    .step-badge {
      width: 28px; height: 28px;
      border-radius: 50%;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: .75rem;
      font-weight: 700;
    }
    .preview-table th { font-size:.7rem; text-transform:uppercase; letter-spacing:.04em; }
    .preview-table td { font-size:.8rem; }
  </style>
  </x-slot>

  {{-- Header --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <div class="d-flex align-items-center gap-2 mb-1">
        <a href="{{ route('transactions.index') }}" class="text-muted">
          <i class="icon-base ti tabler-arrow-left icon-18px"></i>
        </a>
        <h4 class="fw-bold mb-0">CSV İçe Aktar</h4>
      </div>
      <p class="text-muted small mb-0 ms-4">Banka ekstresi yükle, sütun eşle, onayla</p>
    </div>
  </div>

  @if(session('success'))
    <div class="alert alert-success alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-circle-check me-2"></i>{{ session('success') }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  @if($errors->any())
    <div class="alert alert-danger alert-dismissible mb-5" role="alert">
      <i class="icon-base ti tabler-alert-circle me-2"></i>{{ $errors->first() }}
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  @endif

  <div class="row g-5">
    {{-- Left: Steps --}}
    <div class="col-xl-4">
      <div class="card shadow-sm mb-4">
        <div class="card-body">
          <h6 class="fw-semibold mb-4">Nasıl Çalışır?</h6>
          @foreach([
            ['num'=>'1','color'=>'primary', 'title'=>'CSV Dosya Seç',    'desc'=>'Bankanızın dışa aktarma özelliğinden CSV indirin.'],
            ['num'=>'2','color'=>'warning', 'title'=>'Sütunları Eşleştir','desc'=>'Tarih, tutar ve açıklama sütunlarını belirtin.'],
            ['num'=>'3','color'=>'success', 'title'=>'Onayla & Aktar',   'desc'=>'Önizlemeyi kontrol edip tümünü içe aktarın.'],
          ] as $s)
          <div class="d-flex gap-3 mb-4">
            <div class="step-badge bg-label-{{ $s['color'] }} text-{{ $s['color'] }} flex-shrink-0">{{ $s['num'] }}</div>
            <div>
              <div class="fw-semibold small">{{ $s['title'] }}</div>
              <div class="text-muted small">{{ $s['desc'] }}</div>
            </div>
          </div>
          @endforeach
        </div>
      </div>

      <div class="card shadow-sm">
        <div class="card-header py-3">
          <h6 class="card-title mb-0 fw-semibold">
            <i class="icon-base ti tabler-file-description me-2 text-info"></i>Desteklenen Formatlar
          </h6>
        </div>
        <div class="card-body">
          <div class="accordion accordion-flush" id="formatAccordion">
            @foreach([
              ['bank' => 'Garanti BBVA', 'icon' => 'tabler-building-bank', 'color' => 'success',
               'format' => "Tarih;Açıklama;Borç;Alacak;Bakiye\n01.05.2026;Market;250,00;;...\n02.05.2026;Maaş;;35000,00;..."],
              ['bank' => 'İş Bankası',   'icon' => 'tabler-building-bank', 'color' => 'primary',
               'format' => "Tarih;İşlem Açıklaması;Tutar;Bakiye\n01.05.2026;BES Otomatik Ödeme;-250,00;..."],
              ['bank' => 'Akbank',       'icon' => 'tabler-building-bank', 'color' => 'danger',
               'format' => "Değer Tarihi;Açıklama;Tutar\n01.05.2026;MARKET ALIŞVERİŞİ;-250,00"],
              ['bank' => 'Genel (CSV)',  'icon' => 'tabler-table', 'color' => 'secondary',
               'format' => "Tarih;Açıklama;Tutar\n01.05.2026;Herhangi İşlem;-100,00"],
            ] as $fmt)
            <div class="accordion-item border-0">
              <h6 class="accordion-header">
                <button class="accordion-button collapsed p-2 small fw-medium" type="button"
                        data-bs-toggle="collapse"
                        data-bs-target="#fmt{{ $loop->index }}">
                  <i class="icon-base ti {{ $fmt['icon'] }} me-2 text-{{ $fmt['color'] }} icon-14px"></i>
                  {{ $fmt['bank'] }}
                </button>
              </h6>
              <div id="fmt{{ $loop->index }}" class="accordion-collapse collapse"
                   data-bs-parent="#formatAccordion">
                <div class="accordion-body p-2">
                  <pre class="mb-0 rounded p-2 small" style="background:var(--bs-secondary-bg);font-size:.72rem;white-space:pre-wrap;">{{ $fmt['format'] }}</pre>
                </div>
              </div>
            </div>
            @endforeach
          </div>
        </div>
      </div>
    </div>

    {{-- Right: Form / Preview --}}
    <div class="col-xl-8">

      @if(! $preview)
      {{-- STEP 1: Upload --}}
      <div class="card shadow-sm">
        <div class="card-header py-3">
          <h5 class="card-title mb-0">
            <span class="step-badge bg-label-primary text-primary me-2">1</span>
            Dosya Yükle
          </h5>
        </div>
        <div class="card-body">
          <form action="{{ route('transactions.import.preview') }}" method="POST" enctype="multipart/form-data">
            @csrf

            <div class="mb-4">
              <label class="form-label fw-medium">Hesap Seç <span class="text-danger">*</span></label>
              @if($accounts->isEmpty())
                <div class="alert alert-warning">
                  <i class="icon-base ti tabler-alert-triangle me-2"></i>
                  Önce bir banka bağlantısı oluşturun.
                  <a href="{{ route('bank-connections.create') }}" class="alert-link">Bağla →</a>
                </div>
              @else
                <select name="account_id" class="form-select" required>
                  <option value="">Hangi hesaba aktarılsın?</option>
                  @foreach($accounts as $acc)
                    <option value="{{ $acc->id }}">
                      {{ $acc->bank_name }} —
                      {{ match($acc->account_type) {'checking'=>'Vadesiz','savings'=>'Vadeli','investment'=>'Yatırım', default=>$acc->account_type} }}
                      @if($acc->iban) ({{ substr($acc->iban, 0, 12) }}…) @endif
                      · ₺{{ number_format($acc->balance, 0, ',', '.') }}
                    </option>
                  @endforeach
                </select>
              @endif
            </div>

            <div class="mb-4">
              <label class="form-label fw-medium">CSV Dosyası <span class="text-danger">*</span></label>
              <div class="drop-zone d-flex flex-column align-items-center justify-content-center p-5 text-center"
                   id="dropZone">
                <input type="file" name="csv_file" id="csvFile" accept=".csv,.txt" required>
                <i class="icon-base ti tabler-file-type-csv icon-48px text-muted mb-3"></i>
                <div class="fw-medium mb-1">Dosyayı buraya sürükleyin</div>
                <div class="text-muted small mb-3">veya</div>
                <button type="button" class="btn btn-outline-primary btn-sm"
                        onclick="event.stopPropagation(); document.getElementById('csvFile').click()">
                  Dosya Seç
                </button>
                <div id="fileNameDisplay" class="mt-3 text-success small d-none">
                  <i class="icon-base ti tabler-circle-check me-1"></i><span></span>
                </div>
              </div>
              <div class="form-text">
                Maksimum 10 MB. UTF-8 veya Windows-1254 kodlamalı CSV. Noktalı virgül (;) veya virgül (,) ayraçlı.
              </div>
            </div>

            <button type="submit" class="btn btn-primary" id="uploadBtn" {{ $accounts->isEmpty() ? 'disabled' : '' }}>
              <i class="icon-base ti tabler-upload me-2"></i>Yükle & Önizle
            </button>
          </form>
        </div>
      </div>

      @else
      {{-- STEP 2: Preview + Column Mapping --}}
      <div class="card shadow-sm mb-4">
        <div class="card-header py-3 d-flex align-items-center justify-content-between">
          <h5 class="card-title mb-0">
            <span class="step-badge bg-label-warning text-warning me-2">2</span>
            Sütun Eşleştirme
          </h5>
          <div class="d-flex align-items-center gap-3">
            <span class="badge bg-label-success">{{ $preview['total'] }} satır tespit edildi</span>
            <a href="{{ route('transactions.import') }}" class="btn btn-sm btn-outline-secondary"
               onclick="return confirm('Önizleme iptal edilsin mi?')">
              <i class="icon-base ti tabler-x me-1"></i>Baştan Başla
            </a>
          </div>
        </div>
        <div class="card-body">
          <form action="{{ route('transactions.import.confirm') }}" method="POST">
            @csrf

            <div class="row g-4 mb-5">
              <div class="col-sm-6">
                <label class="form-label fw-medium">Tarih Sütunu <span class="text-danger">*</span></label>
                <select name="col_date" class="form-select form-select-sm" required>
                  @foreach($preview['headers'] as $i => $h)
                    <option value="{{ $i }}" {{ preg_match('/tarih|date/i', $h) ? 'selected' : '' }}>
                      {{ $h ?: "Sütun ".($i+1) }}
                    </option>
                  @endforeach
                </select>
              </div>
              <div class="col-sm-6">
                <label class="form-label fw-medium">Tarih Formatı <span class="text-danger">*</span></label>
                <select name="date_format" class="form-select form-select-sm" required>
                  <option value="d.m.Y">GG.AA.YYYY (01.05.2026)</option>
                  <option value="Y-m-d">YYYY-AA-GG (2026-05-01)</option>
                  <option value="d/m/Y">GG/AA/YYYY (01/05/2026)</option>
                  <option value="m/d/Y">AA/GG/YYYY (05/01/2026)</option>
                  <option value="d-m-Y">GG-AA-YYYY (01-05-2026)</option>
                </select>
              </div>
              <div class="col-sm-6">
                <label class="form-label fw-medium">Tutar Sütunu <span class="text-danger">*</span></label>
                <select name="col_amount" class="form-select form-select-sm" required>
                  @foreach($preview['headers'] as $i => $h)
                    <option value="{{ $i }}" {{ preg_match('/tutar|amount|borç|gider/i', $h) ? 'selected' : '' }}>
                      {{ $h ?: "Sütun ".($i+1) }}
                    </option>
                  @endforeach
                </select>
              </div>
              <div class="col-sm-6">
                <label class="form-label fw-medium">Alacak Sütunu (Opsiyonel)</label>
                <select name="col_credit" class="form-select form-select-sm">
                  <option value="">— Yok (tek tutar sütunu) —</option>
                  @foreach($preview['headers'] as $i => $h)
                    <option value="{{ $i }}" {{ preg_match('/alacak|credit|gelir/i', $h) ? 'selected' : '' }}>
                      {{ $h ?: "Sütun ".($i+1) }}
                    </option>
                  @endforeach
                </select>
              </div>
              <div class="col-sm-6">
                <label class="form-label fw-medium">Açıklama Sütunu <span class="text-danger">*</span></label>
                <select name="col_desc" class="form-select form-select-sm" required>
                  @foreach($preview['headers'] as $i => $h)
                    <option value="{{ $i }}" {{ preg_match('/açıklama|desc|işlem/i', $h) ? 'selected' : '' }}>
                      {{ $h ?: "Sütun ".($i+1) }}
                    </option>
                  @endforeach
                </select>
              </div>
              <div class="col-sm-6">
                <label class="form-label fw-medium">Mağaza Sütunu (Opsiyonel)</label>
                <select name="col_merchant" class="form-select form-select-sm">
                  <option value="">— Yok —</option>
                  @foreach($preview['headers'] as $i => $h)
                    <option value="{{ $i }}" {{ preg_match('/mağaza|merchant|karşı/i', $h) ? 'selected' : '' }}>
                      {{ $h ?: "Sütun ".($i+1) }}
                    </option>
                  @endforeach
                </select>
              </div>
            </div>

            {{-- Preview Table --}}
            <h6 class="fw-semibold mb-3">
              <i class="icon-base ti tabler-table me-2 text-info"></i>
              Önizleme (İlk {{ count($preview['preview']) }} satır)
            </h6>
            <div class="table-responsive mb-5" style="max-height:260px;overflow-y:auto;">
              <table class="table table-sm table-bordered preview-table mb-0">
                <thead class="paranette-thead">
                  <tr>
                    @foreach($preview['headers'] as $h)
                      <th class="py-2 px-3">{{ $h ?: '—' }}</th>
                    @endforeach
                  </tr>
                </thead>
                <tbody>
                  @foreach($preview['preview'] as $row)
                  <tr>
                    @foreach($row as $cell)
                      <td class="py-1 px-3">{{ \Illuminate\Support\Str::limit($cell, 30) }}</td>
                    @endforeach
                  </tr>
                  @endforeach
                </tbody>
              </table>
            </div>

            <div class="d-flex align-items-center justify-content-between flex-wrap gap-3">
              <div class="text-muted small">
                <i class="icon-base ti tabler-info-circle me-1"></i>
                <strong>{{ $preview['total'] }}</strong> satır aktarılmaya hazır.
                Tutar 0 olan satırlar otomatik atlanır.
              </div>
              <button type="submit" class="btn btn-success">
                <i class="icon-base ti tabler-check me-2"></i>Onayla & {{ $preview['total'] }} İşlemi Aktar
              </button>
            </div>
          </form>
        </div>
      </div>
      @endif

    </div>
  </div>

  <x-slot name="pageJs">
  <script>
  const dropZone = document.getElementById('dropZone');
  const fileInput = document.getElementById('csvFile');
  const fileDisplay = document.getElementById('fileNameDisplay');

  if (dropZone) {
    dropZone.addEventListener('click', () => fileInput.click());
    dropZone.addEventListener('dragover', e => { e.preventDefault(); dropZone.classList.add('drag-over'); });
    dropZone.addEventListener('dragleave', ()  => dropZone.classList.remove('drag-over'));
    dropZone.addEventListener('drop', e => {
      e.preventDefault();
      dropZone.classList.remove('drag-over');
      if (e.dataTransfer.files[0]) {
        fileInput.files = e.dataTransfer.files;
        showFileName(e.dataTransfer.files[0].name);
      }
    });

    fileInput.addEventListener('change', () => {
      if (fileInput.files[0]) showFileName(fileInput.files[0].name);
    });
  }

  function showFileName(name) {
    fileDisplay.querySelector('span').textContent = name;
    fileDisplay.classList.remove('d-none');
  }
  </script>
  </x-slot>
</x-app-layout>
