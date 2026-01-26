import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/holiday_service.dart';
import '../services/school_holiday_service.dart';
import '../providers/state_provider.dart';

class YearViewScreen extends StatefulWidget {
  const YearViewScreen({super.key});

  @override
  State<YearViewScreen> createState() => _YearViewScreenState();
}

class _YearViewScreenState extends State<YearViewScreen> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = DateTime.now().year;
    SchoolHolidayService.loadSchoolHolidays().then((_) {
      if (mounted) setState(() {});
    });
    HolidayService.loadHolidays().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _prevYear() {
    setState(() {
      _year -= 1;
    });
  }

  void _nextYear() {
    setState(() {
      _year += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > 200) _prevYear();
        if (velocity < -200) _nextYear();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          toolbarHeight: 72,
          title: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '$_year',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(12),
            child: SizedBox(height: 12),
          ),
          actions: [
            IconButton(onPressed: _prevYear, icon: const Icon(Icons.chevron_left)),
            IconButton(onPressed: _nextYear, icon: const Icon(Icons.chevron_right)),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: List.generate(12, (index) {
                  final month = index + 1;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(DateTime(_year, month, 1));
                    },
                    child: Consumer<StateProvider>(
                      builder: (context, stateProvider, child) {
                        return _MiniMonthCard(
                          year: _year,
                          month: month,
                          colorScheme: color,
                          stateProvider: stateProvider,
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniMonthCard extends StatelessWidget {
  const _MiniMonthCard({
    required this.year,
    required this.month,
    required this.colorScheme,
    required this.stateProvider,
  });

  final int year;
  final int month;
  final ColorScheme colorScheme;
  final StateProvider stateProvider;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(year, month, 1);
    final totalDays = DateTime(year, month + 1, 0).day;
    final int startWeekday = (firstOfMonth.weekday + 6) % 7;

    final days = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) {
      days.add(null);
    }
    for (int d = 1; d <= totalDays; d++) {
      days.add(DateTime(year, month, d));
    }
    while (days.length % 7 != 0) {
      days.add(null);
    }
    while (days.length < 42) {
      days.add(null);
    }

    final monthName = DateFormat('MMMM').format(firstOfMonth);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            monthName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 2),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            children: const [
              Center(child: Text('M', style: TextStyle(fontSize: 9))),
              Center(child: Text('T', style: TextStyle(fontSize: 9))),
              Center(child: Text('W', style: TextStyle(fontSize: 9))),
              Center(child: Text('T', style: TextStyle(fontSize: 9))),
              Center(child: Text('F', style: TextStyle(fontSize: 9))),
              Center(child: Text('S', style: TextStyle(fontSize: 9, color: Colors.red))),
              Center(child: Text('S', style: TextStyle(fontSize: 9, color: Colors.red))),
            ],
          ),
          const SizedBox(height: 2),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final date = days[index];
              final isToday = date != null && _strip(date) == _strip(DateTime.now());
              final text = date?.day.toString() ?? '';
              final isSunday = date?.weekday == DateTime.sunday;
              final isSaturday = date?.weekday == DateTime.saturday;
              final isHoliday = date != null && 
                  HolidayService.getHolidayForDate(date, state: stateProvider.selectedState) != null;
              final isStateHoliday = date != null && 
                  HolidayService.isStateHoliday(date, state: stateProvider.selectedState);
              final isSchoolHoliday = date != null && 
                  stateProvider.showSchoolHolidays && 
                  SchoolHolidayService.isSchoolHoliday(date, stateProvider.selectedState);

              Color? bgColor;
              Color textColor = colorScheme.onSurfaceVariant;
              if (isToday) {
                bgColor = colorScheme.primary;
                textColor = colorScheme.onPrimary;
              } else if (isHoliday || isStateHoliday) {
                bgColor = Colors.lightBlue.withOpacity(0.6);
                textColor = Colors.black;
              } else if (isSchoolHoliday) {
                bgColor = Colors.lightGreen.withOpacity(0.5);
                textColor = Colors.black;
              } else if (isSunday) {
                textColor = colorScheme.error;
                bgColor = (isDark
                        ? colorScheme.errorContainer.withOpacity(0.4)
                        : colorScheme.errorContainer.withOpacity(0.5));
              } else if (isSaturday) {
                bgColor = (isDark
                        ? colorScheme.surfaceVariant.withOpacity(0.4)
                        : colorScheme.surfaceVariant.withOpacity(0.5));
              }

              return Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: bgColor != null
                        ? (isHoliday || isStateHoliday || isSchoolHoliday || isToday
                            ? BoxDecoration(shape: BoxShape.circle, color: bgColor)
                            : BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(4),
                              ))
                        : null,
                    child: Text(
                      text,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: textColor,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static DateTime _strip(DateTime d) => DateTime(d.year, d.month, d.day);
}
