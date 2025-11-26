# CropYield - Authentication & Onboarding Flow

## ✅ Implemented Features

### 1. **Authentication System (MVC)**
- ✓ Email/Password Login & Registration
- ✓ Google Sign-In Integration
- ✓ Mobile Number Collection (Optional, with Indian validation)
- ✓ Firebase Auth & Firestore integration

### 2. **Onboarding Flow**
- ✓ Terms & Conditions Screen
  - Professional scrollable terms
  - Acceptance checkbox
  - Saves acceptance to Firestore
  
- ✓ Permissions Screen
  - Location (for weather & soil test centers)
  - Camera (for crop/report photos)
  - Gallery (for document uploads)
  - Beautiful card-based UI
  - Skip option available

### 3. **Navigation Flow**
```
Login/Register
    ↓
Check if Terms Accepted
    ↓
[No] → Terms & Conditions Screen → Permissions Screen → Home
[Yes] → Home Dashboard
```

## 📱 User Experience

1. **New User Journey:**
   - Register → Terms & Conditions → Permissions → Home

2. **Returning User Journey:**
   - Login → (Terms already accepted) → Home

3. **Smart Routing:**
   - App remembers which screens user has completed
   - Never shows Terms/Permissions again once accepted

## 🎯 Next Steps

Ready to implement:
- Dashboard with farm profile completion tracker
- Farm profile setup (location, soil data, crops)
- Weather API integration
- Soil data collection UI
- ML model integration

## 🔐 Permissions Usage

- **Location**: Fetch weather data via API, find soil test centers
- **Camera**: Capture soil reports, crop photos
- **Gallery**: Upload existing documents

All permissions are properly explained to users before requesting.
