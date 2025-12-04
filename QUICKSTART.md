# 🚀 Getting Started with ML-Powered Smart Farming App

## ⚡ One-Command Launch (Recommended)

**macOS/Linux:**
```bash
./start_app.sh
```

**Windows:**
```cmd
start_app.bat
```

This single command will:
- ✅ Start the Python ML API server
- ✅ Install all dependencies automatically
- ✅ Launch the Flutter app
- ✅ Keep everything running
- ✅ Clean up when you press Ctrl+C

---

## 📋 Manual Setup (Optional)

### Step 1: Train the ML Model (One-time setup)

```bash
cd engine/crop_yield
python3 train.py
```

You should see:
```
✅ XGBoost Model Loaded (14 features)
R² Score: 0.71
Model training complete!
```

### Step 2: Start the ML API Server

**Option A - Auto script:**
```bash
cd engine/api
./start_server.sh
```

**Option B - Manual:**
```bash
cd engine/api
pip3 install -r requirements.txt
python3 app.py
```

You should see:
```
🌾 SMART FARMING API SERVER
======================================================================
✅ Model Status: Loaded
✅ Features: 14
======================================================================

🚀 Starting server on http://localhost:5000
```

### Step 3: Run the Flutter App

In a separate terminal:

```bash
flutter run
```

## 🎯 How It Works

### User Journey:
1. **Complete Profile** → User enters farm data (location, size, crops, soil nutrients)
2. **Home Page** → See crops and calendar
3. **Click Date** → Get ML-powered daily recommendations

### Behind the Scenes:
```
Flutter App
    ↓ (HTTP Request)
Python API Server
    ↓
XGBoost ML Model
    ↓ (Prediction + Analysis)
Daily Recommendations
    ↓
Flutter UI
```

### Data Flow:
```dart
User Profile → FarmDataModel
    → MLApiService.getComprehensivePlan()
        → Python Flask API
            → ML Model (yield prediction)
            → Growth stage calculation
            → Weather-based alerts
            → Soil nutrient analysis
        → JSON Response
    → DailyActionsScreen (UI)
```

## 📋 What You Get

### Daily Actions Include:
- ✅ **Crop Stage**: Germination → Tillering → Panicle → Grain Filling → Harvest
- ✅ **Stage-Specific Tasks**: 
  - Day 21: Apply first fertilizer top dressing
  - Day 75: Critical irrigation (flowering stage)
  - Day 130: Harvest window
- ✅ **Weather Alerts**: High rainfall → drainage warnings
- ✅ **Soil Alerts**: Zinc deficiency → apply ZnSO₄
- ✅ **Disease Alerts**: High humidity → fungal risk
- ✅ **Yield Forecast**: 4.5 tonnes/hectare with 88% confidence
- ✅ **Economic Analysis**: Expected profit ₹60,000 - ₹75,000

### Example Output:
```json
{
  "crop_stage": {
    "stage": "Tillering",
    "days": 21,
    "description": "Vegetative growth, new shoots forming"
  },
  "actions": [
    {
      "task": "🌾 First Top Dressing",
      "description": "Apply 15kg Urea per acre",
      "priority": "high",
      "timing": "Morning after irrigation"
    }
  ],
  "yield_forecast": {
    "total_yield_tonnes": 3.66,
    "confidence": 88,
    "net_profit_low": 58200
  }
}
```

## 🛠️ Troubleshooting

### "Connection refused"
- Is the API server running? Check terminal
- Try: `curl http://localhost:5000/health`

### "Model not loaded"
- Did you run `python train.py`?
- Check: `engine/crop_yield/models/crop_yield_climate_model.json` exists

### "Module not found"
```bash
cd engine/api
pip3 install -r requirements.txt
```

### Testing on Physical Device
1. Find your Mac's IP address:
   - System Settings → Network → Wi-Fi → Details
   - Example: `192.168.1.10`

2. Update `lib/services/ml_api_service.dart`:
```dart
static const String baseUrl = 'http://192.168.1.10:5000';
```

3. Ensure phone and Mac are on same Wi-Fi

## 📊 Model Details

- **Algorithm**: XGBoost (Gradient Boosting)
- **Accuracy**: R² = 0.71 (71%)
- **Input Features**: 14
  - Farm area
  - Climate: tavg, tmin, tmax, precipitation
  - Soil: Zn, Fe, Cu, Mn, B, S
  - Engineered: temp_range, nutrient_index
- **Training Data**: 20-year NASA climate + soil micronutrients
- **Output**: Crop yield in tonnes/hectare

## 🎓 Understanding the Recommendations

### Growth Stages (Rice):
- **0-10 days**: Germination → Keep soil moist
- **11-30 days**: Tillering → Apply first fertilizer (day 21)
- **31-60 days**: Stem Elongation → Weed control
- **61-90 days**: Panicle Initiation → **CRITICAL WATER NEEDS**
- **91-110 days**: Grain Filling → Maintain moisture
- **111-130 days**: Maturity → Reduce irrigation
- **130+ days**: Harvest window

### Priority Levels:
- 🔴 **Critical**: Act immediately (water during flowering)
- 🟠 **High**: Within 3 days (fertilizer application)
- 🔵 **Medium**: This week (pest scouting)
- ⚪ **Low**: When convenient (monitoring)

## 🚀 Next Steps

### For Development:
1. Add planting date tracking to farm profile
2. Integrate real-time weather API
3. Add push notifications for critical tasks
4. Implement yearly crop rotation planner

### For Farmers:
1. Complete farm profile with accurate data
2. Check daily recommendations every morning
3. Mark tasks as complete
4. Update soil test results when available

---

**Questions? Issues?** Check the logs in the API server terminal.

**Made with 🌾 for Smart Farming SIH 2025**
