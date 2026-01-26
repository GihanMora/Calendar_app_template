import 'dart:convert';
import 'package:flutter/services.dart';
import '../config/app_config.dart';

class SchoolHoliday {
  final String name;
  final String startDate;
  final String endDate;
  final List<String> states;

  SchoolHoliday({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.states,
  });

  factory SchoolHoliday.fromJson(Map<String, dynamic> json) {
    return SchoolHoliday(
      name: json['Name'] ?? '',
      startDate: json['StartDate'] ?? '',
      endDate: json['EndDate'] ?? '',
      states: List<String>.from(json['States'] ?? []),
    );
  }

  bool isApplicableForState(String selectedState) {
    return selectedState == 'ALL' || states.contains(selectedState);
  }

  DateTime get startDateTime => DateTime.parse(startDate);
  DateTime get endDateTime => DateTime.parse(endDate);

  bool isDateInRange(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
    final end = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
    return (dateOnly.isAfter(start) || dateOnly.isAtSameMomentAs(start)) &&
           (dateOnly.isBefore(end) || dateOnly.isAtSameMomentAs(end));
  }
}

class SchoolHolidayService {
  static List<SchoolHoliday> _holidays = [];
  static bool _isLoaded = false;

  static Future<void> loadSchoolHolidays({bool forceReload = false}) async {
    // Don't load if school holidays are disabled in config
    if (!AppConfig.enableSchoolHolidays) {
      _holidays = [];
      _isLoaded = true;
      return;
    }
    
    if (_isLoaded && !forceReload) return;
    if (forceReload) {
      _isLoaded = false;
      _holidays = [];
    }

    try {
      final String jsonString = await rootBundle.loadString(AppConfig.schoolHolidaysJsonFile);
      final List<dynamic> jsonList = json.decode(jsonString);
      _holidays = jsonList.map((json) {
        try {
          return SchoolHoliday.fromJson(json);
        } catch (e) {
          print('Error parsing school holiday entry: $e, JSON: $json');
          return null;
        }
      }).whereType<SchoolHoliday>().toList();
      _isLoaded = true;
      print('Loaded ${_holidays.length} school holidays successfully');
    } catch (e, stackTrace) {
      print('Error loading school holidays: $e');
      print('Stack trace: $stackTrace');
      _holidays = [];
      _isLoaded = false; // Reset so it can be retried
    }
  }

  static SchoolHoliday? getSchoolHolidayForDate(DateTime date, String selectedState) {
    if (!AppConfig.enableSchoolHolidays) return null;
    try {
      return _holidays.firstWhere(
        (holiday) => holiday.isDateInRange(date) && holiday.isApplicableForState(selectedState)
      );
    } catch (e) {
      return null;
    }
  }

  static bool isSchoolHoliday(DateTime date, String selectedState) {
    if (!AppConfig.enableSchoolHolidays) return false;
    return getSchoolHolidayForDate(date, selectedState) != null;
  }

  static List<SchoolHoliday> getAllSchoolHolidays({String? state}) {
    if (!AppConfig.enableSchoolHolidays) return [];
    if (state == null || state == 'ALL') {
      return _holidays;
    }
    return _holidays.where((holiday) => holiday.isApplicableForState(state)).toList();
  }
}

