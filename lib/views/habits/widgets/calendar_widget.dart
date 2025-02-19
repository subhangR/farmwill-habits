import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarDaysStats {
  final double completionRate;

  CalendarDaysStats({required this.completionRate});
}

class StatsCircles extends StatelessWidget {
  final CalendarDaysStats stats;
  final double size;
  final bool isSelected;

  const StatsCircles({
    Key? key,
    required this.stats,
    required this.size,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color circleColor = Color.lerp(
      Colors.red,
      Colors.green,
      stats.completionRate,
    ) ?? Colors.grey;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? circleColor.withOpacity(0.3)
            : Colors.transparent,
        border: Border.all(
          color: circleColor,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}

class CalendarWidget extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final DateTime? initialDate;
  final Map<DateTime, CalendarDaysStats>? dateStats;
  final String? locale;

  const CalendarWidget({
    Key? key,
    this.dateStats,
    this.onDateSelected,
    this.initialDate,
    this.locale,
  }) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _selectedDate;
  late DateTime _currentWeekStart;
  late List<DateTime> _weekDates;
  late String _locale;
  late List<String> _weekDayNames;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _locale = widget.locale ?? Intl.getCurrentLocale();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _currentWeekStart = _findWeekStartForDate(_selectedDate);
    _weekDates = _generateWeekDates(_currentWeekStart);
    _weekDayNames = _getLocalizedWeekDays();
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected date if initialDate changes
    if (widget.initialDate != null &&
        (oldWidget.initialDate == null ||
            widget.initialDate!.day != oldWidget.initialDate!.day ||
            widget.initialDate!.month != oldWidget.initialDate!.month ||
            widget.initialDate!.year != oldWidget.initialDate!.year)) {
      _selectedDate = widget.initialDate!;
      _updateWeekStart();
    }

    // Update locale if changed
    if (widget.locale != oldWidget.locale) {
      _locale = widget.locale ?? Intl.getCurrentLocale();
      _weekDayNames = _getLocalizedWeekDays();
    }
  }

  void _updateWeekStart() {
    final newWeekStart = _findWeekStartForDate(_selectedDate);

    // Only update if the week has changed
    if (newWeekStart.day != _currentWeekStart.day ||
        newWeekStart.month != _currentWeekStart.month ||
        newWeekStart.year != _currentWeekStart.year) {
      setState(() {
        _currentWeekStart = newWeekStart;
        _weekDates = _generateWeekDates(_currentWeekStart);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getLocalizedWeekDays() {
    final DateFormat weekdayFormat = DateFormat.E(_locale);
    final now = DateTime.now();

    // Get first day of week based on locale
    final firstDayOfWeek = _getFirstDayOfWeek();

    return List.generate(7, (index) {
      final weekday = (firstDayOfWeek + index) % 7;
      // Handle zero-based weekday (Sunday = 0) vs. one-based weekday (Monday = 1)
      final adjustedWeekday = weekday == 0 ? 7 : weekday;
      final date = now.subtract(Duration(days: now.weekday - adjustedWeekday));
      return weekdayFormat.format(date).toUpperCase();
    });
  }

  int _getFirstDayOfWeek() {
    // Default to Monday (1) for most locales
    if (_locale.startsWith('ar') ||
        _locale.startsWith('fa') ||
        _locale.startsWith('he')) {
      return 6; // Saturday for Arabic, Farsi, Hebrew
    } else if (_locale.startsWith('en_US')) {
      return 0; // Sunday for US English
    }
    return 1; // Monday for most other locales
  }

  DateTime _findWeekStartForDate(DateTime date) {
    final firstDayOfWeek = _getFirstDayOfWeek();

    // Calculate days to subtract to get to the start of the week
    int daysToSubtract;
    if (firstDayOfWeek == 0) { // Sunday
      daysToSubtract = date.weekday % 7;
    } else { // Monday or other
      daysToSubtract = (date.weekday - firstDayOfWeek) % 7;
    }

    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
  }

  List<DateTime> _generateWeekDates(DateTime startDate) {
    return List.generate(7, (index) =>
        DateTime(
            startDate.year,
            startDate.month,
            startDate.day + index
        )
    );
  }

  void _navigateWeek(bool forward) {
    setState(() {
      _currentWeekStart = DateTime(
          _currentWeekStart.year,
          _currentWeekStart.month,
          _currentWeekStart.day + (forward ? 7 : -7)
      );
      _weekDates = _generateWeekDates(_currentWeekStart);

      // Check if selected date is still visible in the new week
      final weekEnd = _weekDates.last;
      bool selectedDateInView = false;

      for (var date in _weekDates) {
        if (date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day) {
          selectedDateInView = true;
          break;
        }
      }

      // If selected date not in view, update it to first day of new week
      if (!selectedDateInView) {
        // Keep selection visible by selecting a day in the new week
        // (usually first day when going back, last day when going forward)
        _selectedDate = forward ? weekEnd : _currentWeekStart;
        if (widget.onDateSelected != null) {
          widget.onDateSelected!(_selectedDate);
        }
      }
    });
  }

  String _getDateRangeText() {
    final DateFormat fullFormat = DateFormat.yMMMMd(_locale);
    final DateFormat monthDayFormat = DateFormat.MMMd(_locale);
    final DateFormat yearFormat = DateFormat.y(_locale);

    final weekEnd = _weekDates.last;

    if (_currentWeekStart.month == weekEnd.month &&
        _currentWeekStart.year == weekEnd.year) {
      // Same month and year
      return '${monthDayFormat.format(_currentWeekStart)}-${weekEnd.day}, ${yearFormat.format(_currentWeekStart)}';
    } else if (_currentWeekStart.year == weekEnd.year) {
      // Different months, same year
      return '${monthDayFormat.format(_currentWeekStart)} - ${monthDayFormat.format(weekEnd)}';
    } else {
      // Different years
      return '${fullFormat.format(_currentWeekStart)} - ${fullFormat.format(weekEnd)}';
    }
  }

  Widget _buildDayButton(DateTime date, double dayWidth) {
    final bool isSelected = date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;

    final bool isToday = _isToday(date);

    final DateFormat dayFormat = DateFormat.d(_locale);
    final CalendarDaysStats? stats = widget.dateStats != null ?
    _findMatchingStats(date) : null;

    final bool isCurrentMonth = date.month == DateTime.now().month;

    // Calculate sizes based on available width
    final double circleSize = dayWidth * 0.9;
    final double innerSize = circleSize * 0.9;

    return Container(
      width: dayWidth,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (stats != null)
            StatsCircles(
              stats: stats,
              size: circleSize,
              isSelected: isSelected,
            ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Colors.blue.withOpacity(0.3)
                  : isToday
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.transparent,
              border: isSelected || isToday
                  ? Border.all(
                color: isSelected ? Colors.blue : Colors.amber,
                width: 2,
              )
                  : null,
            ),
            child: Center(
              child: Text(
                dayFormat.format(date),
                style: TextStyle(
                  color: isSelected
                      ? Colors.blue
                      : isToday
                      ? Colors.amber
                      : isCurrentMonth
                      ? Colors.white
                      : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: (isSelected || isToday)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }

  CalendarDaysStats? _findMatchingStats(DateTime date) {
    if (widget.dateStats == null) return null;

    // Try to find exact match
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return widget.dateStats![normalizedDate];
  }

  Widget _buildNavigationArrow(bool forward) {
    return IconButton(
      icon: Icon(
        forward ? Icons.chevron_right : Icons.chevron_left,
        color: Colors.grey[400],
        size: 20,
      ),
      onPressed: () => _navigateWeek(forward),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate day width based on available space
          final availableWidth = constraints.maxWidth - 32; // subtract padding
          final dayWidth = availableWidth / 7;

          return Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CALENDAR',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNavigationArrow(false),
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    _getDateRangeText(),
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              _buildNavigationArrow(true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _weekDayNames.map((day) {
                        return SizedBox(
                          width: dayWidth,
                          child: Center(
                            child: Text(
                              day.length > 3 ? day.substring(0, 3) : day,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _weekDates.map((date) =>
                          GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                });
                                if (widget.onDateSelected != null) {
                                  widget.onDateSelected!(date);
                                }
                              },
                              child: _buildDayButton(date, dayWidth)
                          )
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
    );
  }
}