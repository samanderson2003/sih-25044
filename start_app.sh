#!/bin/bash

# Master startup script for Smart Farming App
# Starts both Python ML API server and Flutter app

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        🌾 Smart Farming App - Auto Launcher 🌾                ║${NC}"
echo -e "${GREEN}║      ML Crop Yield + DL Plant Disease Detection              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to cleanup background processes on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Shutting down all servers...${NC}"
    
    # Kill background jobs from this script
    jobs -p | xargs kill 2>/dev/null || true
    
    # Kill servers by port (backup)
    lsof -ti :5002 | xargs kill -9 2>/dev/null || true
    lsof -ti :5001 | xargs kill -9 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    exit 0
}

# Set trap to cleanup on script exit (Ctrl+C, etc.)
trap cleanup SIGINT SIGTERM EXIT

# Get local IP for display
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "192.168.x.x")

# ===========================
# 1. Start Crop Yield ML API Server (Flask)
# ===========================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📡 Starting Crop Yield ML API Server (Port 5002)...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

(
    cd engine/api
    source venv/bin/activate
    python app.py > api_server.log 2>&1
) &

CROP_YIELD_PID=$!
sleep 3

# Check if server started
if lsof -i :5002 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Crop Yield API started on port 5002${NC}"
else
    echo -e "${RED}❌ Failed to start Crop Yield API${NC}"
fi

echo ""

# ===========================
# 2. Start Plant Disease Detection DL API Server (FastAPI)
# ===========================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔬 Starting Plant Disease Detection API (Port 5001)...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

(
    cd engine/plants_disease
    ./bin/python -m uvicorn server:app --host 0.0.0.0 --port 5001 > disease_api.log 2>&1
) &

DISEASE_PID=$!
sleep 4

# Check if server started
if lsof -i :5001 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Disease Detection API started on port 5001${NC}"
else
    echo -e "${RED}❌ Failed to start Disease Detection API${NC}"
fi

echo ""

# ===========================
# 3. Start Flutter App
# ===========================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📱 Starting Flutter App...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Get Flutter dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get > /dev/null 2>&1

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ ALL SYSTEMS RUNNING                      ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  🌾 Crop Yield API:       http://$LOCAL_IP:5002          ║${NC}"
echo -e "${GREEN}║  🔬 Disease Detection API: http://$LOCAL_IP:5001          ║${NC}"
echo -e "${GREEN}║  📱 Flutter App:          Launching now...                    ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  🛑 Stop All:  Press Ctrl+C                                   ║${NC}"
echo -e "${GREEN}║  📊 View Logs:  tail -f engine/api/api_server.log            ║${NC}"
echo -e "${GREEN}║                  tail -f engine/plants_disease/disease_api.log║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Start Flutter app (this will run in foreground)
flutter run
