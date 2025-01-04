import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/habits.dart';

class HabitsRepository {
  final FirebaseFirestore _firestore;

  // Collection references
  static const String _userHabitsCollection = 'user_habits';
  static const String _monthLogsCollection = 'month_logs';
  static const String _usersCollection = 'users';

  HabitsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new habit
  Future<void> createHabit(String userId, UserHabit habit) async {
    try {
      // Directly set the habit in the habits map using dot notation
      await _firestore
          .collection(_userHabitsCollection)
          .doc(userId)
          .set({
        'habits.${habit.id}': habit.toMap()
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create habit: $e');
    }
  }

  // Update existing habit
  Future<void> updateHabit(String userId, UserHabit habit) async {
    try {
      // Directly update the specific habit in the map using dot notation
      await _firestore
          .collection(_userHabitsCollection)
          .doc(userId)
          .update({'habits.${habit.id}': habit.toMap()});
    } catch (e) {
      throw Exception('Failed to update habit: $e');
    }
  }

  // Delete habit
  Future<void> deleteHabit(String userId, String habitId) async {
    try {
      // Delete field using FieldValue.delete()
      await _firestore
          .collection(_userHabitsCollection)
          .doc(userId)
          .update({
        'habits.$habitId': FieldValue.delete()
      });
    } catch (e) {
      throw Exception('Failed to delete habit: $e');
    }
  }

  // Get all habits for a user
  Future<List<UserHabit>> getAllHabits(String userId) async {
    try {
      final userHabitsDoc = await _firestore
          .collection(_userHabitsCollection)
          .doc(userId)
          .get();

      if (!userHabitsDoc.exists) {
        return [];
      }

      final habits = userHabitsDoc.data()?['habits'] as Map<String, dynamic>? ?? {};

      return habits.values
          .map((habitMap) => UserHabit.fromMap(habitMap))
          .toList();
    } catch (e) {
      throw Exception('Failed to get habits: $e');
    }
  }

  // Get habits for specific weekday
  Future<List<UserHabit>> getHabitsForWeekday(String userId, int weekday) async {
    try {
      final allHabits = await getAllHabits(userId);

      return allHabits.where((habit) {
        if (habit.frequencyType == FrequencyType.daily) {
          return true;
        }

        if (habit.frequencyType == FrequencyType.weekly &&
            habit.weeklySchedule != null) {
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
        }

        return false;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get habits for weekday: $e');
    }
  }

  // Log habit event
  Future<void> logHabitEvent(String userId, UserHabitLog log) async {
    try {
      final monthStart = DateTime(log.timestamp.year, log.timestamp.month);
      final dayKey = log.timestamp.day.toString();
      final docId = '${userId}_${monthStart.toIso8601String()}';

      // Use arrayUnion to add the log directly to the day's logs array
      await _firestore
          .collection(_monthLogsCollection)
          .doc(docId)
          .set({
        'date': monthStart.toIso8601String(),
        'days.$dayKey': {
          'date': DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day).toIso8601String(),
          'logs': FieldValue.arrayUnion([log.toMap()])
        }
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to log habit event: $e');
    }
  }

  // Get logs for a specific day
  Future<UserDayLog?> getDayLogs(String userId, DateTime date) async {
    try {
      final monthStart = DateTime(date.year, date.month);
      final dayKey = date.day.toString();
      final docId = '${userId}_${monthStart.toIso8601String()}';

      // Query only the specific day's data using field path
      final monthLogDoc = await _firestore
          .collection(_monthLogsCollection)
          .doc(docId)
          .get();

      if (!monthLogDoc.exists) {
        return null;
      }

      final dayData = monthLogDoc.data()?['days']?[dayKey];
      if (dayData == null) {
        return null;
      }

      return UserDayLog.fromMap(dayData);
    } catch (e) {
      throw Exception('Failed to get day logs: $e');
    }
  }

  // Get logs for a specific month
  Future<UserMonthLog?> getMonthLogs(String userId, DateTime date) async {
    try {
      final monthStart = DateTime(date.year, date.month);
      final docId = '${userId}_${monthStart.toIso8601String()}';

      final monthLogDoc = await _firestore
          .collection(_monthLogsCollection)
          .doc(docId)
          .get();

      if (!monthLogDoc.exists) {
        return null;
      }

      return UserMonthLog.fromMap(monthLogDoc.data()!);
    } catch (e) {
      throw Exception('Failed to get month logs: $e');
    }
  }

  // Update habit progress
  Future<void> updateHabitProgress(String userId, String habitId, double newProgress) async {
    try {
      await _firestore
          .collection(_userHabitsCollection)
          .doc(userId)
          .update({
        'habits.$habitId.goal.progress': newProgress
      });
    } catch (e) {
      throw Exception('Failed to update habit progress: $e');
    }
  }

  // Archive habit
  Future<void> archiveHabit(String userId, String habitId) async {
    try {
      await _firestore
          .collection(_userHabitsCollection)
          .doc(userId)
          .update({
        'habits.$habitId.isArchived': true
      });
    } catch (e) {
      throw Exception('Failed to archive habit: $e');
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
  // delete habit log in a day log ->
