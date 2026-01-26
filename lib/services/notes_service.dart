import 'package:shared_preferences/shared_preferences.dart';

class NotesService {
  static const String _notesPrefix = 'note_';
  static const String _annualNotesPrefix = 'annual_note_';
  static const String _annualFlagPrefix = 'annual_flag_';
  static const String _notificationFlagPrefix = 'notification_flag_';

  /// Get a unique key for a date
  static String _getDateKey(DateTime date) {
    return '$_notesPrefix${date.year}_${date.month}_${date.day}';
  }

  /// Get a key for annual note (month_day only, no year)
  static String _getAnnualDateKey(DateTime date) {
    return '$_annualNotesPrefix${date.month}_${date.day}';
  }

  /// Get a key for annual flag
  static String _getAnnualFlagKey(DateTime date) {
    return '$_annualFlagPrefix${date.year}_${date.month}_${date.day}';
  }

  /// Get a key for notification flag
  static String _getNotificationFlagKey(DateTime date) {
    return '$_notificationFlagPrefix${date.year}_${date.month}_${date.day}';
  }

  /// Save a note for a specific date
  static Future<bool> saveNote(
    DateTime date,
    String note, {
    bool repeatAnnually = false,
    bool enableNotification = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (note.trim().isEmpty) {
        // If note is empty, remove both regular and annual notes
        final key = _getDateKey(date);
        final annualKey = _getAnnualDateKey(date);
        final flagKey = _getAnnualFlagKey(date);
        final notificationFlagKey = _getNotificationFlagKey(date);
        await prefs.remove(key);
        await prefs.remove(annualKey);
        await prefs.remove(flagKey);
        await prefs.remove(notificationFlagKey);
        return true;
      }

      // Check if this date was previously an annual note
      final annualKey = _getAnnualDateKey(date);
      final wasAnnual = prefs.containsKey(annualKey);

      final notificationFlagKey = _getNotificationFlagKey(date);
      
      if (repeatAnnually) {
        // Save as annual note (month_day only)
        await prefs.setString(annualKey, note);
        
        // Update note and flag for all years (2025, 2026, 2027)
        final currentYear = DateTime.now().year;
        final yearsToUpdate = [currentYear - 1, currentYear, currentYear + 1];
        for (final year in yearsToUpdate) {
          final otherDate = DateTime(year, date.month, date.day);
          final otherFlagKey = _getAnnualFlagKey(otherDate);
          final otherKey = _getDateKey(otherDate);
          final otherNotificationFlagKey = _getNotificationFlagKey(otherDate);
          await prefs.setBool(otherFlagKey, true);
          await prefs.setString(otherKey, note);
          // Set notification flag for annual notes
          await prefs.setBool(otherNotificationFlagKey, enableNotification);
        }
        
        return true;
      } else {
        // Save as regular note
        final key = _getDateKey(date);
        final flagKey = _getAnnualFlagKey(date);
        await prefs.setString(key, note);
        await prefs.setBool(notificationFlagKey, enableNotification);
        await prefs.remove(flagKey); // Remove annual flag if it exists
        
        // If it was previously annual, remove the annual note template and all instances
        if (wasAnnual) {
          await prefs.remove(annualKey);
          // Remove flags and note instances for all years (except current date)
          final currentYear = DateTime.now().year;
          final yearsToUpdate = [currentYear - 1, currentYear, currentYear + 1];
          for (final year in yearsToUpdate) {
            final otherDate = DateTime(year, date.month, date.day);
            // Only remove if it's not the current date being edited
            if (otherDate.year != date.year || otherDate.month != date.month || otherDate.day != date.day) {
              final otherFlagKey = _getAnnualFlagKey(otherDate);
              final otherKey = _getDateKey(otherDate);
              final otherNotificationFlagKey = _getNotificationFlagKey(otherDate);
              await prefs.remove(otherFlagKey);
              await prefs.remove(otherKey);
              await prefs.remove(otherNotificationFlagKey);
            }
          }
        }
        
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get a note for a specific date (checks both regular and annual notes)
  static Future<Map<String, dynamic>?> getNote(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // First check for regular note
      final key = _getDateKey(date);
      final note = prefs.getString(key);
      if (note != null) {
        final flagKey = _getAnnualFlagKey(date);
        final notificationFlagKey = _getNotificationFlagKey(date);
        final isAnnual = prefs.getBool(flagKey) ?? false;
        final hasNotification = prefs.getBool(notificationFlagKey) ?? false;
        return {
          'note': note,
          'repeatAnnually': isAnnual,
          'notificationEnabled': hasNotification,
        };
      }
      
      // If no regular note, check for annual note
      final annualKey = _getAnnualDateKey(date);
      final annualNote = prefs.getString(annualKey);
      if (annualNote != null) {
        final notificationFlagKey = _getNotificationFlagKey(date);
        final hasNotification = prefs.getBool(notificationFlagKey) ?? false;
        return {
          'note': annualNote,
          'repeatAnnually': true,
          'notificationEnabled': hasNotification,
        };
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete a note for a specific date
  static Future<bool> deleteNote(DateTime date, {bool deleteAnnual = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getDateKey(date);
      final flagKey = _getAnnualFlagKey(date);
      final isAnnual = prefs.getBool(flagKey) ?? false;
      
      final notificationFlagKey = _getNotificationFlagKey(date);
      
      if (isAnnual) {
        // If it's an annual note, delete from all years
        final annualKey = _getAnnualDateKey(date);
        await prefs.remove(annualKey);
        
        // Remove all note instances and flags for this date across all years
        final currentYear = DateTime.now().year;
        final yearsToUpdate = [currentYear - 1, currentYear, currentYear + 1];
        for (final year in yearsToUpdate) {
          final otherDate = DateTime(year, date.month, date.day);
          final otherFlagKey = _getAnnualFlagKey(otherDate);
          final otherKey = _getDateKey(otherDate);
          final otherNotificationFlagKey = _getNotificationFlagKey(otherDate);
          await prefs.remove(otherFlagKey);
          await prefs.remove(otherKey);
          await prefs.remove(otherNotificationFlagKey);
        }
      } else {
        // If it's a regular note, just delete this one
        await prefs.remove(key);
        await prefs.remove(flagKey);
        await prefs.remove(notificationFlagKey);
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all notes (including annual repeats for current year range)
  static Future<Map<DateTime, Map<String, dynamic>>> getAllNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final notes = <DateTime, Map<String, dynamic>>{};
      final currentYear = DateTime.now().year;
      final yearsToCheck = [currentYear - 1, currentYear, currentYear + 1]; // 2025, 2026, 2027

      // First, collect all regular notes
      for (final key in allKeys) {
        if (key.startsWith(_notesPrefix)) {
          final dateStr = key.substring(_notesPrefix.length);
          final parts = dateStr.split('_');
          if (parts.length == 3) {
            final year = int.tryParse(parts[0]);
            final month = int.tryParse(parts[1]);
            final day = int.tryParse(parts[2]);
            if (year != null && month != null && day != null) {
              final date = DateTime(year, month, day);
              final note = prefs.getString(key);
              if (note != null) {
                final flagKey = _getAnnualFlagKey(date);
                final notificationFlagKey = _getNotificationFlagKey(date);
                final isAnnual = prefs.getBool(flagKey) ?? false;
                final hasNotification = prefs.getBool(notificationFlagKey) ?? false;
                notes[date] = {
                  'note': note,
                  'repeatAnnually': isAnnual,
                  'notificationEnabled': hasNotification,
                };
              }
            }
          }
        }
      }

      // Then, add annual notes for the years we're checking
      for (final key in allKeys) {
        if (key.startsWith(_annualNotesPrefix)) {
          final dateStr = key.substring(_annualNotesPrefix.length);
          final parts = dateStr.split('_');
          if (parts.length == 2) {
            final month = int.tryParse(parts[0]);
            final day = int.tryParse(parts[1]);
            if (month != null && day != null) {
              final note = prefs.getString(key);
              if (note != null) {
                // Add this annual note for each year we're checking
                for (final year in yearsToCheck) {
                  final date = DateTime(year, month, day);
                  // Only add if there's no regular note for this date
                  if (!notes.containsKey(date)) {
                    final notificationFlagKey = _getNotificationFlagKey(date);
                    final hasNotification = prefs.getBool(notificationFlagKey) ?? false;
                    notes[date] = {
                      'note': note,
                      'repeatAnnually': true,
                      'notificationEnabled': hasNotification,
                    };
                  }
                }
              }
            }
          }
        }
      }

      return notes;
    } catch (e) {
      return {};
    }
  }
}
