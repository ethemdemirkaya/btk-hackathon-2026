<x-app-layout>
  <x-slot name="title">Dashboard</x-slot>

  <div class="row g-6 mb-6">
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Toplam Bakiye</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2">₺0</h4>
              </div>
              <small class="text-muted">Tüm hesaplar</small>
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
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Kart Borcu</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2">₺0</h4>
              </div>
              <small class="text-muted">Tüm kartlar</small>
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
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Aktif Kredi</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2">₺0</h4>
              </div>
              <small class="text-muted">Kalan borç</small>
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
    <div class="col-sm-6 col-xl-3">
      <div class="card">
        <div class="card-body">
          <div class="d-flex align-items-start justify-content-between">
            <div class="content-left">
              <span class="text-heading">Finansal Sağlık</span>
              <div class="d-flex align-items-center my-1">
                <h4 class="mb-0 me-2">--/100</h4>
              </div>
              <small class="text-muted">Sağlık skoru</small>
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
  </div>

  <!-- Kişisel Enflasyon Kartı -->
  <div class="row g-6 mb-6">
    <div class="col-xl-4">
      <div class="card border-primary">
        <div class="card-header d-flex align-items-center">
          <h5 class="card-title mb-0 me-auto">Kişisel Enflasyonunuz</h5>
          <span class="badge bg-label-warning">TÜİK Verisi</span>
        </div>
        <div class="card-body">
          <div class="d-flex align-items-baseline mb-2">
            <h2 class="mb-0 me-2 text-danger">--.--%</h2>
            <small class="text-muted">TÜFE: --.--%</small>
          </div>
          <p class="text-muted small mb-0">
            Banka hesapları bağlandıktan sonra hesaplanacak.
          </p>
        </div>
      </div>
    </div>

    <div class="col-xl-8">
      <div class="card">
        <div class="card-header">
          <h5 class="card-title mb-0">Ajan Asistan</h5>
        </div>
        <div class="card-body">
          <p class="text-muted">Finansal sorularınızı yapay zeka destekli ajan asistanınıza sorun.</p>
          <a href="#" class="btn btn-primary">
            <i class="icon-base ti tabler-robot me-2"></i> Ajana Sor
          </a>
        </div>
      </div>
    </div>
  </div>

  <!-- Banka Bağlantısı -->
  <div class="row g-6">
    <div class="col-12">
      <div class="card">
        <div class="card-header">
          <h5 class="card-title mb-0">Banka Hesapları</h5>
        </div>
        <div class="card-body text-center py-6">
          <i class="icon-base ti tabler-building-bank icon-48px text-muted mb-3"></i>
          <p class="text-muted">Henüz banka hesabı bağlanmamış.</p>
          <a href="#" class="btn btn-outline-primary">
            <i class="icon-base ti tabler-plus me-1"></i> Banka Bağla
          </a>
        </div>
      </div>
    </div>
  </div>
</x-app-layout>
