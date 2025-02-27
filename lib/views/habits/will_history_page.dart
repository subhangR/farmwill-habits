import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import 'habit_state.dart';
import '../../models/habit_data.dart';
import '../../models/habits.dart';
import 'widgets/calendar_widget.dart';
import 'widgets/weekly_stats_widgets/line_scatterd_weekly_stats.dart';
import 'widgets/weekly_stats_widgets/weekly_stats_widget.dart';

class WillHistoryPage extends ConsumerStatefulWidget {
  const WillHistoryPage({super.key});

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

class _WillHistoryPageState extends ConsumerState<WillHistoryPage> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Will stats
  int _totalWillGained = 0;
  int _totalWillLost = 0;
  Map<String, int> _habitWillBreakdown = {};

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    _animationController.forward();
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

    return Scaffold(
      backgroundColor: WillHistoryPage.backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
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
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadInitialData,
        color: Colors.blue.shade700,
        backgroundColor: Colors.grey.shade900,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: WillHistoryPage.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: CalendarWidget(
                    initialDate: _selectedDate,
                    onDateSelected: _onDateSelected,
                  ),
                ),
                const SizedBox(height: 32),
                _buildWillSummaryCards(),
                const SizedBox(height: 32),
                _buildWillGainedGraph(),
                const SizedBox(height: 32),
                _buildWillBreakdown(),
                const SizedBox(height: 32),
                _buildWeeklyTotalWill(),
                const SizedBox(height: 16),
              ],
            ),
          ),
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
            '$_totalWillLost',
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
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: Colors.white, size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWillGainedGraph() {
    final weeklyStats = _calculateDailyWillForCurrentWeek();

    // Fix for the error: ensure all values have at least one non-zero value
    // and set a default horizontal interval
    bool allZero = weeklyStats.dailyStats.every((stat) => stat.value == 0);

    if (allZero) {
      // If all values are zero, we'll show a placeholder message instead
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
              'Will Points per Day',
              style: TextStyle(
                color: WillHistoryPage.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 60,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No data available for this week',
                    style: TextStyle(
                      color: WillHistoryPage.secondaryTextColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete some habits to see your progress',
                    style: TextStyle(
                      color: WillHistoryPage.secondaryTextColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    }

    // If we have non-zero values, display the chart
    try {
      return LineScatterWeeklyStats(
        title: 'Will Points per Day',
        stats: weeklyStats,
        height: 200,
        backgroundColor: WillHistoryPage.cardColor,
        textColor: WillHistoryPage.textColor,
      );
    } catch (e) {
      // Fallback widget in case the chart still throws an error
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WillHistoryPage.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Will Points per Day',
              style: TextStyle(
                color: WillHistoryPage.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Chart could not be displayed',
                style: TextStyle(color: WillHistoryPage.secondaryTextColor),
              ),
            ),
            SizedBox(height: 80),
          ],
        ),
      );
    }
  }

  WeeklyStatsValue _calculateDailyWillForCurrentWeek() {
    final habitState = ref.read(habitStateProvider);
    final now = DateTime.now();

    // Find the start of current week (Monday)
    final currentWeekday = now.weekday;
    final startOfWeek = now.subtract(Duration(days: currentWeekday - 1));

    final dailyStats = <DayStats>[];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Add a small non-zero value to ensure at least one data point
    // This prevents the FlGridData.horizontalInterval = 0 error
    double minValue = 0.01;
    double maxValue = minValue;

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dayLog = habitState.getDayLog(date);

      double willTotal = 0;
      if (dayLog != null) {
        // Sum up will points for this day
        dayLog.habits.forEach((_, habitData) {
          willTotal += habitData.willObtained.toDouble();
        });
      }

      // Ensure value is never exactly 0 to prevent the chart error
      if (willTotal == 0) {
        willTotal = minValue;
      } else if (willTotal > maxValue) {
        maxValue = willTotal;
      }

      dailyStats.add(DayStats(
        day: dayNames[i],
        value: willTotal,
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
          const Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: Colors.blue,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Will Breakdown',
                style: TextStyle(
                  color: WillHistoryPage.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (topHabits.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 40,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No will data available yet',
                      style: TextStyle(
                        color: WillHistoryPage.secondaryTextColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
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

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildWillSourceItem(
                  habit.name,
                  (isPositive ? '+' : '') + willValue.toString(),
                  color,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWillSourceItem(String title, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: WillHistoryPage.textColor,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTotalWill() {
    final weeklyWillStats = _calculateWeeklyTotalWill();
    final netWill = _totalWillGained - _totalWillLost;
    final selectedDateFormatted = DateFormat('MMMM yyyy').format(_selectedDate);

    // Fix for the error: ensure all values have at least one non-zero value
    bool allZero = weeklyWillStats.dailyStats.every((stat) => stat.value == 0);

    if (allZero) {
      // If all values are zero, show a placeholder instead
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
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.insert_chart_outlined,
                    size: 60,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No weekly data available yet',
                    style: TextStyle(
                      color: WillHistoryPage.secondaryTextColor,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      );
    }

    try {
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: _getMaxWillPoints() * 1.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: _getMaxWillPoints() > 10 ? _getMaxWillPoints() / 5 : 2,
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    titlesData: const FlTitlesData(show: true),
                    lineBarsData: _getLineBarsData(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Fallback widget if there's still an error
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
            const Center(
              child: Text(
                'Chart could not be displayed',
                style: TextStyle(color: WillHistoryPage.secondaryTextColor),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }
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

    // Add a small non-zero value to ensure at least one data point
    double minValue = 0.01;
    double maxValue = minValue;

    // For each week, calculate the total will
    for (int i = 0; i < weekStarts.length; i++) {
      final weekStart = weekStarts[i];
      double weekTotal = 0;

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

      // Ensure value is never exactly 0 to prevent chart error
      if (weekTotal == 0) {
        weekTotal = minValue;
      } else if (weekTotal > maxValue) {
        maxValue = weekTotal;
      }

      dailyStats.add(DayStats(
        day: weekNames[i],
        value: weekTotal,
      ));
    }

    return WeeklyStatsValue(dailyStats: dailyStats);
  }

  double _getMaxWillPoints() {
    final weeklyWillStats = _calculateWeeklyTotalWill();
    double maxPoints = 10; // Default minimum
    
    for (var stat in weeklyWillStats.dailyStats) {
      if (stat.value > maxPoints) {
        maxPoints = stat.value;
      }
    }
    
    return maxPoints;
  }

  List<LineChartBarData> _getLineBarsData() {
    final weeklyWillStats = _calculateWeeklyTotalWill();
    final spots = <FlSpot>[];
    
    for (int i = 0; i < weeklyWillStats.dailyStats.length; i++) {
      spots.add(FlSpot(i.toDouble(), weeklyWillStats.dailyStats[i].value));
    }
    
    return [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        color: Colors.blue,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
    ];
  }
}