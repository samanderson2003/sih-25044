# 🌾 Smart Farming App - AI-Powered Agricultural Assistant

[![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue.svg)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.8+-green.svg)](https://python.org)
[![ML](https://img.shields.io/badge/ML-XGBoost-orange.svg)](https://xgboost.ai)
[![License](https://img.shields.io/badge/License-SIH%202025-red.svg)](LICENSE)

An intelligent farming assistant that provides **daily AI-powered recommendations** to maximize crop yield and farmer profits.

---

## 🚀 **One-Command Launch**

```bash
./start_app.sh        # macOS/Linux
start_app.bat         # Windows
```

This starts both the ML API server and Flutter app automatically!

---

## ✨ **Features**

### 🧠 **AI-Powered Daily Recommendations**
- **Growth Stage Intelligence**: Different tasks for each crop phase
- **ML Yield Predictions**: 71% accuracy (R²=0.71) using XGBoost
- **Smart Alerts**: Weather warnings, disease risks, nutrient deficiencies
- **Economic Forecasting**: Expected profit and ROI calculations

### 📱 **User Experience**
- Click any calendar date → Get personalized farming plan
- Priority-ranked tasks (Critical → High → Medium → Low)
- Real-time climate data from NASA POWER API
- Soil health analysis with actionable advice

### 📊 **Example Daily Plan (Rice - Day 21)**
```
🌱 Stage: Tillering (Day 21 since planting)
✅ Tasks:
   🔴 CRITICAL: Apply 15kg Urea per acre
   🟠 HIGH: Maintain 2-3 cm water depth
   🟡 MEDIUM: Remove weeds manually
⚠️ Alerts:
   Zinc deficiency detected - apply ZnSO₄
📈 Forecast:
   Expected Yield: 4.52 tonnes/hectare
   Net Profit: ₹58,200 - ₹76,500
```

---

## 📋 **Quick Start**

### Prerequisites
- Python 3.8+ ([Download](https://www.python.org/downloads/))
- Flutter 3.8+ ([Install Guide](https://flutter.dev/docs/get-started/install))
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/samanderson2003/sih-25044.git
cd sih-25044
```

2. **Train the ML model** (one-time)
```bash
cd engine/crop_yield
python3 train.py
cd ../..
```

3. **Launch everything**
```bash
./start_app.sh
```

That's it! 🎉

---

## 🏗️ **Architecture**

```
┌─────────────────┐
│  Flutter App    │  ← User Interface
└────────┬────────┘
         │ HTTP
         ↓
┌─────────────────┐
│  Flask API      │  ← ML API Server
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│  XGBoost Model  │  ← ML Predictions
└─────────────────┘
         │
         ↓
┌─────────────────┐
│  NASA Climate   │  ← Real Climate Data
│  + Soil Data    │
└─────────────────┘
```

---

## 📂 **Project Structure**

```
sih_25044/
├── start_app.sh              # 🚀 Main launcher
├── engine/
│   ├── api/
│   │   ├── app.py            # Flask API server
│   │   ├── requirements.txt  # Python dependencies
│   │   └── start_server.sh   # API launcher
│   └── crop_yield/
│       ├── train.py          # Train ML model
│       ├── predict.py        # Make predictions
│       └── models/           # Trained models
├── lib/
│   ├── home/
│   │   ├── view/
│   │   │   └── screens/
│   │   │       ├── home_screen.dart
│   │   │       └── daily_actions_screen.dart  # AI recommendations UI
│   │   ├── controller/
│   │   │   └── home_controller.dart
│   │   └── model/
│   ├── services/
│   │   └── ml_api_service.dart  # Flutter ↔ Python connector
│   ├── prior_data/           # Farm profile setup
│   ├── crop_yield_prediction/
│   └── auth/
├── QUICKSTART.md             # Detailed setup guide
└── pubspec.yaml              # Flutter dependencies
```

---

## 🎯 **How It Works**

1. **User clicks a date** on the calendar
2. **Flutter fetches** user's farm data (location, crops, soil)
3. **Sends to Python API** with planting date
4. **ML Model calculates**:
   - Days since planting → Growth stage
   - Climate data → Weather alerts
   - Soil nutrients → Deficiency warnings
   - XGBoost → Yield prediction
5. **Returns intelligent plan** with tasks, alerts, forecast
6. **Flutter displays** beautiful, actionable UI

---

## 🛠️ **Tech Stack**

### Frontend
- **Flutter 3.8+** - Cross-platform mobile framework
- **Provider** - State management
- **Firebase** - Authentication & Firestore database
- **Google Maps** - Location selection

### Backend
- **Flask** - Python web framework
- **XGBoost** - Machine learning model (R²=0.71)
- **Pandas** - Data processing
- **NumPy** - Numerical computations

### Data Sources
- **NASA POWER API** - 20-year climate averages
- **Soil Micronutrient Data** - Regional soil analysis
- **User Input** - Farm-specific data

---

## 🧪 **ML Model Details**

- **Algorithm**: XGBoost (Gradient Boosting)
- **Accuracy**: R² = 0.71 (71% variance explained)
- **Features**: 14 inputs
  - Farm area (hectares)
  - Climate: tavg, tmin, tmax, precipitation
  - Soil: Zn, Fe, Cu, Mn, B, S
  - Engineered: temp_range, nutrient_index
- **Training Data**: 20-year NASA climate + soil micronutrients
- **Output**: Crop yield (tonnes/hectare)
- **Continuous Learning**: Daily updates from farmer submissions

---

## 📊 **API Endpoints**

### Health Check
```bash
GET /health
```

### Daily Actions
```bash
POST /api/daily-actions
{
  "farm_data": {...},
  "target_date": "2024-12-04"
}
```

### Yield Prediction
```bash
POST /api/predict-yield
{
  "farm_data": {...}
}
```

### Comprehensive Plan
```bash
POST /api/comprehensive-plan
{
  "farm_data": {...},
  "target_date": "2024-12-04"
}
```

See [API Documentation](engine/api/README.md) for details.

---

## 🐛 **Troubleshooting**

### API Connection Error
```bash
# Check if API is running
curl http://localhost:5000/health

# Restart API
cd engine/api && python3 app.py
```

### Model Not Found
```bash
# Train the model
cd engine/crop_yield
python3 train.py
```

### Flutter Build Issues
```bash
flutter clean
flutter pub get
flutter run
```

### View Logs
```bash
# API logs
tail -f engine/api/api_server.log

# Flutter verbose
flutter run -v
```

---

## 🤝 **Contributing**

This project is developed for **Smart India Hackathon 2025**.

Team Members:
- [Your Team Members Here]

---

## 📄 **License**

This project is licensed for Smart India Hackathon 2025.

---

## 📞 **Support**

For issues and questions:
- Create an issue on GitHub
- Check [QUICKSTART.md](QUICKSTART.md) for detailed setup
- Review [API README](engine/api/README.md) for API docs

---

## 🌟 **Acknowledgments**

- NASA POWER API for climate data
- XGBoost team for ML framework
- Flutter team for amazing framework
- Smart India Hackathon organizers

---

**Made with 🌾 and ❤️ for Indian Farmers**

*Empowering agriculture through AI and data science*
