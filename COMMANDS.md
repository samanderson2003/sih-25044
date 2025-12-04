# 🔧 Developer Commands Cheat Sheet

## 🚀 Launch Commands

### Start Everything (Recommended)
```bash
./start_app.sh              # macOS/Linux - Starts API + Flutter
start_app.bat               # Windows - Starts API + Flutter
```

### Manual Launch (Separate Terminals)

**Terminal 1 - API Server:**
```bash
cd engine/api
./start_server.sh           # Auto setup + start
# OR
python3 app.py              # Direct start
```

**Terminal 2 - Flutter App:**
```bash
flutter run                 # Default device
flutter run -d chrome       # Web browser
flutter run -d macos        # macOS desktop
```

---

## 🧪 Testing & Debugging

### Test ML API
```bash
# Health check
curl http://localhost:5000/health

# Full API test suite
cd engine/api
python3 test_api.py
```

### Test Flutter
```bash
flutter doctor              # Check environment
flutter devices             # List devices
flutter run -v              # Verbose logs
flutter clean               # Clean build
flutter pub get             # Update dependencies
```

### View Logs
```bash
# API Server logs
tail -f engine/api/api_server.log
cat engine/api/api_server.log | grep "ERROR"

# Flutter logs (while running)
# Already visible in terminal
```

---

## 🔨 Build Commands

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
# Requires macOS and Xcode
```

### Web
```bash
flutter build web
# Output: build/web/
```

---

## 🤖 ML Model Commands

### Train Model
```bash
cd engine/crop_yield
python3 train.py
```

### Make Prediction (Test)
```bash
cd engine/crop_yield
python3 predict.py
```

### Daily Model Update
```bash
cd engine/crop_yield
python3 daily_update.py
```

### Fetch NASA Climate Data
```bash
cd engine/crop_yield
python3 fetch_nasa_weather.py
```

---

## 🗄️ Database Commands

### Firebase Emulator (Local Testing)
```bash
firebase emulators:start
```

### Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```

---

## 🧹 Cleanup Commands

### Clean Everything
```bash
# Flutter
flutter clean

# Python cache
find . -type d -name "__pycache__" -exec rm -r {} +
find . -type f -name "*.pyc" -delete

# API logs
rm engine/api/api_server.log
```

### Reset Python Environment
```bash
cd engine/api
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

---

## 🔍 Debugging Commands

### Check Python Dependencies
```bash
cd engine/api
source venv/bin/activate
pip list
pip check
```

### Check Flutter Dependencies
```bash
flutter pub deps
flutter pub outdated
```

### Port Issues (API already running?)
```bash
# macOS/Linux
lsof -i :5000
kill -9 <PID>

# Find process
ps aux | grep python
ps aux | grep flutter
```

---

## 📊 Performance Monitoring

### Flutter Performance
```bash
flutter run --profile
flutter run --trace-startup
```

### API Performance Test
```bash
# Install Apache Bench
brew install httpd  # macOS

# Benchmark API
ab -n 100 -c 10 http://localhost:5000/health
```

---

## 🔐 Environment Variables

### Set API URL (for physical device testing)
Edit `lib/services/ml_api_service.dart`:
```dart
// Find your Mac IP: System Settings > Network > Wi-Fi
static const String baseUrl = 'http://192.168.1.XXX:5000';
```

---

## 🎨 Code Quality

### Dart Formatting
```bash
dart format lib/
dart analyze
```

### Python Linting
```bash
cd engine/api
pip install pylint black
black *.py                  # Auto-format
pylint app.py              # Lint check
```

---

## 📦 Dependency Management

### Update Flutter Dependencies
```bash
flutter pub upgrade
flutter pub outdated
```

### Update Python Dependencies
```bash
cd engine/api
pip install --upgrade -r requirements.txt
pip list --outdated
```

---

## 🚨 Emergency Commands

### Kill All Processes
```bash
# macOS/Linux
pkill -f "flutter"
pkill -f "python.*app.py"

# Or use the master script's Ctrl+C
```

### Complete Reset
```bash
# Flutter
flutter clean
rm -rf build/
flutter pub get

# Python
cd engine/api
rm -rf venv/
rm api_server.log
cd ../..

# Then restart
./start_app.sh
```

---

## 💡 Pro Tips

### Hot Reload (Flutter)
- Press `r` in terminal while app is running
- Press `R` for hot restart

### API Development
```bash
# Auto-reload on file changes
cd engine/api
export FLASK_ENV=development
flask run --reload
```

### Quick Device Switch
```bash
flutter run                 # Select from list
flutter run -d all          # Run on all devices
```

### Check Git Status
```bash
git status
git log --oneline -10
git diff
```

---

**Keep this file handy for quick reference! 🚀**
