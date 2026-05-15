# Paranette Screenshot Capture Script

# ── ADB otomatik bul ─────────────────────────────────────────────────────────
function Find-ADB {
    foreach ($e in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT)) {
        if ($e) {
            $p = Join-Path $e "platform-tools\adb.exe"
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

# ── Yolları script seviyesinde sabitle ───────────────────────────────────────
$script:ADB = Find-ADB
if (-not $script:ADB) {
    Write-Host "HATA: adb.exe bulunamadi." -ForegroundColor Red
    Write-Host "Android Studio SDK kurulu mu? ANDROID_HOME degiskenini ayarla." -ForegroundColor Yellow
    pause; exit 1
}

# Script'in bulunduğu klasör (docs\) — screenshots klasörü onun altında
$here = $PSScriptRoot
if (-not $here) {
    $here = Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).FullName
}
$script:OutDir = Join-Path $here "screenshots"
New-Item -ItemType Directory -Force -Path $script:OutDir | Out-Null

Write-Host ""
Write-Host "ADB    : $($script:ADB)" -ForegroundColor DarkGray
Write-Host "Klasor : $($script:OutDir)" -ForegroundColor Cyan
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

# ── Capture fonksiyonu ────────────────────────────────────────────────────────
function Capture {
    param([string]$File, [string]$Label)

    $adbExe  = $script:ADB
    $saveDir = $script:OutDir
    $remote  = "/sdcard/ss_tmp.png"
    $local   = Join-Path $saveDir "$File.png"

    Write-Host "  Cekiliyor: $Label ... " -NoNewline -ForegroundColor White

    $ErrorActionPreference = 'SilentlyContinue'
    & $adbExe shell screencap -p $remote | Out-Null
    & $adbExe pull $remote $local        | Out-Null
    & $adbExe shell rm $remote           | Out-Null
    $ErrorActionPreference = 'Continue'

    if (Test-Path $local) {
        Write-Host "TAMAM" -ForegroundColor Green
        Write-Host "    -> $local" -ForegroundColor DarkGray
    } else {
        Write-Host "HATA — dosya olusturulamadi" -ForegroundColor Red
        Write-Host "    Beklenen konum: $local" -ForegroundColor Red
    }
}

# ── Ana döngü ─────────────────────────────────────────────────────────────────
while ($true) {
    $choice = (Read-Host "Secim").Trim().ToLower()
    if ($choice -eq "q") { break }

    if ($choice -eq "a") {
        foreach ($s in $screens) {
            Write-Host ""
            Write-Host "  '$($s.label)' sayfasina gec, hazir olunca Enter'a bas..." -ForegroundColor Cyan
            Read-Host | Out-Null
            Capture -File $s.file -Label $s.label
        }
        Write-Host ""
        Write-Host "Bitti! Klasor aciliyor..." -ForegroundColor Green
        Start-Process explorer.exe $script:OutDir
        break
    }

    $match = $screens | Where-Object { $_.key -eq $choice }
    if ($match) {
        Capture -File $match.file -Label $match.label
    } else {
        Write-Host "  Gecersiz secim." -ForegroundColor Red
    }
}
