import 'package:flutter/material.dart';

class WillWidget extends StatelessWidget {
  final int willPoints;

  const WillWidget({
    super.key,
    required this.willPoints,
  });

  @override
  Widget build(BuildContext context) {
    String willText = willPoints > 0 ? '+$willPoints' : '$willPoints';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade300,  // Lighter golden color
            Colors.amber.shade600,  // Darker golden color
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade700.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Red icon without gradient
          const Icon(
            Icons.flash_on,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 6),
          // Black text without gradient
          Text(
            willText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}