# Paranette Screenshot Capture Script
# Emülatörde istediğin sayfaya geç, sonra numaraya bas ve Enter'a bas.

$screens = @(
    @{ key = "1"; file = "01-dashboard";    label = "Dashboard" },
    @{ key = "2"; file = "02-ai-chat";      label = "AI Finans Asistanı" },
    @{ key = "3"; file = "03-transactions"; label = "İşlemler" },
    @{ key = "4"; file = "04-budget";       label = "Bütçe & Hedefler" },
    @{ key = "5"; file = "05-investments";  label = "Yatırım Portföyü" },
    @{ key = "6"; file = "06-negotiation";  label = "Müzakere Ajanı" },
    @{ key = "7"; file = "07-simulator";    label = "Karar Simülatörü" },
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
    adb shell screencap -p $remote
    adb pull $remote $local 2>$null | Out-Null
    adb shell rm $remote

    if (Test-Path $local) {
        Write-Host "OK  ->  $file.png" -ForegroundColor Green
    } else {
        Write-Host "HATA — ADB bagli mi?" -ForegroundColor Red
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
