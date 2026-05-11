@echo off
echo Starting Paranette development server...
echo Access at: http://paranette.local:8000
echo.
cd /d "%~dp0"
php artisan serve --host=0.0.0.0 --port=8000
