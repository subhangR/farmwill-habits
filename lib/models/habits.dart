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

// Class to handle habit logging
enum LogEventType {
  click,  // Simple completion event
  timeTracked, // Event with duration
}

enum FrequencyType {
  onetime,
  daily
}
//table
// Main UserHabit class
class UserHabit {
  final String uid;
  final String id;
  final String name;
  final HabitType habitType;
  final HabitNature nature;
  final WeeklySchedule weeklySchedule;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isArchived;
  final FrequencyType frequencyType;
  final String targetUnits;
  int targetReps;
  int targetRepStep;
  final int? willPerRep;
  int? maxWill = 0;
  int? startingWill = 0;
  final int repetitionStep;
  final String repetitionUnitType;

  UserHabit({
    required this.uid,
    required this.id,
    required this.name,
    required this.habitType,
    required this.nature,
    required this.weeklySchedule,
    required this.targetReps,
    this.willPerRep,
    this.maxWill,
    this.startingWill,
    required this.createdAt,
    required this.isArchived,
    required this.frequencyType,
    this.repetitionStep = 1,
    this.repetitionUnitType = 'reps',
    this.completedAt,
    this.targetUnits = 'reps',
    this.targetRepStep = 1,
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
      'weeklySchedule': weeklySchedule.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isArchived': isArchived,
      'scorePerRep': willPerRep,
      'targetReps': targetReps,
      'maxScore': maxWill,
      'startingWill': startingWill,
      'frequencyType': frequencyType.name,
      'repetitionStep': repetitionStep,
      'repetitionUnitType': repetitionUnitType,
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
      frequencyType: map['frequencyType'] != null
          ? FrequencyType.values.firstWhere(
              (e) => e.name == map['frequencyType'],
          orElse: () {
            debugPrint('WARNING: Unknown frequencyType "${map['frequencyType']}", defaulting to onetime');
            return FrequencyType.onetime;
          }
      )
          : FrequencyType.onetime,

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
      weeklySchedule: WeeklySchedule.fromMap(map['weeklySchedule']),
      createdAt: parsedCreatedAt,
      completedAt: parsedCompletedAt,
      isArchived: map['isArchived'] ?? false,
      willPerRep: map['scorePerRep'],
      targetReps: map['targetReps'] ?? 1,
      targetUnits: map['targetUnits'] ?? 'reps',
      targetRepStep: map['targetRepStep'] ?? 1,
      maxWill: map['maxScore'],
      startingWill: map['startingWill'],
      repetitionStep: map['repetitionStep'] ?? 1,
      repetitionUnitType: map['repetitionUnitType'] ?? 'reps',
    );
  }
}