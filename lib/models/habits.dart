// Enums for different types and states
import 'package:flutter/material.dart';

enum HabitType {
  regular,
  oneTime,
}

enum HabitNature {
  positive,
  negative,
}

enum FrequencyType {
  daily,
  weekly,
}

enum GoalType {
  duration,
  repetitions,
}

// Class to handle weekly frequency
class WeeklySchedule {
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;

  const WeeklySchedule({
    this.monday = false,
    this.tuesday = false,
    this.wednesday = false,
    this.thursday = false,
    this.friday = false,
    this.saturday = false,
    this.sunday = false,
  });

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
    };
  }

  // Create from Map when fetching from NoSQL
  factory WeeklySchedule.fromMap(Map<String, dynamic> map) {
    return WeeklySchedule(
      monday: map['monday'] ?? false,
      tuesday: map['tuesday'] ?? false,
      wednesday: map['wednesday'] ?? false,
      thursday: map['thursday'] ?? false,
      friday: map['friday'] ?? false,
      saturday: map['saturday'] ?? false,
      sunday: map['sunday'] ?? false,
    );
  }
}

// Class to handle habit goals
class HabitGoal {
  final GoalType type;
  final int target; // minutes for duration, count for repetitions
  final double progress; // current progress towards goal

  const HabitGoal({
    required this.type,
    required this.target,
    this.progress = 0,
  });

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'target': target,
      'progress': progress,
    };
  }

  // Create from Map when fetching from NoSQL
  factory HabitGoal.fromMap(Map<String, dynamic> map) {
    return HabitGoal(
      type: GoalType.values.firstWhere(
            (e) => e.toString() == map['type'],
        orElse: () => GoalType.repetitions,
      ),
      target: map['target'] ?? 0,
      progress: map['progress']?.toDouble() ?? 0,
    );
  }
}

// Class to handle habit logging
enum LogEventType {
  click,  // Simple completion event
  timeTracked, // Event with duration
}


class UserMonthLog {
  final String monthKey;
  final Map<String,UserDayLog> days;

  const UserMonthLog({
    required this.monthKey,
    required this.days,
  });

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'monthKey': monthKey,
      'days':  days.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  // Create from Map when fetching from NoSQL
  factory UserMonthLog.fromMap(Map<String, dynamic> map) {
    return UserMonthLog(
      monthKey: map['monthKey'] ?? '',
      days:
        (map['days'] as Map<String, dynamic>).map((key, value) => MapEntry(key, UserDayLog.fromMap(value))),
    );
  }
}


class HabitData {
  final int reps;
  final int duration; // in minutes
  final int willObtained;
  final int targetReps;
  final int targetDuration;
  final int targetWill;
  final int willPerRep;
  final int willPerDuration; // will per minute
  final int maxWill;
  final int startingWill;
  final bool isCompleted;

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
    this.isCompleted = false,
  });

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
    };
  }

  // Create from Map when fetching from NoSQL
  factory HabitData.fromMap(Map<String, dynamic> map) {
    return HabitData(
      reps: map['reps'] ?? 0,
      duration: map['duration'] ?? 0,
      willObtained: map['willObtained'] ?? 0,
      targetReps: map['targetReps'] ?? 0,
      targetDuration: map['targetDuration'] ?? 0,
      targetWill: map['targetWill'] ?? 0,
      willPerRep: map['willPerRep'] ?? 0,
      willPerDuration: map['willPerDuration'] ?? 0,
      maxWill: map['maxWill'] ?? 0,
      startingWill: map['startingWill'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
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
  }) {
    return HabitData(
      reps: reps ?? this.reps,
      duration: duration ?? this.duration,
      willObtained: willObtained ?? this.willObtained,
      targetReps: targetReps ?? this.targetReps,
      targetDuration: targetDuration ?? this.targetDuration,
      targetWill: targetWill ?? this.targetWill,
      willPerRep: willPerRep ?? this.willPerRep,
      willPerDuration: willPerDuration ?? this.willPerDuration,
      maxWill: maxWill ?? this.maxWill,
      startingWill: startingWill ?? this.startingWill,
      isCompleted: isCompleted ?? this.isCompleted,
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
//table
// Main UserHabit class


class UserHabit {
  final String uid;
  final String id;
  final String name;
  final HabitType habitType;
  final HabitNature nature;
  final int? scorePerRep;
  final int? scorePerMinute;
  final WeeklySchedule? weeklySchedule;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isArchived;
  final IconData habitIcon;  // New field for habit icon
  int targetReps;
  int? targetMinutes = 5;
  int? maxScore = 0;
  int? startingWill = 0;

  UserHabit({
    required this.uid,
    required this.id,
    required this.name,
    required this.habitType,
    required this.nature,
    this.weeklySchedule,
    required this.createdAt,
    this.completedAt,
    this.scorePerMinute,
    this.scorePerRep,
    this.targetReps = 1,
    this.targetMinutes,
    this.maxScore,
    this.startingWill,
    this.isArchived = false,
    this.habitIcon = Icons.check_circle,  // Default icon
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'id': id,
      'name': name,
      'habitType': habitType.name,
      'nature': nature.name,
      'weeklySchedule': weeklySchedule?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isArchived': isArchived,
      'scorePerRep': scorePerRep,
      'scorePerMinute': scorePerMinute,
      'targetReps': targetReps,
      'targetMinutes': targetMinutes,
      'maxScore': maxScore,
      'startingWill': startingWill,
      'habitIcon': {
        'codePoint': habitIcon.codePoint,
        'fontFamily': habitIcon.fontFamily,
        'fontPackage': habitIcon.fontPackage,
      },
    };
  }

  // Update fromMap to handle all fields properly
  factory UserHabit.fromMap(Map<String, dynamic> map) {
    return UserHabit(
      uid: map['uid'] ?? '',
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      habitType: HabitType.values.firstWhere(
            (e) => e.toString() == 'HabitType.${map['habitType']}',
        orElse: () => HabitType.regular,
      ),
      nature: HabitNature.values.firstWhere(
            (e) => e.toString() == 'HabitNature.${map['nature']}',
        orElse: () => HabitNature.positive,
      ),
      weeklySchedule: map['weeklySchedule'] != null
          ? WeeklySchedule.fromMap(map['weeklySchedule'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      isArchived: map['isArchived'] ?? false,
      scorePerRep: map['scorePerRep'],
      scorePerMinute: map['scorePerMinute'],
      targetReps: map['targetReps'] ?? 1,
      targetMinutes: map['targetMinutes'] ?? 5,
      maxScore: map['maxScore'],
      startingWill: map['startingWill'],
      habitIcon: IconData(
        map['habitIcon']?['codePoint'] as int? ?? Icons.check_circle.codePoint,
        fontFamily: map['habitIcon']?['fontFamily'] as String? ?? 'MaterialIcons',
        fontPackage: map['habitIcon']?['fontPackage'] as String?,
      ),
    );
  }
}