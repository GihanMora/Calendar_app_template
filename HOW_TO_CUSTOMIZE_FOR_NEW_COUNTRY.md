# Complete Guide: Creating a Calendar App for Any Country and Publishing to Play Store

This comprehensive guide will walk you through every single step needed to convert this calendar app template into a fully functional calendar app for any country and publish it to the Google Play Store.

---

## 📑 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Understanding the Template Structure](#understanding-the-template-structure)
3. [Step 1: Planning Your App](#step-1-planning-your-app)
4. [Step 2: Update Main Configuration](#step-2-update-main-configuration)
5. [Step 3: Create Holiday Data Files](#step-3-create-holiday-data-files)
6. [Step 4: Update Package Name and Code](#step-4-update-package-name-and-code)
7. [Step 5: Update Project Files](#step-5-update-project-files)
8. [Step 6: Customize App Icon](#step-6-customize-app-icon)
9. [Step 7: Set Up AdMob](#step-7-set-up-admob)
10. [Step 8: Build and Test Locally](#step-8-build-and-test-locally)
11. [Step 9: Prepare for Play Store](#step-9-prepare-for-play-store)
12. [Step 10: Create Google Play Developer Account](#step-10-create-google-play-developer-account)
13. [Step 11: Set Up App Signing](#step-11-set-up-app-signing)
14. [Step 12: Build Release Version](#step-12-build-release-version)
15. [Step 13: Create Play Store Listing](#step-13-create-play-store-listing)
16. [Step 14: Submit to Play Store](#step-14-submit-to-play-store)
17. [Troubleshooting](#troubleshooting)
18. [Post-Publication Checklist](#post-publication-checklist)

---

## Prerequisites

Before you begin, ensure you have:

- ✅ **Flutter SDK** installed (version 3.8.1 or higher)
- ✅ **Android Studio** or **VS Code** with Flutter extensions
- ✅ **Android SDK** installed (API level 21+)
- ✅ **Java JDK 11** or higher
- ✅ **Git** (optional, for version control)
- ✅ **Google Account** (for Play Store and AdMob)
- ✅ **$25 USD** (one-time fee for Google Play Developer account)
- ✅ **Basic knowledge** of JSON format
- ✅ **Text editor** or IDE

---

## Understanding the Template Structure

### Key Files and Their Purposes

```
Calender_App_template/
├── config/
│   ├── country_x.json                    # ⭐ MAIN CONFIG FILE (Single Source of Truth)
│   ├── x_public_holidays_2025_2027.json # Template public holidays
│   └── x_school_holidays_2025_2027.json  # Template school holidays
│
├── lib/
│   ├── config/
│   │   └── app_config.dart               # Reads from country_x.json
│   ├── services/
│   │   ├── holiday_service.dart          # Handles public holidays
│   │   ├── school_holiday_service.dart   # Handles school holidays
│   │   ├── notification_service.dart     # Handles notifications
│   │   └── ads_service.dart              # Handles AdMob ads
│   └── ... (other app files)
│
├── android/
│   ├── app/
│   │   ├── build.gradle.kts              # Reads config from JSON
│   │   └── src/main/
│   │       ├── AndroidManifest.xml       # Android configuration
│   │       └── kotlin/
│   │           └── com/example/xcalendar/
│   │               └── MainActivity.kt    # Main Android activity
│   └── key.properties                     # Signing keys (create this)
│
├── pubspec.yaml                           # Flutter project config
└── store listing/
    └── ico_512.png                        # App icon (replace this)
```

### How Configuration Works

The app uses a **single source of truth** system:
- `config/country_x.json` contains ALL configuration
- `lib/config/app_config.dart` reads from the JSON at runtime
- `android/app/build.gradle.kts` reads from JSON at build time
- No need to edit multiple files - just update the JSON!

---

## Step 1: Planning Your App

Before making changes, plan your app:

### 1.1 Choose Your Country
- Which country's calendar are you creating?
- Does it have states/provinces/regions with different holidays?
- What are the main public holidays?
- Are school holidays important for your users?

### 1.2 Choose Package Name
**CRITICAL:** Package name cannot be changed after publishing!

Format: `com.yourcompany.countrycalendar`

Examples:
- `com.john.uscalendar` (US Calendar)
- `com.sarah.australiancalendar` (Australian Calendar)
- `com.company.ukcalendar` (UK Calendar)

**Rules:**
- Must be lowercase
- Use reverse domain notation
- Must be unique (check Play Store if similar exists)
- No spaces or special characters (except dots)

### 1.3 Choose App Name
- Short and memorable
- Should include country name
- Examples: "US Calendar", "Australian Holidays", "UK Calendar"

### 1.4 Decide on Features
- **States/Regions:** Does your country have regional holidays? (Set `enableStates`)
- **School Holidays:** Do you want school holiday feature? (Set `enableSchoolHolidays`)
- **Ads:** Will you monetize with AdMob? (Set up AdMob account)

---

## Step 2: Update Main Configuration

### 2.1 Edit `config/country_x.json`

This is the **most important file**. Open it and update every field:

```json
{
  "countryName": "Your Country Name",
  "appName": "Your Calendar App Name",
  "appIcon": "assets/icons/app_icon.png",
  "packageName": "com.yourcompany.yourapp",
  "applicationId": "com.yourcompany.yourapp",
  "publicHolidaysJson": "config/your_country_public_holidays.json",
  "schoolHolidaysJson": "config/your_country_school_holidays.json",
  "enableStates": true,
  "enableSchoolHolidays": true,
  "playStoreUrl": "https://play.google.com/store/apps/details?id=com.yourcompany.yourapp",
  "admobAppId": "ca-app-pub-3940256099942544~3347511713",
  "bannerAdUnitId": "ca-app-pub-5202253201958912/6764035035",
  "interstitialAdUnitId": "ca-app-pub-5202253201958912/4746790831",
  "rewardedAdUnitId": "ca-app-pub-5202253201958912/9065289963",
  "nativeAdUnitId": "ca-app-pub-5202253201958912/4529194873",
  "regions": [
    { "code": "ALL", "name": "All Regions" }
  ],
  "notes": "Edit this file to configure the app."
}
```

### 2.2 Field-by-Field Explanation

#### Basic Information
- **`countryName`**: Full country name (e.g., "United States", "Australia", "United Kingdom")
- **`appName`**: Display name shown in app launcher (e.g., "US Calendar", "Australian Holidays")
- **`appIcon`**: Path to icon (usually keep as `"assets/icons/app_icon.png"`)

#### Package Information
- **`packageName`**: Package identifier (e.g., `"com.yourname.uscalendar"`)
- **`applicationId`**: Must match `packageName` exactly
- **`playStoreUrl`**: Update after publishing (e.g., `"https://play.google.com/store/apps/details?id=com.yourname.uscalendar"`)

#### Holiday Data Files
- **`publicHolidaysJson`**: Path to your public holidays file (e.g., `"config/us_public_holidays.json"`)
- **`schoolHolidaysJson`**: Path to your school holidays file (e.g., `"config/us_school_holidays.json"`)

#### Feature Flags
- **`enableStates`**: 
  - `true` if your country has regional/state holidays
  - `false` if all holidays are national
- **`enableSchoolHolidays`**: 
  - `true` to show school holidays feature
  - `false` to hide it completely

#### AdMob Configuration
- **`admobAppId`**: Your AdMob Application ID (format: `ca-app-pub-XXXXXXXX~XXXXXXXX`)
- **`bannerAdUnitId`**: Banner ad unit ID
- **`interstitialAdUnitId`**: Interstitial ad unit ID
- **`rewardedAdUnitId`**: Rewarded ad unit ID
- **`nativeAdUnitId`**: Native ad unit ID

**Note:** During development, you can use Google's test ad IDs:
- Test App ID: `ca-app-pub-3940256099942544~3347511713`
- Test Banner: `ca-app-pub-3940256099942544/6300978111`
- Test Interstitial: `ca-app-pub-3940256099942544/1033173712`
- Test Rewarded: `ca-app-pub-3940256099942544/5224354917`
- Test Native: `ca-app-pub-3940256099942544/2247696110`

#### Regions Configuration
- **`regions`**: Array of states/provinces/regions
- **Format:** `{ "code": "CODE", "name": "Display Name" }`
- **Always include:** `{ "code": "ALL", "name": "All Regions" }` as first entry

**Example for United States:**
```json
"regions": [
  { "code": "ALL", "name": "All States" },
  { "code": "AL", "name": "Alabama" },
  { "code": "AK", "name": "Alaska" },
  { "code": "AZ", "name": "Arizona" },
  { "code": "AR", "name": "Arkansas" },
  { "code": "CA", "name": "California" },
  { "code": "CO", "name": "Colorado" },
  { "code": "CT", "name": "Connecticut" },
  { "code": "DE", "name": "Delaware" },
  { "code": "FL", "name": "Florida" },
  { "code": "GA", "name": "Georgia" },
  { "code": "HI", "name": "Hawaii" },
  { "code": "ID", "name": "Idaho" },
  { "code": "IL", "name": "Illinois" },
  { "code": "IN", "name": "Indiana" },
  { "code": "IA", "name": "Iowa" },
  { "code": "KS", "name": "Kansas" },
  { "code": "KY", "name": "Kentucky" },
  { "code": "LA", "name": "Louisiana" },
  { "code": "ME", "name": "Maine" },
  { "code": "MD", "name": "Maryland" },
  { "code": "MA", "name": "Massachusetts" },
  { "code": "MI", "name": "Michigan" },
  { "code": "MN", "name": "Minnesota" },
  { "code": "MS", "name": "Mississippi" },
  { "code": "MO", "name": "Missouri" },
  { "code": "MT", "name": "Montana" },
  { "code": "NE", "name": "Nebraska" },
  { "code": "NV", "name": "Nevada" },
  { "code": "NH", "name": "New Hampshire" },
  { "code": "NJ", "name": "New Jersey" },
  { "code": "NM", "name": "New Mexico" },
  { "code": "NY", "name": "New York" },
  { "code": "NC", "name": "North Carolina" },
  { "code": "ND", "name": "North Dakota" },
  { "code": "OH", "name": "Ohio" },
  { "code": "OK", "name": "Oklahoma" },
  { "code": "OR", "name": "Oregon" },
  { "code": "PA", "name": "Pennsylvania" },
  { "code": "RI", "name": "Rhode Island" },
  { "code": "SC", "name": "South Carolina" },
  { "code": "SD", "name": "South Dakota" },
  { "code": "TN", "name": "Tennessee" },
  { "code": "TX", "name": "Texas" },
  { "code": "UT", "name": "Utah" },
  { "code": "VT", "name": "Vermont" },
  { "code": "VA", "name": "Virginia" },
  { "code": "WA", "name": "Washington" },
  { "code": "WV", "name": "West Virginia" },
  { "code": "WI", "name": "Wisconsin" },
  { "code": "WY", "name": "Wyoming" },
  { "code": "DC", "name": "District of Columbia" }
]
```

**Example for Australia:**
```json
"regions": [
  { "code": "ALL", "name": "All States" },
  { "code": "NSW", "name": "New South Wales" },
  { "code": "VIC", "name": "Victoria" },
  { "code": "QLD", "name": "Queensland" },
  { "code": "WA", "name": "Western Australia" },
  { "code": "SA", "name": "South Australia" },
  { "code": "TAS", "name": "Tasmania" },
  { "code": "ACT", "name": "Australian Capital Territory" },
  { "code": "NT", "name": "Northern Territory" }
]
```

**Important:** The `code` values must match exactly what you use in your holiday JSON files!

---

## Step 3: Create Holiday Data Files

### 3.1 Public Holidays File

Create a new file: `config/your_country_public_holidays.json`

#### Format Structure:
```json
[
  {
    "Date": "YYYY-MM-DD",
    "Weekday": "DayName",
    "Holiday Name": "Holiday Display Name",
    "Type": "National|State|Regional",
    "States": ["ALL"] or ["CODE1", "CODE2"]
  }
]
```

#### Complete Example:
```json
[
  {
    "Date": "2025-01-01",
    "Weekday": "Wednesday",
    "Holiday Name": "New Year's Day",
    "Type": "National",
    "States": ["ALL"]
  },
  {
    "Date": "2025-01-20",
    "Weekday": "Monday",
    "Holiday Name": "Martin Luther King Jr. Day",
    "Type": "Federal",
    "States": ["ALL"]
  },
  {
    "Date": "2025-07-04",
    "Weekday": "Friday",
    "Holiday Name": "Independence Day",
    "Type": "Federal",
    "States": ["ALL"]
  },
  {
    "Date": "2025-03-17",
    "Weekday": "Monday",
    "Holiday Name": "Evacuation Day",
    "Type": "State",
    "States": ["MA"]
  },
  {
    "Date": "2025-04-21",
    "Weekday": "Monday",
    "Holiday Name": "San Jacinto Day",
    "Type": "State",
    "States": ["TX"]
  }
]
```

#### Field Details:

1. **`Date`**: 
   - Format: `YYYY-MM-DD` (e.g., `"2025-12-25"`)
   - Must be valid date
   - Use actual date, not observed date

2. **`Weekday`**: 
   - Full name: `"Monday"`, `"Tuesday"`, `"Wednesday"`, `"Thursday"`, `"Friday"`, `"Saturday"`, `"Sunday"`
   - Must match the actual weekday of the date

3. **`Holiday Name`**: 
   - Display name shown in app
   - Can be any string (e.g., `"New Year's Day"`, `"Christmas"`)

4. **`Type`**: 
   - Categories: `"National"`, `"Federal"`, `"State"`, `"Regional"`, `"Local"`
   - Used for filtering and display

5. **`States`**: 
   - Array of state/region codes
   - `["ALL"]` for national holidays
   - `["CA", "NY"]` for regional holidays (use codes from your regions config)
   - Must match codes in `country_x.json` regions array

#### Tips for Creating Holiday Data:

1. **Research Sources:**
   - Government websites
   - Official holiday calendars
   - Wikipedia (verify with official sources)

2. **Cover Multiple Years:**
   - Include at least 2-3 years of data
   - Update annually

3. **Handle Observed Dates:**
   - Some holidays are observed on different dates
   - Include both actual and observed dates if needed

4. **Regional Holidays:**
   - Research state/province-specific holidays
   - Verify which regions observe each holiday

5. **Validate JSON:**
   - Use online JSON validator
   - Ensure proper formatting
   - Check all dates are valid

### 3.2 School Holidays File

Create a new file: `config/your_country_school_holidays.json`

#### Format Structure:
```json
[
  {
    "Name": "Holiday Period Name",
    "StartDate": "YYYY-MM-DD",
    "EndDate": "YYYY-MM-DD",
    "States": ["ALL"] or ["CODE1", "CODE2"]
  }
]
```

#### Complete Example:
```json
[
  {
    "Name": "Summer Holidays",
    "StartDate": "2025-12-20",
    "EndDate": "2026-01-31",
    "States": ["ALL"]
  },
  {
    "Name": "Easter Holidays",
    "StartDate": "2026-04-10",
    "EndDate": "2026-04-25",
    "States": ["NSW", "VIC", "QLD"]
  },
  {
    "Name": "Winter Holidays",
    "StartDate": "2026-07-01",
    "EndDate": "2026-07-15",
    "States": ["ALL"]
  },
  {
    "Name": "Spring Holidays",
    "StartDate": "2026-09-26",
    "EndDate": "2026-10-11",
    "States": ["NSW", "VIC"]
  }
]
```

#### Field Details:

1. **`Name`**: 
   - Display name (e.g., `"Summer Holidays"`, `"Easter Break"`)

2. **`StartDate`**: 
   - First day of holiday period
   - Format: `YYYY-MM-DD`

3. **`EndDate`**: 
   - Last day of holiday period (inclusive)
   - Format: `YYYY-MM-DD`

4. **`States`**: 
   - Same as public holidays
   - `["ALL"]` for national holidays
   - Specific codes for regional holidays

#### Tips for School Holidays:

1. **Research by Region:**
   - Different states/provinces may have different dates
   - Check education department websites

2. **Academic Years:**
   - School holidays often span calendar years
   - Include full academic year periods

3. **Multiple Periods:**
   - Include all major holiday periods
   - Summer, Easter, Winter, Spring breaks

---

## Step 4: Update Package Name and Code

### 4.1 Create New Package Directory

**Windows (PowerShell):**
```powershell
New-Item -ItemType Directory -Path "android\app\src\main\kotlin\com\yourcompany\yourapp" -Force
```

**Mac/Linux:**
```bash
mkdir -p android/app/src/main/kotlin/com/yourcompany/yourapp
```

Replace `com.yourcompany.yourapp` with your actual package name.

### 4.2 Move MainActivity.kt

1. **Copy the file:**
   - From: `android/app/src/main/kotlin/com/example/xcalendar/MainActivity.kt`
   - To: `android/app/src/main/kotlin/com/yourcompany/yourapp/MainActivity.kt`

2. **Update package declaration in MainActivity.kt:**

Open the file and change:
```kotlin
package com.example.xcalendar
```

To:
```kotlin
package com.yourcompany.yourapp
```

The rest of the file should remain unchanged:
```kotlin
package com.yourcompany.yourapp

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= 35) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
        super.onCreate(savedInstanceState)
    }
}
```

3. **Delete old MainActivity.kt:**
   - Delete: `android/app/src/main/kotlin/com/example/xcalendar/MainActivity.kt`
   - Delete empty directory: `android/app/src/main/kotlin/com/example/xcalendar/`

### 4.3 Update AndroidManifest.xml

**File:** `android/app/src/main/AndroidManifest.xml`

Find this line (around line 22):
```xml
<activity
    android:name="com.example.xcalendar.MainActivity"
```

Change to:
```xml
<activity
    android:name="com.yourcompany.yourapp.MainActivity"
```

**Note:** The app name (`android:label`) and AdMob ID are automatically read from `config/country_x.json` at build time, so you don't need to change those.

---

## Step 5: Update Project Files

### 5.1 Update pubspec.yaml

**File:** `pubspec.yaml`

1. **Update app name:**
```yaml
name: your_country_calendar
```

**Rules:**
- Lowercase only
- Use underscores, not spaces
- Must be valid Dart package name

2. **Update description:**
```yaml
description: "Your Country Calendar - A Flutter calendar app with public holidays"
```

3. **Update version:**
```yaml
version: 1.0.0+1
```

**Format:** `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- `1.0.0` = Version name (shown to users)
- `+1` = Version code (incremented for each Play Store upload)

4. **Update assets section:**
```yaml
assets:
  - config/country_x.json
  - config/your_country_public_holidays.json
  - config/your_country_school_holidays.json
  - "store listing/ico_512.png"
```

Make sure file names match exactly what you created!

### 5.2 Verify build.gradle.kts

**File:** `android/app/build.gradle.kts`

This file automatically reads from `config/country_x.json`, so you **don't need to edit it manually**. However, verify it exists and contains the JSON reading logic (it should already be there).

---

## Step 6: Customize App Icon

### 6.1 Create App Icon

1. **Design Requirements:**
   - Size: 512x512 pixels
   - Format: PNG (with transparency)
   - Style: Square with rounded corners (Android will handle rounding)
   - Content: Should be recognizable at small sizes

2. **Design Tips:**
   - Use high contrast colors
   - Keep design simple (avoid fine details)
   - Test at small sizes (48x48, 96x96)
   - Ensure it represents your country/calendar theme

3. **Tools:**
   - Canva (free templates)
   - Figma (free)
   - Adobe Illustrator/Photoshop
   - Online icon generators

### 6.2 Replace Icon File

1. **Replace the file:**
   - Location: `store listing/ico_512.png`
   - Replace with your 512x512px icon
   - Keep the same filename

### 6.3 Generate Launcher Icons

Run this command to generate all required icon sizes:

```bash
flutter pub run flutter_launcher_icons
```

This will:
- Generate icons for all Android densities
- Create adaptive icon files
- Update Android manifest automatically

**Verify:** Check that icons were generated in:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`

---

## Step 7: Set Up AdMob

### 7.1 Create AdMob Account

1. **Go to AdMob:** https://admob.google.com
2. **Sign in** with your Google account
3. **Accept terms** and create account
4. **Complete setup** (add payment info if monetizing)

### 7.2 Create AdMob App

1. **Click "Apps"** in AdMob console
2. **Click "Add app"**
3. **Select platform:** Android
4. **Enter app name:** Your calendar app name
5. **Select app category:** Lifestyle or Productivity
6. **Click "Add"**

### 7.3 Create Ad Units

For each ad type, create an ad unit:

#### Banner Ad:
1. Click "Ad units" → "Add ad unit"
2. Select "Banner"
3. Name: "Banner Ad"
4. Copy the Ad Unit ID (format: `ca-app-pub-XXXXXXXX/XXXXXXXX`)

#### Interstitial Ad:
1. Click "Add ad unit"
2. Select "Interstitial"
3. Name: "Interstitial Ad"
4. Copy the Ad Unit ID

#### Rewarded Ad:
1. Click "Add ad unit"
2. Select "Rewarded"
3. Name: "Rewarded Ad"
4. Copy the Ad Unit ID

#### Native Ad:
1. Click "Add ad unit"
2. Select "Native"
3. Name: "Native Ad"
4. Copy the Ad Unit ID

### 7.4 Get App ID

1. In AdMob console, go to "Apps"
2. Find your app
3. Copy the **App ID** (format: `ca-app-pub-XXXXXXXX~XXXXXXXX`)

### 7.5 Update Configuration

Update `config/country_x.json` with your AdMob IDs:

```json
{
  "admobAppId": "ca-app-pub-YOUR-APP-ID~YOUR-APP-ID",
  "bannerAdUnitId": "ca-app-pub-YOUR-PUBLISHER-ID/YOUR-BANNER-ID",
  "interstitialAdUnitId": "ca-app-pub-YOUR-PUBLISHER-ID/YOUR-INTERSTITIAL-ID",
  "rewardedAdUnitId": "ca-app-pub-YOUR-PUBLISHER-ID/YOUR-REWARDED-ID",
  "nativeAdUnitId": "ca-app-pub-YOUR-PUBLISHER-ID/YOUR-NATIVE-ID"
}
```

**Important:** 
- During development, you can use Google's test ad IDs
- Switch to real IDs before publishing
- Never use test IDs in production!

### 7.6 Test Ads

1. **Build and run app:**
   ```bash
   flutter run
   ```

2. **Verify ads load:**
   - Check console for ad loading messages
   - Test ads should appear (if using test IDs)

3. **Check for errors:**
   - Look for AdMob errors in console
   - Verify internet connection
   - Check AdMob app is approved (may take 24-48 hours)

---

## Step 8: Build and Test Locally

### 8.1 Clean Project

```bash
flutter clean
```

This removes all build artifacts and ensures a fresh build.

### 8.2 Get Dependencies

```bash
flutter pub get
```

This downloads all required packages.

### 8.3 Run on Device/Emulator

**Connect device or start emulator, then:**

```bash
flutter run
```

**Or specify device:**
```bash
flutter devices  # List available devices
flutter run -d <device-id>
```

### 8.4 Testing Checklist

Test all features:

- [ ] **App launches** without crashes
- [ ] **App name** displays correctly in launcher
- [ ] **Holidays display** correctly in calendar
- [ ] **State/region filtering** works (if enabled)
- [ ] **School holidays** show (if enabled)
- [ ] **Notifications** work (test scheduling)
- [ ] **Dark/Light theme** switches correctly
- [ ] **Ads load** (if using AdMob)
- [ ] **Settings** screen works
- [ ] **About** screen shows correct info
- [ ] **Share** functionality works
- [ ] **Notes** can be added/edited/deleted
- [ ] **Year view** displays correctly
- [ ] **Month view** displays correctly

### 8.5 Fix Issues

If you encounter errors:

1. **Check console output** for error messages
2. **Verify JSON files** are valid (use JSON validator)
3. **Check file paths** in `config/country_x.json`
4. **Verify package name** matches everywhere
5. **Check assets** are listed in `pubspec.yaml`

### 8.6 Build Debug APK (Optional)

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

Install on device to test:
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## Step 9: Prepare for Play Store

### 9.1 Create Privacy Policy

**Required if using ads or collecting data!**

1. **Create privacy policy:**
   - Use online generators (free)
   - Or write your own
   - Must cover: data collection, ads, permissions

2. **Host it online:**
   - GitHub Pages (free)
   - Google Sites (free)
   - Your own website
   - Privacy policy generators

3. **Save the URL** (you'll need it for Play Store)

### 9.2 Prepare Screenshots

**Requirements:**
- Minimum 2 screenshots
- Maximum 8 screenshots
- Format: PNG or JPEG
- Size: 16:9 or 9:16 aspect ratio
- Resolution: At least 320px, max 3840px

**Recommended:**
- Phone screenshots: 1080x1920px (portrait) or 1920x1080px (landscape)
- Tablet screenshots: 1200x1920px (portrait) or 1920x1200px (landscape)

**What to Screenshot:**
1. Main calendar view
2. Holiday details
3. Settings screen
4. Year view
5. Notes feature
6. Any unique features

### 9.3 Create Feature Graphic

**Requirements:**
- Size: 1024x500 pixels
- Format: PNG or JPEG
- Content: App name, key features, visual appeal

**Tips:**
- Use high-quality images
- Include app name
- Show key features
- Keep text readable

### 9.4 Write Store Listing

Prepare text content:

1. **Short Description** (80 characters max):
   - Brief, compelling description
   - Example: "Complete calendar with all public holidays and school breaks"

2. **Full Description** (4000 characters max):
   - Detailed app description
   - List all features
   - Include keywords for search
   - Use bullet points for readability

3. **App Category:**
   - Primary: Lifestyle or Productivity
   - Secondary: (optional)

---

## Step 10: Create Google Play Developer Account

### 10.1 Sign Up

1. **Go to:** https://play.google.com/console
2. **Sign in** with Google account
3. **Click "Get started"**
4. **Pay $25 USD** (one-time fee)
5. **Complete profile:**
   - Developer name
   - Email
   - Phone number
   - Address

### 10.2 Complete Account Setup

1. **Accept Developer Distribution Agreement**
2. **Verify email address**
3. **Add payment method** (for future app sales)
4. **Complete tax information** (if selling apps)

**Note:** Account approval may take 24-48 hours.

---

## Step 11: Set Up App Signing

### 11.1 Create Keystore

**Windows (PowerShell):**
```powershell
keytool -genkey -v -keystore $env:USERPROFILE\your-app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias your-app-alias
```

**Mac/Linux:**
```bash
keytool -genkey -v -keystore ~/your-app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias your-app-alias
```

**You'll be prompted for:**
- Keystore password (remember this!)
- Key password (can be same as keystore)
- Your name
- Organizational unit
- Organization
- City
- State
- Country code (2 letters, e.g., US, AU, GB)

**Important:**
- Store passwords securely (password manager)
- Backup keystore file (losing it = can't update app!)
- Keep keystore file secure

### 11.2 Create key.properties File

**File:** `android/key.properties`

Create this file with:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=your-app-alias
storeFile=../../your-app-key.jks
```

**Important:**
- Replace `YOUR_STORE_PASSWORD` with actual password
- Replace `YOUR_KEY_PASSWORD` with actual password
- Replace `your-app-alias` with your alias
- Update `storeFile` path if keystore is in different location

### 11.3 Add to .gitignore

**File:** `.gitignore` (create if doesn't exist)

Add these lines:
```
# Keystore files
*.jks
key.properties
```

**CRITICAL:** Never commit keystore or key.properties to Git!

### 11.4 Verify build.gradle.kts

**File:** `android/app/build.gradle.kts`

Verify it contains signing configuration (should already be there):

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

## Step 12: Build Release Version

### 12.1 Final Checks

Before building:

- [ ] All configuration updated in `config/country_x.json`
- [ ] Holiday JSON files created and validated
- [ ] Package name updated everywhere
- [ ] App icon replaced
- [ ] AdMob IDs updated (if using)
- [ ] Version number set in `pubspec.yaml`
- [ ] Keystore created and `key.properties` configured

### 12.2 Clean Build

```bash
flutter clean
flutter pub get
```

### 12.3 Build App Bundle (Recommended)

**For Play Store:**
```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

**Why App Bundle?**
- Smaller download size
- Google optimizes for each device
- Required for new apps on Play Store

### 12.4 Build APK (Alternative)

**If you need APK instead:**
```bash
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

**Note:** APK is larger and not optimized, but useful for direct distribution.

### 12.5 Test Release Build

Before uploading, test the release build:

```bash
# Install on connected device
flutter install --release

# Or manually
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Test thoroughly:**
- All features work
- No crashes
- Performance is good
- Ads work (if using)

---

## Step 13: Create Play Store Listing

### 13.1 Create New App

1. **Go to Play Console:** https://play.google.com/console
2. **Click "Create app"**
3. **Fill in:**
   - App name (from `config/country_x.json`)
   - Default language
   - App or game: App
   - Free or paid: Free (or Paid)
   - Declarations: Check all that apply
4. **Click "Create app"**

### 13.2 Complete Store Listing

#### Main Store Listing:

1. **App name:**
   - Must match or be similar to `appName` in config
   - Max 50 characters

2. **Short description:**
   - Max 80 characters
   - Brief, compelling description
   - Example: "Complete calendar with all public holidays and school breaks"

3. **Full description:**
   - Max 4000 characters
   - Detailed description
   - List features
   - Use formatting (bullet points, line breaks)
   - Include keywords

**Example:**
```
US Calendar - Your Complete Holiday Guide

Stay organized with the most comprehensive US calendar app featuring:

• All Federal Holidays
• State-Specific Holidays
• School Holiday Periods
• Personal Notes & Reminders
• Holiday Notifications
• Beautiful Calendar Views
• Dark & Light Themes
• Works Offline

Perfect for planning your year, tracking holidays, and staying informed about important dates across all US states.
```

4. **App icon:**
   - Upload 512x512px PNG
   - Same as `store listing/ico_512.png`

5. **Feature graphic:**
   - Upload 1024x500px image
   - Promotional banner

6. **Screenshots:**
   - Upload at least 2 screenshots
   - Phone screenshots (required)
   - Tablet screenshots (optional)
   - TV screenshots (if applicable)
   - Wear OS screenshots (if applicable)

7. **Category:**
   - Primary: Lifestyle or Productivity
   - Secondary: (optional)

8. **Tags:** (optional)
   - Keywords for search
   - Example: "calendar", "holidays", "planner"

9. **Contact details:**
   - Email address
   - Phone number (optional)
   - Website (optional)

10. **Privacy Policy:**
    - **Required if using ads!**
    - Enter URL to your privacy policy

### 13.3 Content Rating

1. **Click "Content rating"**
2. **Complete questionnaire:**
   - Answer all questions honestly
   - Based on your app's content
3. **Submit for rating**
4. **Wait for rating** (usually instant)

### 13.4 Target Audience

1. **Select target audience:**
   - Children
   - Children and adults
   - Adults only

2. **Content guidelines:**
   - Review Google's policies
   - Ensure compliance

### 13.5 App Access

1. **All or some features:**
   - Usually "All features"

2. **Declarations:**
   - Check all that apply
   - Ads: Yes (if using AdMob)
   - Data collection: Yes (if collecting any data)

---

## Step 14: Submit to Play Store

### 14.1 Upload App Bundle

1. **Go to "Production"** (or "Internal testing" first)
2. **Click "Create new release"**
3. **Upload AAB file:**
   - Drag and drop `app-release.aab`
   - Or click "Browse files"
4. **Add release name:**
   - Example: "1.0.0 - Initial Release"
5. **Add release notes:**
   - What's new in this version
   - Example: "Initial release with all public holidays and school breaks"

### 14.2 Review and Rollout

1. **Review information:**
   - Check all details
   - Verify version numbers
   - Review release notes

2. **Save:**
   - Click "Save" (doesn't publish yet)

3. **Review checklist:**
   - [ ] Store listing complete
   - [ ] Content rating done
   - [ ] Privacy policy added (if needed)
   - [ ] App bundle uploaded
   - [ ] Release notes added

### 14.3 Submit for Review

1. **Click "Review release"**
2. **Review warnings/errors:**
   - Fix any issues
   - Address warnings
3. **Click "Start rollout to Production"**
4. **Confirm submission**

### 14.4 Review Process

**Timeline:**
- Usually 1-3 days
- Can take up to 7 days
- Complex apps may take longer

**What Google Checks:**
- Policy compliance
- Content rating accuracy
- App functionality
- Security
- Permissions usage

**You'll receive email:**
- When review starts
- When review completes
- If issues found

### 14.5 Handle Rejection (If Any)

If app is rejected:

1. **Read rejection reason** carefully
2. **Fix issues:**
   - Update app if needed
   - Fix store listing
   - Address policy violations
3. **Resubmit:**
   - Upload new version
   - Add explanation of fixes

### 14.6 App Goes Live

Once approved:

1. **App appears in Play Store**
2. **Users can download**
3. **Monitor:**
   - Downloads
   - Ratings
   - Reviews
   - Crashes (in Play Console)

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: App name not updating

**Symptoms:** App still shows old name after changing `appName` in config

**Solutions:**
1. Run `flutter clean`
2. Delete `build/` folder
3. Rebuild: `flutter build appbundle --release`
4. Check `config/country_x.json` has correct `appName`
5. Verify `android/app/build.gradle.kts` reads from JSON

#### Issue: Package name errors

**Symptoms:** Build fails with package-related errors

**Solutions:**
1. Verify `packageName` and `applicationId` in `config/country_x.json` match exactly
2. Check MainActivity.kt is in correct package directory
3. Verify AndroidManifest.xml has correct MainActivity path
4. Ensure package directory structure matches package name
5. Clean and rebuild: `flutter clean && flutter pub get`

#### Issue: Holidays not showing

**Symptoms:** Calendar shows no holidays

**Solutions:**
1. Verify JSON file paths in `config/country_x.json` are correct
2. Check JSON files are listed in `pubspec.yaml` assets
3. Validate JSON format (use online validator)
4. Ensure dates are in correct format (`YYYY-MM-DD`)
5. Check state codes in holidays match region codes in config
6. Verify JSON files are in `config/` directory
7. Check console for loading errors

#### Issue: Ads not loading

**Symptoms:** No ads appear, or ad errors in console

**Solutions:**
1. Verify all AdMob IDs in `config/country_x.json` are correct
2. Check AdMob app is approved (may take 24-48 hours)
3. Ensure internet permission in AndroidManifest.xml (already included)
4. Test with Google's test ad IDs first
5. Check AdMob console for app status
6. Verify AdMob account is active
7. Check device has internet connection

#### Issue: Build fails with signing errors

**Symptoms:** Release build fails with keystore errors

**Solutions:**
1. Verify `android/key.properties` exists and is correct
2. Check keystore file path is correct
3. Verify passwords are correct
4. Ensure keystore file exists at specified path
5. Check file permissions on keystore
6. Try recreating keystore if corrupted

#### Issue: App crashes on launch

**Symptoms:** App opens then immediately closes

**Solutions:**
1. Check console/logcat for error messages
2. Verify all JSON files are valid
3. Check `config/country_x.json` has all required fields
4. Ensure MainActivity package matches config
5. Verify all assets are listed in `pubspec.yaml`
6. Check for null pointer exceptions in logs
7. Test with debug build to see detailed errors

#### Issue: Version code conflicts

**Symptoms:** Play Store rejects upload due to version code

**Solutions:**
1. Increment version code in `pubspec.yaml`
2. Format: `version: 1.0.0+2` (increment the number after `+`)
3. Each upload must have higher version code
4. Version name can stay same, but code must increase

#### Issue: JSON parsing errors

**Symptoms:** Errors about invalid JSON

**Solutions:**
1. Validate JSON files with online validator
2. Check for trailing commas
3. Verify all strings are in quotes
4. Check for missing brackets/braces
5. Ensure proper escaping of special characters
6. Verify date formats are correct

---

## Post-Publication Checklist

After your app is live:

### Week 1:
- [ ] Monitor download numbers
- [ ] Respond to user reviews
- [ ] Check for crash reports in Play Console
- [ ] Monitor ad performance (if using AdMob)
- [ ] Share app on social media
- [ ] Update website/blog (if you have one)

### Ongoing:
- [ ] Update holiday data annually
- [ ] Fix bugs reported by users
- [ ] Add new features based on feedback
- [ ] Update app description based on reviews
- [ ] Monitor and respond to reviews regularly
- [ ] Keep dependencies updated
- [ ] Plan future updates

### Updates:
When updating the app:

1. **Update version:**
   ```yaml
   version: 1.0.1+2  # Increment both
   ```

2. **Update holiday data** (if needed)

3. **Build new release:**
   ```bash
   flutter build appbundle --release
   ```

4. **Upload to Play Console:**
   - Create new release
   - Upload new AAB
   - Add release notes
   - Submit for review

---

## Additional Resources

### Official Documentation:
- [Flutter Documentation](https://docs.flutter.dev/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [AdMob Documentation](https://developers.google.com/admob)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

### Tools:
- [JSON Validator](https://jsonlint.com/)
- [Privacy Policy Generator](https://www.freeprivacypolicy.com/)
- [App Icon Generator](https://www.appicon.co/)
- [Screenshot Tools](https://www.figma.com/) (for creating feature graphics)

### Communities:
- [Flutter Discord](https://discord.gg/flutter)
- [r/FlutterDev](https://reddit.com/r/FlutterDev)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

---

## Final Notes

- **Take your time:** Don't rush the process
- **Test thoroughly:** Better to delay than publish a buggy app
- **Follow policies:** Read Google Play policies carefully
- **Be patient:** Review process takes time
- **Keep backups:** Always backup your keystore and code
- **Update regularly:** Keep holiday data current
- **Listen to users:** Reviews provide valuable feedback

---

**Congratulations!** 🎉 You now have a complete guide to create and publish your calendar app. Good luck with your app development journey!

---

*Last Updated: January 2026*
*Template Version: 1.2.1*
