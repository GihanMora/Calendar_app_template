import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io' show Platform;
import 'holiday_service.dart';
import '../config/app_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static bool _cacheCorrupted = false; // Track if cache is corrupted to prevent scheduling

  /// Initialize notification service
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Initialize date formatting locale data for en_AU
      try {
        await initializeDateFormatting('en_AU', null);
        print('Date formatting locale (en_AU) initialized');
      } catch (e) {
        print('Warning: Could not initialize en_AU locale data: $e');
        // Continue anyway - will use fallback formatting
      }
      
      // Get device timezone - always use the device's actual timezone
      String? deviceTimezone;
      try {
        final deviceNow = DateTime.now();
        final offsetHours = deviceNow.timeZoneOffset.inHours;
        print('Device timezone offset: ${deviceNow.timeZoneOffset} (${offsetHours} hours)');
        
        if (Platform.isAndroid) {
          // On Android, search for timezone that matches the device's current offset
          // This ensures we use the device's actual timezone, not a config default
          final locations = tz.timeZoneDatabase.locations;
          String? bestMatch;
          
          // First, try to find an exact match for current offset
          for (final location in locations.values) {
            try {
              final testTime = tz.TZDateTime.now(tz.getLocation(location.name));
              if (testTime.timeZoneOffset.inHours == offsetHours) {
                // Prefer well-known timezones (major cities)
                if (bestMatch == null || 
                    location.name.contains('/') && 
                    !location.name.startsWith('Etc/') &&
                    !location.name.startsWith('SystemV/')) {
                  bestMatch = location.name;
                  // If we find a major city timezone, use it immediately
                  if (location.name.contains('America/') || 
                      location.name.contains('Europe/') || 
                      location.name.contains('Asia/') || 
                      location.name.contains('Australia/') ||
                      location.name.contains('Africa/') ||
                      location.name.contains('Pacific/')) {
                    deviceTimezone = location.name;
                    print('Found matching device timezone: $location.name (offset: ${offsetHours}h)');
                    break;
                  }
                }
              }
            } catch (e) {
              continue;
            }
          }
          
          // If we found a match but didn't break early, use the best match
          if (deviceTimezone == null && bestMatch != null) {
            deviceTimezone = bestMatch;
            print('Using device timezone: $bestMatch (offset: ${offsetHours}h)');
          }
          
          // If still no match, try using the system's local timezone name
          if (deviceTimezone == null) {
            try {
              final localTzName = tz.local.name;
              if (localTzName != 'UTC' && localTzName != 'Local') {
                deviceTimezone = localTzName;
                print('Using system local timezone: $localTzName');
              }
            } catch (e) {
              print('Could not get system local timezone: $e');
            }
          }
        } else {
          // iOS - use system timezone directly
          deviceTimezone = tz.local.name;
          print('Using iOS system timezone: $deviceTimezone');
        }
        
        // Set the detected timezone
        if (deviceTimezone != null) {
          try {
            final location = tz.getLocation(deviceTimezone);
            tz.setLocalLocation(location);
            print('✅ Device timezone successfully set to: $deviceTimezone');
            print('   Timezone offset: ${tz.TZDateTime.now(location).timeZoneOffset}');
          } catch (e) {
            print('❌ Failed to set timezone $deviceTimezone: $e');
            // Try to use system local timezone as fallback
            try {
              tz.setLocalLocation(tz.local);
              print('Using system local timezone as fallback: ${tz.local.name}');
            } catch (e2) {
              print('Failed to use system local timezone: $e2');
              // Last resort: use UTC but warn user
              tz.setLocalLocation(tz.UTC);
              print('⚠️  WARNING: Using UTC as last resort fallback - notifications may fire at wrong time!');
            }
          }
        } else {
          // No timezone detected, try system local
          try {
            tz.setLocalLocation(tz.local);
            print('Using system local timezone: ${tz.local.name}');
          } catch (e) {
            print('Failed to use system local timezone: $e');
            // Last resort: use UTC but warn
            tz.setLocalLocation(tz.UTC);
            print('⚠️  WARNING: No timezone detected, using UTC - notifications may fire at wrong time!');
          }
        }
      } catch (e) {
        print('Error detecting timezone: $e');
        // Try to use system local timezone as fallback
        try {
          tz.setLocalLocation(tz.local);
          print('Using system local timezone as fallback: ${tz.local.name}');
        } catch (e2) {
          print('Failed to use system local timezone: $e2');
          // Last resort: use UTC but warn
          tz.setLocalLocation(tz.UTC);
          print('⚠️  WARNING: Using UTC as last resort fallback due to error - notifications may fire at wrong time!');
        }
      }

      // Request notification permission
      final notificationPermission = await Permission.notification.request();
      if (!notificationPermission.isGranted) {
        print('Notification permission not granted');
        return false;
      }

      // Request exact alarm permission for Android 12+ (required for exactAllowWhileIdle)
      // Note: This permission may not be available on all devices/Android versions
      try {
        if (await Permission.scheduleExactAlarm.isDenied) {
          final exactAlarmPermission = await Permission.scheduleExactAlarm.request();
          if (exactAlarmPermission.isGranted) {
            print('Exact alarm permission granted');
          } else {
            print('Exact alarm permission not granted, using inexact alarms (notifications may be delayed)');
          }
        } else if (await Permission.scheduleExactAlarm.isGranted) {
          print('Exact alarm permission already granted');
        }
      } catch (e) {
        print('Could not check/request exact alarm permission (may not be available on this device): $e');
        // Continue anyway - we'll use inexact alarms
      }

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialize settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      // Try to clear any corrupted notification cache by getting pending notifications
      // This helps prevent "Missing type parameter" errors
      // IMPORTANT: If the cache is corrupted, we MUST clear it completely to prevent app crashes
      // when notifications fire, as the ScheduledNotificationReceiver will crash trying to load it
      bool cacheIsCorrupted = false;
      try {
        final pending = await _notifications.pendingNotificationRequests();
        print('Found ${pending.length} pending notifications on initialization');
        // Don't auto-reschedule here - let the app lifecycle handle it to avoid infinite loops
      } catch (e) {
        print('CRITICAL: Corrupted notification cache detected: $e');
        print('This will cause app crashes when notifications fire. Clearing cache...');
        cacheIsCorrupted = true;
        
        // Try multiple methods to clear the corrupted cache
        try {
          // Method 1: Try cancelAll
          await _notifications.cancelAll();
          print('Cleared all notifications via cancelAll');
        } catch (e2) {
          print('cancelAll failed: $e2');
        }
        
        // Method 2: Clear SharedPreferences that the plugin might use
        try {
          final prefs = await SharedPreferences.getInstance();
          // The plugin stores notification data in SharedPreferences with specific keys
          // We'll clear all notification-related keys
          final keys = prefs.getKeys();
          final keysToRemove = <String>[];
          for (final key in keys) {
            if (key.contains('flutter_local_notifications') || 
                key.contains('notification') ||
                key.startsWith('notif_')) {
              keysToRemove.add(key);
            }
          }
          for (final key in keysToRemove) {
            await prefs.remove(key);
          }
          print('Cleared ${keysToRemove.length} notification-related SharedPreferences keys');
        } catch (e3) {
          print('Could not clear SharedPreferences: $e3');
        }
      }
      
      // If cache was corrupted, mark it so we don't try to schedule notifications
      // This prevents app crashes when notifications fire
      if (cacheIsCorrupted) {
        _cacheCorrupted = true;
        print('CRITICAL: Cache corruption detected - notification scheduling is DISABLED');
        print('The app will crash if notifications fire with corrupted cache.');
        print('Attempting to cancel all alarms via ADB to prevent crashes...');
        
        // Try to cancel all alarms using ADB command
        // This is a workaround to prevent crashes when notifications fire
        try {
          if (Platform.isAndroid) {
            // Use Process to run ADB command to cancel all alarms
            // Note: This requires the app to have shell permissions, which it doesn't
            // So we'll just log a warning and prevent scheduling
            print('Cannot cancel alarms via ADB from within app - user must clear app data');
            print('To fix: Settings > Apps > ${AppConfig.appName} > Storage > Clear Data');
          }
        } catch (e) {
          print('Could not cancel alarms: $e');
        }
      } else {
        _cacheCorrupted = false;
      }

      _initialized = true;
      return true;
    } catch (e) {
      print('Error initializing notifications: $e');
      return false;
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'calendar_events',
      'Calendar Events',
      description: 'Notifications for calendar events and notes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }


  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    print('Notification tapped: ${response.payload}');
  }

  /// Get notification time settings (days before and time)
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final daysBefore = prefs.getInt('notification_days_before') ?? 1;
    final hour = prefs.getInt('notification_hour') ?? 19; // Default 7 PM
    final minute = prefs.getInt('notification_minute') ?? 0;
    final notifyForAllHolidays = prefs.getBool('notify_for_all_holidays') ?? true;
    print('=== READING NOTIFICATION SETTINGS ===');
    print('Days before: $daysBefore');
    print('Hour: $hour (${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')})');
    print('Minute: $minute');
    print('Notify for all holidays: $notifyForAllHolidays');
    print('=====================================');
    return {
      'daysBefore': daysBefore,
      'hour': hour,
      'minute': minute,
      'notifyForAllHolidays': notifyForAllHolidays,
    };
  }

  /// Save notification time settings
  static Future<void> saveNotificationSettings({
    required int daysBefore,
    required int hour,
    required int minute,
  }) async {
    print('=== SAVING NOTIFICATION SETTINGS ===');
    print('Days before: $daysBefore');
    print('Hour: $hour');
    print('Minute: $minute');
    print('Time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_days_before', daysBefore);
    await prefs.setInt('notification_hour', hour);
    await prefs.setInt('notification_minute', minute);
    print('Settings saved to SharedPreferences');
    
    // Verify the save worked
    final verifyDays = prefs.getInt('notification_days_before');
    final verifyHour = prefs.getInt('notification_hour');
    final verifyMinute = prefs.getInt('notification_minute');
    print('Verification - Days: $verifyDays, Hour: $verifyHour, Minute: $verifyMinute');
    print('=====================================');
    
    // Re-schedule all existing notifications with the new time
    await rescheduleAllNotifications();
  }

  /// Save holiday notification setting
  static Future<void> saveHolidayNotificationSetting(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_for_all_holidays', enabled);
    print('Holiday notification setting saved: $enabled');
    
    // Re-schedule all notifications (including holidays if enabled)
    await rescheduleAllNotifications();
  }
  
  // Static flag to prevent infinite loops
  static bool _isRescheduling = false;
  
  /// Re-schedule all existing notifications with current settings
  static Future<void> rescheduleAllNotifications() async {
    // Prevent infinite loops
    if (_isRescheduling) {
      print('Already rescheduling, skipping to prevent infinite loop');
      return;
    }
    
    try {
      _isRescheduling = true;
      print('=== RE-SCHEDULING ALL NOTIFICATIONS ===');
      
      // First, try to clear any corrupted notification cache
      // This helps prevent "Missing type parameter" errors
      final notificationService = NotificationService();
      // Don't call initialize() here - it might trigger rescheduleAllNotifications again
      if (!notificationService._initialized) {
        await notificationService.initialize();
      }
      
      try {
        // Try to cancel all notifications first to clear corrupted cache
        await notificationService._notifications.cancelAll();
        print('Cleared all existing notifications before rescheduling');
      } catch (e) {
        print('Warning: Could not clear all notifications: $e');
        print('Continuing anyway...');
      }
      
      // Import NotesService here to avoid circular dependency
      // We'll use dynamic import or access SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Find all notes with notifications enabled
      final notificationFlagPrefix = 'notification_flag_';
      final notesPrefix = 'note_';
      final annualNotesPrefix = 'annual_note_';
      final annualFlagPrefix = 'annual_flag_';
      
      // notificationService already initialized above
      
      // Get all dates with notifications enabled
      final datesToReschedule = <DateTime, Map<String, dynamic>>{};
      final currentYear = DateTime.now().year;
      final yearsToCheck = [currentYear - 1, currentYear, currentYear + 1];
      
      // Get today's date for filtering past events
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      
      // First, collect all regular notes with notifications
      for (final key in allKeys) {
        if (key.startsWith(notificationFlagPrefix)) {
          final hasNotification = prefs.getBool(key) ?? false;
          if (hasNotification) {
            final dateStr = key.substring(notificationFlagPrefix.length);
            final parts = dateStr.split('_');
            if (parts.length == 3) {
              final year = int.tryParse(parts[0]);
              final month = int.tryParse(parts[1]);
              final day = int.tryParse(parts[2]);
              if (year != null && month != null && day != null && yearsToCheck.contains(year)) {
                final date = DateTime(year, month, day);
                final dateOnly = DateTime(date.year, date.month, date.day);
                
                // Skip past events - only schedule for today or future dates
                if (dateOnly.isBefore(todayOnly)) {
                  print('Skipping past event: $date (before today)');
                  continue;
                }
                
                final noteKey = '${notesPrefix}${year}_${month}_${day}';
                final note = prefs.getString(noteKey);
                if (note != null && note.trim().isNotEmpty) {
                  final annualFlagKey = '${annualFlagPrefix}${year}_${month}_${day}';
                  final isAnnual = prefs.getBool(annualFlagKey) ?? false;
                  datesToReschedule[date] = {
                    'note': note,
                    'isAnnual': isAnnual,
                  };
                }
              }
            }
          }
        }
      }
      
      // Also check annual notes
      for (final key in allKeys) {
        if (key.startsWith(annualNotesPrefix)) {
          final dateStr = key.substring(annualNotesPrefix.length);
          final parts = dateStr.split('_');
          if (parts.length == 2) {
            final month = int.tryParse(parts[0]);
            final day = int.tryParse(parts[1]);
            if (month != null && day != null) {
              final note = prefs.getString(key);
              if (note != null && note.trim().isNotEmpty) {
                // Check each year for notification flag
                for (final year in yearsToCheck) {
                  final date = DateTime(year, month, day);
                  final dateOnly = DateTime(date.year, date.month, date.day);
                  
                  // Skip past events - only schedule for today or future dates
                  if (dateOnly.isBefore(todayOnly)) {
                    continue;
                  }
                  
                  final notificationFlagKey = '${notificationFlagPrefix}${year}_${month}_${day}';
                  final hasNotification = prefs.getBool(notificationFlagKey) ?? false;
                  if (hasNotification && !datesToReschedule.containsKey(date)) {
                    datesToReschedule[date] = {
                      'note': note,
                      'isAnnual': true,
                    };
                  }
                }
              }
            }
          }
        }
      }
      
      print('Found ${datesToReschedule.length} notes with notifications enabled');
      
      // Re-schedule with new time
      // Note: We skip cancellation if cache is corrupted - new notifications will overwrite old ones
      for (final entry in datesToReschedule.entries) {
        final date = entry.key;
        final noteData = entry.value;
        final note = noteData['note'] as String;
        final isAnnual = noteData['isAnnual'] as bool;
        
        // Skip cancellation - just schedule new notification directly
        // The new notification will overwrite the old one with the same ID
        // This avoids "Missing type parameter" errors from corrupted cache
        print('Skipping cancellation for $date (will overwrite with new notification)');
        
        // Re-schedule with new settings
        try {
          if (isAnnual) {
            // Schedule for all years
            for (final year in yearsToCheck) {
              final scheduledDate = DateTime(year, date.month, date.day);
              final notificationId = getNotificationId(scheduledDate);
              print('Re-scheduling annual notification for $scheduledDate (ID: $notificationId)');
              final success = await notificationService.scheduleNoteNotification(
                eventDate: scheduledDate,
                noteText: note,
                notificationId: notificationId,
                isAnnual: true,
              );
              if (!success) {
                print('ERROR: Failed to schedule notification for $scheduledDate');
              } else {
                print('Successfully re-scheduled notification for $scheduledDate');
              }
            }
          } else {
            // Schedule for this date only
            final notificationId = getNotificationId(date);
            print('Re-scheduling notification for $date (ID: $notificationId)');
            final success = await notificationService.scheduleNoteNotification(
              eventDate: date,
              noteText: note,
              notificationId: notificationId,
              isAnnual: false,
            );
            if (!success) {
              print('ERROR: Failed to schedule notification for $date');
            } else {
              print('Successfully re-scheduled notification for $date');
            }
          }
        } catch (e, stackTrace) {
          print('ERROR: Exception while re-scheduling notification for $date: $e');
          print('Stack trace: $stackTrace');
        }
      }
      
      // Schedule holiday notifications if enabled
      final notifyForAllHolidays = prefs.getBool('notify_for_all_holidays') ?? true;
      if (notifyForAllHolidays) {
        print('Holiday notifications are enabled - scheduling holiday notifications...');
        await _scheduleHolidayNotifications(notificationService, prefs);
      } else {
        print('Holiday notifications are disabled - skipping holiday scheduling');
        // Cancel any existing holiday notifications
        await _cancelHolidayNotifications(notificationService);
      }
      
      print('All notifications re-scheduled with new settings');
      print('===============================================');
    } catch (e) {
      print('Error re-scheduling notifications: $e');
    } finally {
      _isRescheduling = false;
    }
  }

  /// Schedule notifications for all holidays
  static Future<void> _scheduleHolidayNotifications(
    NotificationService notificationService,
    SharedPreferences prefs,
  ) async {
    try {
      // Get selected state from SharedPreferences
      final selectedState = prefs.getString('selected_state') ?? 'ALL';
      
      // Load holidays if not already loaded
      await HolidayService.loadHolidays();
      HolidayService.setSelectedState(selectedState);
      
      // Get all holidays for the selected state
      final holidays = HolidayService.getAllHolidays(state: selectedState);
      print('Found ${holidays.length} holidays to schedule notifications for');
      
      final currentYear = DateTime.now().year;
      final yearsToCheck = [currentYear - 1, currentYear, currentYear + 1];
      
      int scheduledCount = 0;
      for (final holiday in holidays) {
        try {
          // Parse holiday date
          final holidayDate = DateTime.parse(holiday.date);
          
          // Schedule for all years in range
          for (final year in yearsToCheck) {
            final scheduledDate = DateTime(year, holidayDate.month, holidayDate.day);
            final today = DateTime.now();
            final todayOnly = DateTime(today.year, today.month, today.day);
            final scheduledDateOnly = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
            
            // Only schedule if the date is today or in the future
            if (scheduledDateOnly.isBefore(todayOnly)) {
              continue; // Skip past holidays
            }
            
            // Use a unique ID for holidays (starting from 2000000 to avoid conflicts with note IDs)
            final holidayNotificationId = _getHolidayNotificationId(scheduledDate);
            
            // Format holiday notification text with holiday name and type
            final holidayText = '${holiday.holidayName}${holiday.type.isNotEmpty ? ' (${holiday.type})' : ''}';
            
            // Schedule notification with holiday name as the note text
            // The scheduleNoteNotification method will add the date to the notification body
            final success = await notificationService.scheduleNoteNotification(
              eventDate: scheduledDate,
              noteText: holidayText,
              notificationId: holidayNotificationId,
              isAnnual: false, // Holidays are not annual notes, but they repeat yearly
            );
            
            if (success) {
              scheduledCount++;
              print('Scheduled holiday notification for ${holiday.holidayName} on $scheduledDate');
            } else {
              print('Failed to schedule holiday notification for ${holiday.holidayName} on $scheduledDate');
            }
          }
        } catch (e) {
          print('Error scheduling notification for holiday ${holiday.holidayName}: $e');
        }
      }
      
      print('Scheduled $scheduledCount holiday notifications');
    } catch (e) {
      print('Error scheduling holiday notifications: $e');
    }
  }

  /// Cancel all holiday notifications
  static Future<void> _cancelHolidayNotifications(NotificationService notificationService) async {
    try {
      // Load holidays to get all dates
      await HolidayService.loadHolidays();
      final holidays = HolidayService.getAllHolidays();
      
      final currentYear = DateTime.now().year;
      final yearsToCheck = [currentYear - 1, currentYear, currentYear + 1];
      
      for (final holiday in holidays) {
        try {
          final holidayDate = DateTime.parse(holiday.date);
          
          for (final year in yearsToCheck) {
            final scheduledDate = DateTime(year, holidayDate.month, holidayDate.day);
            final holidayNotificationId = _getHolidayNotificationId(scheduledDate);
            await notificationService.cancelNotification(holidayNotificationId);
          }
        } catch (e) {
          print('Error cancelling holiday notification: $e');
        }
      }
      
      print('Cancelled all holiday notifications');
    } catch (e) {
      print('Error cancelling holiday notifications: $e');
    }
  }

  /// Get unique notification ID for holidays (using range 2000000+ to avoid conflicts)
  static int _getHolidayNotificationId(DateTime date) {
    // Use range starting from 2000000 to avoid conflicts with note IDs (which use YYYYMMDD format, max ~20991231)
    // Format: 2000000 + YYYYMMDD (e.g., 2000000 + 20260110 = 20020260110)
    return 2000000 + (date.year * 10000 + date.month * 100 + date.day);
  }

  /// Schedule a notification for a note
  Future<bool> scheduleNoteNotification({
    required DateTime eventDate,
    required String noteText,
    required int notificationId,
    bool isAnnual = false,
  }) async {
    if (!_initialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    // CRITICAL: Don't schedule if cache is corrupted - it will crash the app when notification fires
    if (_cacheCorrupted) {
      print('ERROR: Cannot schedule notification - cache is corrupted. This would cause app crash.');
      print('Please clear app data: Settings > Apps > Australian Calendar > Storage > Clear Data');
      return false;
    }

    try {
      // Get notification settings
      final settings = await getNotificationSettings();
      final daysBefore = settings['daysBefore']!;
      final hour = settings['hour']!;
      final minute = settings['minute']!;

      // Get device's current time to determine timezone
      final deviceNow = DateTime.now();
      final deviceTimezoneOffset = deviceNow.timeZoneOffset;
      
      // Get the local timezone that was set during initialization
      final localTz = tz.local;
      
      // Get current time in the same timezone for comparison
      final nowLocal = tz.TZDateTime.from(deviceNow, localTz);
      
      // Check if the event date is in the past (before today)
      final todayOnly = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
      final eventDateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);
      
      // If the event date is in the past, don't schedule a notification
      if (eventDateOnly.isBefore(todayOnly)) {
        print('Event date ($eventDate) is in the past - skipping notification scheduling');
        return false;
      }
      
      // Calculate notification date (X days before event)
      var notificationDate = eventDate.subtract(Duration(days: daysBefore));
      
      // IMPORTANT: Create TZDateTime directly in the local timezone
      // This ensures the hour:minute is interpreted as LOCAL time, not UTC
      var scheduledTime = tz.TZDateTime(
        localTz,
        notificationDate.year,
        notificationDate.month,
        notificationDate.day,
        hour,      // This is LOCAL hour (e.g., 17 = 5 PM local time)
        minute,    // This is LOCAL minute
      );

      // If the calculated notification time is in the past, adjust it
      // But only if the event date is today or in the future
      if (scheduledTime.isBefore(nowLocal.subtract(const Duration(minutes: 1)))) {
        print('Original notification time is in the past ($scheduledTime), adjusting...');
        
        // If event date is today, schedule for today at the requested time (if not passed)
        if (eventDateOnly.isAtSameMomentAs(todayOnly)) {
          final todayAtRequestedTime = tz.TZDateTime(
            localTz,
            nowLocal.year,
            nowLocal.month,
            nowLocal.day,
            hour,
            minute,
          );
          
          if (todayAtRequestedTime.isAfter(nowLocal.subtract(const Duration(minutes: 1)))) {
            // Today's requested time hasn't passed yet, use it
            scheduledTime = todayAtRequestedTime;
            notificationDate = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
            print('Event is today - adjusted to today at requested time: $scheduledTime');
          } else {
            // Today's time has passed, don't schedule (event is today and notification time passed)
            print('Event is today but notification time has passed - skipping notification');
            return false;
          }
        } else {
          // Event date is in the future, but notification date is in the past
          // Schedule for tomorrow at the requested time to give at least some notice
          final tomorrow = nowLocal.add(const Duration(days: 1));
          scheduledTime = tz.TZDateTime(
            localTz,
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
            hour,
            minute,
          );
          notificationDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
          print('Notification date was in the past - adjusted to tomorrow at requested time: $scheduledTime');
        }
      }

      print('=== NOTIFICATION SCHEDULING DEBUG ===');
      print('Event date: $eventDate');
      print('Days before: $daysBefore');
      print('Notification date: ${notificationDate.year}-${notificationDate.month}-${notificationDate.day}');
      print('Requested time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (LOCAL TIME)');
      print('---');
      print('Device current time (local): $deviceNow');
      print('Device timezone offset: $deviceTimezoneOffset (${deviceTimezoneOffset.inHours} hours)');
      print('App timezone name: ${localTz.name}');
      print('App timezone offset: ${scheduledTime.timeZoneOffset} (${scheduledTime.timeZoneOffset.inHours} hours)');
      print('---');
      print('Scheduled TZDateTime (in ${localTz.name}): $scheduledTime');
      print('  -> This is: ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')} in ${localTz.name}');
      print('Scheduled time UTC equivalent: ${scheduledTime.toUtc()}');
      print('  -> This is: ${scheduledTime.toUtc().hour.toString().padLeft(2, '0')}:${scheduledTime.toUtc().minute.toString().padLeft(2, '0')} UTC');
      print('---');
      print('Current TZDateTime (in ${localTz.name}): $nowLocal');
      print('  -> This is: ${nowLocal.hour.toString().padLeft(2, '0')}:${nowLocal.minute.toString().padLeft(2, '0')} in ${localTz.name}');
      print('Current time UTC equivalent: ${nowLocal.toUtc()}');
      print('  -> This is: ${nowLocal.toUtc().hour.toString().padLeft(2, '0')}:${nowLocal.toUtc().minute.toString().padLeft(2, '0')} UTC');
      print('---');
      final minutesDiff = scheduledTime.difference(nowLocal).inMinutes;
      print('Time until notification: $minutesDiff minutes (${(minutesDiff / 60).toStringAsFixed(1)} hours)');
      if (localTz.name == 'UTC' && deviceTimezoneOffset.inHours != 0) {
        print('⚠️  WARNING: App is using UTC timezone but device is ${deviceTimezoneOffset.inHours > 0 ? '+' : ''}${deviceTimezoneOffset.inHours} hours offset!');
        print('⚠️  This means notifications will fire at the wrong local time!');
        print('⚠️  Expected local time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
        final expectedUtc = hour - deviceTimezoneOffset.inHours;
        final expectedUtcHour = expectedUtc < 0 ? expectedUtc + 24 : (expectedUtc >= 24 ? expectedUtc - 24 : expectedUtc);
        print('⚠️  But scheduled UTC time: ${scheduledTime.toUtc().hour.toString().padLeft(2, '0')}:${scheduledTime.toUtc().minute.toString().padLeft(2, '0')}');
        print('⚠️  This will appear as: ${((scheduledTime.toUtc().hour + deviceTimezoneOffset.inHours) % 24).toString().padLeft(2, '0')}:${scheduledTime.toUtc().minute.toString().padLeft(2, '0')} local time');
      }
      print('=====================================');

      // Format date for notification (with error handling)
      String formattedDate;
      try {
        final dateFormatter = DateFormat('EEEE, MMMM d, yyyy', 'en_AU');
        formattedDate = dateFormatter.format(eventDate);
      } catch (e) {
        // Fallback to simple date format if locale-specific formatting fails
        print('Warning: Failed to format date with en_AU locale: $e');
        formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(eventDate);
      }
      
      // Truncate note text for notification title/body and include date
      final title = 'Event Reminder';
      final noteTextWithDate = '$noteText\n\nDate: $formattedDate';
      final body = noteTextWithDate.length > 200 
          ? '${noteTextWithDate.substring(0, 200)}...' 
          : noteTextWithDate;

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        'calendar_events',
        'Calendar Events',
        channelDescription: 'Notifications for calendar events and notes',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Check if exact alarm permission is granted
      bool hasExactAlarmPermission = false;
      try {
        hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;
      } catch (e) {
        print('Error checking exact alarm permission: $e');
      }

      // Use exact alarm mode if permission is granted, otherwise use inexact
      // Note: inexactAllowWhileIdle still works when app is closed but may have delays
      final scheduleMode = hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      
      print('Has exact alarm permission: $hasExactAlarmPermission, using mode: $scheduleMode');

      print('Scheduling notification with mode: $scheduleMode');
      print('Notification time (local): $scheduledTime');
      print('Notification time (UTC): ${scheduledTime.toUtc()}');
      print('Current time (local): $nowLocal');

      // Schedule notification (zonedSchedule returns void, throws exception on failure)
      print('About to call zonedSchedule with ID: $notificationId');
      try {
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
        print('zonedSchedule call completed without exception');
      } catch (scheduleError) {
        print('ERROR in zonedSchedule call: $scheduleError');
        rethrow;
      }

      // Verify the notification was actually scheduled
      try {
        final pending = await _notifications.pendingNotificationRequests();
        final scheduled = pending.where((n) => n.id == notificationId).toList();
        if (scheduled.isEmpty) {
          print('WARNING: Notification ID $notificationId was not found in pending notifications after scheduling!');
          print('Total pending notifications: ${pending.length}');
        } else {
          print('SUCCESS: Notification ID $notificationId confirmed in pending notifications');
        }
      } catch (verifyError) {
        print('ERROR verifying notification was scheduled: $verifyError');
      }

      print('Notification successfully scheduled for ${scheduledTime.toString()} (ID: $notificationId)');
      print('Event date: $eventDate, Notification date: $notificationDate');
      return true;
    } catch (e, stackTrace) {
      print('Error scheduling notification: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Cancel a notification
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      print('Notification cancelled (ID: $notificationId)');
    } catch (e) {
      // Handle error gracefully - this can happen if notification cache is corrupted
      print('Error cancelling notification $notificationId: $e');
      // Try to cancel all notifications as fallback if individual cancel fails
      try {
        await _notifications.cancelAll();
        print('Cancelled all notifications as fallback');
      } catch (e2) {
        print('Error cancelling all notifications: $e2');
      }
    }
  }

  /// Cancel all notifications for a specific date
  Future<void> cancelNotificationsForDate(DateTime date, {bool isAnnual = false}) async {
    try {
      if (isAnnual) {
        // For annual notes, we need to cancel notifications for all years
        final currentYear = DateTime.now().year;
        final yearsToCheck = [currentYear - 1, currentYear, currentYear + 1];
        for (final year in yearsToCheck) {
          final notificationDate = DateTime(year, date.month, date.day);
          final notificationId = _getNotificationId(notificationDate);
          await cancelNotification(notificationId);
        }
      } else {
        // For regular notes, cancel only for the specific date
        final notificationId = _getNotificationId(date);
        await cancelNotification(notificationId);
      }
    } catch (e) {
      // If cancellation fails (e.g., due to corrupted cache), log but continue
      // The new notification will be scheduled anyway, which will overwrite the old one
      print('Warning: Error cancelling notifications for date $date: $e');
      print('Continuing to schedule new notification...');
    }
  }

  /// Get unique notification ID from date
  static int _getNotificationId(DateTime date) {
    // Use a combination of year, month, day to create unique ID
    // Format: YYYYMMDD (e.g., 20260110 for Jan 10, 2026)
    // This ensures uniqueness while being readable
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// Get notification ID for a date
  static int getNotificationId(DateTime date) {
    return _getNotificationId(date);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling all notifications: $e');
      // Try to clear pending notifications by getting and canceling individually
      try {
        final pending = await _notifications.pendingNotificationRequests();
        for (final notification in pending) {
          try {
            await _notifications.cancel(notification.id);
          } catch (e2) {
            print('Error cancelling notification ${notification.id}: $e2');
          }
        }
        print('Cleared ${pending.length} pending notifications individually');
      } catch (e2) {
        print('Error getting pending notifications: $e2');
      }
    }
  }

  /// Get pending notifications list (for debugging/UI)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Get all pending notifications (for debugging)
  Future<void> debugPendingNotifications() async {
    try {
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      print('=== PENDING NOTIFICATIONS DEBUG ===');
      print('Total pending notifications: ${pendingNotifications.length}');
      final deviceNow = DateTime.now();
      final deviceOffset = deviceNow.timeZoneOffset;
      final nowLocal = tz.TZDateTime.now(tz.local);
      print('Current device time: $deviceNow');
      print('Device timezone offset: $deviceOffset (${deviceOffset.inHours} hours)');
      print('Current time (app TZ): $nowLocal');
      print('App timezone name: ${tz.local.name}');
      print('App timezone offset: ${nowLocal.timeZoneOffset} (${nowLocal.timeZoneOffset.inHours} hours)');
      if (tz.local.name == 'UTC' && deviceOffset.inHours != 0) {
        print('⚠️  WARNING: App is using UTC but device is ${deviceOffset.inHours > 0 ? '+' : ''}${deviceOffset.inHours} hours offset!');
        print('⚠️  Notifications may fire at wrong local time!');
      }
      print('---');
      
      // Get current notification settings
      final settings = await getNotificationSettings();
      print('Notification settings:');
      print('  - Days before: ${settings['daysBefore']}');
      print('  - Time: ${settings['hour']?.toString().padLeft(2, '0')}:${settings['minute']?.toString().padLeft(2, '0')} (expected LOCAL time)');
      
      if (pendingNotifications.isEmpty) {
        print('No pending notifications found!');
      } else {
        for (final notification in pendingNotifications) {
          print('---');
          print('Notification ID: ${notification.id}');
          print('Title: ${notification.title}');
          print('Body: ${notification.body?.substring(0, notification.body!.length > 100 ? 100 : notification.body!.length)}...');
          // Try to parse date from ID (format: YYYYMMDD)
          if (notification.id != null && notification.id! > 20000000 && notification.id! < 30000000) {
            final idStr = notification.id!.toString();
            if (idStr.length == 8) {
              final year = int.tryParse(idStr.substring(0, 4));
              final month = int.tryParse(idStr.substring(4, 6));
              final day = int.tryParse(idStr.substring(6, 8));
              if (year != null && month != null && day != null) {
                final eventDate = DateTime(year, month, day);
                final daysBefore = settings['daysBefore'] as int;
                final hour = settings['hour'] as int;
                final minute = settings['minute'] as int;
                final notificationDate = eventDate.subtract(Duration(days: daysBefore));
                final scheduledTime = tz.TZDateTime(
                  tz.local,
                  notificationDate.year,
                  notificationDate.month,
                  notificationDate.day,
                  hour,
                  minute,
                );
                print('Event date: $eventDate');
                print('Scheduled notification time: $scheduledTime');
                print('  -> This is: ${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')} in ${tz.local.name}');
                print('Scheduled time (UTC): ${scheduledTime.toUtc()}');
                print('  -> This is: ${scheduledTime.toUtc().hour.toString().padLeft(2, '0')}:${scheduledTime.toUtc().minute.toString().padLeft(2, '0')} UTC');
                if (tz.local.name == 'UTC' && deviceOffset.inHours != 0) {
                  final localTimeHour = (scheduledTime.toUtc().hour + deviceOffset.inHours) % 24;
                  final localTimeMinute = scheduledTime.toUtc().minute;
                  print('  -> Will appear as: ${localTimeHour.toString().padLeft(2, '0')}:${localTimeMinute.toString().padLeft(2, '0')} local time (device offset: ${deviceOffset.inHours}h)');
                  print('  -> Expected: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} local time');
                  if (localTimeHour != hour || localTimeMinute != minute) {
                    print('⚠️  TIMEZONE MISMATCH: Notification will fire at wrong time!');
                  }
                }
                final timeUntil = scheduledTime.difference(nowLocal);
                if (timeUntil.isNegative) {
                  print('⚠️  WARNING: This notification time has PASSED! (${timeUntil.inMinutes.abs()} minutes ago)');
                } else {
                  print('Time until notification: ${timeUntil.inHours}h ${timeUntil.inMinutes % 60}m');
                }
              }
            }
          }
        }
      }
      print('===================================');
    } catch (e) {
      print('Error getting pending notifications: $e');
      print('This might indicate cache corruption. Try clearing app data.');
    }
  }

  /// Request exact alarm permission explicitly
  Future<bool> requestExactAlarmPermission() async {
    try {
      if (await Permission.scheduleExactAlarm.isDenied) {
        final result = await Permission.scheduleExactAlarm.request();
        if (result.isGranted) {
          return true;
        }
        // If permission is permanently denied, user needs to go to settings
        if (result.isPermanentlyDenied) {
          print('Exact alarm permission is permanently denied. User needs to enable it in settings.');
          return false;
        }
        return false;
      }
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (e) {
      print('Error requesting exact alarm permission: $e');
      return false;
    }
  }

  /// Open exact alarm settings (Android 12+)
  Future<void> openExactAlarmSettings() async {
    try {
      // Open app settings where user can enable exact alarms
      // On Android 12+, exact alarm permission is managed in system settings
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  /// Test notification - schedule a notification 5 seconds from now for testing
  Future<bool> testNotification() async {
    if (!_initialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    try {
      final testTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
      
      final androidDetails = AndroidNotificationDetails(
        'calendar_events',
        'Calendar Events',
        channelDescription: 'Notifications for calendar events and notes',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: const BigTextStyleInformation('This is a test notification'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      bool hasExactAlarmPermission = false;
      try {
        hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;
      } catch (e) {
        print('Error checking exact alarm permission: $e');
      }

      final scheduleMode = hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _notifications.zonedSchedule(
        999999, // Test notification ID
        'Test Notification',
        'If you see this, notifications are working!',
        testTime,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test',
      );

      print('Test notification scheduled for $testTime');
      return true;
    } catch (e, stackTrace) {
      print('Error scheduling test notification: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
}
