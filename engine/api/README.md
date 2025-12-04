# 🌾 Smart Farming ML API Server

This API server exposes your XGBoost ML model to provide intelligent, data-driven farming recommendations.

## 🚀 Quick Start

### 1. Install Python Dependencies

```bash
cd engine/api
pip install -r requirements.txt
```

Or if you're using Python 3:
```bash
pip3 install -r requirements.txt
```

### 2. Start the API Server

```bash
python app.py
```

Or:
```bash
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

### 3. Test the API

Open a new terminal and run:

```bash
curl http://localhost:5000/health
```

Expected response:
```json
{
  "model_loaded": true,
  "status": "healthy",
  "timestamp": "2024-12-04T..."
}
```

## 📱 Connect Flutter App

### For iOS Simulator / Android Emulator:
The default `http://localhost:5000` will work.

### For Physical Device:
1. Find your Mac's IP address:
   - Open System Settings
   - Go to Network
   - Select Wi-Fi
   - Click Details
   - Find your IP (e.g., `192.168.1.10`)

2. Update `lib/services/ml_api_service.dart`:
```dart
static const String baseUrl = 'http://192.168.1.10:5000';
```

3. Make sure your phone and computer are on the same Wi-Fi network

## 🔌 API Endpoints

### 1. Health Check
```
GET /health
```

### 2. Daily Actions (Intelligent Recommendations)
```
POST /api/daily-actions
Content-Type: application/json

{
  "farm_data": {
    "crop": "Rice",
    "area": 0.809372,
    "area_acres": 2.0,
    "planting_date": "2024-06-15",
    "climate": {
      "tavg_climate": 28.0,
      "tmin_climate": 24.0,
      "tmax_climate": 33.0,
      "prcp_annual_climate": 5.5
    },
    "soil": {
      "zn": 80.0,
      "fe": 94.0,
      "cu": 90.0,
      "mn": 97.0,
      "b": 98.0,
      "s": 0.7
    }
  },
  "target_date": "2024-12-04"
}
```

Response:
```json
{
  "success": true,
  "date": "2024-12-04",
  "crop": "Rice",
  "crop_stage": {
    "stage": "Grain Filling",
    "days": 85,
    "description": "Grain development, maintain moisture"
  },
  "actions": [
    {
      "task": "💧 Maintain Moisture",
      "description": "Keep soil moist but reduce water depth slightly",
      "priority": "high",
      "timing": "Every 3-4 days"
    },
    ...
  ],
  "alerts": [
    {
      "type": "weather",
      "message": "🌧️ High rainfall region - Ensure drainage channels are clear",
      "severity": "medium"
    }
  ],
  "days_to_harvest": 45
}
```

### 3. Yield Prediction
```
POST /api/predict-yield
Content-Type: application/json

{
  "farm_data": { ... }
}
```

Response:
```json
{
  "success": true,
  "yield_per_hectare": 4.52,
  "total_yield_tonnes": 3.66,
  "total_yield_kg": 3660,
  "confidence": 88,
  "economics": {
    "gross_income_low": 73200,
    "gross_income_high": 91500,
    "total_cost": 15000,
    "net_profit_low": 58200,
    "net_profit_high": 76500,
    "roi_low": 388,
    "roi_high": 510
  }
}
```

### 4. Comprehensive Plan
```
POST /api/comprehensive-plan
```

Gets both daily actions + yield prediction in one call.

## 🧪 How It Works

### Growth Stage Calculation
Based on days since planting:
- **Rice**: Germination (0-10d) → Tillering (11-30d) → Stem Elongation (31-60d) → Panicle Initiation (61-90d) → Grain Filling (91-110d) → Maturity (111-130d) → Harvest (130d+)
- **Wheat**: Similar stages with different timings

### Intelligent Recommendations
The API considers:
- ✅ **Crop Growth Stage** - Stage-specific fertilizer, irrigation, pest control
- ✅ **Climate Data** - Temperature, rainfall patterns for risk alerts
- ✅ **Soil Health** - Nutrient deficiency warnings and corrections
- ✅ **ML Model** - XGBoost predictions (R²=0.71, 88% confidence)

### Example Recommendations:
**Day 21 (Tillering Stage)**:
- 🌾 Apply 15kg Urea per acre (critical fertilizer window)
- 💧 Maintain 2-3 cm water depth
- 🌿 Remove weeds

**Day 75 (Panicle Initiation)**:
- 💧 CRITICAL: Never let soil dry out (water stress = 30-50% yield loss)
- 🦠 Scout for stem borers
- ⚠️ High rainfall region? Ensure drainage

## 🔄 Daily Model Updates

Your `daily_update.py` script keeps the model learning from real farmer data:

```bash
# Run daily at 6 PM (set up cron job)
python ../crop_yield/daily_update.py
```

The model gets smarter every day with actual harvest results!

## 🛠️ Troubleshooting

### "Model not loaded"
- Check that `../crop_yield/models/crop_yield_climate_model.json` exists
- Run `python ../crop_yield/train.py` to train the model first

### "Connection refused" from Flutter
- Is the server running? Check terminal
- Are you using the correct IP address?
- Is firewall blocking port 5000?

### "Module not found"
```bash
pip install -r requirements.txt
```

## 📊 Model Performance

- **Algorithm**: XGBoost
- **R² Score**: 0.71 (71% accuracy)
- **Features**: 14 (area, climate, soil nutrients)
- **Training Data**: 20-year NASA climate averages + soil micronutrients
- **Continuous Learning**: Daily updates from farmer submissions

## 🎯 Integration with Flutter

See `lib/services/ml_api_service.dart` for:
- `MLApiService.getDailyActions()` - Get smart recommendations
- `MLApiService.predictYield()` - ML yield forecast
- `MLApiService.getComprehensivePlan()` - Full farming plan

## 📈 Future Enhancements

- [ ] Real-time weather forecasts (integrate OpenWeather API)
- [ ] Advanced disease image recognition with CNN models
- [ ] Market price predictions
- [ ] Automatic push notifications for critical tasks
- [ ] Offline mode with cached recommendations

## 🌿 Disease Detection Endpoints

### 4. Detect Plant Disease (Placeholder)
```
POST /api/detect-disease
Content-Type: multipart/form-data

file: <image file>
```

Response:
```json
{
  "model": "PlantDisease-CNN-v1 (Placeholder)",
  "predicted_class": "Brown Spot",
  "confidence": 0.87,
  "is_healthy": false,
  "description": "Fungal disease caused by nutrient deficiency",
  "recommendations": [
    "Apply balanced NPK fertilizer",
    "Spray fungicide (Mancozeb or Carbendazim)",
    "Improve soil fertility"
  ],
  "severity": "medium",
  "classes": ["Healthy", "Bacterial Blight", "Brown Spot", "Leaf Blast"],
  "probabilities": [0.05, 0.04, 0.87, 0.04],
  "top": [
    {"class": "Brown Spot", "prob": 0.87},
    {"class": "Healthy", "prob": 0.05},
    {"class": "Bacterial Blight", "prob": 0.04}
  ]
}
```

### 5. Get Available Disease Models
```
GET /api/disease-models
```

Response:
```json
{
  "models": {
    "plant_disease_cnn": {
      "name": "Plant Disease CNN",
      "status": "placeholder",
      "classes": ["Healthy", "Bacterial Blight", "Brown Spot", "Leaf Blast"],
      "accuracy": "TBD - Model not yet trained"
    }
  },
  "note": "Actual disease detection model will be added to engine/plants_disease/"
}
```

**Note**: Disease detection currently returns mock data. See `engine/plants_disease/README.md` for instructions on adding a real CNN model.

---

**Made with 🌾 for Smart Farming SIH 2025**
