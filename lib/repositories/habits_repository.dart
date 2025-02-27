import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

import '../models/goals.dart';
import '../models/habit_data.dart';
import '../models/habits.dart';

class HabitsRepository {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Database path references
  static const String _userHabitsPath = 'user_habits';
  static const String _habitLogsPath = 'logs';
  static const String _userGoalsPath = 'user_goals';

  Future<List<UserHabit>?> fetchAllHabits() async {
    try {
      final snapshot = await _database.ref(_userHabitsPath).get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final habits = <UserHabit>[];

        data.forEach((_, userData) {
          if (userData is Map) {
            Map<String, dynamic>.from(userData).forEach((_, habitData) {
              habits
                  .add(UserHabit.fromMap(Map<String, dynamic>.from(habitData)));
            });
          }
        });

        return habits;
      }
      return [];
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Create a new habit
  Future<void> createHabit(String userId, UserHabit habit) async {
    try {
      print("HabitsRepository: Creating habit with ID: ${habit.id}");
      print("HabitsRepository: User ID: $userId");

      final habitMap = habit.toMap();
      print("HabitsRepository: Habit map: $habitMap");

      // Reference to the user's habits
      final userHabitsRef =
          _database.ref('$_userHabitsPath/$userId/${habit.id}');
      print("HabitsRepository: Database path: ${userHabitsRef.path}");

      // Set the habit data with error handling
      try {
        await userHabitsRef.set(habitMap).timeout(Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Database write timed out'));
        print(
            "HabitsRepository: Habit saved to Realtime Database successfully");
      } catch (dbError) {
        print("HabitsRepository: Error during database write: $dbError");
        print(
            "HabitsRepository: Firebase error details: ${dbError.runtimeType}");
        throw Exception('Database write error: $dbError');
      }
    } catch (e) {
      print("HabitsRepository: Error in createHabit: $e");
      // Print stack trace for better debugging
      print(StackTrace.current);
      rethrow;
    }
  }

  // Update existing habit
  Future<void> updateHabit(String userId, UserHabit habit) async {
    try {
      await _database
          .ref('$_userHabitsPath/$userId/${habit.id}')
          .update(habit.toMap());
    } catch (e) {
      throw Exception('Failed to update habit: $e');
    }
  }

  // Delete habit
  Future<void> deleteHabit(String userId, String habitId) async {
    try {
      await _database.ref('$_userHabitsPath/$userId/$habitId').remove();
    } catch (e) {
      throw Exception('Failed to delete habit: $e');
    }
  }

  // Get all habits for a user
  Future<List<UserHabit>> getAllHabits(String userId) async {
    try {
      final snapshot = await _database.ref('$_userHabitsPath/$userId').get();

      if (!snapshot.exists) {
        print("No User Habits Found!");
        return [];
      }

      // Safely convert from Map<Object?, Object?> to Map<String, dynamic>
      final rawData = snapshot.value as Map<Object?, Object?>;
      final habits = <UserHabit>[];

      rawData.forEach((key, value) {
        if (value is Map<Object?, Object?>) {
          try {
            // Convert the entire map structure recursively
            final habitMap = _convertNestedMap(value);
            habits.add(UserHabit.fromMap(habitMap));
          } catch (e) {
            print("Error parsing habit: $e");
          }
        }
      });

      return habits;
    } catch (e) {
      print("Error in getAllHabits: $e");
      throw Exception('Failed to get habits: $e');
    }
  }

  // Helper method to recursively convert nested maps
  Map<String, dynamic> _convertNestedMap(Map<Object?, Object?> map) {
    final result = <String, dynamic>{};

    map.forEach((key, value) {
      if (key is String) {
        if (value is Map<Object?, Object?>) {
          // Recursively convert nested maps
          result[key] = _convertNestedMap(value);
        } else if (value is List) {
          // Handle lists that might contain maps
          result[key] = _convertList(value);
        } else {
          // For primitive values
          result[key] = value;
        }
      }
    });

    return result;
  }

  // Helper method to convert lists that might contain maps
  List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<Object?, Object?>) {
        return _convertNestedMap(item);
      } else if (item is List) {
        return _convertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  Future<void> updateHabitData({
    required String habitId,
    required String userId,
    required HabitData habitData,
    required DateTime date,
  }) async {
    try {
      // Get the formatted date string for the path
      final String monthKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final String dayKey = date.day.toString().padLeft(2, '0');
      final String logPath = '$_habitLogsPath/$userId/$monthKey';

      // Reference to the user's monthly log
      final logRef = _database.ref(logPath);
      final snapshot = await logRef.get();

      if (snapshot.exists) {
        // Get existing data using recursive conversion
        final rawData = snapshot.value as Map<Object?, Object?>;
        final monthLogData = _convertNestedMap(rawData);

        final monthLog = UserMonthLog.fromMap(monthLogData);
        final updatedDays = Map<String, UserDayLog>.from(monthLog.days);

        // Update or create day log
        if (updatedDays.containsKey(dayKey)) {
          final dayLog = updatedDays[dayKey]!;
          final updatedHabits = Map<String, HabitData>.from(dayLog.habits);
          updatedHabits[habitId] = habitData;

          updatedDays[dayKey] = UserDayLog(
            date: dayLog.date,
            habits: updatedHabits,
          );
        } else {
          updatedDays[dayKey] = UserDayLog(
            date: date,
            habits: {habitId: habitData},
          );
        }

        // Update the days data
        await logRef.update({
          'userId': userId,
          'days': updatedDays.map((key, value) => MapEntry(key, value.toMap())),
        });
      } else {
        // Create new month log if it doesn't exist
        final newMonthLog = UserMonthLog(
          userId: userId,
          monthKey: monthKey,
          days: {
            dayKey: UserDayLog(
              date: date,
              habits: {habitId: habitData},
            ),
          },
        );

        await logRef.set(newMonthLog.toMap());
      }
    } catch (e) {
      print('Error updating habit data: $e');
      rethrow;
    }
  }

  // Get habits for specific weekday
  Future<List<UserHabit>> getHabitsForWeekday(
      String userId, int weekday) async {
    try {
      final allHabits = await getAllHabits(userId);

      return allHabits.where((habit) {
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
    } catch (e) {
      throw Exception('Failed to get habits for weekday: $e');
    }
  }

  Future<List<UserMonthLog>?> getAllLogs(String userId) async {
    try {
      final snapshot = await _database.ref('$_habitLogsPath/$userId').get();

      if (!snapshot.exists) {
        return [];
      }

      // Safely convert from Map<Object?, Object?> to Map<String, dynamic>
      final rawData = snapshot.value as Map<Object?, Object?>;
      final logs = <UserMonthLog>[];

      rawData.forEach((key, value) {
        if (value is Map<Object?, Object?>) {
          try {
            // Use our recursive conversion helper
            final logMap = _convertNestedMap(value);
            logs.add(UserMonthLog.fromMap(logMap));
          } catch (e) {
            print("Error parsing month log: $e");
          }
        }
      });

      return logs;
    } catch (e) {
      print("Error in getAllLogs: $e");
      throw Exception('Failed to get all logs: $e');
    }
  }

  // Get logs for a specific month
  Future<UserMonthLog?> getMonthLogs(String userId, DateTime date) async {
    try {
      final String monthKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final String logPath = '$_habitLogsPath/$userId/$monthKey';

      final snapshot = await _database.ref(logPath).get();

      if (!snapshot.exists) {
        return null;
      }

      // Proper casting from Firebase data
      if (snapshot.value is Map) {
        // Use our recursive conversion helper
        final rawMap = snapshot.value as Map<Object?, Object?>;
        final properMap = _convertNestedMap(rawMap);
        return UserMonthLog.fromMap(properMap);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get month logs: $e');
    }
  }

  // Archive habit
  Future<void> archiveHabit(String userId, String habitId) async {
    try {
      await _database
          .ref('$_userHabitsPath/$userId/$habitId/isArchived')
          .set(true);
    } catch (e) {
      throw Exception('Failed to archive habit: $e');
    }
  }

  // Get habit status for a specific day
  Future<UserHabitStatus?> getHabitStatus(
      String userId, String habitId, DateTime date) async {
    try {
      final String monthKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final String dayKey = date.day.toString().padLeft(2, '0');
      final String statusPath =
          '$_habitLogsPath/$userId/$monthKey/days/$dayKey/habits/$habitId/status';

      final snapshot = await _database.ref(statusPath).get();

      if (!snapshot.exists) {
        return null;
      }

      if (snapshot.value is Map) {
        final rawMap = snapshot.value as Map<Object?, Object?>;
        final Map<String, dynamic> properMap = {};
        rawMap.forEach((key, value) {
          if (key is String) {
            properMap[key] = value;
          }
        });
        return UserHabitStatus.fromMap(properMap);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get habit status: $e');
    }
  }

  // Get all habit statuses for a day
  Future<Map<String, UserHabitStatus>> getDayHabitStatuses(
      String userId, DateTime date) async {
    try {
      final String monthKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final String dayKey = date.day.toString().padLeft(2, '0');
      final String habitsPath =
          '$_habitLogsPath/$userId/$monthKey/days/$dayKey/habits';

      final snapshot = await _database.ref(habitsPath).get();

      if (!snapshot.exists) {
        return {};
      }

      final rawData = snapshot.value as Map<Object?, Object?>;
      final statuses = <String, UserHabitStatus>{};

      rawData.forEach((key, value) {
        if (key is String && value is Map<Object?, Object?>) {
          final habitMap = <String, dynamic>{};
          value.forEach((k, v) {
            if (k is String) {
              habitMap[k] = v;
            }
          });

          if (habitMap.containsKey('status')) {
            final statusData = habitMap['status'];
            if (statusData is Map) {
              final statusMap = <String, dynamic>{};
              (statusData as Map<Object?, Object?>).forEach((k, v) {
                if (k is String) {
                  statusMap[k] = v;
                }
              });
              statuses[key] = UserHabitStatus.fromMap(statusMap);
            }
          }
        }
      });

      return statuses;
    } catch (e) {
      throw Exception('Failed to get day habit statuses: $e');
    }
  }

  // Create a new goal
  Future<void> createGoal(String userId, UserGoal goal) async {
    try {
      await _database
          .ref('$_userGoalsPath/$userId/${goal.id}')
          .set(goal.toMap());
    } catch (e) {
      throw Exception('Failed to create goal: $e');
    }
  }

  // Update existing goal
  Future<void> updateGoal(String userId, UserGoal goal) async {
    try {
      await _database
          .ref('$_userGoalsPath/$userId/${goal.id}')
          .update(goal.toMap());
    } catch (e) {
      throw Exception('Failed to update goal: $e');
    }
  }

  // Delete goal
  Future<void> deleteGoal(String userId, String goalId) async {
    try {
      await _database.ref('$_userGoalsPath/$userId/$goalId').remove();
    } catch (e) {
      throw Exception('Failed to delete goal: $e');
    }
  }

  // Get all goals for a user
  Future<List<UserGoal>> getAllGoals(String userId) async {
    try {
      final snapshot = await _database.ref('$_userGoalsPath/$userId').get();

      if (!snapshot.exists) {
        print("No User Goals Found!");
        return [];
      }

      final rawData = snapshot.value as Map<Object?, Object?>;
      final goals = <UserGoal>[];

      rawData.forEach((key, value) {
        if (value is Map<Object?, Object?>) {
          try {
            // Convert the entire map structure recursively
            final goalMap = _convertNestedMap(value);
            goals.add(UserGoal.fromMap(goalMap));
          } catch (e) {
            print("Error parsing goal: $e");
          }
        }
      });

      return goals;
    } catch (e) {
      print("Error in getAllGoals: $e");
      throw Exception('Failed to get goals: $e');
    }
  }

  // Get a specific goal
  Future<UserGoal?> getGoal(String userId, String goalId) async {
    try {
      final snapshot =
          await _database.ref('$_userGoalsPath/$userId/$goalId').get();

      if (!snapshot.exists) {
        return null;
      }

      if (snapshot.value is Map) {
        final rawMap = snapshot.value as Map<Object?, Object?>;
        final properMap = _convertNestedMap(rawMap);
        return UserGoal.fromMap(properMap);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get goal: $e');
    }
  }

  // Add habit to goal
  Future<void> addHabitToGoal(
      String userId, String goalId, String habitId) async {
    try {
      // Get the current goal
      final goal = await getGoal(userId, goalId);
      if (goal == null) {
        throw Exception('Goal not found');
      }

      // Add habit to goal's habit list if not already present
      if (!goal.habitId.contains(habitId)) {
        goal.habitId.add(habitId);
        goal.updatedAt = DateTime.now().toIso8601String();

        // Update the goal
        await updateGoal(userId, goal);
      }
    } catch (e) {
      throw Exception('Failed to add habit to goal: $e');
    }
  }

  // Remove habit from goal
  Future<void> removeHabitFromGoal(
      String userId, String goalId, String habitId) async {
    try {
      // Get the current goal
      final goal = await getGoal(userId, goalId);
      if (goal == null) {
        throw Exception('Goal not found');
      }

      // Remove habit from goal's habit list
      goal.habitId.remove(habitId);
      goal.updatedAt = DateTime.now().toIso8601String();

      // Update the goal
      await updateGoal(userId, goal);
    } catch (e) {
      throw Exception('Failed to remove habit from goal: $e');
    }
  }
}


  //firestore user habits collection -> user habits
  // firestore month log collection -> user month log
  // firestore user collection -> users

  //create habit -> add document into user habits collection with id user id, this document stores all the habits
  //update habit -> update habit in user habits document
  // delete habit -> delete habit from the user habits document
  // get all habits on a given weekday -> get all habits from user habits document and filter the ones on the given weekday
  // get user habit log for the current day -> get month log of the given day, extract habit log from the month log, day log and habit log
  // get user habit log for a given day (for calendar icon) -> similar to current day
  // add user habit log into user day log -> add user habit log into month log, into the corresponding day.
