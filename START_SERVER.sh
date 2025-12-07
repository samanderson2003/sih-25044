#!/bin/bash
# Quick start script for the Plant Disease Detection Server

echo "🌱 Starting Plant Disease Detection Server..."
echo ""

cd "$(dirname "$0")/engine/plants_disease"

# Get local IP
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "localhost")

echo "📍 Server will be accessible at:"
echo "   • Android Emulator: http://10.0.2.2:5001"
echo "   • Physical Device:  http://$LOCAL_IP:5001"
echo "   • Browser:          http://localhost:5001"
echo ""
echo "🔧 Make sure to update lib/crop_diseases_detection/controller/disease_detection_controller.dart"
echo "   Set _physicalDeviceUrl to: 'http://$LOCAL_IP:5001'"
echo ""
echo "Press CTRL+C to stop the server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Start server
./bin/python -m uvicorn server:app --host 0.0.0.0 --port 5001
