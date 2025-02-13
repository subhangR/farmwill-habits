import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmwill_habits/repositories/habits_repository.dart';
import 'package:farmwill_habits/views/habits/widgets/habit_nature_selector.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_schedule_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../models/habits.dart';

class EditHabitPage extends StatefulWidget {
  final UserHabit? userHabit;

  const EditHabitPage({super.key, this.userHabit});
  @override
  State<EditHabitPage> createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  HabitNature _nature = HabitNature.positive;
  int _scorePerUnit = 1;
  WeeklySchedule _weeklySchedule = const WeeklySchedule();
  GoalType _goalType = GoalType.repetitions;
  bool _hasGoal = true;
  bool _hasReminder = false;
  int _repetitions = 1;
  int _willPerRep = 1;
  int _maxScore = 1;
  bool _isAdvancedExpanded = false;
  late TextEditingController _maxScoreController;
  late TextEditingController _willPerRepController;
  late TextEditingController _startingWillController; // Added controller

  int _duration = 5;
  int _startingWill = 0; // Added starting will variable

  int _willPerMinute = 1;
  int _maxWill = 1;
  late TextEditingController _maxWillController;
  late TextEditingController _willPerMinuteController;

  HabitsRepository habitsRepository = GetIt.I<HabitsRepository>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userHabit?.name ?? '');


    if (widget.userHabit != null) {
      _nature = widget.userHabit!.nature;
      _weeklySchedule = widget.userHabit!.weeklySchedule ?? const WeeklySchedule();
    }

    _repetitions = widget.userHabit?.targetReps ?? 1;
    _willPerRep = widget.userHabit?.scorePerRep ?? 1;
    _willPerRepController = TextEditingController(text: _willPerRep.toString());
    _willPerMinuteController = TextEditingController(text: _willPerMinute.toString());
    _maxScoreController = TextEditingController(text: _maxScore.toString());
    _maxWillController = TextEditingController(text: _maxScore.toString());
    _duration = widget.userHabit?.targetMinutes ?? 5;
    _startingWillController = TextEditingController(text: _startingWill.toString()); // Initialize controller

  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxScoreController.dispose();
    _willPerRepController.dispose();
    _maxWillController.dispose();        // Add this
    _willPerMinuteController.dispose();  // Add this
    _startingWillController.dispose(); // Dispose controller

    super.dispose();
  }


  String? _validateInteger(String? value, String fieldName) {
    // if (value == null || value.isEmpty) {
    //   return '$fieldName is required';
    // }
    // if (int.tryParse(value) == null) {
    //   return '$fieldName must be a valid number';
    // }
    // if (int.parse(value) <= 0) {
    //   return '$fieldName must be greater than 0';
    // }
    return null;
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final habit = UserHabit(
        uid: FirebaseAuth.instance.currentUser!.uid,
        id: widget.userHabit?.id ?? FirebaseFirestore.instance.collection('user_habits').doc().id,
        name: _nameController.text,
        habitType: HabitType.regular,
        nature: _nature,
        weeklySchedule: _weeklySchedule,
        targetReps: _repetitions,
        targetMinutes: _duration,
        scorePerRep: _willEnabled ? _willPerRep : null,
        scorePerMinute: _willEnabled ? _willPerMinute : null,
        maxScore: _willEnabled ? _maxWill : null,
        startingWill: _willEnabled ? _startingWill : null,
        createdAt: widget.userHabit?.createdAt ?? DateTime.now(),
        isArchived: widget.userHabit?.isArchived ?? false,
      );

      final userId = FirebaseAuth.instance.currentUser!.uid;

      if (widget.userHabit == null) {
        // Create new habit
        await habitsRepository.createHabit(userId, habit);
      } else {
        // Update existing habit
        await habitsRepository.updateHabit(userId, habit);
      }

      if (mounted) {
        Navigator.pop(context, habit);
      }
    } catch (e) {
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to ${widget.userHabit == null ? 'create' : 'update'} habit: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildGoalInput({
    required String title,
    required int value,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
    required Function(int) onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white, // Added white color for title
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CircularIconButton(
              icon: Icons.remove,
              onTap: onDecrease,
              backgroundColor: const Color(0xFF592B2B), // Darker red for theme
              iconColor: Colors.red[300]!, // Lighter red for visibility
            ),
            const SizedBox(width: 24),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Added white color for value
              ),
            ),
            const SizedBox(width: 24),
            _CircularIconButton(
              icon: Icons.add,
              onTap: onIncrease,
              backgroundColor: const Color(0xFF1B4B1B), // Darker green for theme
              iconColor: Colors.green[300]!, // Lighter green for visibility
            ),
          ],
        ),
      ],
    );
  }


  bool _willEnabled = false;  // Add this with other state variables


  Widget _buildWillSection() {
    if (!_willEnabled) {
      return _buildWillToggle();
    }

    bool isNegative = _nature == HabitNature.negative;

    void ensureNegativeValues() {
      if (isNegative) {
        if (_willPerRep > 0) _willPerRep *= -1;
        if (_willPerMinute > 0) _willPerMinute *= -1;
        if (_maxWill > 0) _maxWill *= -1;

        _willPerRepController.text = _willPerRep.abs().toString();
        _willPerMinuteController.text = _willPerMinute.abs().toString();
        _maxWillController.text = _maxWill.abs().toString();
      }
    }

    ensureNegativeValues();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWillToggle(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Starting Will Input
              _buildWillInput(
                title: 'Starting Will',
                controller: _startingWillController,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null) {
                    setState(() {
                      _startingWill = intValue;
                    });
                  }
                },
                isNegative: false, // Starting will is always positive
              ),
              const SizedBox(height: 16),
              _buildWillInput(
                title: isNegative ? 'Will Lost Per Rep' : 'Will Gained Per Rep',
                controller: _willPerRepController,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null) {
                    setState(() {
                      _willPerRep = isNegative ? -intValue.abs() : intValue;
                      _willPerRepController.text = intValue.abs().toString();
                      _updateMaxWill();
                    });
                  }
                },
                isNegative: isNegative,
              ),
              const SizedBox(height: 16),
              _buildWillInput(
                title: isNegative ? 'Will Lost Per Minute' : 'Will Gained Per Minute',
                controller: _willPerMinuteController,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null) {
                    setState(() {
                      _willPerMinute = isNegative ? -intValue.abs() : intValue;
                      _willPerMinuteController.text = intValue.abs().toString();
                      _updateMaxWill();
                    });
                  }
                },
                isNegative: isNegative,
              ),
              const SizedBox(height: 16),
              _buildWillInput(
                title: isNegative ? 'Maximum Will Losable' : 'Maximum Will Gainable',
                controller: _maxWillController,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null) {
                    setState(() {
                      _maxWill = isNegative ? -intValue.abs() : intValue;
                      _maxWillController.text = intValue.abs().toString();
                    });
                  }
                },
                isNegative: isNegative,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateMaxWill() {
    setState(() {
      bool isNegative = _nature == HabitNature.negative;
      int repsComponent = _repetitions * _willPerRep;
      int durationComponent = _duration * _willPerMinute;
      _maxWill = repsComponent + durationComponent;

      // Update the display value (absolute)
      _maxWillController.text = _maxWill.abs().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.userHabit == null ? 'Create a new habit' : 'Edit habit',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameSection(),
                      const SizedBox(height: 24),
                      _buildHabitTypeSection(),
                      const SizedBox(height: 24),
                      _buildFrequencySection(),
                      const SizedBox(height: 24),
                      _buildGoalSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              child: _buildSubmitButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Name',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Workout',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF3A3A3A),
              ),
              child: const Icon(Icons.add, color: Colors.white70),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a habit name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildHabitTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type of Habit',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        HabitNatureSelector(
          selectedNature: _nature,
          onChanged: (value) {
            setState(() {
              _nature = value;
              if (value == HabitNature.negative) {
                _weeklySchedule = const WeeklySchedule(
                  monday: true,
                  tuesday: true,
                  wednesday: true,
                  thursday: true,
                  friday: true,
                  saturday: true,
                  sunday: true,
                );
              }
            });
          },
          positiveColor: const Color(0xFF4CAF50), // Green for positive
          negativeColor: const Color(0xFFE53935), // Red for negative
          backgroundColor: const Color(0xFF2A2A2A),
          textColor: Colors.white,
        ),
      ],
    );
  }


  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequency',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Text(
          'Choose at least 1 day',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        WeeklyScheduleSelector(
          schedule: _weeklySchedule,
          onChanged: (schedule) {
            setState(() {
              _weeklySchedule = schedule;
            });
          },
          backgroundColor: const Color(0xFF2A2A2A),
          selectedColor: Colors.white,
          unselectedColor: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildGoalSection() {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.grey[800],
        unselectedWidgetColor: Colors.grey[400],
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.grey[400]!,
        ),
      ),
      child: ExpansionTile(
        title: const Text(
          'Goals',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGoalInput(
                  title: 'Reps',
                  value: _repetitions,
                  onDecrease: () {
                    if (_repetitions > 1) {
                      setState(() {
                        _repetitions--;
                        _updateMaxWill();
                      });
                    }
                  },
                  onIncrease: () {
                    setState(() {
                      _repetitions++;
                      _updateMaxWill();
                    });
                  },
                  onEdit: (value) {
                    setState(() {
                      _repetitions = value;
                      _updateMaxWill();
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildGoalInput(
                  title: 'Duration (minutes)',
                  value: _duration,
                  onDecrease: () {
                    if (_duration > 1) {
                      setState(() {
                        _duration -= 5;
                        _updateMaxWill();
                      });
                    }
                  },
                  onIncrease: () {
                    setState(() {
                      _duration += 5;
                      _updateMaxWill();
                    });
                  },
                  onEdit: (value) {
                    setState(() {
                      _duration = value;
                      _updateMaxWill();
                    });
                  },
                ),
                const SizedBox(height: 24),
                _buildWillSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          widget.userHabit == null ? 'Create habit' : 'Update habit',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWillToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: _willEnabled ? Colors.white : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Calculate Will',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _willEnabled ? 'Track your will power' : 'Will tracking disabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: _willEnabled ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _willEnabled,
            onChanged: (bool value) {
              setState(() {
                _willEnabled = value;
              });
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.grey[700],
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[800],
          ),
        ],
      ),
    );
  }

  Widget _buildWillInput({
    required String title,
    required TextEditingController controller,
    required Function(String) onChanged,
    required bool isNegative,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            prefixText: isNegative ? "- " : null,
            prefixStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          validator: (value) {
            String? baseValidation = _validateInteger(value, title);
            if (baseValidation != null) return baseValidation;
            return null;
          },
          onChanged: onChanged,
        ),
      ],
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


