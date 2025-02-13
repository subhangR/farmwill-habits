import 'package:flutter/material.dart';
import '../../../models/habits.dart';

class HabitNatureSelector extends StatelessWidget {
  final HabitNature selectedNature;
  final ValueChanged<HabitNature> onChanged;
  final Color positiveColor;
  final Color negativeColor;
  final Color backgroundColor;
  final Color textColor;

  const HabitNatureSelector({
    Key? key,
    required this.selectedNature,
    required this.onChanged,
    this.positiveColor = const Color(0xFF4CAF50),  // Default green
    this.negativeColor = const Color(0xFFE53935),  // Default red
    this.backgroundColor = const Color(0xFF2A2A2A), // Default dark background
    this.textColor = Colors.white,                 // Default text color
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(HabitNature.positive),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: selectedNature == HabitNature.positive
                    ? positiveColor
                    : backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedNature == HabitNature.positive
                      ? positiveColor
                      : Colors.grey[700]!,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_very_satisfied,
                    size: 40,
                    color: selectedNature == HabitNature.positive
                        ? Colors.white
                        : Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Good',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: selectedNature == HabitNature.positive
                          ? Colors.white
                          : Colors.grey[400],
                    ),
                  ),
                  Text(
                    'Build positive habits',
                    style: TextStyle(
                      fontSize: 12,
                      color: selectedNature == HabitNature.positive
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(HabitNature.negative),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: selectedNature == HabitNature.negative
                    ? negativeColor
                    : backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedNature == HabitNature.negative
                      ? negativeColor
                      : Colors.grey[700]!,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_very_dissatisfied,
                    size: 40,
                    color: selectedNature == HabitNature.negative
                        ? Colors.white
                        : Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: selectedNature == HabitNature.negative
                          ? Colors.white
                          : Colors.grey[400],
                    ),
                  ),
                  Text(
                    'Break negative habits',
                    style: TextStyle(
                      fontSize: 12,
                      color: selectedNature == HabitNature.negative
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}