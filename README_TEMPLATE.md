# Calendar App Template

This is a template Flutter calendar app that can be customized for any country.

## Configuration

All country-specific and app-specific settings are in `lib/config/app_config.dart`. Update the following values:

### Basic Configuration

1. **Country and App Information**:
   - `countryName`: Name of the country (e.g., "X", "Australia", "USA")
   - `appName`: Display name of the app (e.g., "X Calendar", "Australian Calendar")
   - `appDescription`: App description for pubspec.yaml

2. **Package Information**:
   - `packageName`: Package name for the app
   - `applicationId`: Android application ID (should match package name)

3. **JSON File Names**:
   - `publicHolidaysJsonFile`: Name of the public holidays JSON file
   - `schoolHolidaysJsonFile`: Name of the school holidays JSON file

4. **Play Store URL**:
   - `playStoreUrl`: Google Play Store URL (update when published)

6. **AdMob App ID**:
   - `admobAppId`: Your AdMob application ID (currently set to test ID)

7. **States/Regions**:
   - `states`: List of states/regions with codes and names
   - `stateNames`: Map of state codes to state names

8. **About Screen Text**:
   - `aboutScreenText`: Text displayed in the About screen

## Setup Instructions

1. **Update Configuration**:
   - Open `lib/config/app_config.dart`
   - Update all values to match your country/app

2. **Update JSON Files**:
   - Replace `config/x_public_holidays_2025_2027.json` with your country's public holidays
   - Replace `config/x_school_holidays_2025_2027.json` with your country's school holidays
   - Update the file names in `pubspec.yaml` assets section if needed

3. **Update Package Name**:
   - The package name is already set to `com.example.xcalendar` in:
     - `android/app/build.gradle.kts`
     - `android/app/src/main/AndroidManifest.xml`
   - Update these to your desired package name
   - Move `MainActivity.kt` to the correct package directory structure

4. **Update App Name**:
   - App name is set in `lib/config/app_config.dart` as `appName`
   - Also update `android/app/src/main/AndroidManifest.xml` if needed

5. **Update AdMob**:
   - Replace the test AdMob App ID in `android/app/src/main/AndroidManifest.xml` with your real App ID
   - Update `admobAppId` in `app_config.dart`

6. **Update Icons**:
   - Replace `store listing/ico_512.png` with your app icon
   - Run `flutter pub run flutter_launcher_icons` to generate launcher icons

7. **Build and Test**:
   ```bash
   flutter pub get
   flutter run
   ```

## JSON File Format

### Public Holidays JSON Format:
```json
[
  {
    "Date": "2025-01-01",
    "Weekday": "Wednesday",
    "Holiday Name": "New Year's Day",
    "Type": "National",
    "States": ["ALL"]
  }
]
```

### School Holidays JSON Format:
```json
[
  {
    "Name": "Summer Holidays",
    "StartDate": "2025-12-20",
    "EndDate": "2026-01-31",
    "States": ["ALL"]
  }
]
```

## Features

- ✅ Public holidays display
- ✅ School holidays display
- ✅ Region/State filtering
- ✅ Personal notes with reminders
- ✅ Annual recurring notes
- ✅ Notification reminders (configurable timing)
- ✅ Holiday notifications
- ✅ Dark/Light theme support
- ✅ AdMob integration
- ✅ Share functionality
- ✅ Year view calendar

## Notes

- All hardcoded country-specific values have been moved to `app_config.dart`
- The app uses the config values throughout the codebase
- Update the config file to customize for any country
- Make sure to update package names in Android files when creating a new app
