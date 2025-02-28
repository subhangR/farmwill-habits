import 'package:farmwill_habits/repositories/habits_repository.dart';
import 'package:farmwill_habits/views/habits/habit_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'dart:math' as Math;

import '../../../models/habit_data.dart';
import '../../../models/habits.dart';
import '../habit_state.dart';
import 'tap_feedback.dart';

class HabitCard extends ConsumerStatefulWidget {
  final UserHabit userHabit;
  final HabitData? habitData;
  final DateTime selectedDate;

  const HabitCard({
    super.key,
    required this.userHabit,
    this.habitData,
    required this.selectedDate,
  });

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with SingleTickerProviderStateMixin {
  late int _currentReps;
  late int _currentMinutes;
  bool _isInitialized = false;
  DateTime? _lastLoadedDate;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  bool get hasStarted => _currentReps > 0;
  bool get isPositive => widget.userHabit.nature == HabitNature.positive;

  final HabitsRepository _habitsRepository = GetIt.I<HabitsRepository>();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _currentReps = 0;
    _currentMinutes = 0;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
    _loadCurrentDataFromState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForDateChange();
  }

  void _checkForDateChange() {
    final habitState = ref.read(habitStateProvider);
    final currentSelectedDate = habitState.selectedDate;

    if (_lastLoadedDate == null ||
        _lastLoadedDate!.year != currentSelectedDate.year ||
        _lastLoadedDate!.month != currentSelectedDate.month ||
        _lastLoadedDate!.day != currentSelectedDate.day) {
      _loadCurrentDataFromState();
    }
  }

  void _loadCurrentDataFromState() {
    final habitState = ref.read(habitStateProvider);
    final selectedDate = habitState.selectedDate;
    final dayLog = habitState.getDayLog(selectedDate);

    _lastLoadedDate = selectedDate;

    if (dayLog != null && dayLog.habits.containsKey(widget.userHabit.id)) {
      final habitData = dayLog.habits[widget.userHabit.id];
      if (habitData != null) {
        setState(() {
          _currentReps = habitData.reps;
          _currentMinutes = habitData.duration;
          _isInitialized = true;
        });
        _updateProgressAnimation();
      } else {
        setState(() {
          _currentReps = 0;
          _currentMinutes = 0;
          _isInitialized = true;
        });
      }
    } else {
      setState(() {
        _currentReps = 0;
        _currentMinutes = 0;
        _isInitialized = true;
      });
    }
  }

  void _updateProgressAnimation() {
    double progress = 0.0;
    if (widget.userHabit.targetReps > 0) {
      progress = _currentReps / widget.userHabit.targetReps;
      progress = progress.clamp(0.0, 1.0);
    } else {
      // If no target, show some progress based on reps
      progress =
          _currentReps > 0 ? 0.3 + (_currentReps * 0.05).clamp(0.0, 0.7) : 0.0;
    }

    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _animationController.reset();
    _animationController.forward();
  }

  void _handleTap() async {
    // Get the current reps for optimistic UI update
    int previousReps = _currentReps;
    final stepValue = widget.userHabit.repStep;

    // Optimistically update UI immediately
    setState(() {
      _currentReps += stepValue;
    });
    _updateProgressAnimation();

    // Calculate will points for UI update
    final willObtained = _calculateWillObtained();

    // Create the updated habit data
    final habitData = HabitData(
      reps: _currentReps,
      duration: _currentMinutes,
      willObtained: willObtained,
      targetReps: widget.userHabit.targetReps,
      willPerRep: widget.userHabit.willPerRep ?? 0,
      maxWill: widget.userHabit.maxWill ?? 0,
      startingWill: widget.userHabit.startingWill ?? 0,
      isCompleted: _currentReps >= widget.userHabit.targetReps,
    );

    // Get the habit state
    final habitState = ref.read(habitStateProvider);

    // Launch repository update in the background without awaiting
    _saveHabitDataAsync(habitData, habitState, previousReps);
  }

  // Separate method to handle the async repository operations
  Future<void> _saveHabitDataAsync(
      HabitData habitData, UserHabitState habitState, int previousReps) async {
    try {
      // Update in repository without blocking the UI
      await _habitsRepository.updateHabitData(
        habitId: widget.userHabit.id,
        userId: _userId,
        habitData: habitData,
        date: habitState.selectedDate,
      );

      // Reload the state data
      await habitState.loadHabitsAndData(_userId);

      // Force a rebuild if needed and if the widget is still mounted
      if (mounted) {
        setState(() {
          // This will refresh the UI with the latest data from the state
        });
      }
    } catch (e) {
      // Handle errors
      if (mounted) {
        // Revert optimistic update on error
        setState(() {
          _currentReps = previousReps;
        });
        _updateProgressAnimation();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update habit: $e')),
        );
      }
    }
  }

  int _calculateWillObtained() {
    final willPerRep = widget.userHabit.willPerRep ?? 0;
    final maxWill = widget.userHabit.maxWill ?? 0;
    final startingWill = widget.userHabit.startingWill ?? 0;

    int willObtained = _currentReps * willPerRep;

    // Apply max will cap if set
    if (maxWill > 0 && willObtained > maxWill) {
      willObtained = maxWill;
    }

    // Apply starting will if set
    if (startingWill > 0) {
      willObtained += startingWill;
    }

    return willObtained;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the habitStateProvider to rebuild when it changes
    final habitState = ref.watch(habitStateProvider);

    // Make sure we have the latest data
    if (_isInitialized &&
        habitState.habitsData.containsKey(widget.userHabit.id)) {
      final latestData = habitState.habitsData[widget.userHabit.id];
      if (latestData != null && latestData.reps != _currentReps) {
        // Update our local state if it's out of sync
        setState(() {
          _currentReps = latestData.reps;
          _currentMinutes = latestData.duration;
        });
        _updateProgressAnimation();
      }
    }

    final bool isPositiveHabit =
        widget.userHabit.nature == HabitNature.positive;
    final baseColor = isPositiveHabit ? Colors.green : Colors.red;
    final lightColor =
        isPositiveHabit ? Colors.green.shade300 : Colors.red.shade300;

    // Calculate progress percentage for display
    final progressPercent =
        (_currentReps / widget.userHabit.targetReps * 100).toInt();
    final isCompleted = widget.userHabit.targetReps > 0 &&
        _currentReps >= widget.userHabit.targetReps;

    // Get will points
    final willPoints = _getHabitWillPoints();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        splashColor: baseColor.withOpacity(0.3),
        highlightColor: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        child: Card(
          elevation: 12,
          shadowColor: baseColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: baseColor.withOpacity(0.8),
              width: 2.0,
            ),
          ),
          color: Colors.transparent, // Keep card fully transparent
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Gradient background - very subtle
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          baseColor.withOpacity(0.05),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),

                // Glow effect for completed habits
                if (isCompleted)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: baseColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Decrease button at the top right
                if (hasStarted)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: _handleRemove,
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Decrease reps',
                      ),
                    ),
                  ),

                // Completion badge for completed habits
                if (isCompleted)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),

                // Content - Use LayoutBuilder to make content responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate available height for content
                    final availableHeight = constraints.maxHeight;
                    // Adjust font sizes based on available width
                    final isNarrow = constraints.maxWidth < 160;

                    return Padding(
                      padding: EdgeInsets.fromLTRB(8, 8, 8, 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Habit name at the top - with constrained height
                          SizedBox(
                            height: availableHeight * 0.2,
                            child: Center(
                              child: Text(
                                widget.userHabit.name,
                                style: TextStyle(
                                  fontSize: isNarrow ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 3,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          // Reps in the center of the card with unit beside it
                          SizedBox(
                            height: availableHeight * 0.35,
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Current reps in large font
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$_currentReps',
                                        style: TextStyle(
                                          fontSize: isNarrow ? 30 : 36,
                                          fontWeight: FontWeight.bold,
                                          color: lightColor,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 4,
                                              offset: const Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 2),

                                  // Unit beside the reps
                                  Flexible(
                                    child: Text(
                                      widget.userHabit.repUnit,
                                      style: TextStyle(
                                        fontSize: isNarrow ? 14 : 16,
                                        fontWeight: FontWeight.w500,
                                        color: lightColor.withOpacity(0.8),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Bottom section with fixed height allocation
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Target info if available
                                if (widget.userHabit.targetReps > 0)
                                  Text(
                                    'of ${widget.userHabit.targetReps}',
                                    style: TextStyle(
                                      fontSize: isNarrow ? 12 : 14,
                                      color: Colors.white70,
                                    ),
                                  ),

                                // Progress indicator
                                if (widget.userHabit.targetReps > 0)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: constraints.maxWidth * 0.7,
                                      child: AnimatedBuilder(
                                        animation: _progressAnimation,
                                        builder: (context, child) {
                                          return LinearProgressIndicator(
                                            value: _progressAnimation.value,
                                            backgroundColor:
                                                Colors.grey.withOpacity(0.3),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              isCompleted
                                                  ? baseColor.withOpacity(0.8)
                                                  : lightColor,
                                            ),
                                            minHeight: 4,
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                // Will gained display - more compact to avoid overflow
                                if (willPoints != 0)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isNarrow ? 6 : 8,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.bolt,
                                          color: Colors.amber,
                                          size: isNarrow ? 12 : 14,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          willPoints > 0
                                              ? '+$willPoints'
                                              : '$willPoints',
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isNarrow ? 11 : 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Percentage complete at the bottom
                                if (widget.userHabit.targetReps > 0)
                                  Text(
                                    widget.userHabit.nature ==
                                            HabitNature.positive
                                        ? '$progressPercent% complete'
                                        : '${100 - progressPercent}% remaining',
                                    style: TextStyle(
                                      fontSize: isNarrow ? 10 : 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  void _handleRemove() {
    if (_currentReps <= 0) return;

    final stepValue = widget.userHabit.repStep;
    final int previousReps = _currentReps;

    // Optimistically update UI immediately
    setState(() {
      _currentReps = Math.max(0, _currentReps - stepValue);
    });
    _updateProgressAnimation();

    // Calculate will points for UI update
    final willObtained = _calculateWillObtained();

    // Create the updated habit data
    final habitData = HabitData(
      reps: _currentReps,
      duration: _currentMinutes,
      willObtained: willObtained,
      targetReps: widget.userHabit.targetReps,
      willPerRep: widget.userHabit.willPerRep ?? 0,
      maxWill: widget.userHabit.maxWill ?? 0,
      startingWill: widget.userHabit.startingWill ?? 0,
      isCompleted: _currentReps >= widget.userHabit.targetReps,
    );

    // Get the habit state
    final habitState = ref.read(habitStateProvider);

    // Launch repository update in the background without awaiting
    _saveHabitDataAsync(habitData, habitState, previousReps);
  }

  void _handleDoubleTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailsPage(userHabit: widget.userHabit),
      ),
    );
  }

  @override
  void didUpdateWidget(HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.habitData != oldWidget.habitData ||
        widget.selectedDate != oldWidget.selectedDate) {
      _loadCurrentDataFromState();
    }
  }
}
