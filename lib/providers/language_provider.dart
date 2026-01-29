import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  String _language = 'en'; // Default to English

  String get language => _language;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null && (savedLanguage == 'en' || savedLanguage == 'th')) {
        _language = savedLanguage;
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, use default (English)
    }
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    notifyListeners();
    
    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language);
    } catch (e) {
      // If saving fails, continue anyway
    }
  }

  bool get isThai => _language == 'th';
  bool get isEnglish => _language == 'en';
}
