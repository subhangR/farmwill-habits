// Add this to your models directory, e.g., models/goal.dart

import 'package:flutter/foundation.dart';

class UserGoal {
  final String uid;
  final String id;
  final String name;
  final String description;
  String createdAt;
  String updatedAt;
  List<String> habitId;

  UserGoal({
    required this.uid,
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.habitId,
  });

  Map<String, dynamic> toMap() {
    // Debug check for required fields
    if (uid.isEmpty) {
      debugPrint('WARNING: Converting UserGoal to map with empty uid');
    }
    if (id.isEmpty) {
      debugPrint('WARNING: Converting UserGoal to map with empty id');
    }
    if (name.isEmpty) {
      debugPrint('WARNING: Converting UserGoal to map with empty name');
    }

    return {
      'uid': uid,
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'habitId': habitId,
    };
  }

  factory UserGoal.fromMap(Map<String, dynamic> map) {
    // Debug check for required fields
    if (map['uid'] == null || map['uid'] == '') {
      debugPrint('ERROR: Creating UserGoal from map with missing uid');
    }
    if (map['id'] == null || map['id'] == '') {
      debugPrint('ERROR: Creating UserGoal from map with missing id');
    }
    if (map['name'] == null || map['name'] == '') {
      debugPrint('ERROR: Creating UserGoal from map with missing name');
    }

    // Safely handle the habitId list
    List<String> habitIdList = [];
    if (map['habitId'] != null) {
      if (map['habitId'] is List) {
        habitIdList = List<String>.from(map['habitId']);
      } else {
        debugPrint('WARNING: habitId is not a list, converting to empty list');
      }
    }

    return UserGoal(
      uid: map['uid'] ?? '',
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdAt: map['createdAt'] ?? DateTime.now().toIso8601String(),
      updatedAt: map['updatedAt'] ?? DateTime.now().toIso8601String(),
      habitId: habitIdList,
    );
  }
}