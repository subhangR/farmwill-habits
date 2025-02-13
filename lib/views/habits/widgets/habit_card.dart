import 'package:farmwill_habits/repositories/habits_repository.dart';
import 'package:farmwill_habits/views/habits/create_habit_page.dart';
import 'package:farmwill_habits/views/habits/habit_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../models/habits.dart';
import 'habit_input_modal.dart';

class HabitCard extends StatefulWidget {
  UserHabit userHabit;
  HabitCard({
    Key? key,
    required this.userHabit,
  }) : super(key: key);

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  late int _currentReps;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonScaleAnimation;
  double _fillProgress = 0.0; // Track fill progress
  bool _isFilling = false; // Track if currently filling

  bool get isCompleted => _currentReps >= widget.userHabit.targetReps!;
  bool get hasStarted => _currentReps > 0;

  HabitsRepository habitsRepository = GetIt.I<HabitsRepository>();
  String _userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _currentReps = 0;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceIn),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startFilling() {
    setState(() {
      _isFilling = true;
    });

    // Animate fill over 2 seconds
    const fillDuration = Duration(milliseconds: 100);
    final startTime = DateTime.now();

    void updateFill() {
      if (!_isFilling) return;

      final elapsedTime = DateTime.now().difference(startTime);
      final progress =
          (elapsedTime.inMilliseconds / fillDuration.inMilliseconds)
              .clamp(0.0, 1.0);

      setState(() {
        _fillProgress = progress;
      });

      if (progress < 1.0 && _isFilling) {
        Future.delayed(const Duration(milliseconds: 16), updateFill);
      }
    }

    updateFill();
  }

  void _stopFilling() {
    setState(() {
      _isFilling = false;
      _fillProgress = 0.0;
    });
  }

  void _handleTap() async {
    if (_currentReps < widget.userHabit.targetReps!) {
      setState(() => _currentReps++);
      _controller.forward().then((_) => _controller.reverse());
      _startFilling();

      // Create updated habit data
      final habitData = HabitData(
        reps: _currentReps,
        duration: 0, // Update if you're tracking duration
        willObtained: 5, // Update based on your will calculation logic
        targetReps: widget.userHabit.targetReps!,
        targetDuration: widget.userHabit.targetMinutes ?? 0,
        targetWill: widget.userHabit.maxScore ?? 0,
        willPerRep: widget.userHabit.scorePerRep ?? 0,
        willPerDuration: widget.userHabit.scorePerMinute ?? 0,
        maxWill: widget.userHabit.maxScore ?? 0,
        startingWill: widget.userHabit.startingWill ?? 0,
        isCompleted: _currentReps >= widget.userHabit.targetReps!,
      );

      try {
        await habitsRepository.updateHabitData(
          habitId: widget.userHabit.id,
          userId: _userId,
          habitData: habitData,
          date: DateTime.now(),
        );

        if (_currentReps == widget.userHabit.targetReps) {
          _showCompletionConfetti();
        }
      } catch (e) {
        // Handle error (show snackbar, etc.)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update habit: $e')),
        );
      }
    }
  }
  void _handleLongPress() {
    _stopFilling();
    HabitUpdateModal.show(
      context,
      userHabit: widget.userHabit,
      targetDuration: 30,
      currentDuration: 20,
      targetReps: widget.userHabit.targetReps,
      currentReps: _currentReps,
      onUpdate: (reps, duration, completed) {
        setState(() {
          _currentReps = reps;
        });
      },
    );
  }

  void _handleRemove() {
    if (_currentReps > 0) {
      setState(() => _currentReps--);
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  void _showCompletionConfetti() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Updated Habit')),
    );
  }

  void _handDoubleTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailsPage(),
      ),
    );
  }

  String getFrequencyText() {
    WeeklySchedule weeklySchedule = widget.userHabit.weeklySchedule!;
    // count for number of days the weekly schedule is true
    int count = 0;
    if (weeklySchedule.monday) count++;
    if (weeklySchedule.tuesday) count++;
    if (weeklySchedule.wednesday) count++;
    if (weeklySchedule.thursday) count++;
    if (weeklySchedule.friday) count++;
    if (weeklySchedule.saturday) count++;
    if (weeklySchedule.sunday) count++;
    if (count == 7)
      return 'Daily';
    else {
      return "${count}x/week";
    }
  }

  Color getFillColor() {
    if (widget.userHabit.nature == HabitNature.positive) {
      // For positive habits
      if (isCompleted) {
        return Colors.green.shade700.withOpacity(0.3); // Darker green
      } else if (_currentReps > 0) {
        return Colors.green.shade300.withOpacity(0.3); // Lighter green
      }
    } else {
      // For negative habits
      if (isCompleted) {
        return Colors.red.shade700.withOpacity(0.3); // Darker red
      } else if (_currentReps > 0) {
        return Colors.red.shade300.withOpacity(0.3); // Lighter red
      }
    }
    return Colors.transparent;
  }

  Color getProgressColor() {
    if (widget.userHabit.nature == HabitNature.positive) {
      return isCompleted
          ? Colors.green.shade700.withOpacity(0.5)
          : // Darker green
          Colors.green.shade300.withOpacity(0.5); // Lighter green
    } else {
      return isCompleted
          ? Colors.red.shade700.withOpacity(0.5)
          : // Darker red
          Colors.red.shade300.withOpacity(0.5); // Lighter red
    }
  }

// Update _buildActionButton() method:
  Widget _buildActionButton() {
    final isPositive = widget.userHabit.nature == HabitNature.positive;
    final baseColor = isPositive ? Colors.green : Colors.red;

    return Transform.translate(
      offset: const Offset(0, -12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isCompleted ? baseColor.shade700 : baseColor.shade300)
                  .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleRemove,
            onLongPress: _handleLongPress,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCompleted ? baseColor.shade700 : baseColor.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: RotationTransition(
                      turns: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.remove_circle,
                  key: ValueKey(isCompleted),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color getBorderColor() {
      if (widget.userHabit.nature == HabitNature.positive) {
        return Colors.green.withOpacity(0.7);
      } else {
        return Colors.red.withOpacity(0.7);
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onDoubleTap: _handDoubleTap,
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: getBorderColor(),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
// Update the fill animation in build method:
                      if (_isFilling)
                        Positioned.fill(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            decoration: BoxDecoration(
                              color: getFillColor(),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _fillProgress,
                              child: Container(
                                color: getProgressColor(),
                              ),
                            ),
                          ),
                        ),

                      // Fill Animation Layer
                      // Content Layer
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF2D2D2D).withOpacity(0.3),
                        ),
                        child: Row(
                          children: [
                            // Rest of your existing row content...
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.userHabit.habitIcon,
                                size: 32,
                                color:
                                    isCompleted ? Colors.green : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.userHabit.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      widget.userHabit.targetReps == 1
                                          ? isCompleted
                                              ? 'Completed'
                                              : 'Not completed'
                                          : '$_currentReps/${widget.userHabit.targetReps} reps',
                                      key: ValueKey(_currentReps),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        size: 20,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        "5",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  getFrequencyText(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasStarted || isCompleted)
          Positioned(
            top: 0,
            right: 24,
            child: _buildActionButton(),
          ),
      ],
    );
  }
}

