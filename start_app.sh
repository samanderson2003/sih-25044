#!/bin/bash

# Master startup script for Smart Farming App
# Starts both Python ML API server and Flutter app

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        🌾 Smart Farming App - Auto Launcher 🌾                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Error: Python 3 is not installed${NC}"
    echo "Please install Python 3 from https://www.python.org/downloads/"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Error: Flutter is not installed${NC}"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Function to cleanup background processes on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Shutting down...${NC}"
    
    # Kill API server
    if [ ! -z "$API_PID" ]; then
        echo "Stopping API server (PID: $API_PID)..."
        kill $API_PID 2>/dev/null || true
    fi
    
    # Kill Flutter app
    if [ ! -z "$FLUTTER_PID" ]; then
        echo "Stopping Flutter app (PID: $FLUTTER_PID)..."
        kill $FLUTTER_PID 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    exit 0
}

# Set trap to cleanup on script exit (Ctrl+C, etc.)
trap cleanup SIGINT SIGTERM EXIT

# ===========================
# 1. Start Python API Server
# ===========================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📡 Starting ML API Server...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd engine/api

# Check if virtual environment exists, create if not
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}📦 Creating Python virtual environment...${NC}"
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies silently
echo "📥 Installing/updating Python dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

# Check if model exists
if [ ! -f "../crop_yield/models/crop_yield_climate_model.json" ]; then
    echo -e "${YELLOW}⚠️  Warning: ML model not found!${NC}"
    echo "The API will start but predictions won't work until you train the model."
    echo "To train: cd engine/crop_yield && python3 train.py"
    echo ""
    read -p "Press Enter to continue anyway..."
fi

# Start API server in background
echo -e "${GREEN}🚀 Starting API server on http://localhost:5001${NC}"
python app.py > api_server.log 2>&1 &
API_PID=$!

# Wait for API to be ready
echo "⏳ Waiting for API server to be ready..."
sleep 3

# Check if API is running
if curl -s http://localhost:5001/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API server is running (PID: $API_PID)${NC}"
    echo -e "${GREEN}   View logs: tail -f engine/api/api_server.log${NC}"
else
    echo -e "${YELLOW}⚠️  API server may still be starting up...${NC}"
fi

cd ../..  # Back to project root

echo ""

# ===========================
# 2. Start Flutter App
# ===========================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📱 Starting Flutter App...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get > /dev/null 2>&1

# Start Flutter app
echo -e "${GREEN}🚀 Launching Flutter app...${NC}"
echo ""
flutter run &
FLUTTER_PID=$!

# Wait for Flutter app to start
sleep 5

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ ALL SYSTEMS RUNNING                      ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  📡 API Server:  http://localhost:5001                        ║${NC}"
echo -e "${GREEN}║  📱 Flutter App: Check device/emulator                        ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  📋 API Logs:    tail -f engine/api/api_server.log            ║${NC}"
echo -e "${GREEN}║  🛑 Stop All:    Press Ctrl+C                                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}💡 Tip: Click any date on the calendar to see AI recommendations${NC}"
echo ""

# Keep script running and monitoring
echo "Monitoring processes... (Press Ctrl+C to stop everything)"
echo ""

# Wait for Flutter process (it will run in foreground through terminal interaction)
wait $FLUTTER_PID

# If Flutter exits, cleanup will be called automatically
