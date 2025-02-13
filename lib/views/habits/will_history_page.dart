import 'package:flutter/material.dart';
import 'package:farmwill_habits/views/habits/widgets/calendar_widget.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/line_scatterd_weekly_stats.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/weekly_stats_widget.dart';

class WillHistoryPage extends StatelessWidget {
  const WillHistoryPage({Key? key}) : super(key: key);

  // Custom colors for dark theme (keeping consistent with HabitDetailsPage)
  static const backgroundColor = Color(0xFF1A1A1A);
  static const cardColor = Color(0xFF2D2D2D);
  static const accentColor = Color(0xFF7166F9);
  static const positiveColor = Color(0xFF4CAF50);
  static const negativeColor = Color(0xFFFF5252);
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
          'Will History',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CalendarWidget(),
            const SizedBox(height: 32),
            _buildWillSummaryCards(),
            const SizedBox(height: 32),
            _buildWillGainedGraph(),
            const SizedBox(height: 32),
            _buildWillBreakdown(),
            const SizedBox(height: 32),
            _buildWeeklyStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildWillSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildGlassCard(
            'Total Will Gained',
            '+350',
            Icons.trending_up,
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildGlassCard(
            'Total Will Lost',
            '-120',
            Icons.trending_down,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5252), Color(0xFFFF8A80)],
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

  Widget _buildWillGainedGraph() {
    // Example data - you should replace this with actual data from your app
    final weeklyStats = WeeklyStatsValue(
      dailyStats: [
        DayStats(day: 'Mon', value: 50),
        DayStats(day: 'Tue', value: 30),
        DayStats(day: 'Wed', value: 70),
        DayStats(day: 'Thu', value: 20),
        DayStats(day: 'Fri', value: 60),
        DayStats(day: 'Sat', value: 40),
        DayStats(day: 'Sun', value: 80),
      ],
    );

    return LineScatterWeeklyStats(
      title: 'Will Gained per Day',
      stats: weeklyStats,
      height: 200,
      backgroundColor: cardColor,
      textColor: textColor,
    );
  }

  Widget _buildWillBreakdown() {
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
          const Text(
            'Will Breakdown',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildWillSourceItem(
            'Morning Meditation',
            '+150',
            positiveColor,
          ),
          const SizedBox(height: 12),
          _buildWillSourceItem(
            'Exercise Routine',
            '+120',
            positiveColor,
          ),
          const SizedBox(height: 12),
          _buildWillSourceItem(
            'Procrastination',
            '-80',
            negativeColor,
          ),
          const SizedBox(height: 12),
          _buildWillSourceItem(
            'Late Night Screen Time',
            '-40',
            negativeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildWillSourceItem(String title, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyStats() {
    // Example data for weekly stats
    final weeklyStats = WeeklyStatsValue(
      dailyStats: [
        DayStats(day: 'Mon', value: 70),
        DayStats(day: 'Tue', value: 85),
        DayStats(day: 'Wed', value: 60),
        DayStats(day: 'Thu', value: 90),
        DayStats(day: 'Fri', value: 75),
        DayStats(day: 'Sat', value: 80),
        DayStats(day: 'Sun', value: 95),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Performance',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: WeeklyStatsWidget(
              title: '',
              stats: weeklyStats,
              height: 200,
              backgroundColor: cardColor,
              textColor: textColor,
            ),
          ),
        ],
      ),
    );
  }
}