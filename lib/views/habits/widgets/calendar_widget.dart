// calendar_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class CalendarDaysStats {
  final double progressPercent; // 0.0 to 1.0
  final bool isGoodHabit; // true for green, false for red
  final double? willPercent; // 0.0 to 1.0, null if not present

  const CalendarDaysStats({
    required this.progressPercent,
    required this.isGoodHabit,
    this.willPercent,
  });
}
class StatsCircles extends StatelessWidget {
  final CalendarDaysStats stats;
  final double size;
  final bool isSelected;
   StatsCircles({
    Key? key, this.isSelected = false,
    required this.stats,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: StatsCirclesPainter(
        progressPercent: stats.progressPercent,
        isGoodHabit: stats.isGoodHabit,
        willPercent: stats.willPercent,
      ),
    );
  }
}

class StatsCirclesPainter extends CustomPainter {
  final double progressPercent;
  final bool isGoodHabit;
  final double? willPercent;
  final bool isSelected;

  StatsCirclesPainter({
    required this.progressPercent,
    required this.isGoodHabit,
    this.willPercent,
    this.isSelected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Selected state background
    if (isSelected) {
      final backgroundPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.blue.withOpacity(0.2);
      canvas.drawCircle(center, size.width * 0.4, backgroundPaint);
    }

    // Progress circle (inner)
    _drawProgressCircle(canvas, center, size.width * 0.4);

    // Will circle (outer)
    if (willPercent != null) {
      _drawWillCircle(canvas, center, size.width * 0.5);
    }
  }

  void _drawProgressCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Background circle
    paint.color = Colors.grey.withOpacity(0.2);
    canvas.drawCircle(center, radius, paint);

    // Progress arc
    paint.color = isGoodHabit ? Colors.green : Colors.red;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -90 * (3.14159 / 180), // Start from top
      progressPercent * 2 * 3.14159, // Convert to radians
      false,
      paint,
    );
  }

  void _drawWillCircle(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Background circle
    paint.color = Colors.grey.withOpacity(0.2);
    canvas.drawCircle(center, radius, paint);

    // Will arc
    paint.color = Colors.amber;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -90 * (3.14159 / 180), // Start from top
      willPercent! * 2 * 3.14159, // Convert to radians
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(StatsCirclesPainter oldDelegate) {
    return oldDelegate.progressPercent != progressPercent ||
        oldDelegate.isGoodHabit != isGoodHabit ||
        oldDelegate.willPercent != willPercent;
  }
}

class CalendarWidget extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  final DateTime? initialDate;
  final Map<DateTime, CalendarDaysStats>? dateStats; // New parameter
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
    _currentWeekStart = _getWeekStart(_selectedDate);
    _weekDates = _generateWeekDates(_currentWeekStart);
    _weekDayNames = _getLocalizedWeekDays();
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
      final date = now.subtract(Duration(days: now.weekday - weekday - 1));
      return weekdayFormat.format(date).toUpperCase();
    });
  }

  int _getFirstDayOfWeek() {
    // Default to Sunday (0) for most locales
    if (_locale.startsWith('ar') ||
        _locale.startsWith('fa') ||
        _locale.startsWith('he')) {
      return 6; // Saturday for Arabic, Farsi, Hebrew
    } else if (_locale.startsWith('en')) {
      return 0; // Sunday for English
    }
    return 1; // Monday for most other locales
  }

  DateTime _getWeekStart(DateTime date) {
    final firstDayOfWeek = _getFirstDayOfWeek();
    final difference = (date.weekday - firstDayOfWeek) % 7;
    return date.subtract(Duration(days: difference));
  }

  List<DateTime> _generateWeekDates(DateTime startDate) {
    return List.generate(7, (index) => startDate.add(Duration(days: index)));
  }

  void _navigateWeek(bool forward) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: forward ? 7 : -7));
      _weekDates = _generateWeekDates(_currentWeekStart);
    });
  }

  String _getDateRangeText() {
    final DateFormat fullFormat = DateFormat.yMMMMd(_locale);
    final DateFormat monthDayFormat = DateFormat.MMMd(_locale);

    final weekEnd = _currentWeekStart.add(const Duration(days: 6));

    if (_currentWeekStart.month == weekEnd.month &&
        _currentWeekStart.year == weekEnd.year) {
      // Same month and year
      return '${monthDayFormat.format(_currentWeekStart)}-${weekEnd.day}, ${_currentWeekStart.year}';
    } else if (_currentWeekStart.year == weekEnd.year) {
      // Different months, same year
      return '${monthDayFormat.format(_currentWeekStart)} - ${monthDayFormat.format(weekEnd)}';
    } else {
      // Different years
      return '${fullFormat.format(_currentWeekStart)} - ${fullFormat.format(weekEnd)}';
    }
  }
// In _CalendarWidgetState, modify _buildDayButton:
  Widget _buildDayButton(DateTime date) {
    final bool isSelected = date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;
    final bool isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    final DateFormat dayFormat = DateFormat.d(_locale);
    final CalendarDaysStats? stats = widget.dateStats?[DateTime(
        date.year, date.month, date.day)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add horizontal spacing
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = date;
          });
          if (widget.onDateSelected != null) {
            widget.onDateSelected!(date);
          }
        },
        child: Container(
          width: 40, // Increased from 36
          height: 40, // Increased from 36
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (stats != null)
                StatsCircles(
                  stats: stats,
                  size: 30,
                  isSelected: isSelected,
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayFormat.format(date),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.blue
                          : isToday
                          ? Colors.white
                          : Colors.grey[400],
                      fontSize: 16,
                      fontWeight: (isSelected || isToday)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationArrow(bool forward) {
    return IconButton(
      icon: Icon(
        forward
            ? Directionality.of(context) == TextDirection.RTL
            ? Icons.chevron_left
            : Icons.chevron_right
            : Directionality.of(context) == TextDirection.LTR
            ? Icons.chevron_right
            : Icons.chevron_left,
        color: Colors.grey[400],
        size: 20,
      ),
      onPressed: () => _navigateWeek(forward),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRTL = Directionality.of(context) == TextDirection.RTL;

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'TODAY',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildNavigationArrow(false),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _getDateRangeText(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekDayNames.map((day) {
                    return Container(
                      width: 56, // Increased width to account for padding
                      alignment: Alignment.center,
                      child: Text(
                        day,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekDates.map((date) => _buildDayButton(date)).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}