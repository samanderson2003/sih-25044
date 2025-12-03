# fetch_nasa_climate_fast.py
import pandas as pd
import requests
import time
import os

NASA_POWER_URL = "https://power.larc.nasa.gov/api/temporal/climatology/point"

def get_climate_for_district(lat, lon, start_year=2000, end_year=2020):
    """
    Fetch 20-year climate average (MUCH faster than year-by-year)
    """
    params = {
        "parameters": "T2M,T2M_MIN,T2M_MAX,PRECTOTCORR",
        "community": "AG",
        "longitude": lon,
        "latitude": lat,
        "start": start_year,
        "end": end_year,
        "format": "JSON"
    }
    
    try:
        response = requests.get(NASA_POWER_URL, params=params, timeout=30)
        response.raise_for_status()
        data = response.json()
        
        if "properties" not in data or "parameter" not in data["properties"]:
            return None
        
        params_data = data["properties"]["parameter"]
        
        # Get annual averages
        result = {
            "tavg_climate": params_data["T2M"]["ANN"],
            "tmin_climate": params_data["T2M_MIN"]["ANN"],
            "tmax_climate": params_data["T2M_MAX"]["ANN"],
            "prcp_annual_climate": params_data["PRECTOTCORR"]["ANN"]
        }
        
        return result
        
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return None

def fetch_all_climate():
    """
    Fetch climate for each district (only once per district, not per year!)
    """
    # Load district coordinates
    coords = pd.read_csv("data/processed/district_coordinates.csv")
    
    print(f"Total districts: {len(coords)}")
    print(f"Estimated time: {len(coords) * 2 / 60:.1f} minutes")
    print("Starting fetch...")
    
    # Check for existing data
    output_file = "data/processed/district_climate.csv"
    if os.path.exists(output_file):
        existing = pd.read_csv(output_file)
        print(f"Found {len(existing)} existing records")
        # Remove already fetched districts
        coords = coords[~coords["district_name"].isin(existing["district_name"])]
        print(f"Remaining to fetch: {len(coords)}")
    else:
        existing = pd.DataFrame()
    
    climate_data = []
    
    for idx, row in coords.iterrows():
        print(f"[{idx+1}/{len(coords)}] Fetching: {row['state_name']}, {row['district_name']}")
        
        climate = get_climate_for_district(row["latitude"], row["longitude"])
        
        if climate:
            climate_data.append({
                "state_name": row["state_name"],
                "district_name": row["district_name"],
                "latitude": row["latitude"],
                "longitude": row["longitude"],
                **climate
            })
            
            # Save progress every 50 records
            if len(climate_data) % 50 == 0:
                df_progress = pd.DataFrame(climate_data)
                if not existing.empty:
                    df_progress = pd.concat([existing, df_progress], ignore_index=True)
                df_progress.to_csv(output_file, index=False)
                print(f"  ✅ Progress saved: {len(df_progress)} total records")
        
        time.sleep(1.5)  # Be nice to NASA servers
    
    # Final save
    if climate_data:
        df_final = pd.DataFrame(climate_data)
        if not existing.empty:
            df_final = pd.concat([existing, df_final], ignore_index=True)
        df_final.to_csv(output_file, index=False)
        print(f"\n✅ Completed! Total districts: {len(df_final)}")
        print(f"✅ Data saved to: {output_file}")

if __name__ == "__main__":
    os.makedirs("data/processed", exist_ok=True)
    fetch_all_climate()
