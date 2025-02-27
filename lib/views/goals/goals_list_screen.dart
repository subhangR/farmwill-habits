import 'package:farmwill_habits/views/habits/widgets/will_widget.dart';
import 'package:farmwill_habits/views/habits/will_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../models/goals.dart';
import '../../models/habits.dart';
import '../../repositories/habits_repository.dart';
import '../habits/habit_state.dart';
import 'edit_goal.dart';
import 'goal_screen.dart';

class GoalsListPage extends ConsumerStatefulWidget {
  const GoalsListPage({super.key});

  @override
  ConsumerState<GoalsListPage> createState() => _GoalsListScreenState();
}

class _GoalsListScreenState extends ConsumerState<GoalsListPage>
    with SingleTickerProviderStateMixin {
  final HabitsRepository _habitsRepository = GetIt.I<HabitsRepository>();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  List<UserGoal> _goals = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadGoals();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userHabitState = ref.read(habitStateProvider);
      await userHabitState.loadHabitsAndData(_userId);
      await userHabitState.loadGoals(_userId);

      setState(() {
        _goals = userHabitState.goals;
        _isLoading = false;
      });

      _animationController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading goals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the user habit state for changes
    final userHabitState = ref.watch(habitStateProvider);
    final willPoints = userHabitState.willPoints;
    final hasError = userHabitState.error != null;

    // If goals list changes in the state, update local list
    if (_goals != userHabitState.goals) {
      _goals = userHabitState.goals;
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacementNamed('/habits');
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D2D2D),
          title: const Text('Goals'),
          automaticallyImplyLeading: false,
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final habitState = ref.watch(habitStateProvider);
                final totalWill = habitState.calculateTotalWill();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const WillHistoryPage()),
                      );
                    },
                    child: WillWidget(willPoints: totalWill),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CreateGoalPage()),
            );
            _loadGoals();
          },
          backgroundColor: Colors.blue.shade700,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: RefreshIndicator(
          onRefresh: _loadGoals,
          color: Colors.blue.shade700,
          backgroundColor: Colors.grey.shade900,
          child: _buildGoalsGrid(userHabitState),
        ),
      ),
    );
  }

  Widget _buildGoalsGrid(UserHabitState userHabitState) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (userHabitState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              userHabitState.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGoals,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            const Text(
              'No goals yet',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create goals to organize your habits',
              style: TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const CreateGoalPage()),
                );
                _loadGoals();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8, // Increased from 0.7 to make cards shorter
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _goals.length,
      itemBuilder: (context, index) {
        final goal = _goals[index];
        return _buildGoalCard(goal, userHabitState);
      },
    );
  }

  Widget _buildGoalCard(UserGoal goal, UserHabitState userHabitState) {
    // Calculate core metrics
    final totalWillObtained = _calculateTotalWillObtained(goal, userHabitState);
    final totalHabits = goal.habitId.length;
    final completedHabits = _calculateCompletedHabits(goal, userHabitState);

    // Calculate progress
    int totalTargetSteps = 0;
    int totalCompletedSteps = 0;

    for (final habitId in goal.habitId) {
      final habit = userHabitState.habits.firstWhere(
        (h) => h.id == habitId,
        orElse: () => UserHabit(
          id: '',
          name: '',
          repUnit: '',
          repStep: 1,
          targetReps: 0,
          uid: '',
          createdAt: DateTime.now(),
          habitType: HabitType.regular,
          nature: HabitNature.positive,
          weeklySchedule: const WeeklySchedule(),
          isArchived: false,
          frequencyType: FrequencyType.daily,
        ),
      );

      if (habit.id.isEmpty || habit.targetReps <= 0) continue;

      final habitData = userHabitState.habitsData[habitId];
      if (habitData != null) {
        totalTargetSteps += (habit.targetReps / habit.repStep).toInt();
        totalCompletedSteps += (habitData.reps / habit.repStep).toInt();
      }
    }

    // Calculate percentage for visual elements
    final progress =
        totalTargetSteps > 0 ? totalCompletedSteps / totalTargetSteps : 0.0;
    final progressPercent = (progress * 100).toInt();

    // Choose dynamic colors based on progress
    final Color progressColor = progressPercent > 75
        ? Colors.green
        : progressPercent > 50
            ? Colors.amber
            : progressPercent > 25
                ? Colors.orange
                : Colors.red;

    return Card(
      elevation: 8,
      shadowColor: Colors.black54,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D2D2D),
              const Color(0xFF1F1F1F),
            ],
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => GoalScreen(goal: goal)),
            );
          },
          child: Stack(
            children: [
              // Decorative circle
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: progressColor.withOpacity(0.15),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal name
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Progress circle
                    Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          children: [
                            // Progress indicator
                            ShaderMask(
                              shaderCallback: (rect) {
                                return SweepGradient(
                                  startAngle: 0.0,
                                  endAngle: progress * 2 * 3.14159,
                                  stops: const [0.0, 1.0],
                                  center: Alignment.center,
                                  colors: [progressColor, progressColor],
                                ).createShader(rect);
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade800,
                                    width: 5,
                                  ),
                                ),
                              ),
                            ),

                            // Center circle with percent
                            Center(
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF222222),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 2,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$progressPercent%',
                                        style: TextStyle(
                                          color: progressColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Will Points
                        Column(
                          children: [
                            Icon(Icons.bolt,
                                color: Colors.amber.shade300, size: 18),
                            const SizedBox(height: 2),
                            Text(
                              '$totalWillObtained',
                              style: TextStyle(
                                color: Colors.amber.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'WILL',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                        // Habits
                        Column(
                          children: [
                            Icon(Icons.list,
                                color: Colors.blue.shade300, size: 18),
                            const SizedBox(height: 2),
                            Text(
                              '$completedHabits/$totalHabits',
                              style: TextStyle(
                                color: Colors.blue.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'HABITS',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                        // Steps
                        Column(
                          children: [
                            Icon(Icons.flag,
                                color: Colors.green.shade300, size: 18),
                            const SizedBox(height: 2),
                            Text(
                              '$totalCompletedSteps/$totalTargetSteps',
                              style: TextStyle(
                                color: Colors.green.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'STEPS',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(UserGoal goal) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          title:
              const Text('Delete Goal', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete "${goal.name}"?',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteGoal(goal.id);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGoal(String goalId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userHabitState = ref.read(habitStateProvider);
      await userHabitState.deleteGoal(_userId, goalId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal deleted successfully')),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete goal: $e')),
      );
    }
  }

  int _calculateCompletedHabits(UserGoal goal, UserHabitState userHabitState) {
    int completed = 0;
    for (final habitId in goal.habitId) {
      final habit = userHabitState.habits.firstWhere(
        (h) => h.id == habitId,
        orElse: () => UserHabit(
          id: '',
          name: '',
          repUnit: '',
          repStep: 1,
          targetReps: 0,
          uid: '',
          createdAt: DateTime.now(),
          habitType: HabitType.regular,
          nature: HabitNature.positive,
          weeklySchedule: const WeeklySchedule(),
          isArchived: false,
          frequencyType: FrequencyType.daily,
        ),
      );

      if (habit.id.isEmpty) continue;

      final habitData = userHabitState.habitsData[habitId];
      if (habitData != null && habitData.isCompleted) {
        completed++;
      }
    }
    return completed;
  }

  int _calculateTotalWillObtained(
      UserGoal goal, UserHabitState userHabitState) {
    int totalWill = 0;
    for (final habitId in goal.habitId) {
      final habitData = userHabitState.habitsData[habitId];
      if (habitData != null) {
        totalWill += habitData.willObtained;
      }
    }
    return totalWill;
  }
}
