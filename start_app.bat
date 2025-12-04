@echo off
REM Master startup script for Smart Farming App (Windows)
REM Starts both Python ML API server and Flutter app

setlocal enabledelayedexpansion

echo ╔════════════════════════════════════════════════════════════════╗
echo ║        🌾 Smart Farming App - Auto Launcher 🌾                ║
echo ╚════════════════════════════════════════════════════════════════╝
echo.

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Python is not installed
    echo Please install Python from https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Error: Flutter is not installed
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 📡 Starting ML API Server...
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cd engine\api

REM Check if virtual environment exists
if not exist "venv" (
    echo 📦 Creating Python virtual environment...
    python -m venv venv
)

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call venv\Scripts\activate.bat

REM Install dependencies
echo 📥 Installing/updating Python dependencies...
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

REM Check if model exists
if not exist "..\crop_yield\models\crop_yield_climate_model.json" (
    echo ⚠️  Warning: ML model not found!
    echo The API will start but predictions won't work until you train the model.
    echo To train: cd engine\crop_yield ^&^& python train.py
    echo.
    pause
)

REM Start API server in background
echo 🚀 Starting API server on http://localhost:5000
start /B python app.py > api_server.log 2>&1

REM Wait for API to be ready
echo ⏳ Waiting for API server to be ready...
timeout /t 3 /nobreak >nul

echo ✅ API server is running
echo    View logs: type engine\api\api_server.log
echo.

cd ..\..

echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo 📱 Starting Flutter App...
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REM Get Flutter dependencies
echo 📦 Getting Flutter dependencies...
flutter pub get >nul 2>&1

REM Start Flutter app
echo 🚀 Launching Flutter app...
echo.

flutter run

REM When Flutter exits, kill the Python server
echo.
echo 🛑 Shutting down API server...
taskkill /F /IM python.exe /T >nul 2>&1

echo ✅ Cleanup complete
pause
