import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/bubble_weekly_stats.dart';
import 'package:farmwill_habits/views/habits/widgets/calendar_widget.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/circular_weekly_stats.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/line_scatterd_weekly_stats.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/monthly_stats.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/pie_line_weekly_stats.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/weekly_stats_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HabitDetailsPage extends StatelessWidget {
  const HabitDetailsPage({Key? key}) : super(key: key);

  // Custom colors for dark theme
  static const backgroundColor = Color(0xFF1A1A1A);
  static const cardColor = Color(0xFF2D2D2D);
  static const accentColor = Color(0xFF7166F9);
  static const textColor = Color(0xFFF5F5F5);
  static const secondaryTextColor = Color(0xFFB3B3B3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Stop smoking',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CalendarWidget(),
            const SizedBox(height: 32,),
            _buildStreakCards(),
            const SizedBox(height: 32),
            _buildTotalRepetitions(),
            const SizedBox(height: 32),
            _buildDuration(),
            const SizedBox(height: 32),
            _buildDurationWeeklyStats(),
            const SizedBox(height: 32),
            _buildRepsWeeklyStats(),
            const SizedBox(height: 32),
            _buildCompletionRate(),
            const SizedBox(height: 32),
            _buildMonthlyStats(),
            const SizedBox(height: 32),
            _buildFrequency(),
            const SizedBox(height: 32),
            _buildHabitCreatedOn(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyStats() {
    final monthlyStats = MonthlyStatsValue(
      month: DateTime.now(),
      dailyCompletions: [
        DayCompletion(
          date: DateTime(2025, 1, 1),
          completion: 1.0, // Fully completed
        ),
        DayCompletion(
          date: DateTime(2025, 1, 2),
          completion: 0.5, // Partially completed
        ),
        DayCompletion(
          date: DateTime(2025, 1, 3),
          completion: 0.0, // Not completed
        ),
        // ... add more days
      ],
    );

   return MonthlyCalendarStats(
      title: 'January 2025',
      stats: monthlyStats,
      height: 400,
      baseColor: Color(0xFF7166F9),
      backgroundColor: Color(0xFF2D2D2D),
      textColor: Color(0xFFF5F5F5),
    );
  }



  Widget _buildRepsWeeklyStats() {
    // Example data - you should replace this with actual data from your app
    final weeklyStats = WeeklyStatsValue(
      dailyStats: [
        DayStats(day: 'Mon', value: 5),
        DayStats(day: 'Tue', value: 3),
        DayStats(day: 'Wed', value: 7),
        DayStats(day: 'Thu', value: 2),
        DayStats(day: 'Fri', value: 6),
        DayStats(day: 'Sat', value: 4),
        DayStats(day: 'Sun', value: 8),
      ],
    );

    return RadarWeeklyStatsWidget(
      title: 'Repetitions',
      stats: weeklyStats,
      height: 200,
      backgroundColor: cardColor,
      textColor: textColor,
    );
  }



  Widget _buildDurationWeeklyStats() {
    // Example data - you should replace this with actual data from your app
    final weeklyStats = WeeklyStatsValue(
      dailyStats: [
        DayStats(day: 'Mon', value: 5),
        DayStats(day: 'Tue', value: 3),
        DayStats(day: 'Wed', value: 7),
        DayStats(day: 'Thu', value: 2),
        DayStats(day: 'Fri', value: 6),
        DayStats(day: 'Sat', value: 4),
        DayStats(day: 'Sun', value: 8),
      ],
    );

    return LineScatterWeeklyStats(
      title: 'Duration (mins)',
      stats: weeklyStats,
      height: 200,
      backgroundColor: cardColor,
      textColor: textColor,
    );
  }





  Widget _buildStreakCards() {
    return Row(
      children: [
        Expanded(
          child: _buildGlassCard(
            'Current Streak',
            '0',
            Icons.local_fire_department,
            gradient: const LinearGradient(
              colors: [Color(0xFF7166F9), Color(0xFF9C56F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlassCard(
            'Best Streak',
            '0',
            Icons.emoji_events,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(String title, String value, IconData icon, {required Gradient gradient}) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRepetitions() {
    return _buildSection(
      'Total repetitions',
      '0',
      'Since January 6, 2025',
    );
  }


  Widget _buildDuration() {
    return _buildSection(
      'Duration',
      '0 mins',
      'Since January 6, 2025',
    );

  }

  Widget _buildCompletionRate() {
    return _buildSection(
      'Completion Rate',
      '0%',
      'Keep going, you can do it!',
    );
  }

  Widget _buildFrequency() {
    return _buildSection(
      'Frequency',
      '2x / week',
      'Regular schedule',
    );
  }

  Widget _buildHabitCreatedOn() {
    return _buildSection(
      'Habit created on',
      'January 6, 2025',
      'Your journey begins',
    );
  }

  Widget _buildSection(String title, String value, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}