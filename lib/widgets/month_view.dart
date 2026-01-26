import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/state_provider.dart';
import '../services/holiday_service.dart';
import '../services/school_holiday_service.dart';

class MonthView extends StatefulWidget {
  const MonthView({super.key, required this.anchor, required this.onSwipeMonth, this.onDateSelected});

  final DateTime anchor; // any day within the month to display
  final void Function(int deltaMonths) onSwipeMonth; // -1 or +1 typically
  final void Function(DateTime? date)? onDateSelected; // callback when date is selected

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  DateTime? selectedDate;
  bool _holidaysLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadHolidaysAndSetToday();
  }

  Future<void> _loadHolidaysAndSetToday() async {
    await HolidayService.loadHolidays();
    await SchoolHolidayService.loadSchoolHolidays();
    if (mounted) {
      setState(() {
        selectedDate = DateTime.now();
        _holidaysLoaded = true;
      });
    }
  }

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  static int _daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
  static DateTime _strip(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    return Consumer<StateProvider>(
      builder: (context, stateProvider, child) {
        final today = _strip(DateTime.now());
        final first = _firstOfMonth(widget.anchor);
        final totalDays = _daysInMonth(widget.anchor);
        final startWeekday = (first.weekday - 1) % 7; // make Monday=0, Sunday=6

        const weekdayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

        final days = <DateTime>[];
        // Fill leading blanks from previous month
        for (int i = 0; i < startWeekday; i++) {
          days.add(first.subtract(Duration(days: startWeekday - i)));
        }
        // Fill current month
        for (int i = 0; i < totalDays; i++) {
          days.add(DateTime(widget.anchor.year, widget.anchor.month, i + 1));
        }
        // Fill trailing to complete weeks (42 cells max: 6 weeks * 7)
        while (days.length % 7 != 0) {
          final last = days.last;
          days.add(last.add(const Duration(days: 1)));
        }
        while (days.length < 42) {
          final last = days.last;
          days.add(last.add(const Duration(days: 1)));
        }

        final color = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity > 200) widget.onSwipeMonth(-1);
            if (velocity < -200) widget.onSwipeMonth(1);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            child: Column(
              children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final isWeekend = i == 5 || i == 6; // Saturday = 5, Sunday = 6
                    return Expanded(
                      child: Center(
                        child: Text(
                          weekdayNames[i],
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: isWeekend ? color.error : color.onSurfaceVariant,
                                fontWeight: isWeekend ? FontWeight.w600 : FontWeight.normal,
                              ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Compute dynamic height so cells stay square and avoid overflow
                  const int columns = 7;
                  const int rows = 6; // maximum rows in a month grid
                  const double mainAxisSpacing = 8;
                  const double crossAxisSpacing = 6;
                  const double horizontalPadding = 12; // matches Padding below

                  final double availableWidth = constraints.maxWidth - (horizontalPadding * 2);
                  final double totalCrossSpacing = crossAxisSpacing * (columns - 1);
                  final double cellSize = (availableWidth - totalCrossSpacing) / columns;
                  final double totalMainSpacing = mainAxisSpacing * (rows - 1);
                  final double gridHeight = (cellSize * rows) + totalMainSpacing;

                  return SizedBox(
                    height: gridHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: mainAxisSpacing,
                          crossAxisSpacing: crossAxisSpacing,
                          childAspectRatio: 1.0, // square cells
                        ),
                        itemCount: days.length,
                        itemBuilder: (context, index) {
                      final date = days[index];
                      final inMonth = date.month == widget.anchor.month;
                      final isToday = _strip(date) == today;
                      final isSelected = selectedDate != null && _strip(date) == _strip(selectedDate!);
                      final isSaturday = date.weekday == DateTime.saturday;
                      final isSunday = date.weekday == DateTime.sunday;
                      
                      // Check for holidays
                      final holiday = HolidayService.getHolidayForDate(date, state: stateProvider.selectedState);
                      final isHoliday = holiday != null;
                      final isStateHoliday = HolidayService.isStateHoliday(date, state: stateProvider.selectedState);
                      
                      // Check for school holidays
                      final showSchoolHolidays = stateProvider.showSchoolHolidays;
                      final isSchoolHoliday = showSchoolHolidays && 
                          SchoolHolidayService.isSchoolHoliday(date, stateProvider.selectedState);
                      
                      Color textColor;
                      Color backgroundColor;
                      
                      if (isHoliday && inMonth) {
                        // Regular holidays - light blue background (highest priority)
                        textColor = Colors.black;
                        backgroundColor = Colors.lightBlue.withOpacity(0.6);
                      } else if (isSchoolHoliday && inMonth) {
                        // School holidays - light green background (third priority)
                        textColor = Colors.black;
                        backgroundColor = Colors.lightGreen.withOpacity(0.5);
                      } else if (isSaturday && inMonth) {
                        textColor = color.onSurfaceVariant;
                        backgroundColor = isDark
                            ? color.surfaceVariant.withOpacity(0.4)
                            : color.surfaceVariant.withOpacity(0.5);
                      } else if (isSunday && inMonth) {
                        textColor = color.error;
                        backgroundColor = isDark
                            ? color.errorContainer.withOpacity(0.4)
                            : color.errorContainer.withOpacity(0.5);
                      } else if (inMonth) {
                        textColor = color.onSurface;
                        backgroundColor = isDark
                            ? color.surfaceVariant.withOpacity(0.25)
                            : color.surface;
                      } else {
                        textColor = color.onSurfaceVariant.withOpacity(0.5);
                        backgroundColor = isDark
                            ? color.surfaceVariant.withOpacity(0.1)
                            : color.surface;
                      }

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedDate = date;
                              });
                              widget.onDateSelected?.call(date);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isSelected && inMonth
                                    ? [
                                        BoxShadow(
                                          color: color.primary.withOpacity(0.6),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 2),
                                        ),
                                        BoxShadow(
                                          color: color.primary.withOpacity(0.3),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                                border: (isHoliday || isSchoolHoliday || isSaturday || isSunday) && inMonth
                                    ? Border.all(
                                        color: Colors.black.withOpacity(0.6),
                                        width: 1.5,
                                      )
                                    : Border.all(
                                        color: color.outlineVariant.withOpacity(0.4),
                                        width: 1,
                                      ),
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                        color: textColor,
                                        fontWeight: (isHoliday || isSchoolHoliday || isSaturday || isSunday) && inMonth ? FontWeight.w600 : FontWeight.normal,
                                        decoration: isToday ? TextDecoration.underline : TextDecoration.none,
                                        decorationColor: isToday ? color.primary : null,
                                        decorationThickness: isToday ? 2 : null,
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              ],
            ),
          ),
        );
      },
    );
  }

}
