# merge_with_climate.py
import pandas as pd

# Load datasets
crop = pd.read_csv("data/crop/crop_production.csv")
soil_micro = pd.read_csv("data/soil_micro/soil.csv")
climate = pd.read_csv("data/processed/district_climate.csv")

# Normalize
crop.columns = crop.columns.str.lower().str.strip()
soil_micro.columns = soil_micro.columns.str.lower().str.strip()
climate.columns = climate.columns.str.lower().str.strip()

crop["district_name"] = crop["district_name"].str.strip().str.lower()
crop["state_name"] = crop["state_name"].str.strip().str.lower()

crop.rename(columns={"crop_year": "year"}, inplace=True)

# Merge crop + climate (by state and district only, not year)
merged = crop.merge(
    climate,
    on=["state_name", "district_name"],
    how="left"
)

print(f"Crop rows: {len(crop)}")
print(f"With climate data: {len(merged[merged['tavg_climate'].notna()])}")
print(f"Missing climate: {len(merged[merged['tavg_climate'].isna()])}")

# Merge soil micro
soil_micro.rename(columns={"district ": "district"}, inplace=True)
soil_micro["district"] = soil_micro["district"].str.strip().str.lower()

merged = merged.merge(
    soil_micro,
    left_on="district_name",
    right_on="district",
    how="left"
)

# Save
merged.to_csv("data/processed/merged_dataset_climate.csv", index=False)
print(f"\n✅ Final dataset saved: {len(merged)} rows")
print(f"Columns: {list(merged.columns)}")
