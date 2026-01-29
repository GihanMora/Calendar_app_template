import 'dart:convert';
import 'package:flutter/services.dart';
import '../config/app_config.dart';

class Holiday {
  final String date;
  final String weekday;
  final String holidayName;
  final String holidayNameTH;
  final String type;
  final List<String> states;

  Holiday({
    required this.date,
    required this.weekday,
    required this.holidayName,
    required this.holidayNameTH,
    required this.type,
    required this.states,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      date: json['Date'] ?? '',
      weekday: json['Weekday'] ?? '',
      holidayName: json['Holiday Name'] ?? '',
      holidayNameTH: json['Holiday Name TH'] ?? json['Holiday Name'] ?? '',
      type: json['Type'] ?? '',
      states: List<String>.from(json['States'] ?? ['ALL']),
    );
  }

  /// Get the holiday name based on the language code
  /// Returns Thai name if language is 'th', otherwise English name
  String getName(String language) {
    if (language == 'th' && holidayNameTH.isNotEmpty) {
      return holidayNameTH;
    }
    return holidayName;
  }

  bool isApplicableForState(String selectedState) {
    return states.contains('ALL') || states.contains(selectedState);
  }
}

class HolidayService {
  static List<Holiday> _holidays = [];
  static bool _isLoaded = false;
  static String _selectedState = 'ALL';

  static Future<void> loadHolidays({bool forceReload = false}) async {
    if (_isLoaded && !forceReload) return;
    if (forceReload) {
      _isLoaded = false;
      _holidays = [];
    }

    try {
      final String jsonString = await rootBundle.loadString(AppConfig.publicHolidaysJsonFile);
      final List<dynamic> jsonList = json.decode(jsonString);
      _holidays = jsonList.map((json) {
        try {
          return Holiday.fromJson(json);
        } catch (e) {
          print('Error parsing holiday entry: $e, JSON: $json');
          return null;
        }
      }).whereType<Holiday>().toList();
      _isLoaded = true;
      print('Loaded ${_holidays.length} holidays successfully');
    } catch (e, stackTrace) {
      print('Error loading holidays: $e');
      print('Stack trace: $stackTrace');
      _holidays = [];
      _isLoaded = false; // Reset so it can be retried
    }
  }

  static void setSelectedState(String state) {
    _selectedState = state;
  }

  static String getSelectedState() {
    return _selectedState;
  }

  static Holiday? getHolidayForDate(DateTime date, {String? state}) {
    final selectedState = state ?? _selectedState;
    final dateString = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      return _holidays.firstWhere(
        (holiday) => holiday.date == dateString && holiday.isApplicableForState(selectedState)
      );
    } catch (e) {
      return null;
    }
  }

  static bool isHoliday(DateTime date, {String? state}) {
    return getHolidayForDate(date, state: state) != null;
  }

  static bool isStateHoliday(DateTime date, {String? state}) {
    final holiday = getHolidayForDate(date, state: state);
    if (holiday == null) return false;
    final t = holiday.type.toLowerCase();
    return t.contains('state');
  }

  static String? getTypesForDate(DateTime date, {String? state}) {
    final holiday = getHolidayForDate(date, state: state);
    return holiday?.type;
  }

  static List<Holiday> getAllHolidays({String? state}) {
    final selectedState = state ?? _selectedState;
    if (selectedState == 'ALL') {
    return List.from(_holidays);
    }
    return _holidays.where((h) => h.isApplicableForState(selectedState)).toList();
  }
}
