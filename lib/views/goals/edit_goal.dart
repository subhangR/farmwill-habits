import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/goals.dart';
import '../../models/habits.dart';
import '../habits/habit_state.dart';

class CreateGoalPage extends ConsumerStatefulWidget {
  final UserGoal? existingGoal; // Pass this if editing an existing goal

  const CreateGoalPage({super.key, this.existingGoal});

  @override
  _CreateGoalPageState createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends ConsumerState<CreateGoalPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _selectedHabitIds = [];
  bool _isLoading = false;
  late String userId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();

    // If editing an existing goal, populate the form fields
    if (widget.existingGoal != null) {
      _nameController.text = widget.existingGoal!.name;
      _descriptionController.text = widget.existingGoal!.description;
      _selectedHabitIds.addAll(widget.existingGoal!.habitId);
    }

    String uid = FirebaseAuth.instance.currentUser!.uid;
    userId = uid;

    // Load habits if they're not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final habitState = ref.read(habitStateProvider);

      if (habitState.habits.isEmpty && !habitState.isLoading) {
        habitState.loadHabitsAndData(uid);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a goal name'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final habitState = ref.read(habitStateProvider);
      final now = DateTime.now().toIso8601String();
      UserGoal goal;

      if (widget.existingGoal != null) {
        // Update existing goal
        goal = UserGoal(
          uid: userId,
          id: widget.existingGoal!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          createdAt: widget.existingGoal!.createdAt,
          updatedAt: now,
          habitId: _selectedHabitIds,
        );

        await habitState.updateGoal(userId, goal);
      } else {
        // Create new goal
        final goalId = const Uuid().v4();

        goal = UserGoal(
          uid: userId,
          id: goalId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          createdAt: now,
          updatedAt: now,
          habitId: _selectedHabitIds,
        );

        await habitState.addGoal(userId, goal);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Goal ${widget.existingGoal != null ? 'updated' : 'created'} successfully'),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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

  @override
  Widget build(BuildContext context) {
    final habitState = ref.watch(habitStateProvider);
    final habits = habitState.habits;
    final isLoading = habitState.isLoading || _isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: Text(
          widget.existingGoal != null ? 'Edit Goal' : 'Create Goal',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.existingGoal != null
                        ? 'Updating Goal...'
                        : 'Creating Goal...',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Header with icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          widget.existingGoal != null
                              ? Icons.edit_note
                              : Icons.flag_rounded,
                          color: Colors.blue.shade400,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Goal name input
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Goal Name',
                        labelStyle: TextStyle(color: Colors.blue.shade200),
                        hintText: 'Enter a memorable name for your goal',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon:
                            Icon(Icons.title, color: Colors.blue.shade400),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                              BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.red.shade700),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a goal name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description input
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.blue.shade200),
                        hintText: 'What do you want to achieve with this goal?',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: Icon(Icons.description,
                            color: Colors.blue.shade400),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                              BorderSide(color: Colors.blue.shade700, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Habits section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.checklist,
                                  color: Colors.blue.shade400),
                              const SizedBox(width: 8),
                              Text(
                                'Select Habits',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade200,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose habits to include in this goal',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (habits.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No habits found. Create some habits first to add them to this goal.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade900,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: habits.length,
                                separatorBuilder: (context, index) => Divider(
                                  color: Colors.grey.shade800,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final habit = habits[index];
                                  final isSelected =
                                      _selectedHabitIds.contains(habit.id);

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
                                      duration:
                                          const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: CheckboxListTile(
                                        title: Text(
                                          habit.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          habit.nature == HabitNature.positive
                                              ? 'Positive Habit'
                                              : 'Negative Habit',
                                          style: TextStyle(
                                            color: habit.nature ==
                                                    HabitNature.positive
                                                ? Colors.green.shade300
                                                : Colors.red.shade300,
                                            fontSize: 12,
                                          ),
                                        ),
                                        value: isSelected,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedHabitIds.add(habit.id);
                                            } else {
                                              _selectedHabitIds
                                                  .remove(habit.id);
                                            }
                                          });
                                        },
                                        secondary: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: iconColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            habit.nature == HabitNature.positive
                                                ? Icons.add_circle
                                                : Icons.remove_circle,
                                            color: iconColor,
                                          ),
                                        ),
                                        activeColor: Colors.blue.shade700,
                                        checkColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade600),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _saveGoal,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.existingGoal != null
                                      ? Icons.update
                                      : Icons.add,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.existingGoal != null
                                      ? 'Update Goal'
                                      : 'Create Goal',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Selected habits count
                    if (_selectedHabitIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade900.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade800),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.blue.shade400),
                            const SizedBox(width: 8),
                            Text(
                              'Selected ${_selectedHabitIds.length} habit${_selectedHabitIds.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.blue.shade200,
                                fontWeight: FontWeight.w500,
                              ),
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
}
