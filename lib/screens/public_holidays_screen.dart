import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/holiday_service.dart';
import '../services/school_holiday_service.dart';
import '../providers/state_provider.dart';
import '../widgets/native_ad_widget.dart';
import 'dart:developer' as developer;

class PublicHolidaysScreen extends StatefulWidget {
  const PublicHolidaysScreen({super.key});

  @override
  State<PublicHolidaysScreen> createState() => _PublicHolidaysScreenState();
}

class _PublicHolidaysScreenState extends State<PublicHolidaysScreen> {
  List<Holiday> _holidays = [];
  List<SchoolHoliday> _schoolHolidays = [];
  bool _isLoading = true;
  final DateTime _today = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  Holiday? _mostRecentHoliday;
  final GlobalKey _mostRecentHolidayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHolidays() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await HolidayService.loadHolidays();
      await SchoolHolidayService.loadSchoolHolidays();
      
      if (!mounted || !context.mounted) return;
      final stateProvider = Provider.of<StateProvider>(context, listen: false);
      _holidays = HolidayService.getAllHolidays(state: stateProvider.selectedState);
      _schoolHolidays = SchoolHolidayService.getAllSchoolHolidays(state: stateProvider.selectedState);

      // Sort holidays by date
      _holidays.sort((a, b) {
        try {
          return DateTime.parse(a.date).compareTo(DateTime.parse(b.date));
        } catch (e) {
          print('Error parsing date during sort: $e, dates: ${a.date}, ${b.date}');
          return 0;
        }
      });
      _schoolHolidays.sort((a, b) {
        try {
          return a.startDateTime.compareTo(b.startDateTime);
        } catch (e) {
          print('Error comparing school holiday dates: $e');
          return 0;
        }
      });

      // Find most recent holiday (today or next upcoming)
      _findMostRecentHoliday();

    } catch (e, stackTrace) {
      print('Error in _loadHolidays: $e');
      print('Stack trace: $stackTrace');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading holidays: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    // Scroll to most recent holiday after build
    if (_mostRecentHoliday != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMostRecentHoliday();
      });
    }
  }

  void _findMostRecentHoliday() {
    final todayStripped = DateTime(_today.year, _today.month, _today.day);
    
    // Find today's holiday or next upcoming holiday
    for (var holiday in _holidays) {
      final holidayDate = DateTime.parse(holiday.date);
      final holidayStripped = DateTime(holidayDate.year, holidayDate.month, holidayDate.day);
      
      if (holidayStripped.isAtSameMomentAs(todayStripped) || holidayStripped.isAfter(todayStripped)) {
        _mostRecentHoliday = holiday;
        break;
      }
    }
    
    // If no upcoming holiday found, use the last holiday
    if (_mostRecentHoliday == null && _holidays.isNotEmpty) {
      _mostRecentHoliday = _holidays.last;
    }
  }

  void _scrollToMostRecentHoliday() {
    if (_mostRecentHolidayKey.currentContext != null) {
      Scrollable.ensureVisible(
        _mostRecentHolidayKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // Position near top of viewport
      );
    }
  }

  Map<int, List<Holiday>> _groupHolidaysByYear() {
    final Map<int, List<Holiday>> grouped = {};
    for (var holiday in _holidays) {
      final year = DateTime.parse(holiday.date).year;
      if (!grouped.containsKey(year)) {
        grouped[year] = [];
      }
      grouped[year]!.add(holiday);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StateProvider>(
      builder: (context, stateProvider, child) {
        final color = Theme.of(context).colorScheme;

        // Reload holidays if state changes
        if (stateProvider.selectedState != HolidayService.getSelectedState()) {
          HolidayService.setSelectedState(stateProvider.selectedState);
          _loadHolidays();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Public Holidays'),
            backgroundColor: color.primary,
            foregroundColor: color.onPrimary,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildHolidaysList(context, stateProvider, color),
        );
      },
    );
  }

  Widget _buildHolidaysList(BuildContext context, StateProvider stateProvider, ColorScheme color) {
    if (_holidays.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Public Holidays for ${stateProvider.selectedStateName}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color.onSurface,
                ),
          ),
          const SizedBox(height: 10),
          const Text('No public holidays found for this state/territory.'),
        ],
      );
    }

    final groupedHolidays = _groupHolidaysByYear();
    final years = groupedHolidays.keys.toList()..sort();

    final List<Widget> children = [
      Text(
        'Public Holidays for ${stateProvider.selectedStateName}',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color.onSurface,
            ),
      ),
      const SizedBox(height: 10),
    ];

    bool adInserted = false;
    for (int i = 0; i < years.length; i++) {
      final year = years[i];
      final yearHolidays = groupedHolidays[year]!;

      // Add year separator
      children.add(
        Container(
          margin: EdgeInsets.only(top: i > 0 ? 24 : 0, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                '$year',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color.onPrimaryContainer,
                    ),
              ),
            ],
          ),
        ),
      );

      // Insert native ad after first year section (only once)
      if (i == 0 && !adInserted) {
        children.add(
          RepaintBoundary(
            key: const ValueKey('native_ad_wrapper'),
            child: const NativeAdWidget(),
          ),
        );
        adInserted = true;
      }

      // Add holidays for this year
      for (var holiday in yearHolidays) {
        final isMostRecent = _mostRecentHoliday != null &&
            holiday.date == _mostRecentHoliday!.date;
        final widget = _buildHolidayItem(
          context,
          holiday,
          color,
          isMostRecent: isMostRecent,
        );
        children.add(
          isMostRecent
              ? KeyedSubtree(key: _mostRecentHolidayKey, child: widget)
              : widget,
        );
      }
    }

    // Add school holidays section if enabled
    if (stateProvider.showSchoolHolidays) {
      children.addAll([
        const SizedBox(height: 32),
        Text(
          'School Holidays for ${stateProvider.selectedStateName}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color.onSurface,
              ),
        ),
        const SizedBox(height: 10),
        if (_schoolHolidays.isEmpty)
          const Text('No school holidays found for this state/territory.')
        else
          ..._schoolHolidays.map((holiday) => _buildSchoolHolidayItem(context, holiday, color)),
      ]);
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      children: children,
    );
  }

  Widget _buildHolidayItem(
    BuildContext context,
    Holiday holiday,
    ColorScheme color, {
    bool isMostRecent = false,
  }) {
    final holidayDate = DateTime.parse(holiday.date);
    final todayStripped = DateTime(_today.year, _today.month, _today.day);
    final holidayStripped = DateTime(holidayDate.year, holidayDate.month, holidayDate.day);
    final isToday = holidayStripped.isAtSameMomentAs(todayStripped);
    final shouldHighlight = isMostRecent || isToday;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: shouldHighlight ? color.primary : null,
      elevation: shouldHighlight ? 4 : 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: shouldHighlight ? color.onPrimary : color.primary,
          child: Text(
            '${holidayDate.day}',
            style: TextStyle(
              color: shouldHighlight ? color.primary : color.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          holiday.holidayName,
          style: TextStyle(
            fontWeight: shouldHighlight ? FontWeight.bold : FontWeight.normal,
            color: shouldHighlight ? color.onPrimary : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(holidayDate),
              style: TextStyle(
                color: shouldHighlight ? color.onPrimary.withOpacity(0.8) : null,
              ),
            ),
            Text(
              '${holiday.weekday} • ${holiday.type.toUpperCase()}',
              style: TextStyle(
                color: shouldHighlight ? color.onPrimary.withOpacity(0.6) : color.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: shouldHighlight
            ? Icon(
                isToday ? Icons.today : Icons.star,
                color: color.onPrimary,
              )
            : null,
      ),
    );
  }

  Widget _buildSchoolHolidayItem(BuildContext context, SchoolHoliday holiday, ColorScheme color) {
    final todayStripped = DateTime(_today.year, _today.month, _today.day);
    final isCurrent = holiday.isDateInRange(todayStripped);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrent ? color.tertiaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrent ? color.onTertiaryContainer : color.tertiary,
          child: Icon(
            Icons.school,
            color: isCurrent ? color.tertiaryContainer : color.onTertiary,
          ),
        ),
        title: Text(
          holiday.name,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? color.onTertiaryContainer : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${DateFormat('MMM dd, yyyy').format(holiday.startDateTime)} - ${DateFormat('MMM dd, yyyy').format(holiday.endDateTime)}',
              style: TextStyle(
                color: isCurrent ? color.onTertiaryContainer.withOpacity(0.8) : null,
              ),
            ),
            Text(
              'School Holiday',
              style: TextStyle(
                color: isCurrent ? color.onTertiaryContainer.withOpacity(0.6) : color.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: isCurrent
            ? Icon(
                Icons.star,
                color: color.onTertiaryContainer,
              )
            : null,
      ),
    );
  }
}
