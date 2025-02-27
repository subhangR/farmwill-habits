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

class _GoalsListScreenState extends ConsumerState<GoalsListPage> with SingleTickerProviderStateMixin {
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
                        MaterialPageRoute(builder: (context) => const WillHistoryPage()),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  MaterialPageRoute(builder: (context) => const CreateGoalPage()),
                );
                _loadGoals();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    // Calculate progress metrics for this goal
    final goalHabits = userHabitState.habits
        .where((habit) => goal.habitId.contains(habit.id))
        .toList();
    
    // Target progress calculation
    int totalTargetReps = 0;
    int totalCompletedReps = 0;
    
    // Will progress calculation
    int totalWillObtained = 0;
    int maxWillPossible = 0;
    
    // Calculate metrics for all habits in this goal
    for (var habit in goalHabits) {
      final habitData = userHabitState.habitsData[habit.id];
      if (habitData != null) {
        // Target progress
        totalTargetReps += habitData.targetReps;
        totalCompletedReps += habitData.reps;
        
        // Will progress
        totalWillObtained += habitData.willObtained;
        maxWillPossible += habitData.startingWill + (habitData.targetReps * (habit.willPerRep ?? 0));
      }
    }
    
    // Calculate progress percentages (prevent division by zero)
    final targetProgress = totalTargetReps > 0 ? totalCompletedReps / totalTargetReps : 0.0;
    final willProgress = maxWillPossible > 0 ? totalWillObtained / maxWillPossible : 0.0;
    
    // Format percentages for display
    final targetPercent = (targetProgress * 100).toInt();
    final willPercent = (willProgress * 100).toInt();
    
    // Generate random colors for the card
    final List<List<Color>> colorSets = [
      [Colors.blue.shade700, Colors.blue.shade900],
      [Colors.purple.shade700, Colors.purple.shade900],
      [Colors.teal.shade700, Colors.teal.shade900],
      [Colors.indigo.shade700, Colors.indigo.shade900],
      [Colors.deepPurple.shade700, Colors.deepPurple.shade900],
      [Colors.cyan.shade700, Colors.cyan.shade900],
      [Colors.green.shade700, Colors.green.shade900],
    ];
    
    // Use the goal's id to select a consistent color for each goal
    final colorIndex = goal.id.hashCode % colorSets.length;
    final headerColors = colorSets[colorIndex];
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GoalScreen(goal: goal),
            ),
          );
          _loadGoals();
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D2D2D),
                Color(0xFF1A1A1A),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal header with gradient - using random colors
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                height: 50, // Even smaller height
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: headerColors,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Habit count moved here
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.checklist,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${goalHabits.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Goal description
                      if (goal.description.isNotEmpty) ...[
                        Text(
                          goal.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      const Spacer(),
                      
                      // Cool progress indicators - using circular progress
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Target Progress
                          Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background circle
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  // Progress circle
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(
                                      value: targetProgress.clamp(0.0, 1.0),
                                      strokeWidth: 5,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade500),
                                    ),
                                  ),
                                  // Icon
                                  Icon(
                                    Icons.flag,
                                    color: Colors.green.shade300,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Percentage text
                              Text(
                                '$targetPercent%',
                                style: TextStyle(
                                  color: Colors.green.shade300,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          
                          // Will Progress
                          Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Background circle
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  // Progress circle
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(
                                      value: willProgress.clamp(0.0, 1.0),
                                      strokeWidth: 5,
                                      backgroundColor: Colors.transparent,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade500),
                                    ),
                                  ),
                                  // Icon
                                  Icon(
                                    Icons.bolt,
                                    color: Colors.amber.shade300,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Percentage text
                              Text(
                                '$willPercent%',
                                style: TextStyle(
                                  color: Colors.amber.shade300,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      // Add a row below the progress indicators for will obtained
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade900.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bolt,
                              color: Colors.amber.shade300,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalWillObtained',
                              style: TextStyle(
                                color: Colors.amber.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
          title: const Text('Delete Goal', style: TextStyle(color: Colors.white)),
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
}