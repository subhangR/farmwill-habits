// Enhanced UserHabitState with complete state management
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../models/goals.dart';
import '../../models/habit_data.dart';
import '../../models/habits.dart';
import '../../repositories/habits_repository.dart';

final habitStateProvider = ChangeNotifierProvider<UserHabitState>((ref) => UserHabitState());
// Enhanced UserHabitState with streak calculation methods

class UserHabitState extends ChangeNotifier {
  final HabitsRepository _habitsRepository = GetIt.I<HabitsRepository>();

  List<UserHabit> _habits = [];
  Map<String, UserMonthLog> _monthLogs = {};
  Map<String, HabitData> _habitsData = {};
  DateTime _selectedDate = DateTime.now();
  String? _error;
  int _willPoints = 0;
  bool _isLoading = false;

  // Getters
  List<UserHabit> get habits => _habits;
  Map<String, UserMonthLog> get monthLogs => _monthLogs;
  Map<String, HabitData> get habitsData => _habitsData;
  DateTime get selectedDate => _selectedDate;
  String? get error => _error;
  int get willPoints => _willPoints;
  bool get isLoading => _isLoading;

  // Update selected date and refresh data
  void updateSelectedDate(DateTime date) {
    // Normalize date to remove time component for consistent comparison
    _selectedDate = DateTime(date.year, date.month, date.day);

    // Update habits data for the selected date
    final dayLog = getDayLog(_selectedDate);
    if (dayLog != null) {
      _habitsData = dayLog.habits;

      // Recalculate will points for the selected date
      _willPoints = 0;
      dayLog.habits.forEach((_, habitData) {
        _willPoints += habitData.willObtained;
      });
    } else {
      _habitsData = {};
      _willPoints = 0;
    }

    notifyListeners();
  }

  // Get day log for a specific date
  UserDayLog? getDayLog(DateTime date) {
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    final dayKey = date.day.toString().padLeft(2, '0');

    // Get the month log for the given date
    final monthLog = _monthLogs[monthKey];
    if (monthLog == null) return null;

    // Return the day log for the specified day
    return monthLog.days[dayKey];
  }
  Future<void> loadHabitsAndData(String userId, [DateTime? date]) async {
    try {
      _isLoading = true;
      _error = null;

      // Use provided date or current selected date
      final selectedDate = date ?? _selectedDate;

      // Load habits
      final habits = await _habitsRepository.getAllHabits(userId);

      // Load month logs
      final monthLogs = await _habitsRepository.getAllLogs(userId);

      // Load goals
      final userGoals = await _habitsRepository.getAllGoals(userId);

      // Convert list of month logs to map
      final Map<String, UserMonthLog> monthLogsMap = {};
      if (monthLogs != null) {
        for (var log in monthLogs) {
          monthLogsMap[log.monthKey] = log;
        }
      }

      // Get current day's habit data
      final currentDayLog = _getDayLogFromMap(selectedDate, monthLogsMap);

      // Calculate total will points from habit data
      int totalWill = 0;
      if (currentDayLog != null) {
        currentDayLog.habits.forEach((_, habitData) {
          totalWill += habitData.willObtained;
        });
      }

      // Update state
      _habits = habits;
      _monthLogs = monthLogsMap;
      _habitsData = currentDayLog != null ? currentDayLog.habits : {};
      _willPoints = totalWill;
      _goals = userGoals;
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  // Helper method to get day log from a map of month logs
  UserDayLog? _getDayLogFromMap(DateTime date, Map<String, UserMonthLog> monthLogsMap) {
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    final dayKey = date.day.toString().padLeft(2, '0');

    final monthLog = monthLogsMap[monthKey];
    if (monthLog == null) return null;

    return monthLog.days[dayKey];
  }

  // Update will points
  void updateWillPoints(int points) {
    _willPoints += points;
    notifyListeners();
  }

  // Add a new habit
  Future<void> addHabit(String userId, UserHabit habit) async {
    try {
      await _habitsRepository.createHabit(userId, habit);
      await loadHabitsAndData(userId, _selectedDate);
    } catch (e) {
      _error = 'Failed to create habit: $e';
      notifyListeners();
    }
  }

  // Update an existing habit
  Future<void> updateHabit(String userId, UserHabit habit) async {
    try {
      await _habitsRepository.updateHabit(userId, habit);
      await loadHabitsAndData(userId, _selectedDate);
    } catch (e) {
      _error = 'Failed to update habit: $e';
      notifyListeners();
    }
  }

  // Delete a habit
  Future<void> deleteHabit(String userId, String habitId) async {
    try {
      await _habitsRepository.deleteHabit(userId, habitId);
      await loadHabitsAndData(userId, _selectedDate);
    } catch (e) {
      _error = 'Failed to delete habit: $e';
      notifyListeners();
    }
  }

  // Create or update habit data for current selected date
  Future<void> updateHabitData(String userId, String habitId, HabitData habitData) async {
    try {
      await _habitsRepository.updateHabitData(
        habitId: habitId,
        userId: userId,
        habitData: habitData,
        date: _selectedDate,
      );

      // Reload data to ensure UI is synchronized
      await loadHabitsAndData(userId, _selectedDate);
    } catch (e) {
      _error = 'Failed to update habit data: $e';
      notifyListeners();
    }
  }

  // Calculate current streak for a specific habit
  int getCurrentStreak(String habitId, {DateTime? fromDate}) {
    final date = fromDate ?? _selectedDate;
    int currentStreak = 0;
    DateTime currentDate = date;
    bool streakBroken = false;

    // Continue looking back in days until streak is broken
    while (!streakBroken) {
      final hasProgress = _hasHabitProgress(habitId, currentDate);

      if (hasProgress) {
        currentStreak++;
        // Move to previous day
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        streakBroken = true;
      }
    }

    return currentStreak;
  }

  // Calculate best streak for a specific habit
  int getBestStreak(String habitId) {
    // Sort month logs chronologically
    final sortedMonthKeys = _monthLogs.keys.toList()..sort();

    int bestStreak = 0;
    int currentStreak = 0;
    DateTime? lastActiveDate;

    // Process month logs in chronological order
    for (final monthKey in sortedMonthKeys) {
      final monthLog = _monthLogs[monthKey]!;

      // Sort days within month chronologically
      final sortedDayKeys = monthLog.days.keys.toList()..sort();

      for (final dayKey in sortedDayKeys) {
        final dayLog = monthLog.days[dayKey]!;

        // Check if this day has progress for the specified habit
        if (dayLog.habits.containsKey(habitId) &&
            _isHabitProgressValid(dayLog.habits[habitId]!)) {

          final currentDate = _dateFromMonthAndDayKey(monthKey, dayKey);
          if (currentDate != null) {
            // If this is continuing a streak (today or yesterday was active)
            if (lastActiveDate == null ||
                currentDate.difference(lastActiveDate).inDays <= 1) {
              currentStreak++;
            } else {
              // Streak was broken, start a new one
              currentStreak = 1;
            }

            // Update best streak if current is better
            if (currentStreak > bestStreak) {
              bestStreak = currentStreak;
            }

            lastActiveDate = currentDate;
          }
        }
      }
    }

    return bestStreak;
  }

  // Helper method to determine if a habit has any progress on a specific date
  bool _hasHabitProgress(String habitId, DateTime date) {
    final dayLog = getDayLog(date);
    if (dayLog == null) return false;

    final habitData = dayLog.habits[habitId];
    if (habitData == null) return false;

    return _isHabitProgressValid(habitData);
  }

  // Helper method to check if habit data shows meaningful progress
  bool _isHabitProgressValid(HabitData habitData) {
    // Count habit as progressed if:
    // 1. It's marked as completed, OR
    // 2. It has some reps (for rep-based habits), OR
    // 3. It has some duration (for duration-based habits)
    return habitData.isCompleted ||
        habitData.reps > 0 ||
        habitData.duration > 0;
  }

  // Helper method to convert month and day keys to a DateTime
  DateTime? _dateFromMonthAndDayKey(String monthKey, String dayKey) {
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

  // Calculate streaks for all habits as of current date
  Map<String, int> getAllHabitsCurrentStreaks() {
    final Map<String, int> streaks = {};
    for (final habit in _habits) {
      streaks[habit.id] = getCurrentStreak(habit.id);
    }
    return streaks;
  }

  // Calculate best streaks for all habits
  Map<String, int> getAllHabitsBestStreaks() {
    final Map<String, int> bestStreaks = {};
    for (final habit in _habits) {
      bestStreaks[habit.id] = getBestStreak(habit.id);
    }
    return bestStreaks;
  }

  // Check if a habit is scheduled for a specific day
  bool isHabitScheduledForDay(UserHabit habit, DateTime date) {
    if (habit.weeklySchedule == null) return true;

    final weekday = date.weekday;
    switch (weekday) {
      case 1: return habit.weeklySchedule!.monday;
      case 2: return habit.weeklySchedule!.tuesday;
      case 3: return habit.weeklySchedule!.wednesday;
      case 4: return habit.weeklySchedule!.thursday;
      case 5: return habit.weeklySchedule!.friday;
      case 6: return habit.weeklySchedule!.saturday;
      case 7: return habit.weeklySchedule!.sunday;
      default: return false;
    }
  }

  // Get streak considering habit schedule
  int getScheduleAwareStreak(String habitId, {DateTime? fromDate}) {
    final habit = _habits.firstWhere((h) => h.id == habitId, orElse: () => _habits.first);
    final date = fromDate ?? _selectedDate;
    int streak = 0;
    DateTime currentDate = date;
    bool streakBroken = false;

    while (!streakBroken) {
      final isScheduled = isHabitScheduledForDay(habit, currentDate);
      final hasProgress = _hasHabitProgress(habitId, currentDate);

      if (isScheduled) {
        // If scheduled but no progress, streak is broken
        if (!hasProgress) {
          streakBroken = true;
        } else {
          streak++;
        }
      }
      // If not scheduled, just skip the day without breaking streak

      // Move to previous day
      currentDate = currentDate.subtract(const Duration(days: 1));

      // Set reasonable limit to prevent infinite loops (e.g., one year back)
      if (currentDate.difference(date).inDays < -365) {
        break;
      }
    }

    return streak;
  }

  List<UserGoal> _goals = [];
  List<UserGoal> get goals => _goals;

// Load goals
  Future<void> loadGoals(String userId) async {
    try {
      _isLoading = true;
      _error = null;

      final userGoals = await _habitsRepository.getAllGoals(userId);
      _goals = userGoals;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load goals: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

// Add a new goal
  Future<void> addGoal(String userId, UserGoal goal) async {
    try {
      await _habitsRepository.createGoal(userId, goal);
      await loadGoals(userId);
    } catch (e) {
      _error = 'Failed to create goal: $e';
      notifyListeners();
    }
  }

// Update an existing goal
  Future<void> updateGoal(String userId, UserGoal goal) async {
    try {
      await _habitsRepository.updateGoal(userId, goal);
      await loadGoals(userId);
    } catch (e) {
      _error = 'Failed to update goal: $e';
      notifyListeners();
    }
  }

// Delete a goal
  Future<void> deleteGoal(String userId, String goalId) async {
    try {
      await _habitsRepository.deleteGoal(userId, goalId);
      await loadGoals(userId);
    } catch (e) {
      _error = 'Failed to delete goal: $e';
      notifyListeners();
    }
  }

// Add habit to goal
  Future<void> addHabitToGoal(String userId, String goalId, String habitId) async {
    try {
      await _habitsRepository.addHabitToGoal(userId, goalId, habitId);
      await loadGoals(userId);
    } catch (e) {
      _error = 'Failed to add habit to goal: $e';
      notifyListeners();
    }
  }

// Remove habit from goal
  Future<void> removeHabitFromGoal(String userId, String goalId, String habitId) async {
    try {
      await _habitsRepository.removeHabitFromGoal(userId, goalId, habitId);
      await loadGoals(userId);
    } catch (e) {
      _error = 'Failed to remove habit from goal: $e';
      notifyListeners();
    }
  }

  int calculateTotalWill() {
    int totalWill = 0;
    
    // Sum up will from all habit data
    habitsData.forEach((habitId, habitData) {
      totalWill += habitData.willObtained;
    });
    
    return totalWill;
  }

}