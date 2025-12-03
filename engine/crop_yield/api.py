from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional
import pandas as pd
import xgboost as xgb
import joblib
import os

# Initialize FastAPI app
app = FastAPI(
    title="AI Crop Yield Prediction API",
    description="Smart Agriculture Advisory System with ML-based yield prediction",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model and features at startup
model_path = "models/crop_yield_climate_model.json"
features_path = "models/feature_columns_climate.pkl"

model = None
feature_cols = None

@app.on_event("startup")
async def load_model():
    global model, feature_cols
    
    if not os.path.exists(model_path) or not os.path.exists(features_path):
        raise Exception("Model or feature column file missing")
    
    model = xgb.XGBRegressor()
    model.load_model(model_path)
    feature_cols = joblib.load(features_path)

# Pydantic models
class CropPredictionInput(BaseModel):
    area: float = Field(..., description="Farm area in acres", gt=0)
    tavg_climate: float = Field(..., description="Average temperature (°C)")
    tmin_climate: float = Field(..., description="Minimum temperature (°C)")
    tmax_climate: float = Field(..., description="Maximum temperature (°C)")
    prcp_annual_climate: float = Field(..., description="Daily average precipitation (mm)")
    zn_percent: float = Field(..., alias="zn %", description="Zinc percentage")
    fe_percent: float = Field(..., alias="fe%", description="Iron percentage")
    cu_percent: float = Field(..., alias="cu %", description="Copper percentage")
    mn_percent: float = Field(..., alias="mn %", description="Manganese percentage")
    b_percent: float = Field(..., alias="b %", description="Boron percentage")
    s_percent: float = Field(..., alias="s %", description="Sulfur percentage")
    crop: str = Field(..., description="Crop type (e.g., Rice)")
    season: str = Field(..., description="Season (e.g., Kharif, Rabi)")
    year: int = Field(..., description="Year")

class SoilStatus(BaseModel):
    zinc: str
    iron: str
    sulfur: str

class YieldForecast(BaseModel):
    per_hectare_tonnes: float
    total_expected_tonnes: float
    total_kg: float
    confidence_level: int
    model_r2: float

class EconomicEstimate(BaseModel):
    expected_income_low: float
    expected_income_high: float
    estimated_costs: float
    net_profit_low: float
    net_profit_high: float
    roi_low: float
    roi_high: float

class CropPredictionResponse(BaseModel):
    crop: str
    season: str
    farm_area_acres: float
    farm_area_hectares: float
    yield_forecast: YieldForecast
    climate: dict
    soil_health: SoilStatus
    irrigation_suggestion: str
    irrigation_detail: str
    fertilizer_recommendation: List[str]
    crop_suitability: dict
    high_risk_alerts: List[str]
    medium_risk_alerts: List[str]
    economic_estimate: EconomicEstimate
    additional_recommendations: List[str]

@app.get("/")
async def root():
    return {
        "message": "AI Crop Yield Prediction API",
        "status": "active",
        "model_loaded": model is not None
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "model_loaded": model is not None,
        "features_count": len(feature_cols) if feature_cols else 0
    }

@app.post("/predict", response_model=CropPredictionResponse)
async def predict_crop_yield(input_data: CropPredictionInput):
    if model is None or feature_cols is None:
        raise HTTPException(status_code=500, detail="Model not loaded")
    
    # Convert input to dictionary
    user_input = {
        "area": input_data.area * 0.404686,  # Convert acres to hectares
        "tavg_climate": input_data.tavg_climate,
        "tmin_climate": input_data.tmin_climate,
        "tmax_climate": input_data.tmax_climate,
        "prcp_annual_climate": input_data.prcp_annual_climate,
        "zn %": input_data.zn_percent,
        "fe%": input_data.fe_percent,
        "cu %": input_data.cu_percent,
        "mn %": input_data.mn_percent,
        "b %": input_data.b_percent,
        "s %": input_data.s_percent,
        "crop": input_data.crop,
        "season": input_data.season,
        "year": input_data.year
    }
    
    # Engineered features
    user_input["temp_range_climate"] = user_input["tmax_climate"] - user_input["tmin_climate"]
    user_input["nutrient_index"] = (user_input["zn %"] + user_input["fe%"] + user_input["cu %"]) / 3
    
    # Prepare data for ML
    new_data_raw = pd.DataFrame([user_input])
    categorical_cols = ['season']
    new_data = pd.get_dummies(new_data_raw, columns=categorical_cols, drop_first=True)
    
    # Add missing columns
    for col in feature_cols:
        if col not in new_data.columns:
            new_data[col] = 0
    
    new_data = new_data[feature_cols]
    
    # Predict
    predicted_yield_per_hectare = model.predict(new_data)[0]
    user_area_hectares = user_input["area"]
    total_expected_yield = predicted_yield_per_hectare * user_area_hectares
    
    # Calculate confidence
    confidence = 88
    if user_input["zn %"] < 70 or user_input["fe%"] < 85:
        confidence = 78
    
    # Generate advisory
    advice = []
    high_risk = []
    medium_risk = []
    
    # Soil analysis
    zn_status = "🟢 Good" if user_input["zn %"] >= 85 else "🟡 Adequate" if user_input["zn %"] >= 70 else "🔴 Low"
    fe_status = "🟢 Good" if user_input["fe%"] >= 90 else "🟡 Adequate" if user_input["fe%"] >= 80 else "🔴 Low"
    s_status = "🟢 Good" if user_input["s %"] >= 0.5 else "🟡 Adequate" if user_input["s %"] >= 0.3 else "🔴 Low"
    
    if user_input["zn %"] < 85:
        advice.append("Consider ZnSO₄ application (10kg/acre) for yield boost (+300-500 kg/ha)")
    if user_input["zn %"] < 60:
        high_risk.append("🧪 Severe Zinc deficiency — Apply 15kg ZnSO₄ immediately")
    if user_input["s %"] < 0.4:
        advice.append("Low sulfur — Apply Gypsum (20kg/acre) to improve grain quality")
    
    # Weather risk analysis
    annual_rainfall = user_input["prcp_annual_climate"] * 365
    
    if annual_rainfall > 1800:
        high_risk.append("🌧️ High rainfall region → Ensure drainage infrastructure")
        medium_risk.append("🦠 Fungal Disease Risk → Scout fields regularly")
    elif annual_rainfall > 1500:
        medium_risk.append("🌧️ Heavy rainfall region → Monitor drainage")
    
    if user_input["tmax_climate"] > 34:
        high_risk.append("🔥 Hot climate region → Heat-tolerant varieties recommended")
    elif user_input["tmax_climate"] > 32:
        medium_risk.append("⚠️ Warm climate → Monitor for heat stress during flowering")
    
    if user_input["tmin_climate"] < 18:
        medium_risk.append("❄️ Cool climate → May need longer maturity varieties")
    
    # Irrigation suggestion
    if annual_rainfall >= 1800:
        irrigation = "Minimal irrigation needed (high rainfall zone)"
        irrigation_detail = "⚠️ Focus on drainage management"
    elif annual_rainfall >= 1200:
        irrigation = "1-2 supplemental irrigations if rain gaps >7 days"
        irrigation_detail = "✓ Monitor soil moisture during flowering stage"
    elif annual_rainfall >= 800:
        irrigation = "3-4 irrigations required (critical: tillering, flowering, grain filling)"
        irrigation_detail = "✓ Apply 5-7 cm water depth per irrigation"
    else:
        irrigation = "High irrigation dependency: 6-8 cycles throughout season"
        irrigation_detail = "⚠️ Ensure reliable water source, drip/sprinkler recommended"
    
    # Fertilizer recommendation
    fertilizer = []
    if user_input["crop"] == "Rice":
        basal = "40kg Urea + 20kg DAP"
        if user_input["zn %"] < 85:
            basal += " + 10kg ZnSO₄"
        
        fertilizer = [
            f"Basal Dose: {basal} per acre",
            "Top Dressing (1st): 15kg Urea at 21 days (tillering stage)",
            "Top Dressing (2nd): 10kg Urea at 45 days (panicle initiation)"
        ]
        
        if annual_rainfall > 1500:
            fertilizer.append("⚠️ Split fertilizers into 3-4 doses (high rainfall leaches nutrients)")
    
    # Crop suitability
    suitability_score = 100
    suitability_factors = []
    
    if 25 <= user_input["tavg_climate"] <= 30:
        suitability_factors.append("✓ Optimal climate temperature")
    elif 22 <= user_input["tavg_climate"] <= 32:
        suitability_score -= 8
        suitability_factors.append("→ Climate temperature slightly suboptimal")
    else:
        suitability_score -= 20
        suitability_factors.append("⚠ Climate temperature not ideal")
    
    if 1000 <= annual_rainfall <= 1500:
        suitability_factors.append("✓ Ideal regional rainfall")
    elif 800 <= annual_rainfall <= 1800:
        suitability_score -= 5
        suitability_factors.append("→ Regional rainfall manageable")
    else:
        suitability_score -= 15
        suitability_factors.append("⚠ Regional rainfall requires management")
    
    avg_nutrients = (user_input["zn %"] + user_input["fe%"]) / 2
    if avg_nutrients >= 85:
        suitability_factors.append("✓ Good soil health")
    elif avg_nutrients >= 70:
        suitability_score -= 8
        suitability_factors.append("→ Adequate soil nutrients")
    else:
        suitability_score -= 20
        suitability_factors.append("⚠ Soil needs improvement")
    
    suitability_rating = "Excellent" if suitability_score >= 90 else "Good" if suitability_score >= 75 else "Moderate"
    
    # Economic estimate
    price_low = 20
    price_high = 25
    total_kg = total_expected_yield * 1000
    
    gross_income_low = total_kg * price_low
    gross_income_high = total_kg * price_high
    
    cost_per_acre = 7500
    total_cost = cost_per_acre * input_data.area
    
    net_profit_low = gross_income_low - total_cost
    net_profit_high = gross_income_high - total_cost
    
    # Build response
    response = CropPredictionResponse(
        crop=user_input["crop"],
        season=user_input["season"],
        farm_area_acres=input_data.area,
        farm_area_hectares=user_area_hectares,
        yield_forecast=YieldForecast(
            per_hectare_tonnes=predicted_yield_per_hectare,
            total_expected_tonnes=total_expected_yield,
            total_kg=total_kg,
            confidence_level=confidence,
            model_r2=0.71
        ),
        climate={
            "temperature_avg": user_input["tavg_climate"],
            "temperature_min": user_input["tmin_climate"],
            "temperature_max": user_input["tmax_climate"],
            "annual_rainfall_mm": annual_rainfall
        },
        soil_health=SoilStatus(
            zinc=f"{user_input['zn %']}% {zn_status}",
            iron=f"{user_input['fe%']}% {fe_status}",
            sulfur=f"{user_input['s %']}% {s_status}"
        ),
        irrigation_suggestion=irrigation,
        irrigation_detail=irrigation_detail,
        fertilizer_recommendation=fertilizer,
        crop_suitability={
            "rating": suitability_rating,
            "score": suitability_score,
            "factors": suitability_factors
        },
        high_risk_alerts=high_risk,
        medium_risk_alerts=medium_risk,
        economic_estimate=EconomicEstimate(
            expected_income_low=gross_income_low,
            expected_income_high=gross_income_high,
            estimated_costs=total_cost,
            net_profit_low=net_profit_low,
            net_profit_high=net_profit_high,
            roi_low=(net_profit_low/total_cost)*100,
            roi_high=(net_profit_high/total_cost)*100
        ),
        additional_recommendations=advice
    )
    
    return response

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)