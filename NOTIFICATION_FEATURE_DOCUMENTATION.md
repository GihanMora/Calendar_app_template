# Notification Feature Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Files and Components](#files-and-components)
4. [Code Implementation](#code-implementation)
5. [Data Storage](#data-storage)
6. [Permissions](#permissions)
7. [Important Notes and Gotchas](#important-notes-and-gotchas)
8. [Future Reimplementation Guide](#future-reimplementation-guide)

---

## Overview

The notification feature allows users to receive reminders for calendar events/notes at a configurable time before the event date. Key features:

- **Configurable timing**: Users can set how many days before an event (0-7 days) and what time of day
- **Per-note notifications**: Each note can have notifications enabled/disabled individually
- **Annual event support**: Notifications work for both regular and annual (recurring) notes
- **Automatic rescheduling**: When notification settings change, all existing notifications are rescheduled
- **App lifecycle handling**: Notifications are rescheduled when the app resumes (to handle Android app standby)
- **Cache corruption handling**: Detects and handles corrupted notification cache to prevent app crashes
- **Default settings**: Holiday reminders are enabled by default, and note reminders are enabled by default when creating new notes (users can disable if needed)

---

## Architecture

### Flow Diagram

```
User creates/edits note with notification enabled
    ↓
NotesService.saveNote() saves note + notification flag
    ↓
NotificationService.scheduleNoteNotification() schedules notification
    ↓
flutter_local_notifications plugin stores notification in Android AlarmManager
    ↓
When notification time arrives → ScheduledNotificationReceiver fires
    ↓
Notification appears to user
```

### Key Components

1. **NotificationService**: Core service handling all notification operations
2. **NotesService**: Manages note storage and notification flags
3. **UI Screens**: HomeScreen, MyNotesScreen, SettingsScreen for user interaction
4. **App Lifecycle Observer**: Reschedules notifications when app resumes
5. **Android Receivers**: Handle notification delivery and boot completion

---

## Files and Components

### Core Service Files

#### 1. `lib/services/notification_service.dart`
**Purpose**: Main service class for all notification operations

**Key Responsibilities**:
- Initialize notification plugin
- Schedule/cancel notifications
- Manage notification settings
- Handle timezone detection
- Detect and handle cache corruption
- Reschedule all notifications

**Singleton Pattern**: Uses singleton pattern to ensure single instance

#### 2. `lib/services/notes_service.dart`
**Purpose**: Manages note storage and notification flags

**Key Responsibilities**:
- Save/retrieve notes from SharedPreferences
- Manage notification flags (`notification_flag_YYYY_M_D`)
- Handle annual notes and their notification flags

**Storage Keys**:
- `note_YYYY_M_D`: Regular note content
- `annual_note_M_D`: Annual note content (no year)
- `annual_flag_YYYY_M_D`: Flag indicating if note is annual
- `notification_flag_YYYY_M_D`: Flag indicating if notification is enabled

### UI Files

#### 3. `lib/screens/home_screen.dart`
**Purpose**: Main calendar screen where users add/edit notes

**Notification-related code**:
- Toggle notification switch when creating/editing notes
- **Note reminders are enabled by default** when creating new notes (users can disable if needed)
- Schedule notifications when note is saved with notification enabled
- Cancel notifications when note is deleted or notification is disabled

#### 4. `lib/screens/my_notes_screen.dart`
**Purpose**: Screen showing all user notes

**Notification-related code**:
- Display notification status for each note
- Toggle notification on/off for existing notes
- Cancel notifications when notes are deleted
- Edit notes and update notification status

#### 5. `lib/screens/settings_screen.dart`
**Purpose**: Settings screen for configuring notification time

**Notification-related code**:
- Display current notification settings (days before, time)
- Allow users to change notification time and days before
- Save settings and trigger rescheduling of all notifications

### App Initialization

#### 6. `lib/main.dart`
**Purpose**: App entry point and lifecycle management

**Notification-related code**:
- Initialize NotificationService on app startup
- Observe app lifecycle (resume/pause)
- Reschedule notifications when app resumes (to handle Android app standby)

### Android Configuration

#### 7. `android/app/src/main/AndroidManifest.xml`
**Purpose**: Android manifest with permissions and receivers

**Notification-related elements**:
- Permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`
- Receivers: `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`

---

## Code Implementation

### 1. NotificationService Initialization

**Location**: `lib/services/notification_service.dart` (lines 18-211)

```dart
Future<bool> initialize() async {
  if (_initialized) return true;

  try {
    // 1. Initialize timezone
    tz.initializeTimeZones();
    
    // 2. Detect device timezone
    // - For Android: Uses offset to detect timezone (Australia/Sydney for +10/+11)
    // - For iOS: Uses system timezone
    // - Fallback: UTC
    
    // 3. Request notification permission
    final notificationPermission = await Permission.notification.request();
    if (!notificationPermission.isGranted) {
      return false;
    }
    
    // 4. Request exact alarm permission (Android 12+)
    // - Required for exactAllowWhileIdle mode
    // - Falls back to inexactAllowWhileIdle if denied
    
    // 5. Initialize flutter_local_notifications plugin
    await _notifications.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationTapped);
    
    // 6. Create Android notification channel
    await _createNotificationChannel();
    
    // 7. Check for corrupted cache
    // - Tries to get pending notifications
    // - If fails with "Missing type parameter", cache is corrupted
    // - Clears corrupted cache and disables scheduling
    
    _initialized = true;
    return true;
  } catch (e) {
    print('Error initializing notifications: $e');
    return false;
  }
}
```

**Key Points**:
- Timezone detection is critical for scheduling notifications at correct local time
- Cache corruption detection prevents app crashes when notifications fire
- Exact alarm permission improves reliability but isn't required

### 2. Scheduling a Notification

**Location**: `lib/services/notification_service.dart` (lines 457-668)

```dart
Future<bool> scheduleNoteNotification({
  required DateTime eventDate,
  required String noteText,
  required int notificationId,
  bool isAnnual = false,
}) async {
  // 1. Check if cache is corrupted (prevent crashes)
  if (_cacheCorrupted) {
    return false;
  }
  
  // 2. Get notification settings (days before, hour, minute)
  final settings = await getNotificationSettings();
  final daysBefore = settings['daysBefore']!;
  final hour = settings['hour']!;
  final minute = settings['minute']!;
  
  // 3. Calculate notification date (event date - days before)
  var notificationDate = eventDate.subtract(Duration(days: daysBefore));
  
  // 4. Create TZDateTime in local timezone
  // IMPORTANT: Use local timezone, not UTC, so hour:minute is interpreted as local time
  var scheduledTime = tz.TZDateTime(
    localTz,
    notificationDate.year,
    notificationDate.month,
    notificationDate.day,
    hour,      // LOCAL hour (e.g., 19 = 7 PM local time)
    minute,    // LOCAL minute
  );
  
  // 5. Adjust if notification time is in the past
  // - Try event date at requested time
  // - Try today at requested time
  // - Try tomorrow at requested time
  
  // 6. Create notification details (Android + iOS)
  final notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(...),
    iOS: DarwinNotificationDetails(...),
  );
  
  // 7. Check exact alarm permission and choose schedule mode
  final scheduleMode = hasExactAlarmPermission
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;
  
  // 8. Schedule notification
  await _notifications.zonedSchedule(
    notificationId,
    title,
    body,
    scheduledTime,
    notificationDetails,
    androidScheduleMode: scheduleMode,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    payload: '${eventDate.year}_${eventDate.month}_${eventDate.day}',
  );
  
  // 9. Verify notification was scheduled
  final pending = await _notifications.pendingNotificationRequests();
  // Check if notification ID exists in pending list
  
  return true;
}
```

**Key Points**:
- Notification ID format: `YYYYMMDD` (e.g., 20260114 for Jan 14, 2026)
- Timezone handling is critical - always use local timezone for scheduling
- Past time adjustment ensures notifications always fire in the future
- Verification step helps catch scheduling failures

### 3. Rescheduling All Notifications

**Location**: `lib/services/notification_service.dart` (lines 286-454)

```dart
static Future<void> rescheduleAllNotifications() async {
  // 1. Prevent infinite loops with static flag
  if (_isRescheduling) {
    return;
  }
  
  try {
    _isRescheduling = true;
    
    // 2. Initialize service if needed
    final notificationService = NotificationService();
    if (!notificationService._initialized) {
      await notificationService.initialize();
    }
    
    // 3. Try to cancel all existing notifications
    // - This clears corrupted cache
    // - If it fails, continue anyway (new notifications will overwrite)
    
    // 4. Find all notes with notifications enabled
    // - Scan SharedPreferences for notification_flag_* keys
    // - Check both regular notes (note_*) and annual notes (annual_note_*)
    // - Collect dates with notifications enabled
    
    // 5. Re-schedule each notification with new settings
    for (final entry in datesToReschedule.entries) {
      final date = entry.key;
      final noteData = entry.value;
      
      if (isAnnual) {
        // Schedule for all years (current-1, current, current+1)
        for (final year in yearsToCheck) {
          final scheduledDate = DateTime(year, date.month, date.day);
          await notificationService.scheduleNoteNotification(...);
        }
      } else {
        // Schedule for this date only
        await notificationService.scheduleNoteNotification(...);
      }
    }
  } finally {
    _isRescheduling = false;
  }
}
```

**Key Points**:
- Static flag prevents infinite loops (e.g., if reschedule calls initialize which calls reschedule)
- Handles both regular and annual notes
- Skips explicit cancellation if cache is corrupted (new notifications overwrite old ones)

### 4. App Lifecycle Handling

**Location**: `lib/main.dart` (lines 37-67)

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - reschedule notifications
      // This handles cases where Android cancelled alarms due to app standby
      _rescheduleNotifications();
    }
  }
  
  Future<void> _rescheduleNotifications() async {
    try {
      print('App resumed - checking and rescheduling notifications...');
      await NotificationService.rescheduleAllNotifications();
      print('Notifications rescheduled successfully');
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }
}
```

**Key Points**:
- Reschedules notifications when app resumes
- Handles Android app standby which can cancel alarms
- Prevents notifications from being lost when app is in background

### 5. Cache Corruption Detection

**Location**: `lib/services/notification_service.dart` (lines 134-203)

```dart
// Try to get pending notifications
bool cacheIsCorrupted = false;
try {
  final pending = await _notifications.pendingNotificationRequests();
  print('Found ${pending.length} pending notifications on initialization');
} catch (e) {
  // If this fails with "Missing type parameter", cache is corrupted
  print('CRITICAL: Corrupted notification cache detected: $e');
  cacheIsCorrupted = true;
  
  // Try to clear corrupted cache
  try {
    await _notifications.cancelAll();
  } catch (e2) {
    print('cancelAll failed: $e2');
  }
  
  // Clear notification-related SharedPreferences keys
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  for (final key in keys) {
    if (key.contains('flutter_local_notifications') || 
        key.contains('notification') ||
        key.startsWith('notif_')) {
      await prefs.remove(key);
    }
  }
}

// If cache is corrupted, disable scheduling to prevent crashes
if (cacheIsCorrupted) {
  _cacheCorrupted = true;
  print('CRITICAL: Cache corruption detected - notification scheduling is DISABLED');
}
```

**Key Points**:
- Detects corruption by trying to get pending notifications
- "Missing type parameter" error indicates corrupted cache
- Prevents scheduling if cache is corrupted (would cause app crash when notification fires)
- User must clear app data to fix corruption

### 6. Notification Settings Management

**Location**: `lib/services/notification_service.dart` (lines 237-280)

```dart
// Get settings
static Future<Map<String, int>> getNotificationSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final daysBefore = prefs.getInt('notification_days_before') ?? 1;
  final hour = prefs.getInt('notification_hour') ?? 19; // Default 7 PM
  final minute = prefs.getInt('notification_minute') ?? 0;
  return {
    'daysBefore': daysBefore,
    'hour': hour,
    'minute': minute,
  };
}

// Save settings
static Future<void> saveNotificationSettings({
  required int daysBefore,
  required int hour,
  required int minute,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('notification_days_before', daysBefore);
  await prefs.setInt('notification_hour', hour);
  await prefs.setInt('notification_minute', minute);
  
  // Re-schedule all existing notifications with new time
  await rescheduleAllNotifications();
}
```

**Key Points**:
- Settings stored in SharedPreferences
- Default: 1 day before at 7 PM (19:00)
- **Holiday notifications are enabled by default** (`notify_for_all_holidays` defaults to `true`)
- Changing settings automatically reschedules all notifications

### 7. UI Integration - Home Screen

**Location**: `lib/screens/home_screen.dart`

**Key Code Segments**:

```dart
// Toggle notification switch
Switch(
  value: _notificationEnabled,
  onChanged: (value) async {
    if (value) {
      // Request permission when enabling
      final notificationService = NotificationService();
      final initialized = await notificationService.initialize();
      if (!initialized) {
        // Show error dialog
        return;
      }
    }
    setState(() {
      _notificationEnabled = value;
    });
  },
)

// Save note with notification
await NotesService.saveNote(
  date,
  note,
  repeatAnnually: _repeatAnnually,
  enableNotification: _notificationEnabled && note.trim().isNotEmpty,
);

// Schedule notification if enabled
if (_notificationEnabled && note.trim().isNotEmpty) {
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  if (_repeatAnnually) {
    // Schedule for all years
    for (final year in [currentYear - 1, currentYear, currentYear + 1]) {
      final scheduledDate = DateTime(year, date.month, date.day);
      final notificationId = NotificationService.getNotificationId(scheduledDate);
      await notificationService.scheduleNoteNotification(
        eventDate: scheduledDate,
        noteText: note,
        notificationId: notificationId,
        isAnnual: true,
      );
    }
  } else {
    // Schedule for this date only
    final notificationId = NotificationService.getNotificationId(date);
    await notificationService.scheduleNoteNotification(
      eventDate: date,
      noteText: note,
      notificationId: notificationId,
      isAnnual: false,
    );
  }
}
```

### 8. UI Integration - Settings Screen

**Location**: `lib/screens/settings_screen.dart`

**Key Code Segments**:

```dart
// Load current settings
Future<void> _loadNotificationSettings() async {
  final settings = await NotificationService.getNotificationSettings();
  setState(() {
    _daysBefore = settings['daysBefore'] ?? 1;
    _notificationTime = TimeOfDay(
      hour: settings['hour'] ?? 19,
      minute: settings['minute'] ?? 0,
    );
  });
}

// Save new settings
await NotificationService.saveNotificationSettings(
  daysBefore: days,
  hour: time.hour,
  minute: time.minute,
);
// This automatically reschedules all notifications
```

---

## Data Storage

### SharedPreferences Keys

#### Notification Settings
- `notification_days_before`: int (0-7, default: 1)
- `notification_hour`: int (0-23, default: 19)
- `notification_minute`: int (0-59, default: 0)
- `notify_for_all_holidays`: bool (default: true - holiday reminders enabled by default)

#### Note Data
- `note_YYYY_M_D`: String (note content for specific date)
- `annual_note_M_D`: String (annual note content, no year)
- `annual_flag_YYYY_M_D`: bool (true if note is annual)
- `notification_flag_YYYY_M_D`: bool (true if notification is enabled)

**Example**:
- `note_2026_1_14`: "Doctor appointment"
- `notification_flag_2026_1_14`: true
- `annual_flag_2026_1_14`: false

### Notification ID Format

Notification IDs are generated from dates using the formula:
```dart
notificationId = year * 10000 + month * 100 + day
```

**Examples**:
- Jan 14, 2026 → 20260114
- Dec 25, 2025 → 20251225

This ensures:
- Unique IDs for each date
- Readable format for debugging
- No collisions between dates

---

## Permissions

### Android Permissions (AndroidManifest.xml)

```xml
<!-- Required for notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Required for exact alarms (Android 12+) -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />

<!-- Required for notifications after boot -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### Runtime Permissions

1. **Notification Permission** (`Permission.notification`)
   - Requested in `NotificationService.initialize()`
   - Required for all notifications
   - User can deny (notifications won't work)

2. **Exact Alarm Permission** (`Permission.scheduleExactAlarm`)
   - Requested in `NotificationService.initialize()`
   - Required for exact alarms (Android 12+)
   - If denied, uses inexact alarms (may have delays)
   - User can manage in system settings

### Permission Handling

```dart
// Request notification permission
final notificationPermission = await Permission.notification.request();
if (!notificationPermission.isGranted) {
  print('Notification permission not granted');
  return false;
}

// Request exact alarm permission (optional)
if (await Permission.scheduleExactAlarm.isDenied) {
  final exactAlarmPermission = await Permission.scheduleExactAlarm.request();
  if (exactAlarmPermission.isGranted) {
    print('Exact alarm permission granted');
  } else {
    print('Using inexact alarms (notifications may be delayed)');
  }
}
```

---

## Important Notes and Gotchas

### 1. Cache Corruption Issue

**Problem**: The `flutter_local_notifications` plugin can have corrupted cache that causes "Missing type parameter" errors. When a notification fires, `ScheduledNotificationReceiver` tries to load the corrupted cache and crashes the app.

**Solution**:
- Detect corruption on initialization by trying to get pending notifications
- If corruption detected, clear cache and disable scheduling
- User must clear app data to fix

**Prevention**:
- Don't schedule notifications if cache is corrupted
- Clear corrupted cache on initialization
- Handle errors gracefully

### 2. Timezone Handling

**Critical**: Always use local timezone when scheduling notifications. The hour:minute should be interpreted as local time, not UTC.

```dart
// CORRECT: Use local timezone
var scheduledTime = tz.TZDateTime(
  localTz,  // Local timezone (e.g., Australia/Sydney)
  year, month, day,
  hour,     // LOCAL hour (19 = 7 PM local time)
  minute,   // LOCAL minute
);

// WRONG: Don't use UTC
var scheduledTime = tz.TZDateTime.utc(...); // This would schedule at wrong time
```

### 3. Android App Standby

**Problem**: Android can cancel alarms when app is in background (app standby). Notifications won't fire.

**Solution**: Reschedule notifications when app resumes:
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    NotificationService.rescheduleAllNotifications();
  }
}
```

### 4. Infinite Loop Prevention

**Problem**: `rescheduleAllNotifications()` can call `initialize()` which might trigger rescheduling again.

**Solution**: Use static flag to prevent re-entry:
```dart
static bool _isRescheduling = false;

static Future<void> rescheduleAllNotifications() async {
  if (_isRescheduling) {
    return; // Already rescheduling, skip
  }
  _isRescheduling = true;
  try {
    // ... reschedule logic ...
  } finally {
    _isRescheduling = false;
  }
}
```

### 5. Past Time Adjustment

**Problem**: If notification time is in the past, it won't fire.

**Solution**: Adjust to future time:
1. Try event date at requested time
2. Try today at requested time
3. Try tomorrow at requested time

### 6. Annual Notes

**Problem**: Annual notes need notifications for multiple years.

**Solution**: Schedule notifications for current-1, current, and current+1 years:
```dart
if (isAnnual) {
  for (final year in [currentYear - 1, currentYear, currentYear + 1]) {
    final scheduledDate = DateTime(year, date.month, date.day);
    await scheduleNoteNotification(...);
  }
}
```

### 7. Notification ID Collisions

**Problem**: Same notification ID for different dates could cause issues.

**Solution**: Use date-based ID format (YYYYMMDD) which is unique per date.

### 8. SharedPreferences Key Naming

**Important**: When clearing corrupted cache, only clear notification-related keys, not note keys:
```dart
// CORRECT: Only clear notification keys
if (key.contains('flutter_local_notifications') || 
    key.contains('notification') ||
    key.startsWith('notif_')) {
  // Clear this key
}

// WRONG: Don't clear note keys
// if (key.startsWith('note_')) { ... } // This would delete user notes!
```

---

## Future Reimplementation Guide

### Step 1: Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.4
  permission_handler: ^11.4.0
  shared_preferences: ^2.5.3
```

### Step 2: Android Configuration

1. **Add permissions to `AndroidManifest.xml`**:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

2. **Add receivers**:
```xml
<receiver android:exported="false" 
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" 
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.PACKAGE_REPLACED"/>
        <data android:scheme="package" />
    </intent-filter>
</receiver>
```

### Step 3: Create NotificationService

1. Create `lib/services/notification_service.dart`
2. Implement singleton pattern
3. Implement `initialize()` method with:
   - Timezone detection
   - Permission requests
   - Plugin initialization
   - Cache corruption detection
4. Implement `scheduleNoteNotification()` with timezone handling
5. Implement `rescheduleAllNotifications()` with loop prevention
6. Implement settings get/save methods

### Step 4: Integrate with Notes

1. Add notification flag to note storage
2. Update `NotesService.saveNote()` to accept `enableNotification` parameter
3. Store notification flag: `notification_flag_YYYY_M_D`

### Step 5: Add UI Integration

1. **Home Screen**: Add notification toggle switch
2. **My Notes Screen**: Show notification status, allow toggling
3. **Settings Screen**: Add notification time configuration

### Step 6: App Lifecycle Handling

1. Add `WidgetsBindingObserver` to main app state
2. Initialize `NotificationService` in `main()`
3. Reschedule notifications on app resume

### Step 7: Testing Checklist

- [ ] Notification schedules correctly
- [ ] Notification fires at correct time
- [ ] Timezone handling works correctly
- [ ] Annual notes schedule for all years
- [ ] Settings change reschedules all notifications
- [ ] App resume reschedules notifications
- [ ] Cache corruption is detected and handled
- [ ] Permissions are requested correctly
- [ ] Notifications work when app is closed
- [ ] Notifications work after device reboot

### Step 8: Common Issues to Watch For

1. **Timezone issues**: Always use local timezone, not UTC
2. **Cache corruption**: Detect and handle gracefully
3. **Infinite loops**: Use flags to prevent re-entry
4. **App standby**: Reschedule on app resume
5. **Past times**: Adjust to future time
6. **Permission denials**: Handle gracefully, show user message
7. **Notification ID collisions**: Use unique date-based IDs

---

## Code Snippets Reference

### Initialize Notification Service
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await NotificationService().initialize();
  }
  runApp(const MyApp());
}
```

### Schedule Notification
```dart
final notificationId = NotificationService.getNotificationId(date);
await NotificationService().scheduleNoteNotification(
  eventDate: date,
  noteText: note,
  notificationId: notificationId,
  isAnnual: false,
);
```

### Cancel Notification
```dart
await NotificationService().cancelNotificationsForDate(date, isAnnual: false);
```

### Get Settings
```dart
final settings = await NotificationService.getNotificationSettings();
final daysBefore = settings['daysBefore']!;
final hour = settings['hour']!;
final minute = settings['minute']!;
```

### Save Settings
```dart
await NotificationService.saveNotificationSettings(
  daysBefore: 1,
  hour: 19,
  minute: 0,
);
```

---

## Summary

The notification feature is a complex system involving:
- **Service layer**: NotificationService handles all notification operations
- **Storage layer**: SharedPreferences stores settings and notification flags
- **UI layer**: Multiple screens allow users to configure and manage notifications
- **Lifecycle management**: App lifecycle observer ensures notifications persist
- **Error handling**: Cache corruption detection prevents app crashes

Key principles:
1. Always use local timezone for scheduling
2. Detect and handle cache corruption
3. Reschedule on app resume to handle Android app standby
4. Prevent infinite loops with static flags
5. Handle permissions gracefully
6. Adjust past times to future times

For questions or issues, refer to the code comments in `lib/services/notification_service.dart` which contain detailed explanations of each method.
