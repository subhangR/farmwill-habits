import 'package:farmwill_habits/repositories/habits_repository.dart';
import 'package:farmwill_habits/views/habits/habit_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../../models/habit_data.dart';
import '../../../models/habits.dart';
import '../habit_list_screen.dart';
import '../habit_state.dart';
import 'habit_input_modal.dart';

class HabitCard extends ConsumerStatefulWidget {
  final UserHabit userHabit;

  const HabitCard({
    Key? key,
    required this.userHabit,
  }) : super(key: key);

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with SingleTickerProviderStateMixin {
  late int _currentReps;
  late int _currentMinutes;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonScaleAnimation;
  double _fillProgress = 0.0; // Track fill progress
  double _startFillProgress = 0.0; // Track starting fill progress for animations
  double _targetFillProgress = 0.0; // Track target fill progress for animations
  bool _isFilling = false; // Track if currently filling
  bool _isInitialized = false; // Track if card has been initialized
  DateTime? _lastLoadedDate; // Track last loaded date to detect changes

  bool get isCompleted {
    if (widget.userHabit.goalType == GoalType.repetitions) {
      return _currentReps >= widget.userHabit.targetReps!;
    } else {
      return _currentMinutes >= (widget.userHabit.targetMinutes ?? 0);
    }
  }

  bool get hasStarted {
    return widget.userHabit.goalType == GoalType.repetitions
        ? _currentReps > 0
        : _currentMinutes > 0;
  }

  // Additional duration increment value
  final int _minutesIncrement = 5;

  final HabitsRepository _habitsRepository = GetIt.I<HabitsRepository>();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _currentReps = 0;
    _currentMinutes = 0;
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

    // Load current data from provider
    _loadCurrentDataFromState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we need to reload data due to date change
    _checkForDateChange();
  }

  void _checkForDateChange() {
    final habitState = ref.read(habitStateProvider);
    final currentSelectedDate = habitState.selectedDate;

    // Check if the date has changed since we last loaded data
    if (_lastLoadedDate == null ||
        _lastLoadedDate!.year != currentSelectedDate.year ||
        _lastLoadedDate!.month != currentSelectedDate.month ||
        _lastLoadedDate!.day != currentSelectedDate.day) {
      // Date has changed, reload data
      _loadCurrentDataFromState();
    }
  }

  void _loadCurrentDataFromState() {
    final habitState = ref.read(habitStateProvider);
    final selectedDate = habitState.selectedDate;
    final dayLog = habitState.getDayLog(selectedDate);

    // Store current date to track changes
    _lastLoadedDate = selectedDate;

    // Reset state for new date
    setState(() {
      _currentReps = 0;
      _currentMinutes = 0;
      _fillProgress = 0.0;
      _startFillProgress = 0.0;
      _targetFillProgress = 0.0;
    });

    if (dayLog != null && dayLog.habits.containsKey(widget.userHabit.id)) {
      final habitData = dayLog.habits[widget.userHabit.id];
      if (habitData != null) {
        setState(() {
          _currentReps = habitData.reps;
          _currentMinutes = habitData.duration;
          _isInitialized = true;

          // Calculate fill progress based on goal type
          if (widget.userHabit.goalType == GoalType.repetitions) {
            if (_currentReps > 0 && widget.userHabit.targetReps! > 0) {
              _fillProgress = _currentReps / widget.userHabit.targetReps!;
            } else if (isCompleted) {
              _fillProgress = 1.0;
            }
          } else {
            // Duration goal type
            final targetMinutes = widget.userHabit.targetMinutes ?? 0;
            if (_currentMinutes > 0 && targetMinutes > 0) {
              _fillProgress = _currentMinutes / targetMinutes;
            } else if (isCompleted) {
              _fillProgress = 1.0;
            }
          }
          // Initialize start fill progress to current progress
          _startFillProgress = _fillProgress;
        });
      } else {
        setState(() {
          _isInitialized = true;
        });
      }
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startFilling() {
    // Calculate new target fill progress based on current progress
    if (widget.userHabit.goalType == GoalType.repetitions) {
      _targetFillProgress = _currentReps / widget.userHabit.targetReps!;
    } else {
      final targetMinutes = widget.userHabit.targetMinutes ?? 0;
      if (targetMinutes > 0) {
        _targetFillProgress = _currentMinutes / targetMinutes;
      }
    }

    // Store the current progress as starting point
    _startFillProgress = _fillProgress;

    setState(() {
      _isFilling = true;
    });

    // Animate fill over 150ms
    const fillDuration = Duration(milliseconds: 150);
    final startTime = DateTime.now();

    void updateFill() {
      if (!_isFilling) return;

      final elapsedTime = DateTime.now().difference(startTime);
      final animationProgress =
      (elapsedTime.inMilliseconds / fillDuration.inMilliseconds)
          .clamp(0.0, 1.0);

      setState(() {
        // Interpolate between start and target fill values
        _fillProgress = _startFillProgress +
            (_targetFillProgress - _startFillProgress) * animationProgress;
      });

      if (animationProgress < 1.0 && _isFilling) {
        Future.delayed(const Duration(milliseconds: 16), updateFill);
      } else if (animationProgress >= 1.0) {
        _isFilling = false;
      }
    }

    updateFill();
  }

  void _stopFilling() {
    setState(() {
      _isFilling = false;
      // Store current progress as the final state
      _fillProgress = _targetFillProgress;
    });
  }

  void _handleTap() async {
    if (isCompleted) return;

    _controller.forward().then((_) => _controller.reverse());

    // Store previous values for animation
    int previousReps = _currentReps;
    int previousMinutes = _currentMinutes;

    // Update based on goal type
    if (widget.userHabit.goalType == GoalType.repetitions) {
      setState(() => _currentReps++);
    } else {
      setState(() => _currentMinutes += _minutesIncrement);
    }

    _startFilling();

    // Update will points through the provider
    final habitState = ref.read(habitStateProvider);
    int willChange = 0;

    if (widget.userHabit.goalType == GoalType.repetitions && widget.userHabit.willPerRep != null) {
      willChange = widget.userHabit.willPerRep!;
    } else if (widget.userHabit.goalType == GoalType.duration && widget.userHabit.willPerMin != null) {
      willChange = widget.userHabit.willPerMin! * _minutesIncrement;
    }

    if (willChange != 0) {
      habitState.updateWillPoints(willChange);
    }

    // Create updated habit data
    final willObtained = _calculateWillObtained();

    final habitData = HabitData(
      reps: _currentReps,
      duration: _currentMinutes,
      goalType: widget.userHabit.goalType,
      willObtained: willObtained,
      targetReps: widget.userHabit.targetReps ?? 0,
      targetDuration: widget.userHabit.targetMinutes ?? 0,
      targetWill: widget.userHabit.maxScore ?? 0,
      willPerRep: widget.userHabit.willPerRep ?? 0,
      willPerDuration: widget.userHabit.willPerMin ?? 0,
      maxWill: widget.userHabit.maxScore ?? 0,
      startingWill: widget.userHabit.startingWill ?? 0,
      isCompleted: isCompleted,
    );

    try {
      // Update habit data in repository
      await _habitsRepository.updateHabitData(
        habitId: widget.userHabit.id,
        userId: _userId,
        habitData: habitData,
        date: habitState.selectedDate,
      );

      // Reload habits data to refresh the UI
      await habitState.loadHabitsAndData(_userId);

      if (isCompleted) {
        _showCompletionConfetti();
      }
    } catch (e) {
      // Revert local state on error
      setState(() {
        if (widget.userHabit.goalType == GoalType.repetitions) {
          _currentReps = previousReps;
        } else {
          _currentMinutes = previousMinutes;
        }
        _fillProgress = _startFillProgress;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update habit: $e')),
      );
    }
  }

  int _calculateWillObtained() {
    if (widget.userHabit.goalType == GoalType.repetitions) {
      return widget.userHabit.willPerRep != null ?
      _currentReps * widget.userHabit.willPerRep! : 0;
    } else {
      return widget.userHabit.willPerMin != null ?
      _currentMinutes * widget.userHabit.willPerMin! : 0;
    }
  }

  void _handleLongPress() {
    _stopFilling();
    HabitUpdateModal.show(
      context,
      userHabit: widget.userHabit,
      targetDuration: widget.userHabit.targetMinutes ?? 0,
      currentDuration: _currentMinutes,
      targetReps: widget.userHabit.targetReps,
      currentReps: _currentReps,
      onUpdate: (reps, duration, completed) async {
        // Store previous progress for potential animation
        double previousProgress = _fillProgress;

        setState(() {
          _currentReps = reps;
          _currentMinutes = duration;

          // Update fill progress based on new data
          if (widget.userHabit.goalType == GoalType.repetitions) {
            if (widget.userHabit.targetReps! > 0) {
              _fillProgress = reps / widget.userHabit.targetReps!;
            }
          } else {
            final targetMinutes = widget.userHabit.targetMinutes ?? 0;
            if (targetMinutes > 0) {
              _fillProgress = duration / targetMinutes;
            }
          }
        });

        // Create updated habit data for modal update
        final habitData = HabitData(
          reps: reps,
          duration: duration,
          goalType: widget.userHabit.goalType,
          willObtained: _calculateWillObtained(),
          targetReps: widget.userHabit.targetReps ?? 0,
          targetDuration: widget.userHabit.targetMinutes ?? 0,
          targetWill: widget.userHabit.maxScore ?? 0,
          willPerRep: widget.userHabit.willPerRep ?? 0,
          willPerDuration: widget.userHabit.willPerMin ?? 0,
          maxWill: widget.userHabit.maxScore ?? 0,
          startingWill: widget.userHabit.startingWill ?? 0,
          isCompleted: completed,
        );

        try {
          final habitState = ref.read(habitStateProvider);

          // Update habit data in repository
          await _habitsRepository.updateHabitData(
            habitId: widget.userHabit.id,
            userId: _userId,
            habitData: habitData,
            date: habitState.selectedDate,
          );

          // Reload habits data to refresh the UI
          await habitState.loadHabitsAndData(_userId);
        } catch (e) {
          // Revert on error
          setState(() {
            _fillProgress = previousProgress;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update habit: $e')),
          );
        }
      },
    );
  }

  void _handleRemove() async {
    if (!hasStarted) return;

    _controller.forward().then((_) => _controller.reverse());

    // Store previous values for potential revert
    int previousReps = _currentReps;
    int previousMinutes = _currentMinutes;
    double previousFillProgress = _fillProgress;

    // Update based on goal type
    int willChange = 0;

    if (widget.userHabit.goalType == GoalType.repetitions) {
      if (_currentReps > 0) {
        setState(() {
          _currentReps--;
          // Update fill progress
          if (widget.userHabit.targetReps! > 0) {
            _fillProgress = _currentReps / widget.userHabit.targetReps!;
          }
        });

        if (widget.userHabit.willPerRep != null) {
          willChange = -widget.userHabit.willPerRep!;
        }
      }
    } else {
      if (_currentMinutes >= _minutesIncrement) {
        setState(() {
          _currentMinutes -= _minutesIncrement;
          // Update fill progress
          final targetMinutes = widget.userHabit.targetMinutes ?? 0;
          if (targetMinutes > 0) {
            _fillProgress = _currentMinutes / targetMinutes;
          }
        });

        if (widget.userHabit.willPerMin != null) {
          willChange = -widget.userHabit.willPerMin! * _minutesIncrement;
        }
      }
    }

    // Update will points through the provider
    if (willChange != 0) {
      final habitState = ref.read(habitStateProvider);
      habitState.updateWillPoints(willChange);
    }

    // Create updated habit data
    final willObtained = _calculateWillObtained();

    final habitData = HabitData(
      reps: _currentReps,
      duration: _currentMinutes,
      goalType: widget.userHabit.goalType,
      willObtained: willObtained,
      targetReps: widget.userHabit.targetReps ?? 0,
      targetDuration: widget.userHabit.targetMinutes ?? 0,
      targetWill: widget.userHabit.maxScore ?? 0,
      willPerRep: widget.userHabit.willPerRep ?? 0,
      willPerDuration: widget.userHabit.willPerMin ?? 0,
      maxWill: widget.userHabit.maxScore ?? 0,
      startingWill: widget.userHabit.startingWill ?? 0,
      isCompleted: isCompleted,
    );

    try {
      // Update habit data in repository
      final habitState = ref.read(habitStateProvider);
      await _habitsRepository.updateHabitData(
        habitId: widget.userHabit.id,
        userId: _userId,
        habitData: habitData,
        date: habitState.selectedDate,
      );

      // Reload habits data to refresh the UI
      await habitState.loadHabitsAndData(_userId);
    } catch (e) {
      // Revert on error
      setState(() {
        _currentReps = previousReps;
        _currentMinutes = previousMinutes;
        _fillProgress = previousFillProgress;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update habit: $e')),
      );
    }
  }

  void _showCompletionConfetti() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Updated Habit')),
    );
  }

  void _handleDoubleTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailsPage(
          userHabit: widget.userHabit,
        ),
      ),
    ).then((_) {
      // Refresh data when returning from details page
      final habitState = ref.read(habitStateProvider);
      habitState.loadHabitsAndData(_userId);
    });
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

  String getGoalProgressText() {
    // For negative habits, don't show detailed progress
    if (widget.userHabit.nature == HabitNature.negative) {
      return isCompleted ? 'Completed' : hasStarted ? 'In progress' : 'Not started';
    }

    // For positive habits, show detailed progress
    if (widget.userHabit.goalType == GoalType.repetitions) {
      return widget.userHabit.targetReps == 1
          ? isCompleted
          ? 'Completed'
          : 'Not completed'
          : '$_currentReps/${widget.userHabit.targetReps} reps';
    } else {
      return '$_currentMinutes/${widget.userHabit.targetMinutes} min';
    }
  }

  Color getFillColor() {
    if (widget.userHabit.nature == HabitNature.positive) {
      // For positive habits
      if (isCompleted) {
        return Colors.green.shade700.withOpacity(0.3); // Darker green
      } else if (hasStarted) {
        return Colors.green.shade300.withOpacity(0.3); // Lighter green
      }
    } else {
      // For negative habits
      if (isCompleted) {
        return Colors.red.shade700.withOpacity(0.3); // Darker red
      } else if (hasStarted) {
        return Colors.red.shade300.withOpacity(0.3); // Lighter red
      }
    }
    return Colors.transparent;
  }

  Color getProgressColor() {
    if (widget.userHabit.nature == HabitNature.positive) {
      return isCompleted
          ? Colors.green.shade700.withOpacity(0.5)
          : Colors.green.shade300.withOpacity(0.5);
    } else {
      return isCompleted
          ? Colors.red.shade700.withOpacity(0.5)
          : Colors.red.shade300.withOpacity(0.5);
    }
  }

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
    // Watch for changes in the habit state
    final habitState = ref.watch(habitStateProvider);
    final currentDate = habitState.selectedDate;

    // Check if we need to reload data due to date change
    if (_lastLoadedDate == null ||
        _lastLoadedDate!.year != currentDate.year ||
        _lastLoadedDate!.month != currentDate.month ||
        _lastLoadedDate!.day != currentDate.day) {
      // If we're in build, schedule a reload for after this build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCurrentDataFromState();
      });
    }

    // If not initialized yet, show a loading placeholder
    if (!_isInitialized) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          onDoubleTap: _handleDoubleTap,
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
                      // Background fill for completed/partially completed habits
                      if (hasStarted)
                        Positioned.fill(
                          child: Container(
                            color: getFillColor(),
                          ),
                        ),

                      // Progress fill animation
                      if (hasStarted)
                        Positioned.fill(
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _fillProgress.clamp(0.0, 1.0),
                            child: Container(
                              color: getProgressColor(),
                            ),
                          ),
                        ),

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
                                      getGoalProgressText(),
                                      key: ValueKey('${_currentReps}_${_currentMinutes}_${widget.userHabit.nature}_${currentDate.toString()}'),
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
                                      Text(
                                        // Display will points from habit data
                                        _getHabitWillPoints().toString(),
                                        style: const TextStyle(
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

  // Get will points for this habit from state
  int _getHabitWillPoints() {
    final habitState = ref.read(habitStateProvider);
    final selectedDate = habitState.selectedDate;
    final dayLog = habitState.getDayLog(selectedDate);

    if (dayLog != null && dayLog.habits.containsKey(widget.userHabit.id)) {
      final habitData = dayLog.habits[widget.userHabit.id];
      if (habitData != null) {
        return habitData.willObtained;
      }
    }

    return _calculateWillObtained();
  }
}