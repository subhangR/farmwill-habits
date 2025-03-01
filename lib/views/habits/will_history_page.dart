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

enum SortOption {
  willGained,
  willFarmable,
  willPerRep,
}

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

  int _visibleWeeklyItems = 10;
  int _visiblePerformanceItems = 10;

  SortOption _currentSortOption = SortOption.willGained;

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
                  _buildTodayBreakdown(),
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
    int maxFarmableWill = 0;

    for (var habit in widget.habits) {
      final habitData = widget.habitsData[habit.id];

      // Calculate current will obtained
      if (habitData != null) {
        if (habit.nature == HabitNature.positive) {
          totalGained += habitData.willObtained;
        } else {
          totalLost += habitData.willObtained;
        }
      }

      if (habit.nature == HabitNature.positive) {
        if (habit.maxWill != null && habit.maxWill! > 0) {
          maxFarmableWill += habit.maxWill!;
        } else if (habit.targetReps != null && habit.willPerRep != null) {
          maxFarmableWill += habit.targetReps! * habit.willPerRep!;
        }
      }

      // Add starting will if present
      if (habit.startingWill != null) {
        maxFarmableWill += habit.startingWill!;
      }
    }

    final netWill = totalGained + totalLost;
    final willProgress = maxFarmableWill > 0
        ? ((totalGained / maxFarmableWill) * 100).toStringAsFixed(1)
        : '0.0';

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
          const SizedBox(height: 16),
          _buildWillCard(
            'Max Farmable Will',
            maxFarmableWill,
            WillHistoryPage.accentColor,
            Icons.agriculture,
          ),
          const SizedBox(height: 16),
          _buildProgressCard(
            'Progress',
            '$netWill / $maxFarmableWill',
            '$willProgress%',
            WillHistoryPage.accentColor,
            Icons.bar_chart,
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

  Widget _buildProgressCard(String title, String fraction, String percentage,
      Color color, IconData icon) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fraction,
                style: const TextStyle(
                  color: WillHistoryPage.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                percentage,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayBreakdown() {
    var habits = List<UserHabit>.from(widget.habits);

    // Sort based on selected option
    habits.sort((a, b) {
      switch (_currentSortOption) {
        case SortOption.willGained:
          final aWill = widget.habitsData[a.id]?.willObtained ?? 0;
          final bWill = widget.habitsData[b.id]?.willObtained ?? 0;
          return bWill.compareTo(aWill);

        case SortOption.willFarmable:
          final aMax = _calculateMaxWill(a);
          final bMax = _calculateMaxWill(b);
          return bMax.compareTo(aMax);

        case SortOption.willPerRep:
          final aPerRep = a.willPerRep ?? 0;
          final bPerRep = b.willPerRep ?? 0;
          return bPerRep.compareTo(aPerRep);
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today Breakdown',
                style: TextStyle(
                  color: WillHistoryPage.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PopupMenuButton<SortOption>(
                icon: const Icon(Icons.sort, color: WillHistoryPage.textColor),
                onSelected: (SortOption option) {
                  setState(() {
                    _currentSortOption = option;
                  });
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: SortOption.willGained,
                    child: Text('Sort by Will Gained'),
                  ),
                  const PopupMenuItem(
                    value: SortOption.willFarmable,
                    child: Text('Sort by Max Will'),
                  ),
                  const PopupMenuItem(
                    value: SortOption.willPerRep,
                    child: Text('Sort by Will/Rep'),
                  ),
                ],
              ),
            ],
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
              itemCount: habits.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final habit = habits[index];
                final willGained =
                    widget.habitsData[habit.id]?.willObtained ?? 0;
                final maxWill = _calculateMaxWill(habit);

                return ListTile(
                  title: Text(
                    habit.name,
                    style: const TextStyle(color: WillHistoryPage.textColor),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(
                        habit.nature == HabitNature.positive
                            ? Icons.add_circle
                            : Icons.remove_circle,
                        color: habit.nature == HabitNature.positive
                            ? Colors.green
                            : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${habit.willPerRep ?? 0}/rep',
                        style: const TextStyle(
                          color: WillHistoryPage.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$willGained / $maxWill',
                        style: TextStyle(
                          color: willGained >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${((willGained / maxWill) * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: WillHistoryPage.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _calculateMaxWill(UserHabit habit) {
    if (habit.nature != HabitNature.positive) return 0;

    int maxWill = 0;
    if (habit.maxWill != null && habit.maxWill! > 0) {
      maxWill = habit.maxWill!;
    } else if (habit.targetReps != null && habit.willPerRep != null) {
      maxWill = habit.targetReps! * habit.willPerRep!;
    }

    if (habit.startingWill != null) {
      maxWill += habit.startingWill!;
    }

    return maxWill;
  }

  Widget _buildWeeklyBreakdown() {
    // Sort habits by will gained
    final sortedHabits = List<UserHabit>.from(widget.habits)
      ..sort((a, b) {
        final aWill = widget.habitsData[a.id]?.willObtained ?? 0;
        final bWill = widget.habitsData[b.id]?.willObtained ?? 0;
        return bWill.compareTo(aWill);
      });

    final hasMoreItems = sortedHabits.length > _visibleWeeklyItems;

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
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedHabits.length.clamp(0, _visibleWeeklyItems),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final habit = sortedHabits[index];
                    final willGained =
                        widget.habitsData[habit.id]?.willObtained ?? 0;
                    return ListTile(
                      title: Text(
                        habit.name,
                        style:
                            const TextStyle(color: WillHistoryPage.textColor),
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
                if (hasMoreItems)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _visibleWeeklyItems += 10;
                      });
                    },
                    child: Text(
                      'Show More (${sortedHabits.length - _visibleWeeklyItems} remaining)',
                      style:
                          const TextStyle(color: WillHistoryPage.accentColor),
                    ),
                  ),
              ],
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
    final sortedHabits = List<UserHabit>.from(widget.habits)
      ..sort((a, b) {
        final aWill = widget.habitsData[a.id]?.willObtained ?? 0;
        final bWill = widget.habitsData[b.id]?.willObtained ?? 0;
        return bWill.compareTo(aWill);
      });

    final hasMoreItems = sortedHabits.length > _visiblePerformanceItems;

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
            itemCount: sortedHabits.length.clamp(0, _visiblePerformanceItems) +
                (hasMoreItems ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _visiblePerformanceItems) {
                return TextButton(
                  onPressed: () {
                    setState(() {
                      _visiblePerformanceItems += 10;
                    });
                  },
                  child: Text(
                    'Show More (${sortedHabits.length - _visiblePerformanceItems} remaining)',
                    style: const TextStyle(color: WillHistoryPage.accentColor),
                  ),
                );
              }

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
