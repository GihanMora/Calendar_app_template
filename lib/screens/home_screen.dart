import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/month_view.dart';
import '../widgets/banner_ad_widget.dart';
import 'settings_screen.dart';
import 'public_holidays_screen.dart';
import '../services/ads_service.dart';
import 'about_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'year_view_screen.dart';
import '../services/holiday_service.dart';
import '../services/school_holiday_service.dart';
import '../services/notes_service.dart';
import '../providers/state_provider.dart';
import '../services/notification_service.dart';
import 'my_notes_screen.dart';
import '../config/app_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _anchor = _stripTime(DateTime.now());
  DateTime? _selectedDate;
  final TextEditingController _notesController = TextEditingController();
  String? _currentNote;
  DateTime? _lastSavedDate;
  bool _isEditMode = false;
  bool _repeatAnnually = false;
  bool _notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    // Ensure holidays are loaded and today's date is selected so notes appear immediately
    HolidayService.loadHolidays().then((_) {
      if (mounted) {
        final today = _stripTime(DateTime.now());
        setState(() {
          _selectedDate = today;
        });
        _loadNoteForDate(today);
      }
    });
    SchoolHolidayService.loadSchoolHolidays();
  }

  @override
  void dispose() {
    // Save current note before disposing if in edit mode
    if (_isEditMode && _selectedDate != null) {
      NotesService.saveNote(_selectedDate!, _notesController.text, repeatAnnually: _repeatAnnually);
    }
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadNoteForDate(DateTime date) async {
    final noteData = await NotesService.getNote(date);
    if (mounted) {
      setState(() {
        _currentNote = noteData?['note'];
        _notesController.text = noteData?['note'] ?? '';
        _repeatAnnually = noteData?['repeatAnnually'] ?? false;
        // Default to true for new notes, but respect saved value for existing notes
        _notificationEnabled = noteData?['notificationEnabled'] ?? true;
        _lastSavedDate = date;
        _isEditMode = false; // Exit edit mode when loading a new date
      });
    }
  }

  Future<void> _saveNote(DateTime date, String note) async {
    // Get current note data to check if notification was enabled
    final currentNoteData = await NotesService.getNote(date);
    final wasNotificationEnabled = currentNoteData?['notificationEnabled'] == true;
    final wasAnnual = currentNoteData?['repeatAnnually'] == true;

    // Cancel existing notification if it was enabled
    if (wasNotificationEnabled) {
      await NotificationService().cancelNotificationsForDate(
        date,
        isAnnual: wasAnnual,
      );
    }

    // Save note (if note is empty, this will remove it and notifications will be cancelled)
    await NotesService.saveNote(
      date,
      note,
      repeatAnnually: _repeatAnnually,
      enableNotification: _notificationEnabled && note.trim().isNotEmpty,
    );

    // Schedule notification if enabled and note is not empty
    if (_notificationEnabled && note.trim().isNotEmpty) {
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      try {
        if (_repeatAnnually) {
          // For annual notes, schedule for all years
          final currentYear = DateTime.now().year;
          final yearsToSchedule = [currentYear - 1, currentYear, currentYear + 1];
          for (final year in yearsToSchedule) {
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
          // For regular notes, schedule only for this date
          final notificationId = NotificationService.getNotificationId(date);
          await notificationService.scheduleNoteNotification(
            eventDate: date,
            noteText: note,
            notificationId: notificationId,
            isAnnual: false,
          );
        }
        
        // Verify notifications were scheduled
        await notificationService.debugPendingNotifications();
      } catch (e) {
        print('Error scheduling notifications: $e');
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not schedule notifications. Please check app permissions.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _currentNote = note.trim().isEmpty ? null : note;
        _isEditMode = false; // Exit edit mode after saving
      });
    }
  }

  void _toggleEditMode() {
    if (_isEditMode) {
      // Save mode - save the note
      final date = _selectedDate ?? DateTime.now();
      _saveNote(date, _notesController.text);
    } else {
      // Edit mode - enter edit mode
      setState(() {
        _isEditMode = true;
      });
    }
  }

  static DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _goToday() {
    setState(() {
      _anchor = _stripTime(DateTime.now());
    });
  }

  void _prev() {
    setState(() {
      _anchor = DateTime(_anchor.year, _anchor.month - 1, 1);
    });
  }

  void _next() {
    setState(() {
      _anchor = DateTime(_anchor.year, _anchor.month + 1, 1);
    });
  }

  String _titleForAnchor() {
    return DateFormat.y().format(_anchor);
  }

  Future<void> _showAboutRewardDialog() async {
    final color = Theme.of(context).colorScheme;
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('About us'),
          content: const Text('In order to load About Us, please watch a rewarded ad.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('Watch Ad', style: TextStyle(color: color.primary)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final ok = await AdsService.showRewarded();
      if (ok) {
        if (mounted && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          );
        }
      } else {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ad not available at the moment. Please try again.')),
          );
        }
      }
    }
  }

  Future<void> _rateApp() async {
    final url = AppConfig.playStoreUrl;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the Play Store')),
        );
      }
    }
  }

  String _getHolidayText(DateTime date, StateProvider stateProvider) {
    final holiday = HolidayService.getHolidayForDate(date);
    final schoolHoliday = stateProvider.showSchoolHolidays 
        ? SchoolHolidayService.getSchoolHolidayForDate(date, stateProvider.selectedState)
        : null;
    
    if (holiday != null && schoolHoliday != null) {
      final types = HolidayService.getTypesForDate(date);
      final name = holiday.holidayName;
      final holidayText = types != null && types.isNotEmpty ? '$name • ${types.toUpperCase()}' : name;
      return '$holidayText\n🏫 ${schoolHoliday.name}';
    } else if (holiday != null) {
      final types = HolidayService.getTypesForDate(date);
      final name = holiday.holidayName;
      return types != null && types.isNotEmpty ? '$name • ${types.toUpperCase()}' : name;
    } else if (schoolHoliday != null) {
      return '🏫 ${schoolHoliday.name}';
    }
    return 'No special Notes';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateProvider>(
      builder: (context, stateProvider, child) {
        final color = Theme.of(context).colorScheme;
        
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    DateFormat.y().format(_anchor),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () async {
                    if (!mounted) return;
                    await AdsService.ensureLoaded();
                    if (!mounted) return;
                    await AdsService.showIfAvailable(onClosed: () {
                      if (mounted && context.mounted) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const PublicHolidaysScreen()),
                        );
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Holidays',
                      style: TextStyle(
                        color: color.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: false,
            leading: null,
            actions: [
              IconButton(
                tooltip: 'Year view',
                onPressed: () {
                  if (!mounted || !context.mounted) return;
                  Navigator.of(context)
                      .push<DateTime?>(
                        MaterialPageRoute(builder: (context) => const YearViewScreen()),
                      )
                      .then((selectedMonth) {
                    if (selectedMonth != null && mounted) {
                      setState(() {
                        _anchor = DateTime(selectedMonth.year, selectedMonth.month, 1);
                      });
                    }
                  });
                },
                icon: const Icon(Icons.calendar_month),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () {
                  if (!mounted || !context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                icon: const Icon(Icons.settings),
              ),
              const SizedBox(width: 4),
            ],
          ),
          drawer: _buildDrawer(context),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _prev,
                      icon: const Icon(Icons.chevron_left),
                      style: IconButton.styleFrom(
                        backgroundColor: color.surfaceVariant.withOpacity(0.3),
                        foregroundColor: color.onSurface,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            DateFormat('MMMM yyyy').format(_anchor),
                            style: TextStyle(
                              color: color.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _next,
                      icon: const Icon(Icons.chevron_right),
                      style: IconButton.styleFrom(
                        backgroundColor: color.surfaceVariant.withOpacity(0.3),
                        foregroundColor: color.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              // Today indicator - clickable to go to today's month
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: _goToday,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: color.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.today,
                          color: color.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Today is ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: color.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Moved AdMob Banner Ad here to avoid bottom overflow
              const BannerAdWidget(),
              const SizedBox(height: 8),
              MonthView(
                anchor: _anchor,
                onSwipeMonth: (delta) => setState(() {
                  _anchor = DateTime(_anchor.year, _anchor.month + delta, 1);
                }),
                onDateSelected: (date) {
                  // Save current note before switching dates if in edit mode
                  if (_isEditMode && _selectedDate != null) {
                    NotesService.saveNote(_selectedDate!, _notesController.text, repeatAnnually: _repeatAnnually);
                  }
                  setState(() {
                    _selectedDate = date;
                  });
                  if (date != null) {
                    _loadNoteForDate(date);
                  }
                },
              ),
              // Notes segment - positioned immediately after calendar
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.outlineVariant.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDate != null 
                            ? '${_selectedDate!.day} ${DateFormat('MMMM yyyy').format(_selectedDate!)}'
                            : '${DateTime.now().day} ${DateFormat('MMMM yyyy').format(DateTime.now())}',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.w600,
                              color: color.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      // Show holiday info if available
                      Builder(
                        builder: (context) {
                          final date = _selectedDate ?? DateTime.now();
                          final holidayText = _getHolidayText(date, stateProvider);
                          final hasHoliday = HolidayService.getHolidayForDate(date) != null || 
                              (stateProvider.showSchoolHolidays && 
                               SchoolHolidayService.getSchoolHolidayForDate(date, stateProvider.selectedState) != null);
                          if (hasHoliday) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: color.primaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      size: 16,
                                      color: color.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        holidayText,
                                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                              color: color.onPrimaryContainer,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      // Editable notes section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.note,
                                size: 18,
                                color: color.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Notes',
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: color.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                          // Edit/Save button
                          TextButton.icon(
                            onPressed: _toggleEditMode,
                            icon: Icon(
                              _isEditMode ? Icons.save : Icons.edit,
                              size: 18,
                            ),
                            label: Text(
                              _isEditMode ? 'Save' : 'Edit',
                              style: TextStyle(
                                color: color.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Show TextField in edit mode, read-only text in view mode
                      _isEditMode
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _notesController,
                                  maxLines: 4,
                                  minLines: 2,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'Type your notes here...',
                                    hintStyle: TextStyle(
                                      color: color.onSurfaceVariant.withOpacity(0.5),
                                    ),
                                    filled: true,
                                    fillColor: color.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: color.outlineVariant,
                                        width: 1,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: color.outlineVariant.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: color.primary,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        color: color.onSurface,
                                      ),
                                ),
                                // Only show "Repeat annually" and notification toggle when creating NEW note (not editing)
                                if (_currentNote == null || _currentNote!.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Repeat annually',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                      Switch(
                                        value: _repeatAnnually,
                                        onChanged: (value) {
                                          setState(() {
                                            _repeatAnnually = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Builder(
                                    builder: (context) {
                                      final selectedDate = _selectedDate ?? DateTime.now();
                                      final today = DateTime.now();
                                      final todayOnly = DateTime(today.year, today.month, today.day);
                                      final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
                                      final isPastDate = selectedDateOnly.isBefore(todayOnly);
                                      
                                      return Row(
                                        children: [
                                          Icon(
                                            Icons.notifications_outlined,
                                            size: 20,
                                            color: isPastDate
                                                ? color.onSurfaceVariant.withOpacity(0.3)
                                                : (_notificationEnabled
                                                    ? color.primary
                                                    : color.onSurfaceVariant.withOpacity(0.6)),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Notification',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: isPastDate
                                                        ? color.onSurfaceVariant.withOpacity(0.5)
                                                        : null,
                                                  ),
                                            ),
                                          ),
                                          Switch(
                                            value: _notificationEnabled,
                                            onChanged: isPastDate ? null : (value) async {
                                              // Request notification permission if enabling
                                              if (value) {
                                                final notificationService = NotificationService();
                                                final initialized = await notificationService.initialize();
                                                if (!initialized) {
                                                  if (mounted && context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Notification permission is required to enable notifications'),
                                                      ),
                                                    );
                                                  }
                                                  return;
                                                }
                                              }
                                              setState(() {
                                                _notificationEnabled = value;
                                              });
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ],
                            )
                          : Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: color.outlineVariant.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minHeight: 80,
                              ),
                              child: _currentNote != null && _currentNote!.isNotEmpty
                                  ? Text(
                                      _currentNote!,
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                            color: color.onSurface,
                                          ),
                                      overflow: TextOverflow.visible,
                                      softWrap: true,
                                    )
                                  : Text(
                                      'No notes',
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                            color: color.onSurfaceVariant.withOpacity(0.6),
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), // Bottom padding to prevent covering
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: color.primaryContainer,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'store listing/ico_512.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: color.primary,
                            child: Icon(
                              Icons.calendar_today,
                              color: color.onPrimary,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.note),
              title: const Text('My Notes'),
              onTap: () {
                if (!mounted || !context.mounted) return;
                Navigator.pop(context);
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const MyNotesScreen()),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About us'),
              onTap: () {
                Navigator.pop(context);
                _showAboutRewardDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_rate),
              title: const Text('Rate App'),
              onTap: () {
                Navigator.pop(context);
                _rateApp();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () async {
                Navigator.pop(context);
                final link = '${AppConfig.playStoreUrl}&pcampaignid=web_share';
                await Share.share(AppConfig.getShareText());
              },
            ),
            Expanded(child: Container()),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Exit'),
              onTap: () {
                Navigator.pop(context);
                // Close the app
                SystemNavigator.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  
}


