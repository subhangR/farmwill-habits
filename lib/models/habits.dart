// Enums for different types and states
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
  final DateTime date;
  final Map<String,UserDayLog> days;

  const UserMonthLog({
    required this.date,
    required this.days,
  });

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'days':  days.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  // Create from Map when fetching from NoSQL
  factory UserMonthLog.fromMap(Map<String, dynamic> map) {
    return UserMonthLog(
      date: DateTime.parse(map['date']),
      days:
        (map['days'] as Map<String, dynamic>).map((key, value) => MapEntry(key, UserDayLog.fromMap(value))),
    );
  }
}


//table
class UserDayLog {
  final DateTime date;
  final List<UserHabitLog> logs;

  const UserDayLog({
    required this.date,
    required this.logs,
  });

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'logs': logs.map((log) => log.toMap()).toList(),
    };
  }

  // Create from Map when fetching from NoSQL
  factory UserDayLog.fromMap(Map<String, dynamic> map) {
    return UserDayLog(
      date: DateTime.parse(map['date']),
      logs: (map['logs'] as List<dynamic>)
          .map((logMap) => UserHabitLog.fromMap(logMap))
          .toList(),
    );
  }

}

class UserHabitLog {
  final String id;
  final String habitId;
  final String uid;
  final LogEventType eventType;
  final DateTime timestamp; // For click events or start time for time-tracked events
  final DateTime? endTimestamp; // Only for time-tracked events
  final String? note;
  final double? value; // Progress value (reps completed or minutes)

  const UserHabitLog({
    required this.id,
    required this.habitId,
    required this.uid,
    required this.eventType,
    required this.timestamp,
    this.endTimestamp,
    this.note,
    this.value,
  });

  // Calculate duration for time-tracked events
  Duration? getDuration() {
    if (eventType == LogEventType.timeTracked && endTimestamp != null) {
      return endTimestamp!.difference(timestamp);
    }
    return null;
  }

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'uid': uid,
      'eventType': eventType.toString(),
      'timestamp': timestamp.toIso8601String(),
      'endTimestamp': endTimestamp?.toIso8601String(),
      'note': note,
      'value': value,
    };
  }

  // Create from Map when fetching from NoSQL
  factory UserHabitLog.fromMap(Map<String, dynamic> map) {
    return UserHabitLog(
      id: map['id'] ?? '',
      habitId: map['habitId'] ?? '',
      uid: map['uid'] ?? '',
      eventType: LogEventType.values.firstWhere(
            (e) => e.toString() == map['eventType'],
        orElse: () => LogEventType.click,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      endTimestamp: map['endTimestamp'] != null
          ? DateTime.parse(map['endTimestamp'])
          : null,
      note: map['note'],
      value: map['value']?.toDouble(),
    );
  }

  // Create a copy of UserHabitLog with some fields updated
  UserHabitLog copyWith({
    String? id,
    String? habitId,
    String? uid,
    LogEventType? eventType,
    DateTime? timestamp,
    DateTime? endTimestamp,
    String? note,
    double? value,
  }) {
    return UserHabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      uid: uid ?? this.uid,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      endTimestamp: endTimestamp ?? this.endTimestamp,
      note: note ?? this.note,
      value: value ?? this.value,
    );
  }
}

//table
// Main UserHabit class
class UserHabit {
  final String uid; // User ID
  final String id; // Habit ID
  final String name;
  final HabitType habitType;
  final HabitNature nature; // positive or negative
  final double scorePerUnit; // score per rep or per minute
  final FrequencyType frequencyType;
  final WeeklySchedule? weeklySchedule; // null if frequency is daily
  final HabitGoal? goal; // optional goal
  final DateTime createdAt;
  final DateTime? completedAt; // for one-time habits
  final bool isArchived;

  const UserHabit({
    required this.uid,
    required this.id,
    required this.name,
    required this.habitType,
    required this.nature,
    required this.scorePerUnit,
    required this.frequencyType,
    this.weeklySchedule,
    this.goal,
    required this.createdAt,
    this.completedAt,
    this.isArchived = false,
  });

  // Calculate current score based on progress
  double calculateCurrentScore() {
    if (goal == null) return 0;

    double baseScore = nature == HabitNature.positive
        ? scorePerUnit
        : -scorePerUnit.abs();

    if (goal!.type == GoalType.repetitions) {
      return baseScore * goal!.progress;
    } else {
      // For duration goals, progress is in minutes
      return baseScore * goal!.progress;
    }
  }

  // Convert to Map for storing in NoSQL
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'id': id,
      'name': name,
      'habitType': habitType.toString(),
      'nature': nature.toString(),
      'scorePerUnit': scorePerUnit,
      'frequencyType': frequencyType.toString(),
      'weeklySchedule': weeklySchedule?.toMap(),
      'goal': goal?.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  // Create from Map when fetching from NoSQL
  factory UserHabit.fromMap(Map<String, dynamic> map) {
    return UserHabit(
      uid: map['uid'] ?? '',
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      habitType: HabitType.values.firstWhere(
            (e) => e.toString() == map['habitType'],
        orElse: () => HabitType.regular,
      ),
      nature: HabitNature.values.firstWhere(
            (e) => e.toString() == map['nature'],
        orElse: () => HabitNature.positive,
      ),
      scorePerUnit: map['scorePerUnit']?.toDouble() ?? 1.0,
      frequencyType: FrequencyType.values.firstWhere(
            (e) => e.toString() == map['frequencyType'],
        orElse: () => FrequencyType.daily,
      ),
      weeklySchedule: map['weeklySchedule'] != null
          ? WeeklySchedule.fromMap(map['weeklySchedule'])
          : null,
      goal: map['goal'] != null
          ? HabitGoal.fromMap(map['goal'])
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      isArchived: map['isArchived'] ?? false,
    );
  }

  // Create a copy of UserHabit with some fields updated
  UserHabit copyWith({
    String? uid,
    String? id,
    String? name,
    HabitType? habitType,
    HabitNature? nature,
    double? scorePerUnit,
    FrequencyType? frequencyType,
    WeeklySchedule? weeklySchedule,
    HabitGoal? goal,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isArchived,
  }) {
    return UserHabit(
      uid: uid ?? this.uid,
      id: id ?? this.id,
      name: name ?? this.name,
      habitType: habitType ?? this.habitType,
      nature: nature ?? this.nature,
      scorePerUnit: scorePerUnit ?? this.scorePerUnit,
      frequencyType: frequencyType ?? this.frequencyType,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      goal: goal ?? this.goal,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}