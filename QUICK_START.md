# 🚀 ONE COMMAND TO RUN EVERYTHING

## Quick Start

```bash
./start_app.sh
```

That's it! This starts:
- ✅ **Crop Yield API** on port 5002 (avoiding macOS AirPlay on 5000)
- ✅ **Disease Detection API** on port 5001  
- ✅ **Flutter App** on your device

## What You Can Test

### 1. Crop Yield Prediction
- Open app → Calendar → Daily Plan
- Uses ML API on **port 5002**

### 2. Disease Detection
- Open app → Prediction → Select Crop → Take Photo
- Uses Deep Learning API on **port 5001**

## Stop Everything

Press **Ctrl+C** in the terminal - it will stop all servers and the app.

## Troubleshooting

**Port already in use?**
```bash
# Kill processes on ports
lsof -ti :5002 | xargs kill -9
lsof -ti :5001 | xargs kill -9
```

**Need to check logs?**
```bash
# Crop Yield API logs
tail -f engine/api/api_server.log

# Disease Detection API logs
tail -f engine/plants_disease/disease_api.log
```

---

## Configuration

Both APIs are configured for **physical device**:
- Crop Yield: `http://192.168.5.102:5002`
- Disease Detection: `http://192.168.5.102:5001`

If your IP changes, update:
- `lib/crop_yield_prediction/controller/crop_yield_controller.dart`
- `lib/crop_diseases_detection/controller/disease_detection_controller.dart`
