
import 'package:flutter/material.dart';

import '../../../models/habits.dart';

class WeeklyScheduleSelector extends StatelessWidget {
  final WeeklySchedule schedule;
  final Function(WeeklySchedule) onChanged;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  const WeeklyScheduleSelector({
    super.key,
    required this.schedule,
    required this.onChanged,
    this.backgroundColor = const Color(0xFF2A2A2A),
    this.selectedColor = Colors.white,
    this.unselectedColor = const Color(0xFF3D3D3D),
  });

  void _updateDay(int dayIndex) {
    final List<String> dayKeys = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday'
    ];

    final Map<String, dynamic> currentSchedule = schedule.toMap();
    final String selectedDay = dayKeys[dayIndex];

    final Map<String, bool> newSchedule = Map<String, bool>.from(currentSchedule);
    newSchedule[selectedDay] = !currentSchedule[selectedDay]!;

    final updatedSchedule = WeeklySchedule.fromMap(newSchedule);
    onChanged(updatedSchedule);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> displayDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final List<bool> values = [
      schedule.sunday,
      schedule.monday,
      schedule.tuesday,
      schedule.wednesday,
      schedule.thursday,
      schedule.friday,
      schedule.saturday,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final bool isSelected = values[index];
          final String label = displayDays[index];

          return GestureDetector(
            onTap: () => _updateDay(index),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? selectedColor : unselectedColor,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}