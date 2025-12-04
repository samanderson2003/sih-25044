#!/bin/bash

# Startup script for Smart Farming ML API Server

echo "🌾 Starting Smart Farming ML API Server..."
echo ""

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed"
    echo "Please install Python 3 from https://www.python.org/downloads/"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "app.py" ]; then
    echo "❌ Error: app.py not found"
    echo "Please run this script from the engine/api directory:"
    echo "  cd engine/api"
    echo "  ./start_server.sh"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install/update dependencies
echo "📥 Installing dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet

# Check if model exists
if [ ! -f "../crop_yield/models/crop_yield_climate_model.json" ]; then
    echo ""
    echo "⚠️  Warning: ML model not found!"
    echo "Please train the model first:"
    echo "  cd ../crop_yield"
    echo "  python train.py"
    echo ""
    read -p "Press Enter to continue anyway (server will start but predictions won't work)..."
fi

# Start the server
echo ""
echo "="*70
echo "🚀 Starting API server on http://localhost:5000"
echo "="*70
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

python app.py
