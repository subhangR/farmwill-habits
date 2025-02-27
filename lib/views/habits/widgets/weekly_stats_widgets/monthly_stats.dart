import 'package:flutter/material.dart';

class MonthlyStatsValue {
  final List<DayCompletion> dailyCompletions;
  final DateTime month;

  MonthlyStatsValue({
    required this.dailyCompletions,
    required this.month,
  });
}

class DayCompletion {
  final DateTime date;
  final double completion; // 0 to 1, where 0 is empty, 1 is full

  DayCompletion({
    required this.date,
    required this.completion,
  });
}

class MonthlyCalendarStats extends StatelessWidget {
  final String title;
  final MonthlyStatsValue stats;
  final double height;
  final Color baseColor;
  final Color textColor;
  final Color backgroundColor;

  const MonthlyCalendarStats({
    super.key,
    required this.title,
    required this.stats,
    this.height = 300,
    this.baseColor = const Color(0xFF7166F9),
    this.textColor = const Color(0xFFF5F5F5),
    this.backgroundColor = const Color(0xFF2D2D2D),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildWeekDayLabels(),
          const SizedBox(height: 8),
          Expanded(
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekDayLabels() {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) {
        return SizedBox(
          width: 32,
          child: Text(
            day,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(stats.month.year, stats.month.month, 1);
    final lastDayOfMonth = DateTime(stats.month.year, stats.month.month + 1, 0);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final weeks = ((daysInMonth + (firstWeekdayOfMonth == 7 ? 0 : firstWeekdayOfMonth)) / 7).ceil();

    return Column(
      children: List.generate(weeks, (weekIndex) {
        return Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - (firstWeekdayOfMonth == 7 ? 0 : firstWeekdayOfMonth) + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox(width: 32);
              }

              final currentDate = DateTime(stats.month.year, stats.month.month, dayNumber);
              final dayCompletion = stats.dailyCompletions.firstWhere(
                    (completion) => completion.date.isAtSameMomentAs(currentDate),
                orElse: () => DayCompletion(date: currentDate, completion: 0),
              );

              return _buildDayBox(dayNumber, dayCompletion);
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayBox(int day, DayCompletion completion) {
    Color boxColor;
    if (completion.completion == 0) {
      boxColor = backgroundColor;
    } else if (completion.completion == 1) {
      boxColor = baseColor;
    } else {
      boxColor = baseColor.withOpacity(completion.completion);
    }

    final isToday = DateTime.now().year == stats.month.year &&
        DateTime.now().month == stats.month.month &&
        DateTime.now().day == day;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(6),
        border: isToday ? Border.all(
          color: baseColor,
          width: 2,
        ) : Border.all(
          color: textColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Text(
        day.toString(),
        style: TextStyle(
          color: completion.completion > 0.5 ? Colors.white : textColor.withOpacity(0.7),
          fontSize: 12,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}