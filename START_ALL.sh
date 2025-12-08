#!/bin/bash

# Complete startup script for Smart Farming App
# Starts ML server and Flutter app

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        🌾 Smart Farming App - Complete Launcher 🌾           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}🛑 Shutting down ML server...${NC}"
    jobs -p | xargs kill 2>/dev/null || true
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Get local IP
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")

# Start ML Server
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🚀 Starting Crop Yield ML Server (Port 8000)...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

cd engine/crop_yield

# Check virtual environment (bin/ folder exists at root level)
if [ ! -d "bin" ]; then
    echo -e "${YELLOW}⚠️  Virtual environment not found${NC}"
    exit 1
fi

# Check model
if [ ! -f "models/crop_yield_climate_model.json" ]; then
    echo -e "${YELLOW}⚠️  ML model not found${NC}"
    exit 1
fi

# Start server in background (virtual env is at root level)
./bin/python -m uvicorn api:app --host 0.0.0.0 --port 8000 --reload > ../../ml_server.log 2>&1 &

SERVER_PID=$!
sleep 4

# Verify server started
if lsof -i :8000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ ML Server running on http://${LOCAL_IP}:8000${NC}"
else
    echo -e "${YELLOW}⚠️  Server may not be ready yet${NC}"
fi

cd ../..

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📱 Starting Flutter App...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

flutter pub get > /dev/null 2>&1

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ ALL SYSTEMS READY                        ║${NC}"
echo -e "${GREEN}╠════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  🚀 ML Server:  http://${LOCAL_IP}:8000                    ║${NC}"
echo -e "${GREEN}║  📱 Flutter App: Launching...                                 ║${NC}"
echo -e "${GREEN}║  📊 Server Logs: tail -f ml_server.log                        ║${NC}"
echo -e "${GREEN}║  🛑 Stop All:    Press Ctrl+C                                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Run Flutter app (foreground)
flutter run
