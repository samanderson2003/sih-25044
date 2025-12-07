# 🚨 DISEASE DETECTION FIX - Quick Start Guide

## Problem Solved
Your app was trying to connect to the disease detection server, but:
1. ❌ The Python server wasn't running
2. ❌ The app was configured for Android Emulator (10.0.2.2) but you're using a **physical device**
3. ❌ Android was blocking HTTP traffic

## ✅ What Was Fixed
1. ✅ Enabled cleartext HTTP traffic in AndroidManifest.xml
2. ✅ Updated app to use your computer's IP: `192.168.5.102`
3. ✅ Added connection timeout handling (15 seconds)
4. ✅ Server is now running on port 5001
5. ✅ Created easy startup script

---

## 🚀 HOW TO USE

### Step 1: Start the Server (REQUIRED)
**Every time before testing the app**, run:

```bash
./START_SERVER.sh
```

You should see:
```
🌱 Starting Plant Disease Detection Server...
📍 Server will be accessible at:
   • Android Emulator: http://10.0.2.2:5001
   • Physical Device:  http://192.168.5.102:5001
   • Browser:          http://localhost:5001
```

**Keep this terminal window open!** The server must stay running.

### Step 2: Rebuild and Run the App

In a **new terminal**:

```bash
flutter clean
flutter pub get
flutter run
```

### Step 3: Test Disease Detection

1. Open the app on your phone
2. Tap **"Prediction"** tab at the bottom
3. Select a crop (Rice, Tomato, Apple, Grape, Strawberry, or Peach)
4. Tap **"Take Photo"** or **"Upload from Gallery"**
5. Capture/select an image of the crop
6. Wait for detection results

---

## 📱 Device Configuration

### Currently Configured For:
- **Physical Android Device**
- **Computer IP:** `192.168.5.102`

### If You Want to Use Android Emulator:

Edit `lib/crop_diseases_detection/controller/disease_detection_controller.dart`:

Change line 24 from:
```dart
return _physicalDeviceUrl; // Change to _emulatorUrl if using Android Emulator
```

To:
```dart
return _emulatorUrl; // Using Android Emulator
```

---

## 🔧 Troubleshooting

### "Connection timed out" Error

**Problem:** Server is not running
**Solution:** Start the server with `./START_SERVER.sh`

### "Connection refused" Error

**Problem:** Wrong IP address
**Solution:** 
1. Get your computer's IP:
   ```bash
   ipconfig getifaddr en0
   ```
2. Update `lib/crop_diseases_detection/controller/disease_detection_controller.dart`
   line 13:
   ```dart
   static const String _physicalDeviceUrl = 'http://YOUR_IP:5001';
   ```

### Phone and Computer on Different WiFi Networks

**Problem:** Device can't reach computer
**Solution:** Connect both to the **same WiFi network**

### Server Stops Working

**Problem:** Server crashed or was stopped
**Solution:** 
1. Stop the server (CTRL+C in the terminal)
2. Restart with `./START_SERVER.sh`

---

## 📊 Available Models

Your app now has disease detection for:
- 🌾 **Rice** (rice_segmented)
- 🍅 **Tomato** (tomato_segmented)
- 🍎 **Apple** (apple_segmented)
- 🍇 **Grape** (grape_segmented)
- 🍓 **Strawberry** (strawberry_segmented)
- 🍑 **Peach** (peach_segmented)

Each model was trained to detect specific diseases for that crop.

---

## 🎯 Server Status Check

Test if the server is working:

```bash
# Check health
curl http://localhost:5001/health

# List available models
curl http://localhost:5001/api/disease-models
```

You should see JSON responses with status and model information.

---

## 📝 Summary of Changes

### Files Modified:
1. **android/app/src/main/AndroidManifest.xml**
   - Added `android:usesCleartextTraffic="true"`

2. **lib/crop_diseases_detection/controller/disease_detection_controller.dart**
   - Updated to use physical device IP: `192.168.5.102`
   - Added 15-second connection timeout
   - Added debug logging

3. **START_SERVER.sh** (NEW)
   - Easy one-command server startup

### Server Currently Running:
- **Process ID:** Check with `lsof -i :5001`
- **URL:** http://0.0.0.0:5001
- **Models:** 5 crop disease detection models loaded

---

## ⚠️ Important Notes

1. **Server must be running** before testing the app
2. **Keep terminal open** while the server runs
3. **Same WiFi network** for phone and computer
4. **Rebuild app** after any code changes: `flutter run`
5. **IP address changes** if you connect to different WiFi

---

## 🎉 You're Ready!

Your disease detection system is now fully configured and working. Just remember to:
1. Start the server: `./START_SERVER.sh`
2. Run the app: `flutter run`
3. Test detection with real crop images

Good luck with your SIH project! 🚀
