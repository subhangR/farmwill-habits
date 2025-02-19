import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/habit_data.dart';
import '../models/habits.dart';

class HabitsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static const String _userHabitsCollection = 'user_habits';
  static const String _monthLogsCollection = 'habit_logs';


  Future<List<UserHabit>?> fetchAllHabits() async {
    try {
      QuerySnapshot qs  = await _firestore.collection(_userHabitsCollection).get();
      print(qs.docs.length);
      qs.docs.forEach((e) => debugPrint(Map<String,dynamic>.from(e.data() as Map).toString()));
      return qs.docs.map((e) => UserHabit.fromMap(Map<String,dynamic>.from(e.data() as Map))).toList();
    } catch(e) {
      print(e);
    }
    return null;
  }

  // Create a new habit
  Future<void> createHabit(String userId, UserHabit habit) async {
    try {
      // Directly set the habit in the habits map using dot notation
      await _firestore
          .collection(_userHabitsCollection)
          .doc(userId)
          .set({
        '${habit.id}': habit.toMap()
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
        print("No User Habits Document Foujnd!");
        return [];
      }

      final habits = userHabitsDoc.data() as Map<String, dynamic>? ?? {};

      return habits.values
          .map((habitMap) => UserHabit.fromMap(habitMap))
          .toList();
    } catch (e) {
      throw Exception('Failed to get habits: $e');
    }
  }


  Future<void> updateHabitData({
    required String habitId,
    required String userId,
    required HabitData habitData,
    required DateTime date,
  }) async {
    try {
      // Get the formatted date string for the document ID
      final String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final String dayKey = date.day.toString().padLeft(2, '0');
      final String docId = '$userId-$monthKey';

      // Reference to the user's monthly log document
      final docRef = _firestore
          .collection('habit_logs')
          .doc(docId);


      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        print(monthKey);

        // Get existing data
        final monthLog = UserMonthLog.fromMap(docSnapshot.data()!);
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

        // Simple update
        await docRef.update({
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

        print(newMonthLog.toMap());

        await docRef.set(newMonthLog.toMap());
      }
    } catch (e) {
      print('Error updating habit data: $e');
      rethrow;
    }
  }

  // Get habits for specific weekday
  Future<List<UserHabit>> getHabitsForWeekday(String userId, int weekday) async {
    try {
      final allHabits = await getAllHabits(userId);

      return allHabits.where((habit) {

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

        return false;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get habits for weekday: $e');
    }
  }


  Future<List<UserMonthLog>?> getAllLogs(String userId) {
    try {
      return _firestore
          .collection(_monthLogsCollection)
          .where('userId', isEqualTo: userId)
          .get()
          .then((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          return UserMonthLog.fromMap(doc.data());
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get all logs: $e');
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



  // New method to get habit status for a specific day
  Future<UserHabitStatus?> getHabitStatus(String userId, String habitId, DateTime date) async {
    try {
      final monthStart = DateTime(date.year, date.month);
      final dayKey = date.day.toString();
      final docId = '${userId}_${monthStart.toIso8601String()}';

      final monthLogDoc = await _firestore
          .collection(_monthLogsCollection)
          .doc(docId)
          .get();

      if (!monthLogDoc.exists) {
        return null;
      }

      final statusData = monthLogDoc.data()?['days']?[dayKey]?['habits']?[habitId]?['status'];
      if (statusData == null) {
        return null;
      }

      return UserHabitStatus.fromMap(statusData);
    } catch (e) {
      throw Exception('Failed to get habit status: $e');
    }
  }

  // New method to get all habit statuses for a day
  Future<Map<String, UserHabitStatus>> getDayHabitStatuses(String userId, DateTime date) async {
    try {
      final monthStart = DateTime(date.year, date.month);
      final dayKey = date.day.toString();
      final docId = '${userId}_${monthStart.toIso8601String()}';

      final monthLogDoc = await _firestore
          .collection(_monthLogsCollection)
          .doc(docId)
          .get();

      if (!monthLogDoc.exists) {
        return {};
      }

      final habitsData = monthLogDoc.data()?['days']?[dayKey]?['habits'] as Map<String, dynamic>? ?? {};
      final statuses = <String, UserHabitStatus>{};

      habitsData.forEach((habitId, habitData) {
        final statusData = habitData['status'];
        if (statusData != null) {
          statuses[habitId] = UserHabitStatus.fromMap(statusData);
        }
      });

      return statuses;
    } catch (e) {
      throw Exception('Failed to get day habit statuses: $e');
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
