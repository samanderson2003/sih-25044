# train_with_climate.py
import os
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
import xgboost as xgb
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import joblib

# ===========================
# 1. Load merged dataset with CLIMATE
# ===========================
data_path = "data/processed/merged_dataset_climate.csv"
df = pd.read_csv(data_path)

print(f"Original dataset size: {len(df)} rows")

df = df.dropna(subset=["production", "area"])
df = df[df["area"] > 0]

# ===========================
# 2. Create yield per area target
# ===========================
df["yield_per_area"] = df["production"] / df["area"]

# Filter to Rice AND remove outliers
df = df[df["crop"].str.strip() == "Rice"]
df = df[df["yield_per_area"] < 10]
df = df[df["yield_per_area"] > 0.5]

# Remove rows with missing climate data
df = df.dropna(subset=["tavg_climate", "prcp_annual_climate"])

print(f"Dataset shape after cleaning: {df.shape}")
print(f"Yield per area stats:\n{df['yield_per_area'].describe()}")

# ===========================
# 3. Feature Engineering with CLIMATE
# ===========================
df["temp_range_climate"] = df["tmax_climate"] - df["tmin_climate"]
df["nutrient_index"] = (df["zn %"] + df["fe%"] + df["cu %"]) / 3

# ===========================
# 4. Select features & target
# ===========================
numeric_features = ["area", 
                    "tavg_climate", "tmin_climate", "tmax_climate", "prcp_annual_climate",
                    "temp_range_climate",
                    "zn %", "fe%", "cu %", "mn %", "b %", "s %",
                    "nutrient_index"]

numeric_features = [f for f in numeric_features if f in df.columns]

X = df[numeric_features].copy()

categorical_features = []
if "season" in df.columns:
    categorical_features.append("season")

if len(categorical_features) > 0:
    X = pd.get_dummies(X.join(df[categorical_features]), 
                       columns=categorical_features, 
                       drop_first=True)

y = df["yield_per_area"]

# Save feature columns
feature_cols = X.columns.tolist()
os.makedirs("models", exist_ok=True)
joblib.dump(feature_cols, "models/feature_columns_climate.pkl")
print(f"Saved {len(feature_cols)} feature columns")

# ===========================
# 5. Train-test split
# ===========================
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

print(f"Training samples: {len(X_train)}, Test samples: {len(X_test)}")

# ===========================
# 6. Train XGBoost Model
# ===========================
print("\n🔹 Training XGBoost...")
model_xgb = xgb.XGBRegressor(
    n_estimators=300,
    max_depth=8,
    learning_rate=0.05,
    subsample=0.8,
    colsample_bytree=0.8,
    random_state=42,
    n_jobs=-1
)

model_xgb.fit(X_train, y_train)

y_pred_xgb = model_xgb.predict(X_test)

mae_xgb = mean_absolute_error(y_test, y_pred_xgb)
mse_xgb = mean_squared_error(y_test, y_pred_xgb)
r2_xgb = r2_score(y_test, y_pred_xgb)

print("\n" + "="*50)
print("XGBOOST MODEL (With NASA Climate Data)")
print("="*50)
print(f"Mean Absolute Error: {mae_xgb:.2f}")
print(f"Mean Squared Error: {mse_xgb:.2f}")
print(f"R2 Score: {r2_xgb:.4f}")
print("="*50)

# ===========================
# 7. Train RandomForest for comparison
# ===========================
print("\n🔹 Training RandomForest...")
model_rf = RandomForestRegressor(
    n_estimators=200,
    max_depth=15,
    random_state=42,
    n_jobs=-1
)

model_rf.fit(X_train, y_train)

y_pred_rf = model_rf.predict(X_test)

mae_rf = mean_absolute_error(y_test, y_pred_rf)
mse_rf = mean_squared_error(y_test, y_pred_rf)
r2_rf = r2_score(y_test, y_pred_rf)

print("\n" + "="*50)
print("RANDOM FOREST MODEL (With NASA Climate Data)")
print("="*50)
print(f"Mean Absolute Error: {mae_rf:.2f}")
print(f"Mean Squared Error: {mse_rf:.2f}")
print(f"R2 Score: {r2_rf:.4f}")
print("="*50)

# ===========================
# 8. Save best model
# ===========================
if r2_xgb > r2_rf:
    print("\n✅ XGBoost performed better, saving XGBoost model...")
    model_xgb.save_model("models/crop_yield_climate_model.json")
    best_model_type = "XGBoost"
    best_r2 = r2_xgb
else:
    print("\n✅ RandomForest performed better, saving RandomForest model...")
    joblib.dump(model_rf, "models/crop_yield_climate_model.pkl")
    best_model_type = "RandomForest"
    best_r2 = r2_rf

print(f"\n📊 FINAL RESULTS:")
print(f"   Best Model: {best_model_type}")
print(f"   R² Score: {best_r2:.4f}")
print(f"   Improvement over old model (0.61): +{(best_r2-0.61)*100:.1f}%")

# ===========================
# 9. Sanity Check
# ===========================
print("\n" + "="*50)
print("SANITY CHECK with NASA Climate Data")
print("="*50)

test_scenarios = {
    "Optimal": {
        "area": 1.0,
        "tavg_climate": 28.0,
        "tmin_climate": 24.0,
        "tmax_climate": 33.0,
        "prcp_annual_climate": 5.0,  # ~1825mm/year
        "temp_range_climate": 9.0,
        "zn %": 90.0,
        "fe%": 95.0,
        "cu %": 93.0,
        "mn %": 99.0,
        "b %": 100.0,
        "s %": 0.8,
        "nutrient_index": 92.67
    },
    "Poor": {
        "area": 1.0,
        "tavg_climate": 32.0,
        "tmin_climate": 27.0,
        "tmax_climate": 38.0,
        "prcp_annual_climate": 1.5,  # ~550mm/year (drought)
        "temp_range_climate": 11.0,
        "zn %": 55.0,
        "fe%": 70.0,
        "cu %": 65.0,
        "mn %": 75.0,
        "b %": 80.0,
        "s %": 0.3,
        "nutrient_index": 63.33
    }
}

best_model = model_xgb if r2_xgb > r2_rf else model_rf

for scenario_name, inputs in test_scenarios.items():
    test_df = pd.DataFrame([inputs])
    
    for col in feature_cols:
        if col not in test_df.columns:
            test_df[col] = 0
    
    test_df = test_df[feature_cols]
    
    pred = best_model.predict(test_df)[0]
    print(f"{scenario_name} conditions: {pred:.2f} t/ha")

print("\n✅ Model training complete!")
