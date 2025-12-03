# AgriConnect - Farmer Network & Map View

## Overview
AgriConnect is a comprehensive farmer networking feature that provides:
- **Live Map View**: See all registered farmers on an interactive Google Map
- **Farmer Profiles**: Detailed information about each farmer
- **Community Access**: Quick access to chat and news features
- **Privacy Controls**: Farmers control what information is visible

## Features

### 1. Interactive Map
- Displays all registered farmers as map markers
- Current user's location highlighted in blue
- Other farmers shown in green
- Tap any marker to view farmer details

### 2. Farmer Profile Cards
When you tap a marker, a detailed profile card slides up showing:
- 👤 Farmer Name & Location
- 🌾 Current Crop Being Grown
- 🧪 Soil Health Status (Excellent/Good/Fair/Poor)
- 💧 Irrigation Method
- ⚠ Active Disease/Pest Alerts
- 📈 Latest Crop Prediction Report
  - Estimated Yield
  - Growth Phase
  - Weather Risk
  - Prediction Date
- 📱 Contact Options (if permissions granted)
- 👥 Follow/Unfollow Functionality

### 3. Top Navigation
- **Left**: Community Chat (Coming Soon)
- **Center**: AgriConnect Title
- **Right**: News Feed (Coming Soon)

### 4. Privacy Features
- Phone numbers only shown if farmer enables visibility
- Location can be approximate (village-level) or exact
- Farmers control their information sharing

## Setup Instructions

### Google Maps API Key Setup

1. **Get your API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing
   - Enable "Maps SDK for Android"
   - Create credentials → API Key
   - Copy your API key

2. **Add API Key to Android**:
   - Open `/android/app/src/main/AndroidManifest.xml`
   - Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSy...your-actual-key-here"/>
   ```

3. **Restrict API Key** (Recommended):
   - In Google Cloud Console, restrict your key to:
     - Application restrictions: Android apps
     - Add your package name: `com.example.sih_25044`
     - Add SHA-1 fingerprint from your keystore

## File Structure
```
lib/connections/
├── model/
│   └── farmer_model.dart         # FarmerProfile & CropPredictionData models
├── controller/
│   └── connections_controller.dart # State management & map logic
└── view/
    ├── connections_screen.dart    # Main map screen
    └── farmer_profile_card.dart   # Farmer details bottom sheet
```

## Static Data (For Testing)

The app currently uses 5 sample farmers in Chennai area:
1. **Sam Anderson** (Current User - Blue Marker)
   - Location: Chennai (13.0827, 80.2707)
   - Crop: Rice
   - Soil: Good

2. **Rajesh Kumar**
   - Location: Poonamallee
   - Crop: Wheat
   - Soil: Excellent

3. **Priya Devi**
   - Location: Tambaram
   - Crop: Cotton
   - Soil: Fair
   - Alert: Pest warning

4. **Murugan S**
   - Location: Avadi
   - Crop: Sugarcane
   - Soil: Good
   - Alert: Disease detected

5. **Lakshmi Narayanan**
   - Location: Pallavaram
   - Crop: Maize
   - Soil: Excellent

## Navigation

Bottom Tab Bar includes:
- **Home** 🏠 - Crop Management Dashboard
- **Prediction** 📊 - Crop Yield & Disease Detection
- **Connect** 🌐 - AgriConnect Map View ← NEW
- **Profile** 👤 - User Profile

## Future Enhancements

### Planned Features:
1. **Community Chat**
   - Group discussions
   - Image sharing
   - Q&A forums
   - District/language-based sub-communities

2. **News Feed**
   - Agriculture news from News API
   - Weather bulletins
   - Market prices
   - Government schemes
   - Bookmark & share articles

3. **Real-time Updates**
   - Live farmer locations
   - Firebase Firestore integration
   - Push notifications

4. **Advanced Filters**
   - Filter by crop type
   - Filter by distance
   - Search farmers by name
   - Filter by soil health status

## Dependencies

```yaml
google_maps_flutter: ^2.9.0  # Map integration
provider: ^6.1.2             # State management
intl: ^0.19.0               # Date formatting
geolocator: ^13.0.2         # Location services
```

## Permissions Required

Already configured in AndroidManifest.xml:
- ✅ ACCESS_FINE_LOCATION
- ✅ ACCESS_COARSE_LOCATION
- ✅ INTERNET
- ✅ ACCESS_NETWORK_STATE

## Usage

1. **View Map**:
   - Navigate to "Connect" tab
   - Map loads with all farmer markers

2. **View Farmer Profile**:
   - Tap any marker on the map
   - Profile card slides up from bottom
   - Swipe down or tap X to close

3. **Navigate to Your Location**:
   - Tap the location button (bottom-right)
   - Map centers on your position

4. **Follow Farmers**:
   - Open farmer profile
   - Tap "Follow Farmer" button
   - Button changes to "Unfollow"

5. **Contact Farmer** (if phone visible):
   - Open farmer profile
   - Tap "Call" to initiate phone call
   - Tap "Message" to open chat (coming soon)

## Troubleshooting

### Map not loading?
- Verify API key is correct in AndroidManifest.xml
- Check internet connection
- Ensure Maps SDK for Android is enabled

### Markers not appearing?
- Check static data in ConnectionsController
- Verify latitude/longitude values are valid
- Check console for errors

### Location button not working?
- Ensure location permissions granted
- Check if GPS is enabled
- Verify current user data exists

## Color Theme
- Primary Green: `#2D5016`
- Background Cream: `#F8F6F0`
- Current User Marker: Blue
- Other Farmers: Green
