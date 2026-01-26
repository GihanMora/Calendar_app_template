import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notes_service.dart';
import '../services/notification_service.dart';

class MyNotesScreen extends StatefulWidget {
  const MyNotesScreen({super.key});

  @override
  State<MyNotesScreen> createState() => _MyNotesScreenState();
}

class _MyNotesScreenState extends State<MyNotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<DateTime, Map<String, dynamic>> _allNotes = {};
  bool _isLoading = true;
  int _selectedYear = 2026; // Default to 2026

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Index 1 = 2026
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && mounted) {
        setState(() {
          _selectedYear = [2025, 2026, 2027][_tabController.index];
        });
      }
    });
    _loadAllNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllNotes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final notes = await NotesService.getAllNotes();
    if (mounted) {
      setState(() {
        _allNotes = notes;
        _isLoading = false;
      });
    }
  }

  String _getDaysText(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final difference = dateOnly.difference(todayOnly).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference > 0) {
      if (difference == 1) {
        return '1 day to go';
      } else {
        return '$difference days to go';
      }
    } else {
      final daysAgo = difference.abs();
      if (daysAgo == 1) {
        return '1 day ago';
      } else {
        return '$daysAgo days ago';
      }
    }
  }

  List<MapEntry<DateTime, Map<String, dynamic>>> _getNotesForYear(int year) {
    return _allNotes.entries
        .where((entry) => entry.key.year == year)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key)); // Sort by date ascending
  }

  Future<void> _deleteNote(DateTime date, bool isAnnual) async {
    if (!mounted || !context.mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text(
          isAnnual
              ? 'Are you sure you want to delete this annual note from all years?'
              : 'Are you sure you want to delete this note?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Cancel notifications before deleting
      await NotificationService().cancelNotificationsForDate(date, isAnnual: isAnnual);
      
      // Always delete annual notes from all years, regular notes just from current date
      await NotesService.deleteNote(date, deleteAnnual: isAnnual);
      
      // Wait for dialog to fully close
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (!mounted) return;
      
      await _loadAllNotes();
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    }
  }

  Future<void> _editNote(DateTime date, String currentNote, bool repeatAnnually, bool notificationEnabled) async {
    if (!mounted || !context.mounted) return;
    
    final controller = TextEditingController(text: currentNote);
    bool notifyEnabled = notificationEnabled;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                DateFormat('MMMM dd, yyyy').format(date),
                style: const TextStyle(fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      maxLines: 5,
                      minLines: 3,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Type your notes here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (ctx) {
                        final today = DateTime.now();
                        final todayOnly = DateTime(today.year, today.month, today.day);
                        final dateOnly = DateTime(date.year, date.month, date.day);
                        final isPastDate = dateOnly.isBefore(todayOnly);
                        
                        return Row(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              size: 20,
                              color: isPastDate
                                  ? Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                                  : (notifyEnabled
                                      ? Theme.of(ctx).colorScheme.primary
                                      : Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Notification',
                                style: TextStyle(
                                  color: isPastDate
                                      ? Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                      : null,
                                ),
                              ),
                            ),
                            Switch(
                              value: notifyEnabled,
                              onChanged: isPastDate ? null : (value) {
                                setDialogState(() {
                                  notifyEnabled = value;
                                });
                              },
                            ),
                          ],
                        );
                      },
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
                  onPressed: () {
                    Navigator.of(dialogContext).pop({
                      'note': controller.text,
                      'notificationEnabled': notifyEnabled,
                    });
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // Wait for dialog route to be completely removed and all dependencies cleared
    // This ensures the TextField widget has fully detached from the controller
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Now safely dispose the controller after the dialog widget tree has been cleaned up
    controller.dispose();
    
    if (result != null && mounted) {
      if (!mounted) return;
      
      final noteText = result['note'].toString();
      final enableNotification = result['notificationEnabled'] == true;

      // Cancel existing notifications
      if (notificationEnabled) {
        await NotificationService().cancelNotificationsForDate(date, isAnnual: repeatAnnually);
      }

      // Save note
      await NotesService.saveNote(
        date,
        noteText,
        repeatAnnually: repeatAnnually,
        enableNotification: enableNotification,
      );

      // Schedule notification if enabled
      if (enableNotification && noteText.trim().isNotEmpty) {
        final notificationService = NotificationService();
        await notificationService.initialize();
        
        if (repeatAnnually) {
          final currentYear = DateTime.now().year;
          final yearsToSchedule = [currentYear - 1, currentYear, currentYear + 1];
          for (final year in yearsToSchedule) {
            final scheduledDate = DateTime(year, date.month, date.day);
            final notificationId = NotificationService.getNotificationId(scheduledDate);
            await notificationService.scheduleNoteNotification(
              eventDate: scheduledDate,
              noteText: noteText,
              notificationId: notificationId,
              isAnnual: true,
            );
          }
        } else {
          final notificationId = NotificationService.getNotificationId(date);
          await notificationService.scheduleNoteNotification(
            eventDate: date,
            noteText: noteText,
            notificationId: notificationId,
            isAnnual: false,
          );
        }
      }

      if (!mounted) return;
      
      // Now safely reload notes - this will call setState internally
      await _loadAllNotes();
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved')),
        );
      }
    }
  }

  Widget _buildNotesList(int year, ColorScheme color) {
    final notesForYear = _getNotesForYear(year);

    if (notesForYear.isEmpty) {
      return Container(
        color: color.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_outlined,
                size: 64,
                color: color.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No notes yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can add notes from the calendar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: color.surfaceContainerHighest,
      child: RefreshIndicator(
        onRefresh: _loadAllNotes,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notesForYear.length,
          itemBuilder: (context, index) {
            final entry = notesForYear[index];
            final date = entry.key;
            final noteData = entry.value;
            final note = noteData['note'] as String;
            final repeatAnnually = noteData['repeatAnnually'] as bool? ?? false;
            final notificationEnabled = noteData['notificationEnabled'] as bool? ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: color.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: color.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row: Date and Tag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date section
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: color.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('MMMM dd, yyyy').format(date),
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: color.onSurface,
                                              fontSize: 14,
                                            ),
                                      ),
                                      if (repeatAnnually)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.repeat,
                                                size: 10,
                                                color: color.primary.withValues(alpha: 0.7),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Annual',
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                      color: color.primary.withValues(alpha: 0.7),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Days to go/ago tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getDaysText(date),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: color.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Note text - left aligned
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          note,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: color.onSurface.withValues(alpha: 0.9),
                                height: 1.4,
                                fontSize: 14,
                              ),
                          maxLines: 10,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Action buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Notification button
                          Builder(
                            builder: (context) {
                              final today = DateTime.now();
                              final todayOnly = DateTime(today.year, today.month, today.day);
                              final dateOnly = DateTime(date.year, date.month, date.day);
                              final isPastDate = dateOnly.isBefore(todayOnly);
                              
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: isPastDate ? null : () async {
                                    if (!mounted) return;
                                    
                                    // Toggle notification
                                    final newNotificationState = !notificationEnabled;
                                    
                                    // Request permission if enabling
                                    if (newNotificationState) {
                                      final notificationService = NotificationService();
                                      final initialized = await notificationService.initialize();
                                      if (!initialized) {
                                        if (!mounted) return;
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Notification permission is required'),
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                    }

                                    // Cancel existing notifications if disabling
                                    if (!newNotificationState) {
                                      await NotificationService().cancelNotificationsForDate(
                                        date,
                                        isAnnual: repeatAnnually,
                                      );
                                    }

                                    // Update note with new notification state
                                    await NotesService.saveNote(
                                      date,
                                      note,
                                      repeatAnnually: repeatAnnually,
                                      enableNotification: newNotificationState,
                                    );

                                    // Schedule notification if enabling and note is not empty
                                    if (newNotificationState && note.trim().isNotEmpty) {
                                      final notificationService = NotificationService();
                                      await notificationService.initialize();
                                      
                                      if (repeatAnnually) {
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
                                        final notificationId = NotificationService.getNotificationId(date);
                                        await notificationService.scheduleNoteNotification(
                                          eventDate: date,
                                          noteText: note,
                                          notificationId: notificationId,
                                          isAnnual: false,
                                        );
                                      }
                                    }

                                    // Wait before updating
                                    await Future.delayed(const Duration(milliseconds: 300));
                                    
                                    if (!mounted) return;
                                    
                                    // Reload notes directly
                                    await _loadAllNotes();
                                    
                                    if (mounted && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            newNotificationState
                                                ? 'Notification enabled'
                                                : 'Notification disabled',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      notificationEnabled
                                          ? Icons.notifications
                                          : Icons.notifications_outlined,
                                      size: 18,
                                      color: isPastDate
                                          ? color.onSurfaceVariant.withValues(alpha: 0.3)
                                          : (notificationEnabled
                                              ? color.primary
                                              : color.onSurfaceVariant.withValues(alpha: 0.6)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          // Edit button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _editNote(date, note, repeatAnnually, notificationEnabled),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: color.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Delete button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _deleteNote(date, repeatAnnually),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: color.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '2025'),
            Tab(text: '2026'),
            Tab(text: '2027'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotesList(2025, color),
                _buildNotesList(2026, color),
                _buildNotesList(2027, color),
              ],
            ),
    );
  }
}
