# Paranette Web Server Baslatici
# Kullanim: powershell -ExecutionPolicy Bypass -File start-server.ps1

$ErrorActionPreference = 'Continue'
$wampMysql = "C:\wamp64\bin\mysql\mysql8.1.0\bin\mysqld.exe"
$wampMysqlIni = "C:\wamp64\bin\mysql\mysql8.1.0\my.ini"

# 1. MySQL calisiyorsa pas gec, degilse baslt
$mysqlRunning = (Get-NetTCPConnection -LocalPort 3306 -State Listen -ErrorAction SilentlyContinue) -ne $null
if (-not $mysqlRunning) {
    Write-Host "[1/2] MySQL baslatiliyor..." -ForegroundColor Yellow
    Start-Process -FilePath $wampMysql -ArgumentList "--defaults-file=`"$wampMysqlIni`"" -WindowStyle Hidden
    Start-Sleep -Seconds 3
} else {
    Write-Host "[1/2] MySQL zaten calisiyor." -ForegroundColor Green
}

# 2. Laravel sunucusu baslt
Write-Host "[2/2] Laravel sunucusu baslatiliyor (0.0.0.0:8000)..." -ForegroundColor Yellow
Write-Host "Durdurmak icin CTRL+C" -ForegroundColor Cyan
Write-Host ""
Set-Location $PSScriptRoot
& php artisan serve --host=0.0.0.0 --port=8000
