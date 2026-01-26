import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/state_provider.dart';
import '../services/ads_service.dart';
import '../services/notification_service.dart';
import '../config/app_config.dart';

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
    return Consumer2<ThemeProvider, StateProvider>(
      builder: (context, themeProvider, stateProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme'),
                    subtitle: Text(_getCurrentThemeName()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(),
                  ),
                ),
                if (AppConfig.enableStates) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('State/Territory'),
                      subtitle: Text(stateProvider.selectedStateName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showStateDialog(stateProvider),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Holidays',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (AppConfig.enableSchoolHolidays) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      secondary: const Icon(Icons.school_outlined),
                      title: const Text('Show School Holidays'),
                      subtitle: const Text('Display school holiday ranges on calendar'),
                      value: stateProvider.showSchoolHolidays,
                      onChanged: (value) {
                        stateProvider.setShowSchoolHolidays(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value ? 'School holidays enabled' : 'School holidays disabled',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Notifications',
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
                        title: const Text('Notification Time'),
                        subtitle: Text(
                          '${_daysBefore} day${_daysBefore != 1 ? 's' : ''} before at ${_notificationTime.format(context)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showNotificationTimeDialog(),
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.event),
                        title: const Text('Notify for All Holidays'),
                        subtitle: const Text('Get notifications for all public holidays'),
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
                                        ? 'Holiday notifications enabled'
                                        : 'Holiday notifications disabled',
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
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Debug Notifications'),
                    subtitle: const Text('Check pending notifications and settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _debugNotifications(context),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Calendar'),
                    subtitle: const Text('Version 1.0.0'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCurrentThemeName() {
    final themeMode = Provider.of<ThemeProvider>(context, listen: false).themeMode;
    switch (themeMode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.dark:
        return 'Dark Theme';
    }
  }

  void _showThemeDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: _getCurrentThemeMode(),
              onChanged: (value) => _changeTheme(value!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light Theme'),
              value: ThemeMode.light,
              groupValue: _getCurrentThemeMode(),
              onChanged: (value) => _changeTheme(value!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Theme'),
              value: ThemeMode.dark,
              groupValue: _getCurrentThemeMode(),
              onChanged: (value) => _changeTheme(value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  ThemeMode _getCurrentThemeMode() {
    return Provider.of<ThemeProvider>(context, listen: false).themeMode;
  }

  void _changeTheme(ThemeMode themeMode) {
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
        title: 'Theme change',
        message: 'In order to do this, please watch a rewarded ad.',
        onRewardOk: () {
          if (mounted && context.mounted) {
            Provider.of<ThemeProvider>(context, listen: false).setThemeMode(themeMode);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Theme changed to ${_getThemeName(themeMode)}')),
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
        SnackBar(content: Text('Theme changed to ${_getThemeName(themeMode)}')),
      );
    }
  }

  Future<void> _showRewardDialog({required String title, required String message, required VoidCallback onRewardOk}) async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Watch Ad'),
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
            const SnackBar(content: Text('Ad not available. Please try again later.')),
          );
        }
      }
    }
  }

  void _showStateDialog(StateProvider stateProvider) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select State/Territory'),
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
                          content: Text('Showing holidays for ${state['name']}'),
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.dark:
        return 'Dark Theme';
    }
  }

  Future<void> _showNotificationTimeDialog() async {
    if (!mounted) return;
    
    int daysBefore = _daysBefore;
    TimeOfDay selectedTime = _notificationTime;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Notification Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Days before event',
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
                            label: '$daysBefore day${daysBefore != 1 ? 's' : ''}',
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
                      'Time',
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
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop({
                    'daysBefore': daysBefore,
                    'time': selectedTime,
                  }),
                  child: const Text('Save'),
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
            const SnackBar(content: Text('Notification settings saved')),
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
