import 'package:farmwill_habits/models/habit_data.dart';
import 'package:farmwill_habits/views/habits/create_habit_page_v2.dart';
import 'package:farmwill_habits/views/habits/widgets/habit_card.dart';
import 'package:farmwill_habits/views/habits/widgets/will_widget.dart';
import 'package:farmwill_habits/views/habits/will_history_page.dart';
import 'package:farmwill_habits/views/habits/habit_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../models/goals.dart';
import '../../models/habits.dart';
import '../../repositories/habits_repository.dart';
import '../habits/habit_state.dart';
import 'edit_goal.dart';

class GoalScreen extends ConsumerStatefulWidget {
  final UserGoal goal;

  const GoalScreen({
    super.key,
    required this.goal,
  });

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen>
    with SingleTickerProviderStateMixin {
  final HabitsRepository _habitsRepository = GetIt.I<HabitsRepository>();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  late UserGoal _goal;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadHabitsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadHabitsData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userHabitState = ref.read(habitStateProvider);
      await userHabitState.loadHabitsAndData(_userId);

      // Refresh goal data if needed
      final goalFromState = userHabitState.goals
          .firstWhere((g) => g.id == _goal.id, orElse: () => _goal);

      setState(() {
        _goal = goalFromState;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading habit data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the user habit state for changes
    final userHabitState = ref.watch(habitStateProvider);
    final willPoints = userHabitState.willPoints;
    final hasError = userHabitState.error != null;

    // Check if goal was updated in state
    final goalInState = userHabitState.goals
        .firstWhere((g) => g.id == _goal.id, orElse: () => _goal);

    if (goalInState != _goal) {
      _goal = goalInState;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(_goal.name, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Add manage habits button
          IconButton(
            icon: const Icon(Icons.playlist_add, color: Colors.white),
            tooltip: 'Manage Habits',
            onPressed: () {
              _createHabitAndAddToGoal(_goal);
            },
          ),
          // Add delete goal button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Delete Goal',
            onPressed: () => _showDeleteConfirmation(_goal),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                // Get habits associated with this goal
                final goalHabits = userHabitState.habits
                    .where((habit) => _goal.habitId.contains(habit.id))
                    .toList();

                // Get habit data for these habits
                final goalHabitsData = Map<String, HabitData>.fromEntries(
                    userHabitState.habitsData.entries
                        .where((entry) => _goal.habitId.contains(entry.key)));

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WillHistoryPage(
                      habits: goalHabits,
                      habitsData: goalHabitsData,
                      title: '${_goal.name} - Will History',
                    ),
                  ),
                );
              },
              child: WillWidget(
                  willPoints: _calculateGoalWill(userHabitState, _goal)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateGoalPage(existingGoal: _goal),
                ),
              );
              // Reload habit data after editing
              _loadHabitsData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHabitsData,
              color: Colors.blue.shade700,
              backgroundColor: Colors.grey.shade900,
              child: _buildGoalContent(userHabitState),
            ),
    );
  }

  Widget _buildGoalContent(UserHabitState userHabitState) {
    if (userHabitState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              userHabitState.error!,
              style: TextStyle(color: Colors.red.shade400),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadHabitsData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Get associated habits for this goal
    final goalHabits = userHabitState.habits
        .where((habit) => _goal.habitId.contains(habit.id))
        .toList();

    // Calculate total will points from habits in this goal
    int totalWill = 0;
    for (final habit in goalHabits) {
      final habitData = userHabitState.habitsData[habit.id];
      if (habitData != null) {
        totalWill += habitData.willObtained;
      }
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Goal info card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildGoalInfoCard(_goal, goalHabits, totalWill),
            ),
          ),
        ),

        // Habits header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        color: Colors.blue.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Associated Habits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${goalHabits.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Empty state for no habits
        if (goalHabits.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.playlist_add,
                          size: 48,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No habits associated with this goal yet',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add habits to track your progress towards this goal',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddHabitDialog(_goal),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Habits'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          // Grid layout for habit cards
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverFadeTransition(
              opacity: _fadeAnimation,
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final habit = goalHabits[index];
                    return HabitCard(
                      userHabit: habit,
                      selectedDate: DateTime.now(),
                    );
                  },
                  childCount: goalHabits.length,
                ),
              ),
            ),
          ),

        // Add bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildGoalInfoCard(
      UserGoal goal, List<UserHabit> goalHabits, int totalWill) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade600, Colors.blue.shade900],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (goal.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          goal.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Goal stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatItem(
                      icon: Icons.calendar_today,
                      label: 'Created',
                      value: _formatDate(goal.createdAt),
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      icon: Icons.update,
                      label: 'Updated',
                      value: _formatDate(goal.updatedAt),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem(
                      icon: Icons.checklist,
                      label: 'Habits',
                      value: goalHabits.length.toString(),
                      iconColor: Colors.green.shade400,
                    ),
                    const SizedBox(width: 16),
                    _buildStatItem(
                      icon: Icons.bolt,
                      label: 'Will Points',
                      value: totalWill.toString(),
                      iconColor: Colors.amber.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: iconColor ?? Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  Future<void> _showDeleteConfirmation(UserGoal goal) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.amber.shade700),
              const SizedBox(width: 8),
              const Text('Delete Goal', style: TextStyle(color: Colors.white)),
            ],
          ),
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
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
        SnackBar(
          content: const Text('Goal deleted successfully'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back since we deleted the goal
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete goal: $e'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showAddHabitDialog(UserGoal goal) async {
    final userHabitState = ref.read(habitStateProvider);
    final allHabits = userHabitState.habits;

    // Create a map to track selection state
    final Map<String, bool> selectedHabits = {};

    // Initialize with current selections
    for (final habit in allHabits) {
      selectedHabits[habit.id] = goal.habitId.contains(habit.id);
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.library_add_check, color: Colors.blue.shade400),
                  const SizedBox(width: 8),
                  const Text(
                    'Manage Habits',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select habits to associate with "${goal.name}":',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade800),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: allHabits.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.grey.shade800,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final habit = allHabits[index];
                            final isSelected =
                                selectedHabits[habit.id] ?? false;

                            // Determine colors based on habit nature
                            final Color iconColor =
                                habit.nature == HabitNature.positive
                                    ? Colors.green.shade400
                                    : Colors.red.shade400;

                            final Color bgColor = isSelected
                                ? (habit.nature == HabitNature.positive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1))
                                : Colors.transparent;

                            return Material(
                              color: Colors.transparent,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: CheckboxListTile(
                                  title: Text(
                                    habit.name,
                                    style: const TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    habit.nature == HabitNature.positive
                                        ? 'Positive Habit'
                                        : 'Negative Habit',
                                    style: TextStyle(
                                      color:
                                          habit.nature == HabitNature.positive
                                              ? Colors.green.shade300
                                              : Colors.red.shade300,
                                      fontSize: 12,
                                    ),
                                  ),
                                  value: selectedHabits[habit.id],
                                  activeColor: Colors.blue.shade600,
                                  checkColor: Colors.white,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      selectedHabits[habit.id] = value ?? false;
                                    });
                                  },
                                  secondary: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: iconColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      habit.nature == HabitNature.positive
                                          ? Icons.add_circle
                                          : Icons.remove_circle,
                                      color: iconColor,
                                    ),
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Selected count
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Selected: ${selectedHabits.values.where((v) => v).length} habits',
                        style: TextStyle(color: Colors.blue.shade300),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateGoalHabits(goal, selectedHabits);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateGoalHabits(
      UserGoal goal, Map<String, bool> selectedHabits) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Create a new list of habit IDs based on selections
      final List<String> updatedHabitIds = [];
      selectedHabits.forEach((habitId, isSelected) {
        if (isSelected) {
          updatedHabitIds.add(habitId);
        }
      });

      // Create updated goal
      final updatedGoal = UserGoal(
        uid: goal.uid,
        id: goal.id,
        name: goal.name,
        description: goal.description,
        createdAt: goal.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        habitId: updatedHabitIds,
      );

      // Update goal in state
      final userHabitState = ref.read(habitStateProvider);
      await userHabitState.updateGoal(_userId, updatedGoal);

      setState(() {
        _goal = updatedGoal;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Goal updated successfully'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update goal: $e'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int _calculateGoalWill(UserHabitState userHabitState, UserGoal goal) {
    int totalWill = 0;

    // Get all habits associated with this goal
    final goalHabits = userHabitState.habits
        .where((habit) => goal.habitId.contains(habit.id))
        .toList();

    // Sum up will from habit data for these habits only
    for (var habit in goalHabits) {
      final habitData = userHabitState.habitsData[habit.id];
      if (habitData != null) {
        totalWill += habitData.willObtained;
      }
    }

    return totalWill;
  }

  void _createHabitAndAddToGoal(UserGoal goal) async {
    try {
      // Navigate to create habit page and wait for result
      final UserHabit? newHabit = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const EditHabitPageV2(),
        ),
      );

      // If we got a new habit back
      if (newHabit != null) {
        setState(() {
          _isLoading = true;
        });

        final habitState = ref.read(habitStateProvider);

        // Add habit to goal
        await _habitsRepository.addHabitToGoal(
          _userId,
          goal.id,
          newHabit.id,
        );

        // Reload data to refresh state
        await _loadHabitsData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${newHabit.name} to ${goal.name}'),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add habit to goal: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
