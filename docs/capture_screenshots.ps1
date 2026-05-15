# Paranette Screenshot Capture Script

# ── ADB otomatik bul ─────────────────────────────────────────────────────────
function Find-ADB {
    foreach ($env in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT)) {
        if ($env) {
            $p = Join-Path $env "platform-tools\adb.exe"
            if (Test-Path $p) { return $p }
        }
    }
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\platform-tools\adb.exe"
    )
    foreach ($p in $candidates) { if (Test-Path $p) { return $p } }
    $found = Get-Command adb -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    return $null
}

$adb = Find-ADB
if (-not $adb) {
    Write-Host "HATA: adb.exe bulunamadi. ANDROID_HOME ortam degiskenini ayarla." -ForegroundColor Red
    pause; exit 1
}

# ── Kayıt klasörü — script'in yanındaki screenshots\ klasörü ─────────────────
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $MyInvocation.MyCommand.Path }
$outDir    = Join-Path $scriptDir "screenshots"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host ""
Write-Host "ADB      : $adb" -ForegroundColor DarkGray
Write-Host "Kaydedilecek klasor: $outDir" -ForegroundColor Cyan
Write-Host ""

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

Write-Host "=== Paranette Screenshot Capture ===" -ForegroundColor Cyan
foreach ($s in $screens) { Write-Host "  [$($s.key)] $($s.label)" -ForegroundColor Yellow }
Write-Host "  [a] Hepsini sirayla cek" -ForegroundColor Green
Write-Host "  [q] Cikis" -ForegroundColor Gray
Write-Host ""

function Capture($file, $label) {
    $remote = "/sdcard/ss_tmp.png"
    $local  = Join-Path $outDir "$file.png"

    Write-Host "  Cekiliyor: $label ... " -NoNewline -ForegroundColor White

    & $adb shell screencap -p $remote 2>$null | Out-Null
    & $adb pull $remote $local 2>$null  | Out-Null
    & $adb shell rm $remote             2>$null | Out-Null

    if (Test-Path $local) {
        Write-Host "TAMAM" -ForegroundColor Green
        Write-Host "    -> $local" -ForegroundColor DarkGray
    } else {
        Write-Host "HATA — dosya olusturulamadi: $local" -ForegroundColor Red
    }
}

while ($true) {
    $choice = (Read-Host "Secim").Trim().ToLower()
    if ($choice -eq "q") { break }

    if ($choice -eq "a") {
        foreach ($s in $screens) {
            Write-Host ""
            Write-Host "  '$($s.label)' sayfasina gec, hazir olunca Enter'a bas..." -ForegroundColor Cyan
            Read-Host "  (Enter)" | Out-Null
            Capture $s.file $s.label
        }
        Write-Host ""
        Write-Host "Bitti! Klasoru ac:" -ForegroundColor Green
        Start-Process explorer.exe $outDir
        break
    }

    $match = $screens | Where-Object { $_.key -eq $choice }
    if ($match) {
        Capture $match.file $match.label
        Write-Host "  Klasoru ac: $outDir" -ForegroundColor DarkGray
    } else {
        Write-Host "  Gecersiz secim." -ForegroundColor Red
    }
}
