
import 'package:get_it/get_it.dart';

import '../models/habit_data.dart';
import '../models/habits.dart';
import '../repositories/habits_repository.dart';

class HabitService {
  final HabitsRepository habitsRepository = GetIt.I<HabitsRepository>();

  // Cache storage
  final Map<String, List<UserHabit>> _userHabitsCache = {};
  final Map<String, Map<String, UserMonthLog>> _monthLogsCache = {}; // userId -> monthKey -> MonthLog

  // Cache invalidation timestamp
  final Map<String, DateTime> _userHabitsCacheTimestamp = {};
  final Map<String, Map<String, DateTime>> _monthLogsCacheTimestamp = {};

  // Cache duration (5 minutes for habits, 2 minutes for logs)
  static const Duration _habitsCacheDuration = Duration(minutes: 5);
  static const Duration _logsCacheDuration = Duration(minutes: 2);

  // Get all habits with caching
  Future<List<UserHabit>> getAllHabits(String userId) async {
    final now = DateTime.now();
    final lastUpdate = _userHabitsCacheTimestamp[userId];

    if (lastUpdate != null &&
        now.difference(lastUpdate) < _habitsCacheDuration &&
        _userHabitsCache.containsKey(userId)) {
      return _userHabitsCache[userId]!;
    }

    final habits = await habitsRepository.getAllHabits(userId);
    _userHabitsCache[userId] = habits;
    _userHabitsCacheTimestamp[userId] = now;
    return habits;
  }

  // Get habits for specific weekday with caching
  Future<List<UserHabit>> getHabitsForWeekday(String userId, int weekday) async {
    final habits = await getAllHabits(userId);
    return habits.where((habit) {
      if (habit.weeklySchedule == null) return false;

      switch (weekday) {
        case DateTime.monday:
          return habit.weeklySchedule!.monday;
        case DateTime.tuesday:
          return habit.weeklySchedule!.tuesday;
        case DateTime.wednesday:
          return habit.weeklySchedule!.wednesday;
        case DateTime.thursday:
          return habit.weeklySchedule!.thursday;
        case DateTime.friday:
          return habit.weeklySchedule!.friday;
        case DateTime.saturday:
          return habit.weeklySchedule!.saturday;
        case DateTime.sunday:
          return habit.weeklySchedule!.sunday;
        default:
          return false;
      }
    }).toList();
  }

  // Get month log with caching
  Future<UserMonthLog?> getMonthLog(String userId, DateTime date) async {
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    final now = DateTime.now();

    if (_monthLogsCache[userId]?[monthKey] != null &&
        _monthLogsCacheTimestamp[userId]?[monthKey] != null &&
        now.difference(_monthLogsCacheTimestamp[userId]![monthKey]!) < _logsCacheDuration) {
      return _monthLogsCache[userId]![monthKey];
    }

    final monthLog = await habitsRepository.getMonthLogs(userId, date);

    if (monthLog != null) {
      _monthLogsCache[userId] ??= {};
      _monthLogsCacheTimestamp[userId] ??= {};
      _monthLogsCache[userId]![monthKey] = monthLog;
      _monthLogsCacheTimestamp[userId]![monthKey] = now;
    }

    return monthLog;
  }

  // Get habit data for a specific date
  Future<Map<String, HabitData>> getHabitDataForDate(String userId, DateTime date) async {
    final monthLog = await getMonthLog(userId, date);
    if (monthLog == null) return {};

    final dayKey = date.day.toString().padLeft(2, '0');
    return monthLog.days[dayKey]?.habits ?? {};
  }

  // Helper method to check if habit is scheduled for a specific day
  bool _isHabitScheduledForDay(UserHabit habit, DateTime date) {
    if (habit.weeklySchedule == null) return true;

    switch (date.weekday) {
      case DateTime.monday:
        return habit.weeklySchedule!.monday;
      case DateTime.tuesday:
        return habit.weeklySchedule!.tuesday;
      case DateTime.wednesday:
        return habit.weeklySchedule!.wednesday;
      case DateTime.thursday:
        return habit.weeklySchedule!.thursday;
      case DateTime.friday:
        return habit.weeklySchedule!.friday;
      case DateTime.saturday:
        return habit.weeklySchedule!.saturday;
      case DateTime.sunday:
        return habit.weeklySchedule!.sunday;
      default:
        return false;
    }
  }

  // Calculate will progress for a habit
  double _calculateWillProgress(UserHabit habit, HabitData? data) {
    if (data == null) return 0.0;

    final willObtained = data.willObtained;
    final maxWill = data.maxWill;

    if (maxWill == 0) return 0.0;
    return (willObtained / maxWill).clamp(0.0, 1.0);
  }

  // Create or update habit data
  Future<void> updateHabitData(String userId, String habitId, HabitData habitData, DateTime date) async {
    await habitsRepository.updateHabitData(
      habitId: habitId,
      userId: userId,
      habitData: habitData,
      date: date,
    );

    // Invalidate month log cache for the updated month
    final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    _monthLogsCache[userId]?.remove(monthKey);
    _monthLogsCacheTimestamp[userId]?.remove(monthKey);
  }

  // Create new habit
  Future<void> createHabit(String userId, UserHabit habit) async {
    await habitsRepository.createHabit(userId, habit);
    _invalidateHabitsCache(userId);
  }

  // Update existing habit
  Future<void> updateHabit(String userId, UserHabit habit) async {
    await habitsRepository.updateHabit(userId, habit);
    _invalidateHabitsCache(userId);
  }

  // Delete habit
  Future<void> deleteHabit(String userId, String habitId) async {
    await habitsRepository.deleteHabit(userId, habitId);
    _invalidateHabitsCache(userId);
  }

  // Archive habit
  Future<void> archiveHabit(String userId, String habitId) async {
    await habitsRepository.archiveHabit(userId, habitId);
    _invalidateHabitsCache(userId);
  }

  // Helper method to invalidate habits cache
  void _invalidateHabitsCache(String userId) {
    _userHabitsCache.remove(userId);
    _userHabitsCacheTimestamp.remove(userId);
  }
}