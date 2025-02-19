import 'package:farmwill_habits/views/habits/habit_details_page.dart';
import 'package:farmwill_habits/views/habits/widgets/will_widget.dart';
import 'package:flutter/material.dart';

import '../../../models/habits.dart';
class HabitUpdateModal extends StatefulWidget {
  UserHabit userHabit;
  final int currentReps;
  final int currentDuration;
  final Function(int reps, int duration, bool completed) onUpdate;

  HabitUpdateModal({
    Key? key,
    required this.userHabit,
    required this.currentReps,
    required this.currentDuration,
    required this.onUpdate,
  }) : super(key: key);

  static Future<void> show(
      BuildContext context, {
        required UserHabit userHabit,
        required int currentReps,
        required int targetReps,
        required int currentDuration,
        required int targetDuration,
        required Function(int reps, int duration, bool completed) onUpdate,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HabitUpdateModal(
        userHabit: userHabit,
        currentReps: currentReps,
        currentDuration: currentDuration,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<HabitUpdateModal> createState() => _HabitUpdateModalState();
}

class _HabitUpdateModalState extends State<HabitUpdateModal>
    with SingleTickerProviderStateMixin {
  late int _reps;
  late int _duration;
  late AnimationController _animationController;
  late Animation<double> _animation;

  bool get _isRepsCompleted => _reps >= widget.userHabit.targetReps;
  bool get _isDurationCompleted => widget.userHabit.targetMinutes != 0 ?
        _duration >= widget.userHabit.targetMinutes! : false;
  bool get _isHabitCompleted => _isRepsCompleted;

  @override
  void initState() {
    super.initState();
    _reps = widget.currentReps;
    _duration = widget.currentDuration;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleAddRep() {
    setState(() => _reps++);
  }

  void _handleSubtractRep() {
    if (_reps > 0) {
      setState(() => _reps--);
    }
  }

  void _handleCompleteReps() {
    setState(() => _reps = widget.userHabit.targetReps);
  }

  void _handleAddDuration() {
    setState(() => _duration += 5);
  }

  void _handleSubtractDuration() {
    if (_duration >= 5) {
      setState(() => _duration -= 5);
    }
  }

  void _handleCompleteDuration() {
    setState(() => _duration = widget.userHabit.targetMinutes ?? 0);
  }

  void _handleComplete() {
    widget.onUpdate(_reps, _duration, _isHabitCompleted);
    Navigator.pop(context);
  }

  void _showHabitDetails() {
    // Implement habit details navigation
  }

  Widget _buildProgressSection({
    required String title,
    required int current,
    required int target,
    required VoidCallback onAdd,
    required VoidCallback onSubtract,
    required VoidCallback onComplete,
    required bool isCompleted,
    String? unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${current}/${target}${unit != null ? ' $unit' : ''}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Controls section with fixed width
            SizedBox(
              width: 200, // Fixed width for controls
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _CircularIconButton(
                    icon: Icons.remove,
                    onTap: onSubtract,
                    backgroundColor: Colors.red.shade100,
                    iconColor: Colors.red.shade700,
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 48, // Fixed width for number
                    child: Text(
                      '$current',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _CircularIconButton(
                    icon: Icons.add,
                    onTap: onAdd,
                    backgroundColor: Colors.green.shade100,
                    iconColor: Colors.green.shade700,
                  ),
                ],
              ),
            ),
            const Spacer(), // This will push the complete button to the right
            // Complete button with fixed width
            SizedBox(
              width: 140, // Fixed width for complete button
              child: ElevatedButton.icon(
                onPressed: onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCompleted ? Colors.green : Colors.blue.shade100,
                  foregroundColor: isCompleted ? Colors.white : Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(isCompleted ? Icons.check : Icons.flag),
                label: Text(isCompleted ? 'Completed' : 'Complete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>  HabitDetailsPage(
          userHabit: widget.userHabit,
        ), // You'll need to create this page
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - _animation.value)),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar with Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      widget.userHabit.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    WillWidget(willPoints: 10),
                    IconButton(
                      onPressed: _openCalendar,
                      icon: Icon(
                        Icons.calendar_month,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Reps Control
                _buildProgressSection(
                  title: 'Repetitions',
                  current: _reps,
                  target: widget.userHabit.targetReps,
                  onAdd: _handleAddRep,
                  onSubtract: _handleSubtractRep,
                  onComplete: _handleCompleteReps,
                  isCompleted: _isRepsCompleted,
                ),
                const SizedBox(height: 24),

                // Duration Control
                _buildProgressSection(
                  title: 'Duration',
                  current: _duration,
                  target: widget.userHabit.targetMinutes ?? 0,
                  onAdd: _handleAddDuration,
                  onSubtract: _handleSubtractDuration,
                  onComplete: _handleCompleteDuration,
                  isCompleted: _isDurationCompleted,
                  unit: 'min',
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _handleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isHabitCompleted
                        ? Colors.green.shade600
                        : Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      const SizedBox(width: 8),
                      const Text(
                        'Save',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Habit Details Button
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  const _CircularIconButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}