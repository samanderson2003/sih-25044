# test_scenarios.py
import pandas as pd
import xgboost as xgb
import joblib

# Load model
model = xgb.XGBRegressor()
model.load_model("models/crop_yield_climate_model.json")
feature_cols = joblib.load("models/feature_columns_climate.pkl")

print("="*70)
print("🧪 MODEL VALIDATION - TESTING DIFFERENT SCENARIOS")
print("="*70)

# Define test scenarios
scenarios = {
    "1. OPTIMAL CONDITIONS (Punjab-style)": {
        "area": 2.0 * 0.404686,
        "tavg_climate": 27.0,  # Perfect for rice
        "tmin_climate": 22.0,
        "tmax_climate": 32.0,
        "prcp_annual_climate": 3.5,  # ~1275mm/year (good)
        "temp_range_climate": 10.0,
        "zn %": 92.0,  # Excellent
        "fe%": 96.0,  # Excellent
        "cu %": 94.0,  # Excellent
        "mn %": 98.0,
        "b %": 99.0,
        "s %": 0.8,
        "nutrient_index": 94.0,
        "season": "Kharif"
    },
    
    "2. DROUGHT CONDITIONS (Rajasthan-like)": {
        "area": 2.0 * 0.404686,
        "tavg_climate": 32.0,  # Hot
        "tmin_climate": 26.0,
        "tmax_climate": 39.0,  # Very hot
        "prcp_annual_climate": 1.2,  # ~440mm/year (drought)
        "temp_range_climate": 13.0,
        "zn %": 60.0,  # Low
        "fe%": 72.0,  # Low
        "cu %": 68.0,  # Low
        "mn %": 78.0,
        "b %": 82.0,
        "s %": 0.3,
        "nutrient_index": 66.7,
        "season": "Kharif"
    },
    
    "3. HEAVY RAINFALL (Kerala-style)": {
        "area": 2.0 * 0.404686,
        "tavg_climate": 27.5,
        "tmin_climate": 24.0,
        "tmax_climate": 31.0,
        "prcp_annual_climate": 9.0,  # ~3285mm/year (very high)
        "temp_range_climate": 7.0,
        "zn %": 75.0,  # Adequate (leached by rain)
        "fe%": 88.0,
        "cu %": 82.0,
        "mn %": 92.0,
        "b %": 94.0,
        "s %": 0.5,
        "nutrient_index": 81.7,
        "season": "Kharif"
    },
    
    "4. MODERATE CONDITIONS (West Bengal typical)": {
        "area": 2.0 * 0.404686,
        "tavg_climate": 28.0,
        "tmin_climate": 24.0,
        "tmax_climate": 33.0,
        "prcp_annual_climate": 5.5,  # ~2000mm/year
        "temp_range_climate": 9.0,
        "zn %": 80.0,
        "fe%": 94.0,
        "cu %": 90.0,
        "mn %": 97.0,
        "b %": 98.0,
        "s %": 0.7,
        "nutrient_index": 88.0,
        "season": "Kharif"
    },
    
    "5. COLD CLIMATE (Himachal-style)": {
        "area": 2.0 * 0.404686,
        "tavg_climate": 21.0,  # Cold
        "tmin_climate": 15.0,  # Very cold
        "tmax_climate": 28.0,
        "prcp_annual_climate": 4.0,  # ~1460mm/year
        "temp_range_climate": 13.0,
        "zn %": 85.0,
        "fe%": 92.0,
        "cu %": 88.0,
        "mn %": 95.0,
        "b %": 96.0,
        "s %": 0.6,
        "nutrient_index": 88.3,
        "season": "Kharif"
    },
    
    "6. POOR SOIL + GOOD CLIMATE": {
        "area": 2.0 * 0.404686,
        "tavg_climate": 27.0,  # Good
        "tmin_climate": 23.0,
        "tmax_climate": 32.0,
        "prcp_annual_climate": 3.8,  # ~1387mm/year (good)
        "temp_range_climate": 9.0,
        "zn %": 52.0,  # Very poor
        "fe%": 68.0,  # Poor
        "cu %": 61.0,  # Poor
        "mn %": 72.0,
        "b %": 78.0,
        "s %": 0.25,
        "nutrient_index": 60.3,
        "season": "Kharif"
    }
}

# Run predictions
results = []

for scenario_name, inputs in scenarios.items():
    # Prepare data
    test_df = pd.DataFrame([inputs])
    
    # Handle categorical (season)
    test_df = pd.get_dummies(test_df, columns=['season'], drop_first=True)
    
    # Add missing columns
    for col in feature_cols:
        if col not in test_df.columns:
            test_df[col] = 0
    
    # Align columns
    test_df = test_df[feature_cols]
    
    # Predict
    pred_per_ha = model.predict(test_df)[0]
    total_yield = pred_per_ha * inputs["area"]
    annual_rainfall = inputs["prcp_annual_climate"] * 365
    
    results.append({
        'scenario': scenario_name,
        'yield_per_ha': pred_per_ha,
        'total_yield': total_yield,
        'climate': f"{inputs['tavg_climate']:.1f}°C, {annual_rainfall:.0f}mm",
        'nutrients': f"Zn:{inputs['zn %']:.0f}% Fe:{inputs['fe%']:.0f}%"
    })
    
    # Print detailed result
    print(f"\n{scenario_name}")
    print("-" * 70)
    print(f"  Climate: Tavg={inputs['tavg_climate']:.1f}°C, Rain={annual_rainfall:.0f}mm/year")
    print(f"  Soil: Zn={inputs['zn %']:.0f}%, Fe={inputs['fe%']:.0f}%, Cu={inputs['cu %']:.0f}%")
    print(f"  🌾 PREDICTED YIELD: {pred_per_ha:.2f} t/ha ({pred_per_ha*1000:.0f} kg/ha)")
    print(f"  📦 Total for 2 acres: {total_yield:.2f} tonnes")
    
    # Economic estimate
    income_low = total_yield * 1000 * 20
    income_high = total_yield * 1000 * 25
    profit_low = income_low - 15000
    profit_high = income_high - 15000
    print(f"  💰 Expected Profit: ₹{profit_low:,.0f} - ₹{profit_high:,.0f}")

# Summary comparison
print("\n" + "="*70)
print("📊 SUMMARY COMPARISON")
print("="*70)

results_df = pd.DataFrame(results)
results_df = results_df.sort_values('yield_per_ha', ascending=False)

print("\nYield Ranking (High to Low):")
for idx, row in results_df.iterrows():
    print(f"{row['scenario']:<45} {row['yield_per_ha']:>6.2f} t/ha")

print("\n" + "="*70)
print("✅ VALIDATION CHECKS:")
print("="*70)

# Check if predictions are logical
optimal_yield = results_df.iloc[0]['yield_per_ha']
worst_yield = results_df.iloc[-1]['yield_per_ha']

print(f"\n1. Range Check:")
print(f"   Best scenario: {optimal_yield:.2f} t/ha")
print(f"   Worst scenario: {worst_yield:.2f} t/ha")
print(f"   Difference: {optimal_yield - worst_yield:.2f} t/ha")

if optimal_yield > worst_yield:
    print("   ✅ PASS: Best > Worst (logical)")
else:
    print("   ❌ FAIL: Best <= Worst (not logical)")

print(f"\n2. Realism Check (India national avg = 2.7 t/ha):")
for idx, row in results_df.iterrows():
    pct = (row['yield_per_ha'] / 2.7) * 100
    status = "✅" if 50 < pct < 180 else "⚠️"
    print(f"   {status} {row['scenario'][:35]:<35} {pct:>5.0f}% of national avg")

print(f"\n3. Sensitivity Check:")
# Find scenarios with similar climate but different soil
mod_cond = [r for r in results if "MODERATE" in r['scenario']][0]
poor_soil = [r for r in results if "POOR SOIL" in r['scenario']][0]

if mod_cond and poor_soil:
    soil_impact = mod_cond['yield_per_ha'] - poor_soil['yield_per_ha']
    print(f"   Good soil vs Poor soil: {soil_impact:.2f} t/ha difference")
    if soil_impact > 0.3:
        print(f"   ✅ PASS: Soil quality matters (impact = {soil_impact:.2f} t/ha)")
    else:
        print(f"   ⚠️ WARNING: Soil impact seems low")

print("\n" + "="*70)
