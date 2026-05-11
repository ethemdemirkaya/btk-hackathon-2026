# Paranette Local Development Starter
# Run with: PowerShell -ExecutionPolicy Bypass -File start.ps1
# Starts: Laravel dev server + queue worker (for async AI agents)

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
        Write-Host "  Not running as admin. Manually add this line to hosts:" -ForegroundColor Red
        Write-Host "  $hostEntry" -ForegroundColor White
    }
} else {
    Write-Host "paranette.local already in hosts file." -ForegroundColor Green
}

Set-Location $PSScriptRoot

Write-Host ""
Write-Host "  Paranette dev stack" -ForegroundColor Cyan
Write-Host "  Web  -> http://paranette.local:8000" -ForegroundColor White
Write-Host "  Jobs -> queue:work (database driver, async AI agents)" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C in each window to stop." -ForegroundColor Gray
Write-Host ""

# Start queue worker in a new PowerShell window
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$PSScriptRoot'; Write-Host '[Queue Worker] Starting...' -ForegroundColor Yellow; php artisan queue:work --sleep=3 --tries=1 --max-time=3600" -WindowStyle Normal

# Small delay so queue window appears first
Start-Sleep -Milliseconds 500

# Start web server in this window
Write-Host "[Web Server] Starting at http://paranette.local:8000" -ForegroundColor Cyan
php artisan serve --host=0.0.0.0 --port=8000
