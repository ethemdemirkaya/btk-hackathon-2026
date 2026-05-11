# Paranette Local Development Starter
# Run with: PowerShell -ExecutionPolicy Bypass -File start.ps1

$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
$hostEntry = "127.0.0.1 paranette.local"
$hostContent = Get-Content $hostsFile -Raw

if ($hostContent -notmatch "paranette\.local") {
    Write-Host "Adding paranette.local to hosts file (requires admin)..." -ForegroundColor Yellow
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Add-Content -Path $hostsFile -Value "`n$hostEntry"
        Write-Host "  Done!" -ForegroundColor Green
    } else {
        Write-Host "  Not running as admin. Please run once as Administrator to add hosts entry." -ForegroundColor Red
        Write-Host "  OR manually add this line to C:\Windows\System32\drivers\etc\hosts:" -ForegroundColor Cyan
        Write-Host "  $hostEntry" -ForegroundColor White
    }
} else {
    Write-Host "paranette.local already in hosts file." -ForegroundColor Green
}

Write-Host ""
Write-Host "Starting Paranette dev server at http://paranette.local:8000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host ""

Set-Location $PSScriptRoot
php artisan serve --host=0.0.0.0 --port=8000
