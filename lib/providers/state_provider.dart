import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/holiday_service.dart';
import '../config/app_config.dart';

class StateProvider extends ChangeNotifier {
  String _selectedState = 'ALL';
  bool _showSchoolHolidays = false;
  bool _useBuddhistEra = false; // Buddhist Era (BE) vs International (Gregorian)

  StateProvider() {
    _loadState();
  }

  String get selectedState => _selectedState;
  bool get showSchoolHolidays => _showSchoolHolidays;
  bool get useBuddhistEra => _useBuddhistEra;

  /// Convert Gregorian year to Buddhist Era (BE) year
  /// Buddhist Era is 543 years ahead of Gregorian calendar
  static int toBuddhistYear(int gregorianYear) {
    return gregorianYear + 543;
  }

  /// Get the display year based on current setting
  int getDisplayYear(int gregorianYear) {
    return _useBuddhistEra ? toBuddhistYear(gregorianYear) : gregorianYear;
  }

  /// Get formatted year string with optional suffix
  String getFormattedYear(int gregorianYear) {
    if (_useBuddhistEra) {
      return '${toBuddhistYear(gregorianYear)}';
    }
    return '$gregorianYear';
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // If states are disabled, always use 'ALL'
      _selectedState = AppConfig.enableStates 
          ? (prefs.getString('selected_state') ?? 'ALL')
          : 'ALL';
      // If school holidays are disabled, don't show them
      _showSchoolHolidays = AppConfig.enableSchoolHolidays 
          ? (prefs.getBool('show_school_holidays') ?? false)
          : false;
      // Load Buddhist Era preference
      _useBuddhistEra = prefs.getBool('use_buddhist_era') ?? false;
      HolidayService.setSelectedState(_selectedState);
      notifyListeners();
    } catch (e) {
      print('Error loading state: $e');
    }
  }

  Future<void> setSelectedState(String state) async {
    // If states are disabled, always use 'ALL'
    if (!AppConfig.enableStates) {
      _selectedState = 'ALL';
      HolidayService.setSelectedState('ALL');
      notifyListeners();
      return;
    }
    
    _selectedState = state;
    HolidayService.setSelectedState(state);
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_state', state);
    } catch (e) {
      print('Error saving state: $e');
    }
  }

  Future<void> setShowSchoolHolidays(bool value) async {
    // If school holidays are disabled in config, don't allow enabling
    if (!AppConfig.enableSchoolHolidays) {
      _showSchoolHolidays = false;
      notifyListeners();
      return;
    }
    
    _showSchoolHolidays = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_school_holidays', value);
    } catch (e) {
      print('Error saving school holidays preference: $e');
    }
  }

  Future<void> setUseBuddhistEra(bool value) async {
    _useBuddhistEra = value;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_buddhist_era', value);
    } catch (e) {
      print('Error saving Buddhist Era preference: $e');
    }
  }

  String get selectedStateName {
    return AppConfig.stateNames[_selectedState] ?? _selectedState;
  }

  static List<Map<String, String>> get states => AppConfig.states;
}

