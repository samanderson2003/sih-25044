# district_coords.py - FIXED VERSION
import pandas as pd

# Load your crop data
crop = pd.read_csv("data/crop/crop_production.csv")
crop.columns = crop.columns.str.lower().str.strip()

# Get unique districts
districts = crop[["state_name", "district_name"]].drop_duplicates()
districts["state_name"] = districts["state_name"].str.strip().str.lower()
districts["district_name"] = districts["district_name"].str.strip().str.lower()

print(f"Total unique districts: {len(districts)}")

# State coordinates (capital cities)
STATE_COORDS = {
    "andhra pradesh": (15.9129, 79.7400),
    "arunachal pradesh": (28.2180, 94.7278),
    "assam": (26.2006, 92.9376),
    "bihar": (25.0961, 85.3131),
    "chhattisgarh": (21.2787, 81.8661),
    "goa": (15.2993, 74.1240),
    "gujarat": (22.2587, 71.1924),
    "haryana": (29.0588, 76.0856),
    "himachal pradesh": (31.1048, 77.1734),
    "jharkhand": (23.6102, 85.2799),
    "karnataka": (15.3173, 75.7139),
    "kerala": (10.8505, 76.2711),
    "madhya pradesh": (22.9734, 78.6569),
    "maharashtra": (19.7515, 75.7139),
    "manipur": (24.6637, 93.9063),
    "meghalaya": (25.4670, 91.3662),
    "mizoram": (23.1645, 92.9376),
    "nagaland": (26.1584, 94.5624),
    "odisha": (20.9517, 85.0985),
    "punjab": (31.1471, 75.3412),
    "rajasthan": (27.0238, 74.2179),
    "sikkim": (27.5330, 88.5122),
    "tamil nadu": (11.1271, 78.6569),
    "telangana": (18.1124, 79.0193),
    "tripura": (23.9408, 91.9882),
    "uttar pradesh": (26.8467, 80.9462),
    "uttarakhand": (30.0668, 79.0193),
    "west bengal": (22.9868, 87.8550),
    "andaman and nicobar islands": (11.7401, 92.6586),
    "chandigarh": (30.7333, 76.7794),
    "dadra and nagar haveli": (20.1809, 73.0169),
    "daman and diu": (20.4283, 72.8397),
    "delhi": (28.7041, 77.1025),
    "jammu and kashmir": (33.7782, 76.5762),
    "ladakh": (34.1526, 77.5771),
    "lakshadweep": (10.5667, 72.6417),
    "puducherry": (11.9416, 79.8083),
    "jammu & kashmir": (33.7782, 76.5762),  # Alternative spelling
}

# Function to get coordinates
def get_coords(state_name):
    state = state_name.lower().strip()
    
    # Direct match
    if state in STATE_COORDS:
        return STATE_COORDS[state]
    
    # Fuzzy match for common variations
    for key in STATE_COORDS.keys():
        if key in state or state in key:
            return STATE_COORDS[key]
    
    # Default to center of India
    print(f"⚠️ No match for state: '{state}', using default coords")
    return (20.5937, 78.9629)

# Apply coordinates
districts["latitude"] = districts["state_name"].apply(lambda x: get_coords(x)[0])
districts["longitude"] = districts["state_name"].apply(lambda x: get_coords(x)[1])

# Check for any NaN values
missing = districts[districts["latitude"].isna() | districts["longitude"].isna()]
if len(missing) > 0:
    print(f"\n❌ Found {len(missing)} districts with missing coordinates:")
    print(missing["state_name"].unique())
else:
    print("\n✅ All districts have coordinates!")

# Show sample
print("\nSample data:")
print(districts.head(10))

# Check unique states and their counts
print("\nStates found:")
state_counts = districts["state_name"].value_counts()
print(state_counts.head(10))

# Save
districts.to_csv("data/processed/district_coordinates.csv", index=False)
print(f"\n✅ Saved {len(districts)} districts with coordinates")
