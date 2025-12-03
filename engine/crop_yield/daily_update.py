# daily_update.py - Runs daily at 6 PM to update model
import pandas as pd
import xgboost as xgb
import joblib
import datetime
import os

def update_model_with_farmer_data():
    """
    This function runs daily to update model with real farmer yields
    """
    print("\n" + "="*70)
    print(f"🌾 DAILY MODEL UPDATE - {datetime.datetime.now().strftime('%Y-%m-%d %I:%M %p')}")
    print("="*70)
    
    # ===========================
    # 1. Check if new data exists
    # ===========================
    new_data_file = "data/daily_submissions/today_harvests.csv"
    
    if not os.path.exists(new_data_file):
        print(f"⚠️ No new farmer data found at {new_data_file}")
        print("Skipping update for today.")
        return False
    
    # ===========================
    # 2. Load today's farmer submissions
    # ===========================
    print("📥 Loading today's farmer data...")
    df_new = pd.read_csv(new_data_file)
    
    # Clean data
    df_new = df_new.dropna(subset=["production", "area", "tavg_climate", "prcp_annual_climate"])
    df_new = df_new[df_new["area"] > 0]
    df_new["yield_per_area"] = df_new["production"] / df_new["area"]
    
    # Filter outliers
    df_new = df_new[(df_new["yield_per_area"] > 0.5) & (df_new["yield_per_area"] < 10)]
    
    if len(df_new) < 10:
        print(f"⚠️ Only {len(df_new)} valid records. Need at least 10.")
        print("Waiting for more submissions...")
        return False
    
    print(f"✅ Found {len(df_new)} valid farmer submissions")
    
    # ===========================
    # 3. Prepare features (SAME as training)
    # ===========================
    print("🔧 Preparing features...")
    
    # Add engineered features
    df_new["temp_range_climate"] = df_new["tmax_climate"] - df_new["tmin_climate"]
    df_new["nutrient_index"] = (df_new["zn %"] + df_new["fe%"] + df_new["cu %"]) / 3
    
    # Load feature columns
    feature_cols = joblib.load("models/feature_columns_climate.pkl")
    
    # Select numeric features
    numeric_features = ["area", "tavg_climate", "tmin_climate", "tmax_climate", 
                        "prcp_annual_climate", "temp_range_climate",
                        "zn %", "fe%", "cu %", "mn %", "b %", "s %", "nutrient_index"]
    
    X_new = df_new[numeric_features].copy()
    
    # Add season
    if "season" in df_new.columns:
        X_new = pd.get_dummies(X_new.join(df_new[["season"]]), columns=["season"], drop_first=True)
    
    # Align columns with training
    for col in feature_cols:
        if col not in X_new.columns:
            X_new[col] = 0
    X_new = X_new[feature_cols]
    
    y_new = df_new["yield_per_area"]
    
    # ===========================
    # 4. Create XGBoost DMatrix
    # ===========================
    dtrain_new = xgb.DMatrix(X_new, label=y_new)
    
    # ===========================
    # 5. Load existing model and parameters
    # ===========================
    print("🔄 Loading yesterday's model...")
    
    params = {
        "objective": "reg:squarederror",
        "learning_rate": 0.05,
        "max_depth": 8,
        "subsample": 0.8,
        "colsample_bytree": 0.8,
        "eval_metric": "rmse"
    }
    
    # ===========================
    # 6. THE MAGIC - Continue training
    # ===========================
    print("🚀 Learning from today's farmers...")
    print(f"   Adding 50 new decision trees on top of existing model...")
    
    model_updated = xgb.train(
        params,
        dtrain_new,
        num_boost_round=50,  # Add 50 new trees
        xgb_model="models/crop_yield_climate_model.json",  # ← Load old model
        verbose_eval=False
    )
    
    # ===========================
    # 7. Save updated model (replaces old one)
    # ===========================
    print("💾 Saving updated model...")
    model_updated.save_model("models/crop_yield_climate_model.json")
    
    # ===========================
    # 8. Archive today's data
    # ===========================
    archive_folder = "data/daily_submissions/archive"
    os.makedirs(archive_folder, exist_ok=True)
    
    archive_file = f"{archive_folder}/farmers_{datetime.datetime.now().strftime('%Y%m%d')}.csv"
    df_new.to_csv(archive_file, index=False)
    
    # Delete today's file (already processed)
    os.remove(new_data_file)
    
    # ===========================
    # 9. Update timestamp
    # ===========================
    with open("models/last_update.txt", "w") as f:
        f.write(datetime.datetime.now().strftime("%Y-%m-%d %I:%M %p"))
    
    print("\n" + "="*70)
    print(f"✅ UPDATE COMPLETE!")
    print(f"   - Learned from {len(df_new)} farmers")
    print(f"   - Model now has 50 more decision trees")
    print(f"   - Next predictions will be more accurate!")
    print("="*70 + "\n")
    
    return True

# Run the update
if __name__ == "__main__":
    update_model_with_farmer_data()
