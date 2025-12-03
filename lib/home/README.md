# Home Module - Crop Management System

A professional and minimalist home screen implementation following MVC architecture for agricultural crop management.

## Features

### 1️⃣ Weather Indicator + Alerts
- Real-time weather display with temperature, humidity, and rainfall probability
- Color-coded weather cards with gradient backgrounds
- Alert system for weather-based warnings (high humidity, rainfall, etc.)

### 2️⃣ Crop Selection Tiles
- Horizontal scrollable crop tiles
- Each crop has a unique color theme and icon
- Visual feedback for selected crop
- Currently includes: Rice 🌾, Wheat 🌾, Maize 🌽, Cotton ☁️

### 3️⃣ Yearly Calendar View
- Color-coded calendar based on crop suitability
- Three suitability levels:
  - 🔴 **High Compatibility** (Peak Season) - Red
  - 🟢 **Normal Season** (Moderate) - Green
  - 🟡 **Not Recommended** (Not Ideal) - Yellow
- Interactive calendar with month navigation
- Click on any month to view weekly tasks

### 4️⃣ Monthly Task Breakdown
- Week-by-week task schedule for each month
- Shows crop stage for each week
- Detailed task list for each week
- Example stages: Sowing, Germination, Vegetative Growth, Pest Alert, etc.

### 5️⃣ Daily Action Plan
- Weather-based dynamic recommendations
- Precise actions based on:
  - Current weather conditions
  - Crop stage
  - Rainfall probability
  - Temperature and humidity
- Priority-based recommendations:
  - ⚠️ Critical (Must do)
  - 🕒 Recommended (Should do)
  - ℹ️ Optional (Can do)
  - 🚫 Avoid (Don't do)
- Action types:
  - Irrigation
  - Fertilization
  - Pest Control
  - Weed Control
  - Monitoring

## Architecture

### MVC Structure

```
lib/home/
├── controller/
│   └── home_controller.dart          # State management with ChangeNotifier
├── model/
│   ├── crop_model.dart                # Crop, SeasonSuitability, WeeklyTask
│   ├── weather_model.dart             # Weather, WeatherAlert
│   └── daily_action_model.dart        # DailyAction, ActionRecommendation
└── view/
    ├── screens/
    │   ├── home_screen.dart           # Main home screen
    │   ├── month_detail_screen.dart   # Monthly task breakdown
    │   └── daily_action_screen.dart   # Daily action recommendations
    └── widgets/
        ├── weather_indicator.dart     # Weather card widget
        ├── weather_alerts.dart        # Alert notifications
        └── crop_tile.dart             # Crop selection tile
```

## Usage

### In your main.dart or routing:

```dart
import 'package:sih_25044/home/view/screens/home_screen.dart';

// Navigate to home screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const HomeScreen()),
);
```

### Dependencies Added

- `provider: ^6.1.2` - State management
- `intl: ^0.19.0` - Date formatting
- `table_calendar: ^3.1.2` - Calendar widget (already included)

## Customization

### Adding New Crops

Edit `home_controller.dart` and add new crop in `_loadCrops()`:

```dart
Crop _createNewCrop() {
  return Crop(
    id: 'crop_id',
    name: 'Crop Name',
    icon: '🌱',
    themeColor: const Color(0xFF123456),
    monthSuitability: {
      // 1-12 months
      1: SeasonSuitability.notRecommended,
      // ... rest of months
    },
    monthlyTasks: {
      // month -> weekly tasks
      6: [
        WeeklyTask(
          week: 1,
          stage: 'Stage Name',
          tasks: ['Task 1', 'Task 2'],
        ),
      ],
    },
  );
}
```

### Integrating Weather API

Replace mock weather in `_loadWeather()` method in `home_controller.dart`:

```dart
Future<void> _loadWeather() async {
  _isLoadingWeather = true;
  notifyListeners();

  // Your API call here
  final response = await http.get(Uri.parse('your_weather_api'));
  _currentWeather = Weather.fromJson(response);

  _generateWeatherAlerts();
  _isLoadingWeather = false;
  notifyListeners();
}
```

## Color Scheme

- Primary Text: `#2C3E50`
- Background: `#F5F5F5`
- High Compatibility: `#E74C3C` (Red)
- Normal: `#27AE60` (Green)
- Not Recommended: `#F39C12` (Yellow)
- Critical: `#E74C3C`
- Recommended: `#3498DB`
- Optional: `#95A5A6`
- Avoid: `#E67E22`

## Design Principles

- **Minimalist**: Clean interface with ample white space
- **Professional**: Consistent typography and color usage
- **Intuitive**: Clear visual hierarchy and navigation
- **Responsive**: Smooth animations and transitions
- **Data-Driven**: Weather-based dynamic recommendations

## Next Steps

1. Run `flutter pub get` to install dependencies
2. Integrate real weather API
3. Connect to backend for crop data
4. Add user preferences and settings
5. Implement notifications for critical alerts
