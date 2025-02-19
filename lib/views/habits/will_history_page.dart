import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'habit_state.dart';
import '../../models/habit_data.dart';
import '../../models/habits.dart';
import 'widgets/calendar_widget.dart';
import 'widgets/weekly_stats_widgets/line_scatterd_weekly_stats.dart';
import 'widgets/weekly_stats_widgets/weekly_stats_widget.dart';

class WillHistoryPage extends ConsumerStatefulWidget {
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
  ConsumerState<WillHistoryPage> createState() => _WillHistoryPageState();
}

class _WillHistoryPageState extends ConsumerState<WillHistoryPage> {
  DateTime _selectedDate = DateTime.now();
  String _userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = true;

  // Will stats
  int _totalWillGained = 0;
  int _totalWillLost = 0;
  Map<String, int> _habitWillBreakdown = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    // Get the habit state provider
    final habitState = ref.read(habitStateProvider);

    // Load month logs and day data
    await habitState.loadHabitsAndData(_userId, _selectedDate);

    // Calculate will statistics
    _calculateWillStats();

    setState(() {
      _isLoading = false;
    });
  }

  void _calculateWillStats() {
    final habitState = ref.read(habitStateProvider);
    final monthLogs = habitState.monthLogs;
    final habits = habitState.habits;

    // Reset counters
    _totalWillGained = 0;
    _totalWillLost = 0;
    _habitWillBreakdown = {};

    // Calculate totals from all month logs
    for (var monthLog in monthLogs.values) {
      for (var dayLog in monthLog.days.values) {
        dayLog.habits.forEach((habitId, habitData) {
          // Find the habit to determine if it's positive or negative
          final habit = habits.firstWhere(
                (h) => h.id == habitId,
            orElse: () => habits.first,
          );

          final willValue = habitData.willObtained;

          // Update totals based on habit nature
          if (habit.nature == HabitNature.positive) {
            _totalWillGained += willValue;
          } else {
            _totalWillLost += willValue;
          }

          // Update breakdown by habit
          if (!_habitWillBreakdown.containsKey(habitId)) {
            _habitWillBreakdown[habitId] = 0;
          }
          _habitWillBreakdown[habitId] = (_habitWillBreakdown[habitId] ?? 0) + willValue;
        });
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _isLoading = true;
    });

    final habitState = ref.read(habitStateProvider);

    // Update selected date in provider
    habitState.updateSelectedDate(date);

    // Recalculate stats
    _calculateWillStats();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch habit state for changes
    final habitState = ref.watch(habitStateProvider);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: WillHistoryPage.backgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: WillHistoryPage.backgroundColor,
      appBar: AppBar(
        backgroundColor: WillHistoryPage.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WillHistoryPage.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Will History',
          style: TextStyle(color: WillHistoryPage.textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CalendarWidget(
              initialDate: _selectedDate,
              onDateSelected: _onDateSelected,
            ),
            const SizedBox(height: 32),
            _buildWillSummaryCards(),
            const SizedBox(height: 32),
            _buildWillGainedGraph(),
            const SizedBox(height: 32),
            _buildWillBreakdown(),
            const SizedBox(height: 32),
            _buildWeeklyTotalWill(),
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
            '+$_totalWillGained',
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
            '-$_totalWillLost',
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
    final habitState = ref.read(habitStateProvider);
    final weeklyStats = _calculateDailyWillForCurrentWeek();

    return LineScatterWeeklyStats(
      title: 'Will Points per Day',
      stats: weeklyStats,
      height: 200,
      backgroundColor: WillHistoryPage.cardColor,
      textColor: WillHistoryPage.textColor,
    );
  }

  WeeklyStatsValue _calculateDailyWillForCurrentWeek() {
    final habitState = ref.read(habitStateProvider);
    final now = DateTime.now();

    // Find the start of current week (Monday)
    final currentWeekday = now.weekday;
    final startOfWeek = now.subtract(Duration(days: currentWeekday - 1));

    final dailyStats = <DayStats>[];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dayLog = habitState.getDayLog(date);

      int willTotal = 0;
      if (dayLog != null) {
        // Sum up will points for this day
        dayLog.habits.forEach((_, habitData) {
          willTotal += habitData.willObtained;
        });
      }

      dailyStats.add(DayStats(
        day: dayNames[i],
        value: willTotal.toDouble(),
      ));
    }

    return WeeklyStatsValue(dailyStats: dailyStats);
  }

  Widget _buildWillBreakdown() {
    final habitState = ref.read(habitStateProvider);
    final habits = habitState.habits;

    // Sort habits by will contribution
    final sortedEntries = _habitWillBreakdown.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    // Take top 5 habits or all if less than 5
    final topHabits = sortedEntries.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WillHistoryPage.cardColor,
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
              color: WillHistoryPage.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ...topHabits.map((entry) {
            final habit = habits.firstWhere(
                  (h) => h.id == entry.key,
              orElse: () => habits.first,
            );

            final willValue = entry.value;
            final isPositive = willValue >= 0;
            final color = isPositive ?
            WillHistoryPage.positiveColor :
            WillHistoryPage.negativeColor;

            return Column(
              children: [
                _buildWillSourceItem(
                  habit.name,
                  (isPositive ? '+' : '') + willValue.toString(),
                  color,
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),

          if (topHabits.isEmpty)
            const Text(
              'No will data available for the selected period',
              style: TextStyle(
                color: WillHistoryPage.secondaryTextColor,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWillSourceItem(String title, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: WillHistoryPage.secondaryTextColor,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
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

  Widget _buildWeeklyTotalWill() {
    final weeklyWillStats = _calculateWeeklyTotalWill();
    final netWill = _totalWillGained - _totalWillLost;
    final selectedDateFormatted = DateFormat('MMMM yyyy').format(_selectedDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WillHistoryPage.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Will Performance - $selectedDateFormatted',
            style: const TextStyle(
              color: WillHistoryPage.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Net Will: ${netWill >= 0 ? "+$netWill" : netWill}',
            style: TextStyle(
              color: netWill >= 0 ?
              WillHistoryPage.positiveColor :
              WillHistoryPage.negativeColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: WeeklyStatsWidget(
              title: '',
              stats: weeklyWillStats,
              height: 200,
              backgroundColor: WillHistoryPage.cardColor,
              textColor: WillHistoryPage.textColor,
            ),
          ),
        ],
      ),
    );
  }

  WeeklyStatsValue _calculateWeeklyTotalWill() {
    final habitState = ref.read(habitStateProvider);
    final now = DateTime.now();

    // Calculate the start of each week for the last 4 weeks
    final List<DateTime> weekStarts = [];
    final currentWeekStart = DateTime(
        now.year, now.month, now.day - (now.weekday - 1)
    );

    for (int i = 0; i < 4; i++) {
      weekStarts.add(
          currentWeekStart.subtract(Duration(days: 7 * i))
      );
    }
    weekStarts.sort(); // Sort chronologically

    final dailyStats = <DayStats>[];
    final weekNames = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];

    // For each week, calculate the total will
    for (int i = 0; i < weekStarts.length; i++) {
      final weekStart = weekStarts[i];
      int weekTotal = 0;

      // Sum will for each day in the week
      for (int day = 0; day < 7; day++) {
        final date = weekStart.add(Duration(days: day));
        final dayLog = habitState.getDayLog(date);

        if (dayLog != null) {
          dayLog.habits.forEach((_, habitData) {
            weekTotal += habitData.willObtained;
          });
        }
      }

      dailyStats.add(DayStats(
        day: weekNames[i],
        value: weekTotal.toDouble(),
      ));
    }

    return WeeklyStatsValue(dailyStats: dailyStats);
  }
}