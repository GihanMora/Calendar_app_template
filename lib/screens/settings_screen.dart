import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/state_provider.dart';
import '../providers/language_provider.dart';
import '../services/ads_service.dart';
import '../services/notification_service.dart';
import '../config/app_config.dart';
import '../utils/localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _daysBefore = 1;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 19, minute: 0); // Default 7 PM
  bool _notifyForAllHolidays = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final settings = await NotificationService.getNotificationSettings();
    if (mounted) {
      setState(() {
        _daysBefore = settings['daysBefore'] ?? 1;
        _notificationTime = TimeOfDay(
          hour: settings['hour'] ?? 19,
          minute: settings['minute'] ?? 0,
        );
        _notifyForAllHolidays = settings['notifyForAllHolidays'] ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, StateProvider, LanguageProvider>(
      builder: (context, themeProvider, stateProvider, languageProvider, child) {
        final language = languageProvider.language;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalization.getText('settings', language)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalization.getText('appearance', language),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: Text(AppLocalization.getText('theme', language)),
                    subtitle: Text(_getCurrentThemeName(language)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(language),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: Text(AppLocalization.getText('language', language)),
                    subtitle: Text(_getCurrentLanguageName(language)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(language),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(AppLocalization.getText('year_format', language)),
                    subtitle: Text(_getCurrentYearFormatName(stateProvider, language)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showYearFormatDialog(stateProvider, language),
                  ),
                ),
                if (AppConfig.enableStates) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(AppLocalization.getText('state_territory', language)),
                      subtitle: Text(stateProvider.selectedStateName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showStateDialog(stateProvider, language),
                    ),
                  ),
                ],
                // The whole Holidays section only makes sense when there is
                // something to show under it. Its only control is the school-
                // holidays toggle, so gate the header too — otherwise (e.g.
                // Thailand, where enableSchoolHolidays is false) an empty
                // "Holidays" header renders with nothing beneath it.
                if (AppConfig.enableSchoolHolidays) ...[
                  const SizedBox(height: 24),
                  Text(
                    AppLocalization.getText('holidays', language),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      secondary: const Icon(Icons.school_outlined),
                      title: Text(AppLocalization.getText('show_school_holidays', language)),
                      subtitle: Text(AppLocalization.getText('school_holidays_desc', language)),
                      value: stateProvider.showSchoolHolidays,
                      onChanged: (value) {
                        stateProvider.setShowSchoolHolidays(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value 
                                  ? AppLocalization.getText('school_holidays_enabled', language)
                                  : AppLocalization.getText('school_holidays_disabled', language),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  AppLocalization.getText('notifications', language),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: Text(AppLocalization.getText('notification_time', language)),
                        subtitle: Text(
                          '${_daysBefore} ${_daysBefore != 1 ? AppLocalization.getText('days_before', language) : AppLocalization.getText('day_before', language)} at ${_notificationTime.format(context)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showNotificationTimeDialog(language),
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.event),
                        title: Text(AppLocalization.getText('notify_all_holidays', language)),
                        subtitle: Text(AppLocalization.getText('notify_all_holidays_desc', language)),
                        value: _notifyForAllHolidays,
                        onChanged: (value) async {
                          await NotificationService.saveHolidayNotificationSetting(value);
                          if (mounted) {
                            setState(() {
                              _notifyForAllHolidays = value;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? AppLocalization.getText('holiday_notifications_enabled', language)
                                        : AppLocalization.getText('holiday_notifications_disabled', language),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Developer-only diagnostic — hidden from release builds so it
                // never ships in the production settings menu.
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.bug_report_outlined),
                      title: Text(AppLocalization.getText('debug_notifications', language)),
                      subtitle: Text(AppLocalization.getText('debug_notifications_desc', language)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _debugNotifications(context),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  AppLocalization.getText('about', language),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(AppLocalization.getText('app_title', language)),
                    subtitle: Text('${AppLocalization.getText('version', language)} 1.0.0'),
                  ),
                ),
              ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getCurrentThemeName(String language) {
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    switch (themeMode) {
      case ThemeMode.system:
        return AppLocalization.getText('system_default', language);
      case ThemeMode.light:
        return AppLocalization.getText('light_theme', language);
      case ThemeMode.dark:
        return AppLocalization.getText('dark_theme', language);
    }
  }

  String _getCurrentLanguageName(String language) {
    return language == 'th' 
        ? AppLocalization.getText('thai', language)
        : AppLocalization.getText('english', language);
  }

  void _showThemeDialog(String language) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalization.getText('theme', language)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(AppLocalization.getText('system_default', language)),
              value: ThemeMode.system,
              groupValue: _getCurrentThemeMode(),
              onChanged: (value) => _changeTheme(value!, language),
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppLocalization.getText('light_theme', language)),
              value: ThemeMode.light,
              groupValue: _getCurrentThemeMode(),
              onChanged: (value) => _changeTheme(value!, language),
            ),
            RadioListTile<ThemeMode>(
              title: Text(AppLocalization.getText('dark_theme', language)),
              value: ThemeMode.dark,
              groupValue: _getCurrentThemeMode(),
              onChanged: (value) => _changeTheme(value!, language),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalization.getText('close', language)),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(String language) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalization.getText('language', language)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _getCurrentLanguage(),
              onChanged: (value) => _changeLanguage(value!, language),
            ),
            RadioListTile<String>(
              title: const Text('ไทย (Thai)'),
              value: 'th',
              groupValue: _getCurrentLanguage(),
              onChanged: (value) => _changeLanguage(value!, language),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalization.getText('close', language)),
          ),
        ],
      ),
    );
  }

  String _getCurrentLanguage() {
    return Provider.of<LanguageProvider>(context, listen: false).language;
  }

  void _changeLanguage(String newLanguage, String currentLanguage) async {
    if (newLanguage == currentLanguage) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop();
    Provider.of<LanguageProvider>(context, listen: false).setLanguage(newLanguage);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${AppLocalization.getText('language_changed', newLanguage)} ${newLanguage == 'th' ? 'ไทย' : 'English'}')),
    );
  }

  String _getCurrentYearFormatName(StateProvider stateProvider, String language) {
    return stateProvider.useBuddhistEra 
        ? AppLocalization.getText('buddhist_era', language)
        : AppLocalization.getText('international', language);
  }

  void _showYearFormatDialog(StateProvider stateProvider, String language) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalization.getText('year_format', language)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: Text(AppLocalization.getText('buddhist_era', language)),
              subtitle: Text(language == 'th' ? 'ปี ${StateProvider.toBuddhistYear(DateTime.now().year)}' : 'Year ${StateProvider.toBuddhistYear(DateTime.now().year)}'),
              value: true,
              groupValue: stateProvider.useBuddhistEra,
              onChanged: (value) => _changeYearFormat(stateProvider, value!, language),
            ),
            RadioListTile<bool>(
              title: Text(AppLocalization.getText('international', language)),
              subtitle: Text(language == 'th' ? 'ปี ${DateTime.now().year}' : 'Year ${DateTime.now().year}'),
              value: false,
              groupValue: stateProvider.useBuddhistEra,
              onChanged: (value) => _changeYearFormat(stateProvider, value!, language),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalization.getText('close', language)),
          ),
        ],
      ),
    );
  }

  void _changeYearFormat(StateProvider stateProvider, bool useBuddhistEra, String language) {
    if (useBuddhistEra == stateProvider.useBuddhistEra) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop();
    stateProvider.setUseBuddhistEra(useBuddhistEra);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${AppLocalization.getText('year_format_changed', language)} ${useBuddhistEra ? AppLocalization.getText('buddhist_era', language) : AppLocalization.getText('international', language)}')),
    );
  }

  ThemeMode _getCurrentThemeMode() {
    return Provider.of<ThemeProvider>(context, listen: false).themeMode;
  }

  void _changeTheme(ThemeMode themeMode, String language) {
    if (!mounted) return;
    
    final current = _getCurrentThemeMode();
    if (themeMode == current) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    // Gate Light/Dark behind rewarded ad with the same dialog language as About Us
    if (themeMode != ThemeMode.system) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      _showRewardDialog(
        title: AppLocalization.getText('theme_change', language),
        message: AppLocalization.getText('watch_ad_message', language),
        language: language,
        onRewardOk: () {
          if (mounted && context.mounted) {
            Provider.of<ThemeProvider>(context, listen: false).setThemeMode(themeMode);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${AppLocalization.getText('theme_changed', language)} ${_getThemeName(themeMode, language)}')),
            );
          }
        },
      );
      return;
    }
    if (mounted && context.mounted) {
      Provider.of<ThemeProvider>(context, listen: false).setThemeMode(themeMode);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalization.getText('theme_changed', language)} ${_getThemeName(themeMode, language)}')),
      );
    }
  }

  Future<void> _showRewardDialog({required String title, required String message, required String language, required VoidCallback onRewardOk}) async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalization.getText('cancel', language)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalization.getText('watch_ad', language)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await AdsService.showRewarded();
      if (!mounted) return;
      if (ok) {
        onRewardOk();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalization.getText('ad_not_available', language))),
          );
        }
      }
    }
  }

  void _showStateDialog(StateProvider stateProvider, String language) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalization.getText('select_state', language)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: StateProvider.states.map((state) {
              return RadioListTile<String>(
                title: Text(state['name']!),
                value: state['code']!,
                groupValue: stateProvider.selectedState,
                onChanged: (value) {
                  if (value != null) {
                    stateProvider.setSelectedState(value);
                    Navigator.of(dialogContext).pop();
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${AppLocalization.getText('showing_holidays_for', language)} ${state['name']}'),
                        ),
                      );
                    }
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalization.getText('close', language)),
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode, String language) {
    switch (mode) {
      case ThemeMode.system:
        return AppLocalization.getText('system_default', language);
      case ThemeMode.light:
        return AppLocalization.getText('light_theme', language);
      case ThemeMode.dark:
        return AppLocalization.getText('dark_theme', language);
    }
  }

  Future<void> _showNotificationTimeDialog(String language) async {
    if (!mounted) return;
    
    int daysBefore = _daysBefore;
    TimeOfDay selectedTime = _notificationTime;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalization.getText('notification_settings', language)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalization.getText('days_before_event', language),
                      style: Theme.of(dialogContext).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: daysBefore.toDouble(),
                            min: 0,
                            max: 7,
                            divisions: 7,
                            label: '$daysBefore ${daysBefore != 1 ? AppLocalization.getText('days_before', language) : AppLocalization.getText('day_before', language)}',
                            onChanged: (value) {
                              setDialogState(() {
                                daysBefore = value.toInt();
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '$daysBefore',
                            textAlign: TextAlign.center,
                            style: Theme.of(dialogContext).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalization.getText('time', language),
                      style: Theme.of(dialogContext).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text(
                        selectedTime.format(dialogContext),
                        style: Theme.of(dialogContext).textTheme.titleMedium,
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime,
                        );
                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Theme.of(dialogContext).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalization.getText('cancel', language)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop({
                    'daysBefore': daysBefore,
                    'time': selectedTime,
                  }),
                  child: Text(AppLocalization.getText('save', language)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      final days = result['daysBefore'] as int;
      final time = result['time'] as TimeOfDay;

      await NotificationService.saveNotificationSettings(
        daysBefore: days,
        hour: time.hour,
        minute: time.minute,
      );

      if (mounted) {
        setState(() {
          _daysBefore = days;
          _notificationTime = time;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalization.getText('notification_settings_saved', language))),
          );
        }
      }
    }
  }

  Future<void> _debugNotifications(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.debugPendingNotifications();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Get pending notifications to show in dialog
        final pending = await notificationService.getPendingNotifications();
        final settings = await NotificationService.getNotificationSettings();
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Notification Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current Settings:', style: Theme.of(context).textTheme.titleSmall),
                  Text('  • Days before: ${settings['daysBefore']}'),
                  Text('  • Time: ${settings['hour']?.toString().padLeft(2, '0')}:${settings['minute']?.toString().padLeft(2, '0')}'),
                  const SizedBox(height: 16),
                  Text('Pending Notifications: ${pending.length}', style: Theme.of(context).textTheme.titleSmall),
                  if (pending.isEmpty)
                    const Text('  No pending notifications found.')
                  else
                    ...pending.take(10).map((n) => Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('  • ID: ${n.id}\n    ${n.title}'),
                    )),
                  if (pending.length > 10)
                    Text('  ... and ${pending.length - 10} more'),
                  const SizedBox(height: 16),
                  const Text(
                    'Check console/logs for detailed information including scheduled times.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
