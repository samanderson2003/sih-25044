# 🌱 Plant Disease Detection - Flutter Integration Guide

## Overview
Your Flutter app now has an enhanced crop disease detection system that:
1. **Selects crop type first** - Beautiful crop cards with icons (🌾 Rice, 🍅 Tomato, 🍎 Apple, 🍇 Grape, 🍓 Strawberry, 🍑 Peach)
2. **Captures/uploads image** - Camera or gallery options
3. **Sends to ML model** - Your trained TensorFlow models via FastAPI server
4. **Shows results** - Disease name, confidence, and detailed information

## 📋 What Was Changed

### 1. Flutter App (`lib/crop_diseases_detection/`)

#### `view/crop_detection_screen.dart`
- **Added crop selection screen**: Grid of 6 crop cards with emoji icons
- **Two-step flow**: Select crop → Take/Upload photo
- **Dynamic UI**: Shows selected crop name and icon
- **Model integration**: Passes selected crop model key to API

#### `controller/disease_detection_controller.dart`
- Already configured to work with your API endpoints:
  - `/health` - Check server status
  - `/api/disease-models` - Get available models
  - `/api/detect-disease` - Analyze image

### 2. Python Server (`engine/plants_disease/`)

#### `server.py`
- **Added new endpoints**:
  - `GET /api/disease-models` - List available models
  - `POST /api/detect-disease` - Process disease detection
- **Backward compatible**: Old `/predict` endpoint still works
- **Auto-discovery**: Automatically finds all `best_*_segmented.keras` models

#### `start_server.sh`
- Easy one-command server startup
- Shows connection URLs for emulator and real devices
- Checks for trained models before starting

## 🚀 How to Run

### Step 1: Start the Python Server

```bash
cd /Users/samandersony/StudioProjects/projects/sih_25044/engine/plants_disease

# Option A: Use the startup script
./start_server.sh

# Option B: Manual start
$PWD/bin/uvicorn server:app --reload --host 0.0.0.0 --port 5001
```

The server will start on: **http://0.0.0.0:5001**

### Step 2: Configure Flutter App

Edit `lib/crop_diseases_detection/controller/disease_detection_controller.dart`:

**For Android Emulator:**
```dart
static const String _baseUrl = 'http://10.0.2.2:5001';
```

**For Real Android Device (same WiFi):**
```dart
static const String _baseUrl = 'http://YOUR_COMPUTER_IP:5001';  // e.g., http://192.168.1.100:5001
```

To find your computer's IP:
```bash
# macOS
ipconfig getifaddr en0

# Linux
hostname -I | awk '{print $1}'

# Windows
ipconfig | findstr IPv4
```

### Step 3: Run Flutter App

```bash
cd /Users/samandersony/StudioProjects/projects/sih_25044

# For emulator
flutter run

# For specific device
flutter run -d <device-id>
```

## 🎯 User Flow

1. **Open App** → Navigate to "Prediction" tab (bottom navbar)

2. **Select Crop** → Tap on crop card (Rice, Tomato, Apple, Grape, Strawberry, or Peach)

3. **Capture/Upload Image**:
   - Tap "Take Photo" for camera
   - Tap "Choose from Gallery" for existing photo

4. **Wait for Analysis** → Loading spinner while model processes image

5. **View Results**:
   - Disease name (e.g., "Bacterial leaf blight")
   - Confidence percentage (e.g., "99.15%")
   - Severity level
   - Top 5 predictions
   - Treatment recommendations (if available)

6. **History** → Recent detections saved automatically

## 🔧 Model Mapping

The app's crop selection maps to these models:

| Crop Card | Model Key | Model File |
|-----------|-----------|------------|
| 🌾 Rice | `rice_segmented` | `best_rice_segmented.keras` |
| 🍅 Tomato | `tomato_segmented` | `best_tomato_segmented.keras` |
| 🍎 Apple | `apple_segmented` | `best_apple_segmented.keras` |
| 🍇 Grape | `grape_segmented` | `best_grape_segmented.keras` |
| 🍓 Strawberry | `strawberry_segmented` | `best_strawberry_segmented.keras` |
| 🍑 Peach | `peach_segmented` | `best_peach_segmented.keras` |

## 🧪 Testing

### Test Server API Directly

```bash
# Health check
curl http://localhost:5001/health

# List models
curl http://localhost:5001/api/disease-models

# Test detection
curl -X POST -F "file=@rice_dataset/segmented/Bacterial leaf blight/DSC_0385.jpg" \
     -F "model=rice_segmented" \
     http://localhost:5001/api/detect-disease
```

### Test in Flutter App

1. Select Rice crop
2. Upload a test image from `rice_dataset/segmented/Bacterial leaf blight/`
3. Should detect "Bacterial leaf blight" with high confidence

## 📱 Translations

All UI elements support English ↔ Odia translation:
- Crop names
- Button labels
- Tips and guidelines
- Detection results
- History items

Language can be switched in the Profile tab.

## 🐛 Troubleshooting

### "Detection service is offline"
- Check if server is running: `curl http://localhost:5001/health`
- Verify base URL in `disease_detection_controller.dart`
- For real device, ensure same WiFi network

### "No trained models found"
- Ensure `.keras` model files exist in `engine/plants_disease/`
- Each model needs corresponding `_classes.json` file
- Run `ls -la best_*.keras` to verify

### Images not uploading
- Check file size (max 10MB)
- Verify image format (JPEG, PNG)
- Check Flutter permissions in `AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.CAMERA"/>
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
  ```

### Low prediction confidence
- Ensure good image quality (well-lit, clear, focused)
- Capture affected leaf/plant part only
- Avoid blurry or distant images
- Use correct crop model

## 📊 API Response Format

```json
{
  "model": "rice_segmented",
  "predicted_index": 0,
  "predicted_class": "Bacterial leaf blight",
  "confidence": 0.9915,
  "classes": ["Bacterial leaf blight", "Brown spot", "Leaf smut"],
  "probabilities": [0.9915, 0.0075, 0.0010],
  "top": [
    {"class": "Bacterial leaf blight", "prob": 0.9915},
    {"class": "Brown spot", "prob": 0.0075},
    {"class": "Leaf smut", "prob": 0.0010}
  ]
}
```

## 🔐 Security Notes (For Production)

- [ ] Add API authentication
- [ ] Implement rate limiting
- [ ] Use HTTPS
- [ ] Validate file types server-side
- [ ] Set max file size limits
- [ ] Add CORS restrictions
- [ ] Log API usage
- [ ] Monitor model performance

## 🎨 Customization

### Add New Crop
1. Train model using `train_plant_disease.py`
2. Add crop to `_availableCrops` in `crop_detection_screen.dart`:
   ```dart
   {
     'name': 'Wheat',
     'key': 'wheat_segmented',
     'icon': '🌾',
     'color': Color(0xFFD4AF37),
   }
   ```
3. Server will auto-discover the model

### Change Colors
Update colors in crop cards:
```dart
'color': Color(0xFFYOUR_HEX_COLOR),
```

## 📈 Performance Tips

1. **Model Caching**: Server caches loaded models in memory
2. **Image Optimization**: App resizes images before upload
3. **Async Processing**: Detection runs on background thread
4. **History Limit**: Keeps last 20 detections only

## ✅ Success Checklist

- [ ] Server running on port 5001
- [ ] Flutter app connects to server
- [ ] All 6 crop models available
- [ ] Can select crop and upload image
- [ ] Detection results display correctly
- [ ] History saves detections
- [ ] Translations work for both languages
- [ ] Camera and gallery permissions granted

## 📝 Next Steps

1. **Add Treatment Recommendations**: Extend disease result screen with treatment advice
2. **Offline Mode**: Cache recent detections for offline viewing
3. **Analytics**: Track detection accuracy and usage
4. **Push Notifications**: Alert farmers about detected diseases
5. **Expert Consultation**: Connect farmers with agricultural experts
6. **Weather Integration**: Correlate diseases with weather conditions

---

**Server Status**: Check at http://localhost:5001/health  
**API Docs**: Visit http://localhost:5001/docs (FastAPI auto-generated)  
**Support**: See `SERVER_SETUP.md` for detailed server configuration
