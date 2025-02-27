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
import 'habit_input_modal.dart';

class HabitCard extends ConsumerStatefulWidget {
  final UserHabit userHabit;

  const HabitCard({
    super.key,
    required this.userHabit,
  });

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard> {
  late int _currentReps;
  late int _currentMinutes;
  bool _isInitialized = false;
  DateTime? _lastLoadedDate;

  bool get hasStarted => _currentReps > 0;

  final HabitsRepository _habitsRepository = GetIt.I<HabitsRepository>();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _currentReps = 0;
    _currentMinutes = 0;
    _loadCurrentDataFromState();
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

    setState(() {
      _currentReps = 0;
      _currentMinutes = 0;
    });

    if (dayLog != null && dayLog.habits.containsKey(widget.userHabit.id)) {
      final habitData = dayLog.habits[widget.userHabit.id];
      if (habitData != null) {
        setState(() {
          _currentReps = habitData.reps;
          _currentMinutes = habitData.duration;
          _isInitialized = true;
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

  void _handleTap() async {
    int previousReps = _currentReps;
    final stepValue = widget.userHabit.repetitionStep ?? 1;
    
    setState(() {
      _currentReps += stepValue;
    });

    final habitState = ref.read(habitStateProvider);
    int willChange = 0;

    if (widget.userHabit.willPerRep != null) {
      willChange = widget.userHabit.willPerRep! * stepValue;
    }

    if (willChange != 0) {
      habitState.updateWillPoints(willChange);
    }

    final willObtained = _calculateWillObtained();
    final habitData = HabitData(
      reps: _currentReps,
      duration: _currentMinutes,
      willObtained: willObtained,
      targetReps: 0,
      willPerRep: widget.userHabit.willPerRep ?? 0,
      maxWill: widget.userHabit.maxWill ?? 0,
      startingWill: widget.userHabit.startingWill ?? 0,
      isCompleted: false,
    );

    try {
      await _habitsRepository.updateHabitData(
        habitId: widget.userHabit.id,
        userId: _userId,
        habitData: habitData,
        date: habitState.selectedDate,
      );

      await habitState.loadHabitsAndData(_userId);
    } catch (e) {
      setState(() {
        _currentReps = previousReps;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update habit: $e')),
      );
    }
  }

  int _calculateWillObtained() {
    return widget.userHabit.willPerRep != null
        ? _currentReps * widget.userHabit.willPerRep!
        : 0;
  }

  void _handleLongPress() {
    final int previousReps = _currentReps;
    
    HabitUpdateModal.show(
      context,
      userHabit: widget.userHabit,
      targetReps: 0,
      currentReps: _currentReps,
      onUpdate: (reps, duration, completed) async {
        setState(() {
          _currentReps = reps;
          _currentMinutes = duration;
        });

        final willObtained = _calculateWillObtained();
        final habitData = HabitData(
          reps: _currentReps,
          duration: _currentMinutes,
          willObtained: willObtained,
          targetReps: 0,
          willPerRep: widget.userHabit.willPerRep ?? 0,
          maxWill: widget.userHabit.maxWill ?? 0,
          startingWill: widget.userHabit.startingWill ?? 0,
          isCompleted: false,
        );

        try {
          final habitState = ref.read(habitStateProvider);
          await _habitsRepository.updateHabitData(
            habitId: widget.userHabit.id,
            userId: _userId,
            habitData: habitData,
            date: habitState.selectedDate,
          );

          await habitState.loadHabitsAndData(_userId);
        } catch (e) {
          setState(() {
            _currentReps = previousReps;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update habit: $e')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitStateProvider);
    final currentDate = habitState.selectedDate;

    if (_lastLoadedDate == null ||
        _lastLoadedDate!.year != currentDate.year ||
        _lastLoadedDate!.month != currentDate.month ||
        _lastLoadedDate!.day != currentDate.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCurrentDataFromState();
      });
    }

    if (!_isInitialized) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        onDoubleTap: _handleDoubleTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userHabit.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reps: $_currentReps'),
                  Text('Will: ${_getHabitWillPoints()}'),
                  if (hasStarted)
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed: _handleRemove,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
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

    final stepValue = widget.userHabit.repetitionStep ?? 1;
    final int previousReps = _currentReps;

    setState(() {
      _currentReps = Math.max(0, _currentReps - stepValue);
    });

    final habitState = ref.read(habitStateProvider);
    int willChange = 0;

    if (widget.userHabit.willPerRep != null) {
      willChange = -widget.userHabit.willPerRep! * stepValue;
    }

    if (willChange != 0) {
      habitState.updateWillPoints(willChange);
    }

    final willObtained = _calculateWillObtained();
    final habitData = HabitData(
      reps: _currentReps,
      duration: _currentMinutes,
      willObtained: willObtained,
      targetReps: 0,
      willPerRep: widget.userHabit.willPerRep ?? 0,
      maxWill: widget.userHabit.maxWill ?? 0,
      startingWill: widget.userHabit.startingWill ?? 0,
      isCompleted: false,
    );

    try {
      _habitsRepository.updateHabitData(
        habitId: widget.userHabit.id,
        userId: _userId,
        habitData: habitData,
        date: habitState.selectedDate,
      ).then((_) {
        habitState.loadHabitsAndData(_userId);
      });
    } catch (e) {
      setState(() {
        _currentReps = previousReps;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update habit: $e')),
      );
    }
  }

  void _handleDoubleTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailsPage(userHabit: widget.userHabit),
      ),
    );
  }
}
