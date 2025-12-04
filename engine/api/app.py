# app.py - Flask API Server for ML Model
from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import xgboost as xgb
import joblib
import os
import sys
from datetime import datetime, timedelta

# Add parent directory to path to import from crop_yield
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

app = Flask(__name__)
CORS(app)  # Allow Flutter app to connect

# ===========================
# Load ML Model at Startup
# ===========================
# Get the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(SCRIPT_DIR, "../crop_yield/models/crop_yield_climate_model.json")
FEATURES_PATH = os.path.join(SCRIPT_DIR, "../crop_yield/models/feature_columns_climate.pkl")

print("🚀 Loading ML Model...")
try:
    model = xgb.XGBRegressor()
    model.load_model(MODEL_PATH)
    feature_cols = joblib.load(FEATURES_PATH)
    print(f"✅ Model loaded successfully ({len(feature_cols)} features)")
except Exception as e:
    print(f"❌ Error loading model: {e}")
    model = None
    feature_cols = None

# ===========================
# Helper Functions
# ===========================
def calculate_crop_stage(planting_date_str, crop_type):
    """
    Calculate current growth stage based on days since planting
    """
    try:
        planting_date = datetime.strptime(planting_date_str, "%Y-%m-%d")
        days_since_planting = (datetime.now() - planting_date).days
        
        # Rice growth stages (adjust for other crops)
        if crop_type.lower() == "rice":
            if days_since_planting < 0:
                return {"stage": "Not Planted", "days": days_since_planting, "description": "Future planting date"}
            elif days_since_planting <= 10:
                return {"stage": "Germination", "days": days_since_planting, "description": "Seed sprouting phase"}
            elif days_since_planting <= 30:
                return {"stage": "Tillering", "days": days_since_planting, "description": "Vegetative growth, new shoots forming"}
            elif days_since_planting <= 60:
                return {"stage": "Stem Elongation", "days": days_since_planting, "description": "Active growth, prepare for panicle"}
            elif days_since_planting <= 90:
                return {"stage": "Panicle Initiation", "days": days_since_planting, "description": "Flowering stage, critical water needs"}
            elif days_since_planting <= 110:
                return {"stage": "Grain Filling", "days": days_since_planting, "description": "Grain development, maintain moisture"}
            elif days_since_planting <= 130:
                return {"stage": "Maturity", "days": days_since_planting, "description": "Near harvest, reduce water"}
            else:
                return {"stage": "Ready for Harvest", "days": days_since_planting, "description": "Harvest window"}
        
        # Wheat growth stages
        elif crop_type.lower() == "wheat":
            if days_since_planting < 0:
                return {"stage": "Not Planted", "days": days_since_planting, "description": "Future planting date"}
            elif days_since_planting <= 15:
                return {"stage": "Germination", "days": days_since_planting, "description": "Seed sprouting"}
            elif days_since_planting <= 40:
                return {"stage": "Tillering", "days": days_since_planting, "description": "Vegetative growth"}
            elif days_since_planting <= 80:
                return {"stage": "Stem Extension", "days": days_since_planting, "description": "Rapid growth phase"}
            elif days_since_planting <= 100:
                return {"stage": "Heading", "days": days_since_planting, "description": "Flowering, critical period"}
            elif days_since_planting <= 120:
                return {"stage": "Grain Filling", "days": days_since_planting, "description": "Grain development"}
            elif days_since_planting <= 140:
                return {"stage": "Maturity", "days": days_since_planting, "description": "Approaching harvest"}
            else:
                return {"stage": "Ready for Harvest", "days": days_since_planting, "description": "Harvest time"}
        
        # Default for other crops
        else:
            progress = min(100, int((days_since_planting / 120) * 100))
            return {"stage": "Growing", "days": days_since_planting, "description": f"{progress}% complete"}
    
    except Exception as e:
        return {"stage": "Unknown", "days": 0, "description": str(e)}

def generate_daily_actions(farm_data, crop_stage, target_date):
    """
    Generate intelligent daily recommendations based on:
    - Crop growth stage
    - Weather/climate data
    - Soil nutrients
    - Target date
    """
    actions = []
    alerts = []
    
    stage_name = crop_stage["stage"]
    days_since_planting = crop_stage["days"]
    
    # Get data
    climate = farm_data.get("climate", {})
    soil = farm_data.get("soil", {})
    crop_type = farm_data.get("crop", "Rice")
    
    annual_rainfall = climate.get("prcp_annual_climate", 5.0) * 365
    tavg = climate.get("tavg_climate", 28.0)
    tmax = climate.get("tmax_climate", 33.0)
    
    zn = soil.get("zn", 80.0)
    fe = soil.get("fe", 90.0)
    s = soil.get("s", 0.5)
    
    # ===========================
    # Stage-Specific Actions
    # ===========================
    
    if stage_name == "Germination":
        actions.append({
            "task": "🌱 Maintain Moisture",
            "description": "Keep soil consistently moist (not waterlogged)",
            "priority": "high",
            "timing": "Morning"
        })
        actions.append({
            "task": "🔍 Monitor Germination",
            "description": "Check for uniform sprouting across field",
            "priority": "medium",
            "timing": "Evening"
        })
    
    elif stage_name == "Tillering":
        # First top dressing around day 21
        if 18 <= days_since_planting <= 24:
            actions.append({
                "task": "🌾 First Top Dressing",
                "description": f"Apply 15kg Urea per acre (Day {days_since_planting})",
                "priority": "high",
                "timing": "Morning after irrigation"
            })
            alerts.append({
                "type": "fertilizer",
                "message": "⏰ Critical fertilizer window - Apply urea within next 3 days",
                "severity": "high"
            })
        
        actions.append({
            "task": "💧 Irrigation Schedule",
            "description": "Maintain 2-3 cm water depth" if annual_rainfall < 1200 else "Monitor natural rainfall",
            "priority": "high",
            "timing": "As needed"
        })
        
        actions.append({
            "task": "🌿 Weed Control",
            "description": "Remove weeds manually or apply herbicide",
            "priority": "medium",
            "timing": "Morning"
        })
    
    elif stage_name == "Stem Elongation" or stage_name == "Stem Extension":
        # Second top dressing around day 45
        if crop_type.lower() == "rice" and 42 <= days_since_planting <= 48:
            actions.append({
                "task": "🌾 Second Top Dressing",
                "description": f"Apply 10kg Urea per acre (Day {days_since_planting})",
                "priority": "high",
                "timing": "Morning"
            })
            alerts.append({
                "type": "fertilizer",
                "message": "⏰ Second fertilizer application window - Apply within 3 days",
                "severity": "high"
            })
        
        actions.append({
            "task": "💧 Increase Water Supply",
            "description": "Ensure adequate moisture for rapid growth",
            "priority": "high",
            "timing": "Twice weekly"
        })
    
    elif stage_name == "Panicle Initiation" or stage_name == "Heading":
        actions.append({
            "task": "💧 Critical Water Needs",
            "description": "⚠️ MOST CRITICAL STAGE - Never let soil dry out",
            "priority": "critical",
            "timing": "Daily monitoring"
        })
        alerts.append({
            "type": "irrigation",
            "message": "🚨 Flowering stage - Water stress now = 30-50% yield loss",
            "severity": "critical"
        })
        
        actions.append({
            "task": "🦠 Pest Scouting",
            "description": "Check for stem borers, leaf folders",
            "priority": "high",
            "timing": "Morning & Evening"
        })
    
    elif stage_name == "Grain Filling":
        actions.append({
            "task": "💧 Maintain Moisture",
            "description": "Keep soil moist but reduce water depth slightly",
            "priority": "high",
            "timing": "Every 3-4 days"
        })
        
        actions.append({
            "task": "🔍 Monitor Grain Development",
            "description": "Check for uniform grain filling and milky stage",
            "priority": "medium",
            "timing": "Weekly"
        })
    
    elif stage_name == "Maturity":
        actions.append({
            "task": "💧 Reduce Irrigation",
            "description": "Drain field 7-10 days before harvest",
            "priority": "high",
            "timing": "Stop irrigation"
        })
        
        if days_since_planting >= 120:
            actions.append({
                "task": "🌾 Prepare for Harvest",
                "description": "Check grain moisture (should be 20-25%)",
                "priority": "high",
                "timing": "Within 1 week"
            })
            alerts.append({
                "type": "harvest",
                "message": f"📅 Harvest window approaching - Plan for harvest in 5-10 days",
                "severity": "medium"
            })
    
    elif stage_name == "Ready for Harvest":
        actions.append({
            "task": "🌾 HARVEST NOW",
            "description": "Grain moisture at optimal level - harvest immediately",
            "priority": "critical",
            "timing": "ASAP"
        })
        alerts.append({
            "type": "harvest",
            "message": "🚨 Harvest window open - Delays may cause grain shattering",
            "severity": "critical"
        })
    
    # ===========================
    # Weather-Based Actions
    # ===========================
    
    if annual_rainfall > 1800:
        alerts.append({
            "type": "weather",
            "message": "🌧️ High rainfall region - Ensure drainage channels are clear",
            "severity": "medium"
        })
        
        if stage_name not in ["Maturity", "Ready for Harvest"]:
            actions.append({
                "task": "🚿 Check Drainage",
                "description": "Prevent waterlogging damage",
                "priority": "medium",
                "timing": "After heavy rain"
            })
    
    if tmax > 35:
        alerts.append({
            "type": "weather",
            "message": f"🔥 High temperature ({tmax}°C) - Heat stress risk",
            "severity": "medium"
        })
        actions.append({
            "task": "🌡️ Heat Stress Mitigation",
            "description": "Irrigate in evening to cool soil",
            "priority": "medium",
            "timing": "Evening"
        })
    
    # ===========================
    # Soil-Based Actions
    # ===========================
    
    if zn < 70:
        alerts.append({
            "type": "soil",
            "message": f"⚠️ Zinc deficiency detected ({zn}%) - Yield at risk",
            "severity": "high"
        })
        actions.append({
            "task": "🧪 Apply Zinc Sulfate",
            "description": "Apply 15kg ZnSO₄ per acre immediately",
            "priority": "high",
            "timing": "Within 3 days"
        })
    
    if s < 0.3:
        alerts.append({
            "type": "soil",
            "message": f"⚠️ Sulfur deficiency ({s}%) - Grain quality at risk",
            "severity": "medium"
        })
        actions.append({
            "task": "🧪 Apply Gypsum",
            "description": "Apply 20kg Gypsum per acre",
            "priority": "medium",
            "timing": "Before panicle initiation"
        })
    
    # ===========================
    # Disease Risk
    # ===========================
    
    if annual_rainfall > 1500 and tavg > 25:
        alerts.append({
            "type": "disease",
            "message": "🦠 Fungal disease risk (high humidity + warm temp)",
            "severity": "medium"
        })
        actions.append({
            "task": "🔍 Scout for Leaf Blast",
            "description": "Check leaves for brown spots with gray centers",
            "priority": "medium",
            "timing": "Weekly"
        })
    
    # Sort actions by priority
    priority_order = {"critical": 0, "high": 1, "medium": 2, "low": 3}
    actions.sort(key=lambda x: priority_order.get(x["priority"], 3))
    
    return {
        "actions": actions,
        "alerts": alerts,
        "crop_stage": crop_stage,
        "days_to_harvest": max(0, 130 - days_since_planting) if crop_type.lower() == "rice" else max(0, 140 - days_since_planting)
    }

def predict_yield(farm_data):
    """
    Predict crop yield using ML model
    """
    if model is None or feature_cols is None:
        return {"error": "Model not loaded"}
    
    try:
        # Extract climate data (handle both formats)
        climate = farm_data.get("climate", {})
        
        # Prepare input data
        user_input = {
            "area": farm_data.get("farm_area_acres", farm_data.get("area", 1.0)) * 0.404686,  # Convert acres to hectares
            "tavg_climate": climate.get("tavg_climate", climate.get("tavg", 25)),
            "tmin_climate": climate.get("tmin_climate", climate.get("tmin", 20)),
            "tmax_climate": climate.get("tmax_climate", climate.get("tmax", 30)),
            "prcp_annual_climate": climate.get("prcp_annual_climate", climate.get("prcp", 100)),
            "zn %": farm_data["soil"]["zn"],
            "fe%": farm_data["soil"]["fe"],
            "cu %": farm_data["soil"]["cu"],
            "mn %": farm_data["soil"]["mn"],
            "b %": farm_data["soil"]["b"],
            "s %": farm_data["soil"]["s"]
        }
        
        # Engineer features
        user_input["temp_range_climate"] = user_input["tmax_climate"] - user_input["tmin_climate"]
        user_input["nutrient_index"] = (user_input["zn %"] + user_input["fe%"] + user_input["cu %"]) / 3
        
        # Convert to DataFrame
        new_data = pd.DataFrame([user_input])
        
        # Handle season if present
        if "season" in farm_data:
            new_data["season"] = farm_data["season"]
            new_data = pd.get_dummies(new_data, columns=["season"], drop_first=True)
        
        # Add missing columns
        for col in feature_cols:
            if col not in new_data.columns:
                new_data[col] = 0
        
        # Align columns
        new_data = new_data[feature_cols]
        
        # Predict
        predicted_yield_per_hectare = float(model.predict(new_data)[0])  # Convert numpy float32 to Python float
        total_expected_yield = float(predicted_yield_per_hectare * user_input["area"])
        
        # Calculate confidence
        confidence = 88
        if user_input["zn %"] < 70 or user_input["fe%"] < 85:
            confidence = 78
        
        # Economic calculation
        price_low = 20  # Rs per kg
        price_high = 25
        total_kg = float(total_expected_yield * 1000)
        
        gross_income_low = float(total_kg * price_low)
        gross_income_high = float(total_kg * price_high)
        
        area_acres = float(farm_data.get("farm_area_acres", farm_data.get("area", 1.0) * 2.47105))  # hectares to acres
        cost_per_acre = 7500
        total_cost = float(cost_per_acre * area_acres)
        
        net_profit_low = float(gross_income_low - total_cost)
        net_profit_high = float(gross_income_high - total_cost)
        
        return {
            "yield_forecast": {
                "per_hectare_tonnes": round(predicted_yield_per_hectare, 2),
                "total_expected_tonnes": round(total_expected_yield, 2),
                "total_kg": int(total_kg),
                "confidence_level": int(confidence)
            },
            "economic_estimate": {
                "gross_income_low": int(gross_income_low),
                "gross_income_high": int(gross_income_high),
                "total_cost": int(total_cost),
                "net_profit_low": int(net_profit_low),
                "net_profit_high": int(net_profit_high),
                "roi_low": int(round((net_profit_low / total_cost) * 100, 0)),
                "roi_high": int(round((net_profit_high / total_cost) * 100, 0))
            }
        }
    
    except Exception as e:
        return {"error": str(e)}

# ===========================
# API Endpoints
# ===========================

@app.route('/health', methods=['GET'])
def health_check():
    """Check if API is running"""
    return jsonify({
        "status": "healthy",
        "model_loaded": model is not None,
        "timestamp": datetime.now().isoformat()
    })

@app.route('/api/daily-actions', methods=['POST'])
def get_daily_actions():
    """
    Get intelligent daily recommendations for a specific date
    
    Request body:
    {
        "farm_data": {
            "crop": "Rice",
            "area": 0.809372,  // hectares
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
        "target_date": "2024-12-04"  // optional, defaults to today
    }
    """
    try:
        data = request.get_json()
        farm_data = data.get("farm_data")
        target_date = data.get("target_date", datetime.now().strftime("%Y-%m-%d"))
        
        if not farm_data:
            return jsonify({"error": "farm_data is required"}), 400
        
        # Calculate crop stage
        planting_date = farm_data.get("planting_date")
        crop_type = farm_data.get("crop", "Rice")
        
        if not planting_date:
            return jsonify({"error": "planting_date is required"}), 400
        
        crop_stage = calculate_crop_stage(planting_date, crop_type)
        
        # Generate daily actions
        recommendations = generate_daily_actions(farm_data, crop_stage, target_date)
        
        return jsonify({
            "success": True,
            "date": target_date,
            "crop": crop_type,
            **recommendations
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/predict-yield', methods=['POST'])
def api_predict_yield():
    """
    Predict crop yield using ML model
    
    Request body: Same as daily-actions
    """
    try:
        data = request.get_json()
        farm_data = data.get("farm_data")
        
        if not farm_data:
            return jsonify({"error": "farm_data is required"}), 400
        
        result = predict_yield(farm_data)
        
        if "error" in result:
            return jsonify(result), 500
        
        return jsonify({
            "success": True,
            **result
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/api/comprehensive-plan', methods=['POST'])
def get_comprehensive_plan():
    """
    Get complete farming plan: daily actions + yield prediction + economic forecast
    """
    try:
        data = request.get_json()
        farm_data = data.get("farm_data")
        target_date = data.get("target_date", datetime.now().strftime("%Y-%m-%d"))
        
        if not farm_data:
            return jsonify({"error": "farm_data is required"}), 400
        
        # Get crop stage and actions
        planting_date = farm_data.get("planting_date")
        crop_type = farm_data.get("crop_type", farm_data.get("crop", "Rice"))
        crop_stage = calculate_crop_stage(planting_date, crop_type)
        recommendations = generate_daily_actions(farm_data, crop_stage, target_date)
        
        # Get yield prediction
        yield_result = predict_yield(farm_data)
        
        # Check if prediction failed
        if "error" in yield_result:
            return jsonify({
                "success": True,
                "date": target_date,
                "crop": crop_type,
                "daily_plan": recommendations,
                "yield_forecast": {"error": yield_result["error"]},
                "ml_model": "XGBoost (R²=0.71)"
            })
        
        # Flatten the structure for the home page view
        forecast_data = yield_result.get("yield_forecast", {})
        economic_data = yield_result.get("economic_estimate", {})
        
        combined_forecast = {
            "total_yield_tonnes": forecast_data.get("total_expected_tonnes", 0),
            "total_yield_kg": forecast_data.get("total_kg", 0),
            "yield_per_hectare": forecast_data.get("per_hectare_tonnes", 0),
            "confidence": forecast_data.get("confidence_level", 0),
            "economics": economic_data
        }
        
        return jsonify({
            "success": True,
            "date": target_date,
            "crop": crop_type,
            "daily_plan": recommendations,
            "yield_forecast": combined_forecast,
            "ml_model": "XGBoost (R²=0.71)"
        })
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ===========================
# Disease Detection Endpoints
# ===========================
@app.route('/api/detect-disease', methods=['POST'])
def detect_disease():
    """
    Disease detection endpoint (placeholder until actual model is added)
    Accepts: multipart/form-data with 'file' (image)
    Returns: Disease detection results
    """
    try:
        # Check if file is present
        if 'file' not in request.files:
            return jsonify({"error": "No image file provided"}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "Empty filename"}), 400
        
        # TODO: Load actual disease detection model
        # For now, return mock data with realistic structure
        
        # Simulate different disease scenarios based on random selection
        import random
        diseases = [
            {
                "class": "Healthy",
                "confidence": 0.92,
                "description": "No disease detected. Plant appears healthy.",
                "recommendations": [
                    "Continue regular monitoring",
                    "Maintain current care routine",
                    "Ensure proper watering schedule"
                ]
            },
            {
                "class": "Bacterial Blight",
                "confidence": 0.87,
                "description": "Bacterial infection affecting leaves",
                "recommendations": [
                    "Remove affected leaves immediately",
                    "Apply copper-based bactericide",
                    "Improve field drainage",
                    "Avoid overhead irrigation"
                ]
            },
            {
                "class": "Brown Spot",
                "confidence": 0.78,
                "description": "Fungal disease caused by nutrient deficiency",
                "recommendations": [
                    "Apply balanced NPK fertilizer",
                    "Spray fungicide (Mancozeb or Carbendazim)",
                    "Improve soil fertility",
                    "Ensure adequate silicon levels"
                ]
            },
            {
                "class": "Leaf Blast",
                "confidence": 0.84,
                "description": "Fungal disease affecting leaves and stems",
                "recommendations": [
                    "Apply Tricyclazole or Isoprothiolane",
                    "Remove infected plant debris",
                    "Reduce nitrogen fertilizer",
                    "Improve air circulation"
                ]
            }
        ]
        
        # Select random disease for demo
        selected = random.choice(diseases)
        
        # Create all disease probabilities
        all_classes = [d["class"] for d in diseases]
        probabilities = [0.0] * len(all_classes)
        predicted_index = all_classes.index(selected["class"])
        probabilities[predicted_index] = selected["confidence"]
        
        # Add small random probabilities for other classes
        remaining = 1.0 - selected["confidence"]
        for i in range(len(probabilities)):
            if i != predicted_index:
                probabilities[i] = remaining / (len(probabilities) - 1)
        
        # Create top predictions (sorted by probability)
        top_predictions = []
        for i, prob in enumerate(probabilities):
            top_predictions.append({
                "class": all_classes[i],
                "prob": round(prob, 4)
            })
        top_predictions.sort(key=lambda x: x["prob"], reverse=True)
        top_predictions = top_predictions[:3]  # Top 3
        
        response = {
            "model": "PlantDisease-CNN-v1 (Placeholder)",
            "predicted_index": predicted_index,
            "predicted_class": selected["class"],
            "confidence": selected["confidence"],
            "classes": all_classes,
            "probabilities": [round(p, 4) for p in probabilities],
            "top": top_predictions,
            "description": selected["description"],
            "recommendations": selected["recommendations"],
            "severity": "high" if selected["confidence"] > 0.8 and selected["class"] != "Healthy" else "medium",
            "is_healthy": selected["class"] == "Healthy"
        }
        
        return jsonify(response)
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/disease-models', methods=['GET'])
def get_disease_models():
    """
    Get available disease detection models
    """
    return jsonify({
        "models": {
            "plant_disease_cnn": {
                "name": "Plant Disease CNN",
                "status": "placeholder",
                "classes": ["Healthy", "Bacterial Blight", "Brown Spot", "Leaf Blast"],
                "accuracy": "TBD - Model not yet trained"
            }
        },
        "note": "Actual disease detection model will be added to engine/plants_disease/"
    })


if __name__ == '__main__':
    print("\n" + "="*70)
    print("🌾 SMART FARMING API SERVER")
    print("="*70)
    print(f"✅ Model Status: {'Loaded' if model else 'Not Loaded'}")
    print(f"✅ Features: {len(feature_cols) if feature_cols else 0}")
    print("="*70)
    print("\n🚀 Starting server on http://localhost:5001\n")
    
    app.run(host='0.0.0.0', port=5001, debug=True)
