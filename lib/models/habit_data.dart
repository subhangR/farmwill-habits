// lib/models/habit_data.dart

import 'package:farmwill_habits/models/habits.dart';

class HabitData {
  final int reps;                   // Current number of repetitions completed
  final int duration;               // Duration in minutes
  final int willObtained;
  final GoalType goalType;// Amount of will points obtained
  final int targetReps;            // Target number of repetitions
  final int targetDuration;        // Target duration in minutes
  final int targetWill;            // Target will points
  final int willPerRep;            // Will points earned per repetition
  final int willPerDuration;       // Will points earned per minute
  final int maxWill;               // Maximum will points possible
  final int startingWill;          // Initial will points
  final bool isCompleted;          // Whether the habit is completed for the day
  final DateTime? lastUpdated;      // Last time the habit was updated
  final List<DateTime>? timestamps; // Timestamps of when reps were completed
  final String? notes;             // Any notes for the day's habit
  final Map<String, dynamic>? metadata; // Additional metadata

  const HabitData({
    this.reps = 0,
    this.duration = 0,
    this.willObtained = 0,
    required this.targetReps,
    required this.targetDuration,
    required this.targetWill,
    required this.willPerRep,
    required this.willPerDuration,
    required this.maxWill,
    required this.startingWill,
    required this.goalType,
    this.isCompleted = false,
    this.lastUpdated,
    this.timestamps,
    this.notes,
    this.metadata,
  });

  // Calculate progress percentage
  double get progressPercentage {
    if (targetReps > 0) {
      return (reps / targetReps).clamp(0.0, 1.0);
    }
    if (targetDuration > 0) {
      return (duration / targetDuration).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  // Calculate will points based on reps and duration
  int calculateWillPoints() {
    int points = 0;
    points += reps * willPerRep;
    points += duration * willPerDuration;
    return points.clamp(0, maxWill);
  }

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'duration': duration,
      'willObtained': willObtained,
      'targetReps': targetReps,
      'targetDuration': targetDuration,
      'targetWill': targetWill,
      'willPerRep': willPerRep,
      'willPerDuration': willPerDuration,
      'maxWill': maxWill,
      'startingWill': startingWill,
      'isCompleted': isCompleted,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'timestamps': timestamps?.map((t) => t.toIso8601String()).toList(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  // Create from Map when fetching from NoSQL
  factory HabitData.fromMap(Map<String, dynamic> map) {
    return HabitData(
      reps: map['reps'] ?? 0,
      duration: map['duration'] ?? 0,
      willObtained: map['willObtained'] ?? 0,
      goalType: map['goalType'] ?? GoalType.repetitions,
      targetReps: map['targetReps'] ?? 0,
      targetDuration: map['targetDuration'] ?? 0,
      targetWill: map['targetWill'] ?? 0,
      willPerRep: map['willPerRep'] ?? 0,
      willPerDuration: map['willPerDuration'] ?? 0,
      maxWill: map['maxWill'] ?? 0,
      startingWill: map['startingWill'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.parse(map['lastUpdated'])
          : null,
      timestamps: (map['timestamps'] as List<dynamic>?)?.map(
              (timestamp) => DateTime.parse(timestamp as String)
      ).toList(),
      notes: map['notes'],
      metadata: map['metadata'],
    );
  }

  // Create a copy with some fields updated
  HabitData copyWith({
    int? reps,
    int? duration,
    int? willObtained,
    int? targetReps,
    int? targetDuration,
    int? targetWill,
    int? willPerRep,
    int? willPerDuration,
    int? maxWill,
    int? startingWill,
    bool? isCompleted,
    DateTime? lastUpdated,
    List<DateTime>? timestamps,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return HabitData(
      reps: reps ?? this.reps,
      duration: duration ?? this.duration,
      willObtained: willObtained ?? this.willObtained,
      targetReps: targetReps ?? this.targetReps,
      targetDuration: targetDuration ?? this.targetDuration,
      targetWill: targetWill ?? this.targetWill,
      willPerRep: willPerRep ?? this.willPerRep,
      goalType: goalType,
      willPerDuration: willPerDuration ?? this.willPerDuration,
      maxWill: maxWill ?? this.maxWill,
      startingWill: startingWill ?? this.startingWill,
      isCompleted: isCompleted ?? this.isCompleted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      timestamps: timestamps ?? this.timestamps,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper method to update reps
  HabitData incrementReps() {
    final newReps = reps + 1;
    final newWillObtained = calculateWillPoints();
    final newIsCompleted = newReps >= targetReps;

    return copyWith(
      reps: newReps,
      willObtained: newWillObtained,
      isCompleted: newIsCompleted,
      lastUpdated: DateTime.now(),
    );
  }

  // Helper method to update duration
  HabitData updateDuration(int newDuration) {
    final newWillObtained = calculateWillPoints();
    final newIsCompleted = newDuration >= targetDuration;

    return copyWith(
      duration: newDuration,
      willObtained: newWillObtained,
      isCompleted: newIsCompleted,
      lastUpdated: DateTime.now(),
    );
  }

  // Merge with another HabitData instance
  HabitData merge(HabitData other) {
    return copyWith(
      reps: reps + other.reps,
      duration: duration + other.duration,
      willObtained: willObtained + other.willObtained,
      timestamps: [...(timestamps ?? []), ...(other.timestamps ?? [])],
      lastUpdated: DateTime.now(),
      isCompleted: isCompleted || other.isCompleted,
      notes: notes != null && other.notes != null
          ? '$notes\n${other.notes}'
          : notes ?? other.notes,
      metadata: {
        ...(metadata ?? {}),
        ...(other.metadata ?? {}),
      },
    );
  }
}


class UserMonthLog {
  final String monthKey;
  final Map<String,UserDayLog> days;
  final String userId;

  const UserMonthLog({
    required this.monthKey,
    required this.days,
    required this.userId,
  });

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'monthKey': monthKey,
      'days':  days.map((key, value) => MapEntry(key, value.toMap())),
      'userId':  userId,
    };
  }

  // Create from Map when fetching from NoSQL
  factory UserMonthLog.fromMap(Map<String, dynamic> map) {
    return UserMonthLog(
      monthKey: map['monthKey'] ?? '',
      userId: map['userId'] ?? '',
      days:
      (map['days'] as Map<String, dynamic>).map((key, value) => MapEntry(key, UserDayLog.fromMap(value))),
    );
  }
}


class UserDayLog {
  final DateTime date;
  final Map<String, HabitData> habits; // Map of habitId to HabitData

  const UserDayLog({
    required this.date,
    required this.habits,
  });

  String dateKey() {
    return '${date.year}-${date.month}-${date.day}';
  }

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'habits': habits.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  // Create from Map when fetching from NoSQL
  factory UserDayLog.fromMap(Map<String, dynamic> map) {
    return UserDayLog(
      date: DateTime.parse(map['date']),
      habits: (map['habits'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, HabitData.fromMap(value)),
      ),
    );
  }

  // Create a copy with some fields updated
  UserDayLog copyWith({
    DateTime? date,
    Map<String, HabitData>? habits,
  }) {
    return UserDayLog(
      date: date ?? this.date,
      habits: habits ?? this.habits,
    );
  }
}

class UserHabitStatus {
  final String habitId;
  final DateTime date;
  final bool completed;
  final double progress; // Progress towards goal

  const UserHabitStatus({
    required this.habitId,
    required this.date,
    required this.completed,
    required this.progress,
  });

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'date': date.toIso8601String(),
      'completed': completed,
      'progress': progress,
    };
  }

  // Create from Map when fetching from NoSQL
  factory UserHabitStatus.fromMap(Map<String, dynamic> map) {
    return UserHabitStatus(
      habitId: map['habitId'] ?? '',
      date: DateTime.parse(map['date']),
      completed: map['completed'] ?? false,
      progress: map['progress']?.toDouble() ?? 0,
    );
  }
}
