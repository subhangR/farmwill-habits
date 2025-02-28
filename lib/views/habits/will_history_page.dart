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
  final List<UserHabit> habits;
  final Map<String, HabitData> habitsData;
  final String title;

  const WillHistoryPage({
    super.key,
    required this.habits,
    required this.habitsData,
    this.title = 'Will History',
  });

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

class _WillHistoryPageState extends ConsumerState<WillHistoryPage>
    with SingleTickerProviderStateMixin {
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

    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Calculate will statistics
    _calculateWillStats();

    setState(() {
      _isLoading = false;
    });
  }

  void _calculateWillStats() {
    // Will be implemented based on provided habits and data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WillHistoryPage.backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WillHistoryPage.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
              color: WillHistoryPage.textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildTodaySection(),
                  _buildWeeklyBreakdown(),
                  _buildLast7DaysTable(),
                  _buildHabitsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTodaySection() {
    int totalGained = 0;
    int totalLost = 0;

    for (var habit in widget.habits) {
      final habitData = widget.habitsData[habit.id];
      if (habitData != null) {
        if (habit.nature == HabitNature.positive) {
          totalGained += habitData.willObtained;
        } else {
          totalLost += habitData.willObtained;
        }
      }
    }

    final netWill = totalGained - totalLost;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today',
            style: TextStyle(
              color: WillHistoryPage.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildWillCard(
                  'Gained',
                  totalGained,
                  Colors.green,
                  Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildWillCard(
                  'Lost',
                  totalLost,
                  Colors.red,
                  Icons.arrow_downward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildWillCard(
            'Net Will',
            netWill,
            netWill >= 0 ? Colors.blue : Colors.red,
            netWill >= 0 ? Icons.trending_up : Icons.trending_down,
          ),
        ],
      ),
    );
  }

  Widget _buildWillCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WillHistoryPage.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: const TextStyle(
              color: WillHistoryPage.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBreakdown() {
    // Sort habits by will gained
    final sortedHabits = List<UserHabit>.from(widget.habits)
      ..sort((a, b) {
        final aWill = widget.habitsData[a.id]?.willObtained ?? 0;
        final bWill = widget.habitsData[b.id]?.willObtained ?? 0;
        return bWill.compareTo(aWill);
      });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Breakdown',
            style: TextStyle(
              color: WillHistoryPage.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: WillHistoryPage.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedHabits.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final habit = sortedHabits[index];
                final willGained =
                    widget.habitsData[habit.id]?.willObtained ?? 0;
                return ListTile(
                  title: Text(
                    habit.name,
                    style: const TextStyle(color: WillHistoryPage.textColor),
                  ),
                  trailing: Text(
                    willGained.toString(),
                    style: TextStyle(
                      color: willGained >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLast7DaysTable() {
    final days = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: index));
      return date;
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 Days',
            style: TextStyle(
              color: WillHistoryPage.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: WillHistoryPage.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                      label: Text('Date',
                          style: TextStyle(color: WillHistoryPage.textColor))),
                  DataColumn(
                      label: Text('Gained',
                          style: TextStyle(color: Colors.green))),
                  DataColumn(
                      label: Text('Lost', style: TextStyle(color: Colors.red))),
                  DataColumn(
                      label: Text('Net',
                          style: TextStyle(color: WillHistoryPage.textColor))),
                ],
                rows: days.map((date) {
                  final gained = _calculateDayWill(date, true);
                  final lost = _calculateDayWill(date, false);
                  final net = gained - lost;

                  return DataRow(cells: [
                    DataCell(Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(color: WillHistoryPage.textColor),
                    )),
                    DataCell(Text(
                      gained.toString(),
                      style: const TextStyle(color: Colors.green),
                    )),
                    DataCell(Text(
                      lost.toString(),
                      style: const TextStyle(color: Colors.red),
                    )),
                    DataCell(Text(
                      net.toString(),
                      style: TextStyle(
                          color: net >= 0 ? Colors.green : Colors.red),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDayWill(DateTime date, bool isPositive) {
    int total = 0;
    for (var habit in widget.habits) {
      if (habit.nature ==
          (isPositive ? HabitNature.positive : HabitNature.negative)) {
        final habitData = widget.habitsData[habit.id];
        if (habitData != null) {
          total += habitData.willObtained;
        }
      }
    }
    return total;
  }

  Widget _buildHabitsList() {
    // Sort habits by total will gained
    final sortedHabits = List<UserHabit>.from(widget.habits)
      ..sort((a, b) {
        final aWill = widget.habitsData[a.id]?.willObtained ?? 0;
        final bWill = widget.habitsData[b.id]?.willObtained ?? 0;
        return bWill.compareTo(aWill);
      });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Habits Performance',
            style: TextStyle(
              color: WillHistoryPage.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedHabits.length,
            itemBuilder: (context, index) {
              final habit = sortedHabits[index];
              final willGained = widget.habitsData[habit.id]?.willObtained ?? 0;

              return Card(
                color: WillHistoryPage.cardColor,
                child: ListTile(
                  title: Text(
                    habit.name,
                    style: const TextStyle(color: WillHistoryPage.textColor),
                  ),
                  subtitle: Text(
                    habit.nature == HabitNature.positive
                        ? 'Positive Habit'
                        : 'Negative Habit',
                    style: TextStyle(
                      color: habit.nature == HabitNature.positive
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Will: $willGained',
                        style: TextStyle(
                          color: willGained >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${habit.willPerRep ?? 0} per rep',
                        style: const TextStyle(
                          color: WillHistoryPage.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
