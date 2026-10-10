@echo off
echo ====================================================
echo Starting RidePool AI Backend (FastAPI) and UI (Flutter)
echo ====================================================

start "RidePool Backend (FastAPI)" cmd /k "cd /d %~dp0backend && python -m uvicorn app.main:app --reload --port 8000"

timeout /t 2 /nobreak >nul

start "RidePool UI (Flutter Chrome)" cmd /k "cd /d %~dp0mobile && flutter run -d chrome"
