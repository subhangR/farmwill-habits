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


//table
// Main UserHabit class
class UserHabit {
  final String uid;
  final String id;
  final String name;
  final HabitType habitType;
  final HabitNature nature;
  final int? willPerRep;
  final int? willPerMin;
  final WeeklySchedule? weeklySchedule;
  final DateTime createdAt;
  final DateTime? completedAt;
  final GoalType goalType;
  final bool isArchived;
  final IconData habitIcon;  // New field for habit icon
  int targetReps;
  int? targetMinutes = 0;
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
    required this.goalType,
    this.completedAt,
    this.willPerMin,
    this.willPerRep,
    this.targetReps = 1,
    this.targetMinutes,
    this.maxScore,
    this.startingWill,
    this.isArchived = false,
    this.habitIcon = Icons.check_circle,  // Default icon
  });

  Map<String, dynamic> toMap() {
    // Debug check for required fields
    if (uid.isEmpty) {
      debugPrint('WARNING: Converting UserHabit to map with empty uid');
    }
    if (id.isEmpty) {
      debugPrint('WARNING: Converting UserHabit to map with empty id');
    }
    if (name.isEmpty) {
      debugPrint('WARNING: Converting UserHabit to map with empty name');
    }

    return {
      'uid': uid,
      'id': id,
      'name': name,
      'habitType': habitType.name,
      'nature': nature.name,
      'goalType': goalType.name, // Fixed missing goalType in toMap
      'weeklySchedule': weeklySchedule?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isArchived': isArchived,
      'scorePerRep': willPerRep,
      'scorePerMinute': willPerMin,
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

  // Update fromMap to handle all fields properly with debug statements
  factory UserHabit.fromMap(Map<String, dynamic> map) {
    // Debug check for required fields
    if (map['uid'] == null || map['uid'] == '') {
      debugPrint('ERROR: Creating UserHabit from map with missing uid');
    }
    if (map['id'] == null || map['id'] == '') {
      debugPrint('ERROR: Creating UserHabit from map with missing id');
    }
    if (map['name'] == null || map['name'] == '') {
      debugPrint('ERROR: Creating UserHabit from map with missing name');
    }
    if (map['createdAt'] == null) {
      debugPrint('ERROR: Creating UserHabit from map with missing createdAt');
    }
    if (map['habitType'] == null) {
      debugPrint('ERROR: Creating UserHabit from map with missing habitType');
    }
    if (map['nature'] == null) {
      debugPrint('ERROR: Creating UserHabit from map with missing nature');
    }
    if (map['goalType'] == null) {
      debugPrint('ERROR: Creating UserHabit from map with missing goalType');
    }

    // Parse createdAt safely
    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now();
    } catch (e) {
      debugPrint('ERROR: Failed to parse createdAt: ${e.toString()}');
      parsedCreatedAt = DateTime.now();
    }

    // Parse completedAt safely
    DateTime? parsedCompletedAt;
    if (map['completedAt'] != null) {
      try {
        parsedCompletedAt = DateTime.parse(map['completedAt']);
      } catch (e) {
        debugPrint('WARNING: Failed to parse completedAt: ${e.toString()}');
      }
    }

    return UserHabit(
      uid: map['uid'] ?? '',
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      goalType: map['goalType'] != null
          ? GoalType.values.firstWhere(
              (e) => e.name == map['goalType'],
          orElse: () {
            debugPrint('WARNING: Unknown goalType "${map['goalType']}", defaulting to repetitions');
            return GoalType.repetitions;
          }
      )
          : GoalType.repetitions,
      habitType: map['habitType'] != null
          ? HabitType.values.firstWhere(
              (e) => e.name == map['habitType'],
          orElse: () {
            debugPrint('WARNING: Unknown habitType "${map['habitType']}", defaulting to regular');
            return HabitType.regular;
          }
      )
          : HabitType.regular,
      nature: map['nature'] != null
          ? HabitNature.values.firstWhere(
              (e) => e.name == map['nature'],
          orElse: () {
            debugPrint('WARNING: Unknown nature "${map['nature']}", defaulting to positive');
            return HabitNature.positive;
          }
      )
          : HabitNature.positive,
      weeklySchedule: map['weeklySchedule'] != null
          ? WeeklySchedule.fromMap(map['weeklySchedule'])
          : null,
      createdAt: parsedCreatedAt,
      completedAt: parsedCompletedAt,
      isArchived: map['isArchived'] ?? false,
      willPerRep: map['scorePerRep'],
      willPerMin: map['scorePerMinute'],
      targetReps: map['targetReps'] ?? 1,
      targetMinutes: map['targetMinutes'] ?? 0,
      maxScore: map['maxScore'],
      startingWill: map['startingWill'],
      habitIcon: map['habitIcon'] != null
          ? IconData(
        map['habitIcon']['codePoint'] as int? ?? Icons.check_circle.codePoint,
        fontFamily: map['habitIcon']['fontFamily'] as String? ?? 'MaterialIcons',
        fontPackage: map['habitIcon']['fontPackage'] as String?,
      )
          : Icons.check_circle,
    );
  }
}