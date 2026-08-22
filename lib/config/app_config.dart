import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// App Configuration
/// 
/// This file loads configuration from config/country_x.json.
/// Edit ONLY the JSON file - values are loaded at app startup.

class AppConfig {
  static bool _isInitialized = false;
  static Map<String, dynamic> _config = {};
  
  // Default fallback values (used if JSON fails to load)
  static const String _defaultCountryName = 'X';
  static const String _defaultAppName = 'X Calendar';
  static const String _defaultAppIcon = 'assets/icons/app_icon.png';
  static const String _defaultPackageName = 'com.gihan.thaicalendar';
  static const String _defaultApplicationId = 'com.gihan.thaicalendar';
  static const String _defaultPublicHolidaysJson = 'config/th_public_holidays_2025_2027.json';
  static const String _defaultSchoolHolidaysJson = 'config/th_school_holidays_2025_2027.json';
  static const bool _defaultEnableStates = true;
  static const bool _defaultEnableSchoolHolidays = true;
  static const String _defaultPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.gihan.thaicalendar';
  static const String _defaultAdmobAppId = 'ca-app-pub-5202253201958912~5352519435';
  static const String _defaultBannerAdUnitId = 'ca-app-pub-5202253201958912/8149781586';
  static const String _defaultInterstitialAdUnitId = 'ca-app-pub-5202253201958912/2794239473';
  static const String _defaultRewardedAdUnitId = 'ca-app-pub-5202253201958912/7459516442';
  static const String _defaultNativeAdUnitId = 'ca-app-pub-5202253201958912/1768932415';

  // AdMob ad units are platform-specific: the ids above/JSON are the ANDROID
  // units. These are the real iOS units, pairing with the real iOS
  // GADApplicationIdentifier in ios/Runner/Info.plist.
  static const String _iosBannerAdUnitId = 'ca-app-pub-5202253201958912/8467574533';
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-5202253201958912/8467574533';
  static const String _iosRewardedAdUnitId = 'ca-app-pub-5202253201958912/1902166180';
  static const String _iosNativeAdUnitId = 'ca-app-pub-5202253201958912/1475780456';
  
  /// Initialize config by loading from JSON file
  /// Must be called before using any AppConfig values
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final String jsonString = await rootBundle.loadString('config/country_x.json');
      _config = json.decode(jsonString) as Map<String, dynamic>;
      _isInitialized = true;
      print('✅ App config loaded from country_x.json');
      print('   - appName: ${_config['appName']}');
      print('   - countryName: ${_config['countryName']}');
      print('   - packageName: ${_config['packageName']}');
      print('   - enableStates: ${_config['enableStates']}');
      print('   - enableSchoolHolidays: ${_config['enableSchoolHolidays']}');
    } catch (e, stackTrace) {
      print('❌ Error loading config from JSON: $e');
      print('Stack trace: $stackTrace');
      print('Using default values');
      _config = {};
      _isInitialized = true;
    }
  }
  
  // Getters that read from loaded JSON config
  static String get countryName => _config['countryName'] as String? ?? _defaultCountryName;
  static String get appName => _config['appName'] as String? ?? _defaultAppName;
  static String get appDescription => '$appName - A Flutter calendar app with public holidays';
  static String get appIcon => _config['appIcon'] as String? ?? _defaultAppIcon;
  
  // Package Information (read from JSON)
  static String get packageName => 
      _config['packageName'] as String? ?? _defaultPackageName;
  static String get applicationId => 
      _config['applicationId'] as String? ?? _defaultApplicationId;
  
  // JSON File Names
  static String get publicHolidaysJsonFile => 
      _config['publicHolidaysJson'] as String? ?? _defaultPublicHolidaysJson;
  static String get schoolHolidaysJsonFile => 
      _config['schoolHolidaysJson'] as String? ?? _defaultSchoolHolidaysJson;
  
  // Feature Flags
  static bool get enableStates => 
      _config['enableStates'] as bool? ?? _defaultEnableStates;
  static bool get enableSchoolHolidays => 
      _config['enableSchoolHolidays'] as bool? ?? _defaultEnableSchoolHolidays;
  
  // Play Store URL (read from JSON)
  static String get playStoreUrl => 
      _config['playStoreUrl'] as String? ?? _defaultPlayStoreUrl;
  
  // AdMob App ID (read from JSON)
  static String get admobAppId => 
      _config['admobAppId'] as String? ?? _defaultAdmobAppId;
  
  // Ad Unit IDs (read from JSON)
  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  // Ad Unit IDs — iOS uses its own units; Android reads from JSON config.
  static String get bannerAdUnitId => _isIOS
      ? _iosBannerAdUnitId
      : (_config['bannerAdUnitId'] as String? ?? _defaultBannerAdUnitId);
  static String get interstitialAdUnitId => _isIOS
      ? _iosInterstitialAdUnitId
      : (_config['interstitialAdUnitId'] as String? ?? _defaultInterstitialAdUnitId);
  static String get rewardedAdUnitId => _isIOS
      ? _iosRewardedAdUnitId
      : (_config['rewardedAdUnitId'] as String? ?? _defaultRewardedAdUnitId);
  static String get nativeAdUnitId => _isIOS
      ? _iosNativeAdUnitId
      : (_config['nativeAdUnitId'] as String? ?? _defaultNativeAdUnitId);
  
  // States/Regions Configuration
  static List<Map<String, String>> get states {
    if (!_isInitialized) {
      return [
        {'code': 'ALL', 'name': 'All Regions'},
      ];
    }
    
    final regions = _config['regions'] as List<dynamic>?;
    if (regions == null || regions.isEmpty) {
      return [
        {'code': 'ALL', 'name': 'All Regions'},
      ];
    }
    
    return regions.map((region) {
      final regionMap = region as Map<String, dynamic>;
      return {
        'code': regionMap['code'] as String? ?? '',
        'name': regionMap['name'] as String? ?? '',
      };
    }).toList();
  }
  
  // State names mapping
  static Map<String, String> get stateNames {
    final stateList = states;
    final Map<String, String> names = {};
    for (final state in stateList) {
      names[state['code']!] = state['name']!;
    }
    return names;
  }
  
  // About Screen Text (generated from config)
  static String get aboutScreenText {
    final country = countryName;
    final app = appName;
    return '''$app
This app provides a complete and updated calendar with $country public holidays${enableSchoolHolidays ? ' and school holidays' : ''}${enableStates ? ' by region' : ''}.

Features:
• All public holidays: National${enableStates ? ' and region-specific' : ''} holidays${enableSchoolHolidays ? '\n• School holidays: School holiday periods${enableStates ? ' by region' : ''}' : ''}${enableStates ? '\n• Region selection: Filter holidays by your region or view all' : ''}
• Personal notes: Add notes to any date
• Offline access: All holiday data included

A great helper to plan your daily activities and stay informed about holidays${enableStates ? ' across $country' : ' in $country'}.''';
  }
  
  // Share Text
  static String getShareText() {
    return 'Check out the $appName app: $playStoreUrl&pcampaignid=web_share';
  }
}
