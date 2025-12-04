#!/usr/bin/env python3
"""
Test script to verify ML API is working correctly
"""
import requests
import json

BASE_URL = "http://localhost:5000"

def test_health():
    """Test if API server is running"""
    print("🔍 Testing API health...")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        data = response.json()
        
        if data['status'] == 'healthy' and data['model_loaded']:
            print("✅ API is healthy and model is loaded")
            return True
        else:
            print(f"⚠️  API responded but model status: {data}")
            return False
    except Exception as e:
        print(f"❌ API health check failed: {e}")
        print("Is the server running? Start with: python app.py")
        return False

def test_daily_actions():
    """Test daily actions endpoint"""
    print("\n🔍 Testing daily actions...")
    
    test_data = {
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
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/daily-actions",
            headers={'Content-Type': 'application/json'},
            json=test_data,
            timeout=10
        )
        
        data = response.json()
        
        if data.get('success'):
            print("✅ Daily actions generated successfully")
            print(f"   Crop: {data['crop']}")
            print(f"   Stage: {data['crop_stage']['stage']} (Day {data['crop_stage']['days']})")
            print(f"   Actions: {len(data['actions'])} tasks")
            print(f"   Alerts: {len(data['alerts'])} warnings")
            print(f"   Days to harvest: {data['days_to_harvest']}")
            
            if data['actions']:
                print("\n   First task:")
                task = data['actions'][0]
                print(f"     {task['task']}")
                print(f"     Priority: {task['priority']}")
            
            return True
        else:
            print(f"❌ API returned error: {data}")
            return False
            
    except Exception as e:
        print(f"❌ Daily actions test failed: {e}")
        return False

def test_yield_prediction():
    """Test yield prediction endpoint"""
    print("\n🔍 Testing yield prediction...")
    
    test_data = {
        "farm_data": {
            "crop": "Rice",
            "area": 0.809372,
            "area_acres": 2.0,
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
        }
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/predict-yield",
            headers={'Content-Type': 'application/json'},
            json=test_data,
            timeout=10
        )
        
        data = response.json()
        
        if data.get('success'):
            print("✅ Yield prediction successful")
            print(f"   Yield: {data['total_yield_tonnes']} tonnes ({data['total_yield_kg']} kg)")
            print(f"   Per Hectare: {data['yield_per_hectare']} t/ha")
            print(f"   Confidence: {data['confidence']}%")
            
            econ = data['economics']
            print(f"\n   Economic Forecast:")
            print(f"     Income: ₹{econ['gross_income_low']:,} - ₹{econ['gross_income_high']:,}")
            print(f"     Profit: ₹{econ['net_profit_low']:,} - ₹{econ['net_profit_high']:,}")
            print(f"     ROI: {econ['roi_low']}% - {econ['roi_high']}%")
            
            return True
        else:
            print(f"❌ Prediction failed: {data}")
            return False
            
    except Exception as e:
        print(f"❌ Yield prediction test failed: {e}")
        return False

def main():
    print("="*70)
    print("🌾 SMART FARMING ML API TEST SUITE")
    print("="*70)
    print()
    
    tests_passed = 0
    tests_total = 4  # Updated to 4 tests
    
    if test_health():
        tests_passed += 1
    
    if test_daily_actions():
        tests_passed += 1
    
    if test_yield_prediction():
        tests_passed += 1
    
    if test_disease_models():
        tests_passed += 1
    
    print("\n" + "="*70)
    print(f"📊 TEST RESULTS: {tests_passed}/{tests_total} passed")
    
    if tests_passed == tests_total:
        print("🎉 All tests passed! API is working perfectly.")
    else:
        print(f"⚠️  {tests_total - tests_passed} test(s) failed.")
    
    print("="*70)
    print()


def test_disease_models():
    """Test disease models endpoint"""
    print("\n🌿 Test 4: Disease Models Endpoint")
    print("-" * 70)
    
    try:
        response = requests.get(
            f"{BASE_URL}/api/disease-models",
            timeout=10
        )
        
        data = response.json()
        
        if response.status_code == 200:
            print("✅ Disease models endpoint working")
            models = data.get('models', {})
            print(f"   Available models: {list(models.keys())}")
            if models:
                for model_key, model_info in models.items():
                    print(f"   - {model_info['name']}: {model_info['status']}")
                    print(f"     Classes: {', '.join(model_info['classes'][:3])}...")
            print(f"\n   Note: {data.get('note', 'N/A')}")
            return True
        else:
            print(f"❌ Disease models request failed: {response.status_code}")
            print(response.text)
            return False
    
    except Exception as e:
        print(f"❌ Disease models test failed: {e}")
        return False


if __name__ == "__main__":
    main()
