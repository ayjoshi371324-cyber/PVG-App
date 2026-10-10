Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Starting RidePool AI Backend (FastAPI) and UI (Flutter)" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# Start FastAPI backend
Write-Host "1. Launching FastAPI Backend on http://127.0.0.1:8000..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot/backend'; python -m uvicorn app.main:app --reload --port 8000"

Start-Sleep -Seconds 2

# Start Flutter UI (Chrome)
Write-Host "2. Launching Flutter Web UI in Chrome..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot/mobile'; flutter run -d chrome"
