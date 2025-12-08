#!/bin/bash
# Startup script for Crop Yield Prediction ML Server

echo "🌾 Starting Crop Yield Prediction ML Server..."
echo ""

cd "$(dirname "$0")/engine/crop_yield"

# Get local IP
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")

echo "📍 Server will be accessible at:"
echo "   • Physical Device:  http://$LOCAL_IP:8000"
echo "   • Browser:          http://localhost:8000"
echo "   • API Docs:         http://localhost:8000/docs"
echo ""
echo "🔧 Update lib/services/ml_api_service.dart if needed:"
echo "   Set baseUrl to: 'http://$LOCAL_IP:8000'"
echo ""
echo "Press CTRL+C to stop the server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if virtual environment exists
if [ ! -d "bin" ]; then
    echo "❌ Virtual environment not found!"
    echo "Please run: python3 -m venv . && source bin/activate && pip install -r requirements.txt"
    exit 1
fi

# Check if model exists
if [ ! -f "models/crop_yield_climate_model.json" ]; then
    echo "❌ ML model not found!"
    echo "Please train the model first by running: ./bin/python train.py"
    exit 1
fi

# Start FastAPI server
echo "🚀 Starting FastAPI server on port 8000..."
./bin/python -m uvicorn api:app --host 0.0.0.0 --port 8000 --reload
