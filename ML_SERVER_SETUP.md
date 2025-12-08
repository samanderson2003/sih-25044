# ML Server Setup Guide

## ✅ Configuration Complete!

Your app is now configured to connect to the FastAPI ML server:
- **Port**: 8000 (changed from 5002)
- **Endpoint**: `/predict` (changed from `/api/predict-yield`)
- **Timeout**: 60 seconds
- **Mock Data**: Removed (only real ML predictions)

## 🚀 Start the ML Server

### Option 1: Quick Start (Recommended)
```bash
cd /Users/samandersony/StudioProjects/projects/sih_25044
./START_CROP_YIELD_SERVER.sh
```

The script will:
- Check for required files (venv, model)
- Detect your local IP address
- Start the FastAPI server on port 8000
- Show the URL your device should connect to

### Option 2: Manual Start
```bash
cd /Users/samandersony/StudioProjects/projects/sih_25044/engine/crop_yield
source venv/bin/activate
python -m uvicorn api:app --host 0.0.0.0 --port 8000 --reload
```

## 📡 Verify Server is Running

1. **Check Terminal Output**:
   ```
   INFO:     Uvicorn running on http://0.0.0.0:8000
   INFO:     Application startup complete
   ```

2. **Test in Browser** (on Mac):
   - Open: http://localhost:8000/docs
   - You should see FastAPI's interactive API documentation

3. **Test from Device**:
   - Your app is configured to connect to: `http://192.168.5.102:8000`
   - Make sure your Mac and device are on the same Wi-Fi network

## 🔍 API Endpoint Details

### POST /predict
Expects JSON body:
```json
{
  "area": 2.5,
  "tavg_climate": 25.3,
  "tmin_climate": 18.2,
  "tmax_climate": 32.4,
  "prcp_annual_climate": 1200.5,
  "zn_percent": 0.8,
  "fe_percent": 1.2,
  "cu_percent": 0.15,
  "mn_percent": 0.25,
  "b_percent": 0.05,
  "s_percent": 0.3,
  "crop": "Paddy",
  "season": "Kharif",
  "year": 2024
}
```

Returns:
```json
{
  "yield_forecast": {
    "per_hectare_tonnes": 3.5,
    "total_expected_tonnes": 8.75,
    "confidence_level": 85,
    "model_r2": 0.85
  },
  "economic_estimate": {
    "gross_income_low": 175000,
    "gross_income_high": 218750,
    "total_cost": 37500,
    "net_profit_low": 137500,
    "net_profit_high": 181250,
    "roi_low": 366.7,
    "roi_high": 483.3
  }
}
```

## 🛠️ Troubleshooting

### Connection Refused / Timeout
1. **Server Not Running**: Run `./START_CROP_YIELD_SERVER.sh`
2. **Wrong IP**: Check your Mac's IP with:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   Update `lib/services/ml_api_service.dart` line 10 if needed

3. **Firewall Blocking**: Allow incoming connections on port 8000

### Model Not Loading
- Check `engine/crop_yield/models/crop_yield_climate_model.json` exists
- Ensure virtual environment is activated
- Install dependencies: `pip install -r requirements.txt`

### Request Format Errors
The app now automatically converts form data to FastAPI format:
- **Before**: `{'farm_data': {...}}`
- **After**: Direct fields matching API schema

## 📱 Testing the Complete Flow

1. **Start ML Server**: `./START_CROP_YIELD_SERVER.sh`
2. **Verify Server**: Open http://localhost:8000/docs
3. **Run Flutter App**: Open in VS Code and run
4. **Submit Form**: Enter farm details and submit
5. **Check Results**:
   - Real ML prediction (not mock data)
   - AI variety recommendations (39+ varieties)
   - ChatGPT farming advice for Odisha
   - Lottie animations
   - Economic estimates

## 🎯 What Changed

### Before (Broken):
- ❌ Port 5002 (nothing listening)
- ❌ Endpoint `/api/predict-yield` (doesn't exist)
- ❌ 10-second timeout (too short)
- ❌ Mock data fallback (hiding errors)

### After (Fixed):
- ✅ Port 8000 (FastAPI server)
- ✅ Endpoint `/predict` (correct)
- ✅ 60-second timeout (adequate for ML)
- ✅ Real errors shown (no mock fallback)
- ✅ Request format matches API schema

## 📝 Files Modified
- `/lib/services/ml_api_service.dart` - Updated URL, endpoint, timeout
- `/lib/crop_yield_prediction/view/crop_yield_prediction_screen.dart` - Enhanced error logging, AI workflow
- `/START_CROP_YIELD_SERVER.sh` - New startup script (created)

---

**Next Steps**: Run `./START_CROP_YIELD_SERVER.sh` and test your app!
