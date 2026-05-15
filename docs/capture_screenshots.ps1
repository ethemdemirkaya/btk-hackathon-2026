# Paranette Screenshot Capture Script
# Emülatörde istediğin sayfaya geç, sonra numaraya bas ve Enter'a bas.

# ── ADB otomatik bul ─────────────────────────────────────────────────────────
function Find-ADB {
    # 1. Ortam değişkenleri
    foreach ($env in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT)) {
        if ($env) {
            $p = Join-Path $env "platform-tools\adb.exe"
            if (Test-Path $p) { return $p }
        }
    }
    # 2. Android Studio varsayılan konumu
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\platform-tools\adb.exe",
        "C:\android-sdk\platform-tools\adb.exe"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { return $p }
    }
    # 3. PATH
    $found = Get-Command adb -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    return $null
}

$adb = Find-ADB
if (-not $adb) {
    Write-Host ""
    Write-Host "HATA: adb.exe bulunamadi." -ForegroundColor Red
    Write-Host "Android Studio SDK yüklü mü? Yoksa ANDROID_HOME ortam degiskenini ayarla." -ForegroundColor Yellow
    Write-Host "Örnek: `$env:ANDROID_HOME = 'C:\Users\<kullanici>\AppData\Local\Android\Sdk'" -ForegroundColor Gray
    Write-Host ""
    pause
    exit 1
}

Write-Host "ADB: $adb" -ForegroundColor DarkGray

# ── Ekran listesi ─────────────────────────────────────────────────────────────
$screens = @(
    @{ key = "1"; file = "01-dashboard";    label = "Dashboard" },
    @{ key = "2"; file = "02-ai-chat";      label = "AI Finans Asistani" },
    @{ key = "3"; file = "03-transactions"; label = "Islemler" },
    @{ key = "4"; file = "04-budget";       label = "Butce & Hedefler" },
    @{ key = "5"; file = "05-investments";  label = "Yatirim Portfoyu" },
    @{ key = "6"; file = "06-negotiation";  label = "Muzakere Ajani" },
    @{ key = "7"; file = "07-simulator";    label = "Karar Simulatoru" },
    @{ key = "8"; file = "08-reports";      label = "Raporlar" }
)

$outDir = "$PSScriptRoot\screenshots"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host ""
Write-Host "=== Paranette Screenshot Capture ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Emülatörde ilgili sayfaya gec, sonra asagidaki numaraya bas." -ForegroundColor Gray
Write-Host ""

foreach ($s in $screens) {
    Write-Host "  [$($s.key)] $($s.label)" -ForegroundColor Yellow
}
Write-Host "  [a] Hepsini sirayla cek (her birinde Enter beklenir)" -ForegroundColor Green
Write-Host "  [q] Cikis" -ForegroundColor Gray
Write-Host ""

function Capture($file, $label) {
    $remote = "/sdcard/paranette_ss.png"
    $local  = "$outDir\$file.png"

    Write-Host "  Cekiliyor: $label ... " -NoNewline -ForegroundColor White
    & $adb shell screencap -p $remote
    & $adb pull $remote $local 2>$null | Out-Null
    & $adb shell rm $remote

    if (Test-Path $local) {
        Write-Host "OK  ->  $file.png" -ForegroundColor Green
    } else {
        Write-Host "HATA — Emülatör acik mi?" -ForegroundColor Red
    }
}

while ($true) {
    $choice = Read-Host "Secim"
    $choice = $choice.Trim().ToLower()

    if ($choice -eq "q") { break }

    if ($choice -eq "a") {
        foreach ($s in $screens) {
            Write-Host ""
            Write-Host "  Emülatörde '$($s.label)' sayfasina gec, hazir olunca Enter'a bas..." -ForegroundColor Cyan
            Read-Host "  (Enter)" | Out-Null
            Capture $s.file $s.label
        }
        Write-Host ""
        Write-Host "Tum ekran goruntuleri alindi! docs\screenshots\ klasorune kaydedildi." -ForegroundColor Green
        break
    }

    $match = $screens | Where-Object { $_.key -eq $choice }
    if ($match) {
        Capture $match.file $match.label
    } else {
        Write-Host "  Gecersiz secim." -ForegroundColor Red
    }
}
