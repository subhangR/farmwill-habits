import 'package:farmwill_habits/models/habits.dart';
import 'package:farmwill_habits/views/habits/create_habit_page_v2.dart';
import 'package:farmwill_habits/views/habits/widgets/calendar_widget.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/circular_weekly_stats.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/line_scatterd_weekly_stats.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/monthly_stats.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_stats_widgets/weekly_stats_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/habit_data.dart';
import '../../services/habit_service.dart';
import 'create_habit_page.dart';
import 'habit_list_screen.dart';
import 'habit_state.dart';

class HabitDetailsPage extends ConsumerStatefulWidget {
  final UserHabit userHabit;

  const HabitDetailsPage({Key? key, required this.userHabit}) : super(key: key);

  static const backgroundColor = Color(0xFF1A1A1A);
  static const cardColor = Color(0xFF2D2D2D);
  static const accentColor = Color(0xFF7166F9);
  static const textColor = Color(0xFFF5F5F5);
  static const secondaryTextColor = Color(0xFFB3B3B3);

  @override
  ConsumerState<HabitDetailsPage> createState() => _HabitDetailsPageState();
}

class _HabitDetailsPageState extends ConsumerState<HabitDetailsPage> {
  DateTime _selectedDate = DateTime.now();
  String _userId = FirebaseAuth.instance.currentUser!.uid;
  UserHabit? _habit;
  HabitData? _habitData;
  bool _isLoading = true;

  // Calculated stats
  int _totalRepetitions = 0;
  int _totalDuration = 0;
  double _completionRate = 0.0;
  int _currentStreak = 0;
  int _bestStreak = 0;

  // Add new state variables for lifetime stats
  int _lifetimeReps = 0;
  int _lifetimeWill = 0;

  // Add state variables for today's stats
  int _todayReps = 0;
  int _todayWill = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    final habitState = ref.read(habitStateProvider);
    await habitState.loadHabitsAndData(_userId, _selectedDate);

    // Calculate lifetime stats
    _calculateLifetimeStats();

    // Calculate today's stats
    _calculateTodayStats();

    setState(() {
      _isLoading = false;
    });
  }

  void _calculateLifetimeStats() {
    final habitState = ref.read(habitStateProvider);
    final monthLogs = habitState.monthLogs;

    _lifetimeReps = 0;
    _lifetimeWill = 0;

    for (var monthLog in monthLogs.values) {
      for (var dayLog in monthLog.days.values) {
        if (dayLog.habits.containsKey(widget.userHabit.id)) {
          final habitData = dayLog.habits[widget.userHabit.id]!;
          _lifetimeReps += habitData.reps;
          _lifetimeWill += habitData.willObtained;
        }
      }
    }
  }

  void _calculateTodayStats() {
    final habitState = ref.read(habitStateProvider);
    final todayLog = habitState.getDayLog(_selectedDate);

    if (todayLog?.habits.containsKey(widget.userHabit.id) ?? false) {
      final habitData = todayLog!.habits[widget.userHabit.id]!;
      _todayReps = habitData.reps;
      _todayWill = habitData.willObtained;
    } else {
      _todayReps = 0;
      _todayWill = 0;
    }
  }

  void _calculateStats() {
    final habitState = ref.read(habitStateProvider);
    final monthLogs = habitState.monthLogs;

    // Reset counters
    _totalRepetitions = 0;
    _totalDuration = 0;
    int totalDaysScheduled = 0;
    int totalDaysCompleted = 0;

    // Get current day log
    final dayLog = habitState.getDayLog(_selectedDate);
    if (dayLog != null && dayLog.habits.containsKey(widget.userHabit.id)) {
      _habitData = dayLog.habits[widget.userHabit.id];
    } else {
      _habitData = null;
    }

    // Calculate stats from all month logs
    for (var monthLog in monthLogs.values) {
      for (var entry in monthLog.days.entries) {
        final dayKey = entry.key;
        final dayLog = entry.value;

        if (dayLog.habits.containsKey(widget.userHabit.id)) {
          final habitData = dayLog.habits[widget.userHabit.id]!;

          // Add to totals
          _totalRepetitions += habitData.reps;
          _totalDuration += habitData.duration;

          // Check if this day was scheduled for the habit
          final date = _dateFromMonthLogAndDayKey(monthLog.monthKey, dayKey);
          if (date != null && _isHabitScheduledForDay(date)) {
            totalDaysScheduled++;
            if (habitData.isCompleted) {
              totalDaysCompleted++;
            }
          }
        }
      }
    }

    // Calculate completion rate
    _completionRate = totalDaysScheduled > 0
        ? (totalDaysCompleted / totalDaysScheduled) * 100
        : 0.0;

    // Calculate streaks
    _calculateStreaks();
  }

  void _calculateStreaks() {
    final habitState = ref.read(habitStateProvider);
    final monthLogs = habitState.monthLogs;

    // Current streak (consecutive days completed up to selected date)
    _currentStreak = 0;
    DateTime current = _selectedDate;
    bool streakBroken = false;

    while (!streakBroken) {
      final monthKey =
          '${current.year}-${current.month.toString().padLeft(2, '0')}';
      final dayKey = current.day.toString().padLeft(2, '0');

      final monthLog = monthLogs[monthKey];
      if (monthLog == null) {
        streakBroken = true;
        continue;
      }

      final dayLog = monthLog.days[dayKey];
      if (dayLog == null) {
        streakBroken = true;
        continue;
      }

      final habitData = dayLog.habits[widget.userHabit.id];
      if (habitData == null || !habitData.isCompleted) {
        streakBroken = true;
        continue;
      }

      // Only count days that are scheduled for this habit
      if (_isHabitScheduledForDay(current)) {
        _currentStreak++;
      }

      // Go to previous day
      current = current.subtract(const Duration(days: 1));
    }

    // Best streak (longest streak in available data)
    _bestStreak = 0;
    int tempStreak = 0;

    // Sort month logs chronologically
    final sortedMonthKeys = monthLogs.keys.toList()..sort();

    for (var monthKey in sortedMonthKeys) {
      final monthLog = monthLogs[monthKey]!;
      final sortedDayKeys = monthLog.days.keys.toList()..sort();

      for (var dayKey in sortedDayKeys) {
        final dayLog = monthLog.days[dayKey]!;
        final habitData = dayLog.habits[widget.userHabit.id];

        final date = _dateFromMonthLogAndDayKey(monthKey, dayKey);
        if (date != null && _isHabitScheduledForDay(date)) {
          if (habitData != null && habitData.isCompleted) {
            tempStreak++;
            if (tempStreak > _bestStreak) {
              _bestStreak = tempStreak;
            }
          } else {
            tempStreak = 0;
          }
        }
      }
    }
  }

  bool _isHabitScheduledForDay(DateTime date) {
    if (widget.userHabit.weeklySchedule == null) return true;

    final weekday = date.weekday;
    switch (weekday) {
      case 1:
        return widget.userHabit.weeklySchedule!.monday;
      case 2:
        return widget.userHabit.weeklySchedule!.tuesday;
      case 3:
        return widget.userHabit.weeklySchedule!.wednesday;
      case 4:
        return widget.userHabit.weeklySchedule!.thursday;
      case 5:
        return widget.userHabit.weeklySchedule!.friday;
      case 6:
        return widget.userHabit.weeklySchedule!.saturday;
      case 7:
        return widget.userHabit.weeklySchedule!.sunday;
      default:
        return false;
    }
  }

  DateTime? _dateFromMonthLogAndDayKey(String monthKey, String dayKey) {
    try {
      final parts = monthKey.split('-');
      if (parts.length != 2) return null;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(dayKey);

      return DateTime(year, month, day);
    } catch (e) {
      return null;
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
    _calculateStats();

    setState(() {
      _isLoading = false;
    });
  }

  // Method to handle editing the habit
  void _editHabit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditHabitPageV2(userHabit: widget.userHabit),
      ),
    ).then((value) {
      // Refresh data when returning from edit page
      if (value == true) {
        _loadInitialData();
      }
    });
  }

  // Method to perform the actual deletion
  Future<void> _confirmDelete() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("Confirming deletion of habit: ${widget.userHabit.id}");

      // Use the habitState provider to delete the habit
      final habitState = ref.read(habitStateProvider);
      await habitState.deleteHabit(_userId, widget.userHabit.id);

      print("Habit deleted successfully through provider");

      // Return to previous screen after successful deletion
      if (mounted) {
        print("Navigating back after deletion");
        Navigator.pop(
            context, true); // Pass true to indicate successful deletion
      }
    } catch (e) {
      print("Error in _confirmDelete: $e");

      setState(() {
        _isLoading = false;
      });

      // Show error dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete habit: $e')),
        );
      }
    }
  }

  // Method to handle deleting the habit
  void _deleteHabit() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: HabitDetailsPage.cardColor,
          title: const Text(
            'Delete Habit',
            style: TextStyle(color: HabitDetailsPage.textColor),
          ),
          content: Text(
            'Are you sure you want to delete "${widget.userHabit.name}"? This action cannot be undone.',
            style: const TextStyle(color: HabitDetailsPage.secondaryTextColor),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: HabitDetailsPage.accentColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmDelete();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HabitDetailsPage.backgroundColor,
      appBar: AppBar(
        backgroundColor: HabitDetailsPage.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: HabitDetailsPage.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _habit?.name ?? widget.userHabit.name,
          style: const TextStyle(
              color: HabitDetailsPage.textColor, fontWeight: FontWeight.w600),
        ),
        actions: [
          // Edit (pencil) icon
          IconButton(
            icon: const Icon(Icons.edit, color: HabitDetailsPage.textColor),
            tooltip: 'Edit habit',
            onPressed: _editHabit,
          ),
          // Delete icon
          IconButton(
            icon: const Icon(Icons.delete, color: HabitDetailsPage.textColor),
            tooltip: 'Delete habit',
            onPressed: _deleteHabit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLifetimeSection(),
            const SizedBox(height: 32),
            _buildTodaySection(),
            const SizedBox(height: 32),
            _buildWeekSection(),
            const SizedBox(height: 32),
            _buildLast7DaysSection(),
            const SizedBox(height: 32),
            _buildMonthSection(),
            const SizedBox(height: 32),
            _buildDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLifetimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lifetime Stats',
          style: TextStyle(
            color: HabitDetailsPage.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildStreakCards(),
        const SizedBox(height: 16),
        _buildSection(
          'Total Repetitions',
          _lifetimeReps.toString(),
          'Lifetime achievement',
        ),
        const SizedBox(height: 16),
        _buildSection(
          'Total Will Obtained',
          _lifetimeWill.toString(),
          'Lifetime will points',
        ),
      ],
    );
  }

  Widget _buildTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today',
          style: TextStyle(
            color: HabitDetailsPage.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildSection(
          'Progress',
          '$_todayReps/${widget.userHabit.targetReps}',
          'Today\'s repetitions',
        ),
        const SizedBox(height: 16),
        _buildSection(
          'Will Obtained',
          _todayWill.toString(),
          'Today\'s will points',
        ),
      ],
    );
  }

  Widget _buildWeekSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Week',
          style: TextStyle(
            color: HabitDetailsPage.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CalendarWidget(
          initialDate: _selectedDate,
          onDateSelected: _onDateSelected,
        ),
        const SizedBox(height: 16),
        _buildWeeklyStatsTable(),
      ],
    );
  }

  Widget _buildWeeklyStatsTable() {
    final weekStats = _calculateWeekStats();

    return Container(
      decoration: BoxDecoration(
        color: HabitDetailsPage.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWeeklyTableRow('Day', 'Reps', 'Will', isHeader: true),
          const Divider(color: HabitDetailsPage.secondaryTextColor),
          ...weekStats.entries.map((entry) => _buildWeeklyTableRow(
                entry.key,
                '${entry.value.reps}/${widget.userHabit.targetReps}',
                entry.value.will.toString(),
              )),
        ],
      ),
    );
  }

  Widget _buildWeeklyTableRow(String day, String reps, String will,
      {bool isHeader = false}) {
    final textStyle = TextStyle(
      color:
          isHeader ? HabitDetailsPage.accentColor : HabitDetailsPage.textColor,
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(day, style: textStyle)),
          Expanded(child: Text(reps, style: textStyle)),
          Expanded(child: Text(will, style: textStyle)),
        ],
      ),
    );
  }

  Map<String, WeeklyStats> _calculateWeekStats() {
    final habitState = ref.read(habitStateProvider);
    final stats = <String, WeeklyStats>{};
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Get start of week
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dayLog = habitState.getDayLog(date);
      final habitData = dayLog?.habits[widget.userHabit.id];

      stats[weekDays[i]] = WeeklyStats(
        reps: habitData?.reps ?? 0,
        will: habitData?.willObtained ?? 0,
      );
    }

    return stats;
  }

  Widget _buildStreakCards() {
    return Row(
      children: [
        Expanded(
          child: _buildGlassCard(
            'Current Streak',
            ref
                .read(habitStateProvider)
                .getCurrentStreak(widget.userHabit.id)
                .toString(),
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
            ref
                .read(habitStateProvider)
                .getBestStreak(widget.userHabit.id)
                .toString(),
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

  Widget _buildGlassCard(String title, String value, IconData icon,
      {required Gradient gradient}) {
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

  Widget _buildSection(String title, String value, String subtitle) {
    // Apply color based on goal type
    Color sectionColor;
    if (widget.userHabit.nature == HabitNature.positive) {
      sectionColor = const Color(0xFF4CAF50).withOpacity(0.2);
    } else {
      sectionColor = const Color(0xFFFF5722)
          .withOpacity(0.2); // Orange tint for negative reps
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HabitDetailsPage.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: sectionColor,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: HabitDetailsPage.secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: HabitDetailsPage.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: HabitDetailsPage.secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLast7DaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last 7 Days',
          style: TextStyle(
            color: HabitDetailsPage.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildLast7DaysTable(),
      ],
    );
  }

  Widget _buildLast7DaysTable() {
    final stats = _calculateLast7DaysStats();

    return Container(
      decoration: BoxDecoration(
        color: HabitDetailsPage.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWeeklyTableRow('Date', 'Reps', 'Will', isHeader: true),
          const Divider(color: HabitDetailsPage.secondaryTextColor),
          ...stats.entries.map((entry) => _buildWeeklyTableRow(
                DateFormat('MMM d').format(entry.key),
                '${entry.value.reps}/${widget.userHabit.targetReps}',
                entry.value.will.toString(),
              )),
        ],
      ),
    );
  }

  Map<DateTime, WeeklyStats> _calculateLast7DaysStats() {
    final habitState = ref.read(habitStateProvider);
    final stats = <DateTime, WeeklyStats>{};

    // Get last 7 days including today
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dayLog = habitState.getDayLog(date);
      final habitData = dayLog?.habits[widget.userHabit.id];

      stats[date] = WeeklyStats(
        reps: habitData?.reps ?? 0,
        will: habitData?.willObtained ?? 0,
      );
    }

    return Map.fromEntries(
        stats.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  Widget _buildMonthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Overview',
          style: TextStyle(
            color: HabitDetailsPage.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildMonthlyStats(),
      ],
    );
  }

  Widget _buildMonthlyStats() {
    final habitState = ref.read(habitStateProvider);
    final selectedMonthLog = _getSelectedMonthLog();
    final dailyCompletions = <DayCompletion>[];

    if (selectedMonthLog != null) {
      final daysInMonth =
          DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final dayKey = day.toString().padLeft(2, '0');
        final dayLog = selectedMonthLog.days[dayKey];
        final date = DateTime(_selectedDate.year, _selectedDate.month, day);

        double completion = 0.0;
        if (dayLog != null && dayLog.habits.containsKey(widget.userHabit.id)) {
          final habitData = dayLog.habits[widget.userHabit.id]!;
          completion = habitData.reps / widget.userHabit.targetReps;
        }

        dailyCompletions.add(DayCompletion(
          date: date,
          completion: completion,
        ));
      }
    }

    final monthlyStats = MonthlyStatsValue(
      month: _selectedDate,
      dailyCompletions: dailyCompletions,
    );

    return MonthlyCalendarStats(
      title: DateFormat('MMMM yyyy').format(_selectedDate),
      stats: monthlyStats,
      height: 400,
      baseColor: HabitDetailsPage.accentColor,
      backgroundColor: HabitDetailsPage.cardColor,
      textColor: HabitDetailsPage.textColor,
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            color: HabitDetailsPage.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFrequency(),
        const SizedBox(height: 16),
        _buildHabitCreatedOn(),
      ],
    );
  }

  UserMonthLog? _getSelectedMonthLog() {
    final habitState = ref.read(habitStateProvider);
    final monthKey =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
    return habitState.monthLogs[monthKey];
  }

  Widget _buildFrequency() {
    final weeklySchedule = widget.userHabit.weeklySchedule;
    String frequencyText = 'Daily';

    if (weeklySchedule != null) {
      int daysCount = 0;
      if (weeklySchedule.monday) daysCount++;
      if (weeklySchedule.tuesday) daysCount++;
      if (weeklySchedule.wednesday) daysCount++;
      if (weeklySchedule.thursday) daysCount++;
      if (weeklySchedule.friday) daysCount++;
      if (weeklySchedule.saturday) daysCount++;
      if (weeklySchedule.sunday) daysCount++;

      if (daysCount < 7) {
        frequencyText = '$daysCount times per week';
      }
    }

    return _buildSection(
      'Frequency',
      frequencyText,
      _getFrequencyDetailText(),
    );
  }

  String _getFrequencyDetailText() {
    final weeklySchedule = widget.userHabit.weeklySchedule;
    if (weeklySchedule == null) return 'Every day';

    List<String> days = [];
    if (weeklySchedule.monday) days.add('Mon');
    if (weeklySchedule.tuesday) days.add('Tue');
    if (weeklySchedule.wednesday) days.add('Wed');
    if (weeklySchedule.thursday) days.add('Thu');
    if (weeklySchedule.friday) days.add('Fri');
    if (weeklySchedule.saturday) days.add('Sat');
    if (weeklySchedule.sunday) days.add('Sun');

    if (days.length == 7) return 'Every day';
    if (days.isEmpty) return 'No days scheduled';
    return days.join(', ');
  }

  Widget _buildHabitCreatedOn() {
    final createdDate = widget.userHabit.createdAt;
    final formattedDate = DateFormat('MMMM d, yyyy').format(createdDate);
    final natureType = widget.userHabit.nature == HabitNature.positive
        ? 'Positive'
        : 'Negative';

    return _buildSection(
      'Created on',
      formattedDate,
      'Type: $natureType',
    );
  }
}

class WeeklyStats {
  final int reps;
  final int will;

  WeeklyStats({required this.reps, required this.will});
}
