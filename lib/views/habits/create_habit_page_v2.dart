// File: edit_habit_page.dart
import 'package:farmwill_habits/views/habits/widgets/habit_nature_selector.dart';
import 'package:farmwill_habits/views/habits/widgets/weekly_schedule_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../models/habits.dart';
import '../../repositories/habits_repository.dart';

class EditHabitPageV2 extends StatefulWidget {
  final UserHabit? userHabit;
  const EditHabitPageV2({super.key, this.userHabit});

  @override
  State<EditHabitPageV2> createState() => _EditHabitPageV2State();
}

class _EditHabitPageV2State extends State<EditHabitPageV2> {
  final _formKey = GlobalKey<FormState>();
  late final HabitFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HabitFormController(widget.userHabit);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
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
                      NameSection(controller: _controller),
                      const SizedBox(height: 24),
                      HabitTypeSection(controller: _controller),
                      const SizedBox(height: 24),
                      FrequencySection(
                        controller: _controller,
                      ),
                      const SizedBox(height: 24),
                      TargetSection(controller: _controller),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20.0),
              child: SubmitButton(
                formKey: _formKey,
                controller: _controller,
                isEdit: widget.userHabit != null,
                onSubmit: () async {
                  // Add debug print
                  print("Submit callback triggered");

                  try {
                    final habit = await _controller.submitHabit();
                    if (context.mounted && habit != null) {
                      print("Habit created successfully, popping with result");
                      Navigator.pop(context, habit);
                    } else {
                      print("Habit is null or context is not mounted");
                    }
                  } catch (e) {
                    print("Error in submit callback: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to save habit: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// File: controllers/habit_form_controller.dart
class HabitFormController extends ChangeNotifier {
  final TextEditingController nameController;
  final TextEditingController maxScoreController;
  final TextEditingController willPerRepController;
  final TextEditingController maxWillController;
  final TextEditingController willPerMinuteController;
  final TextEditingController startingWillController;
  final TextEditingController unitTypeController;
  late HabitsRepository habitsRepository;

  HabitNature nature;
  WeeklySchedule _weeklySchedule;
  bool willEnabled;
  int repetitions;
  int willPerRep;
  int maxWill;
  int startingWill;
  int willPerRepValue = 0;
  int maxWillValue = 0;
  int startingWillValue = 0;
  FrequencyType _frequencyType;

  final HabitNature _nature;

  FrequencyType get frequencyType => _frequencyType;
  final UserHabit? originalHabit;

  WeeklySchedule get weeklySchedule => _weeklySchedule;

  int _repetitionStep;
  String _repetitionUnitType;

  int get repetitionStep => _repetitionStep;
  String get repetitionUnitType => _repetitionUnitType;

  HabitFormController(this.originalHabit)
      : nameController = TextEditingController(text: originalHabit?.name ?? ''),
        maxScoreController = TextEditingController(),
        willPerRepController = TextEditingController(),
        maxWillController = TextEditingController(),
        willPerMinuteController = TextEditingController(),
        startingWillController = TextEditingController(),
        unitTypeController =
            TextEditingController(text: originalHabit?.repUnit ?? 'reps'),
        nature = originalHabit?.nature ?? HabitNature.positive,
        _weeklySchedule =
            originalHabit?.weeklySchedule ?? const WeeklySchedule(),
        _frequencyType = FrequencyType.daily,
        repetitions = originalHabit?.targetReps ?? 1,
        willPerRep = originalHabit?.willPerRep ?? 1,
        willEnabled = originalHabit?.willPerRep != null ? true : false,
        maxWill = 1,
        _nature = originalHabit?.nature ?? HabitNature.positive,
        startingWill = originalHabit?.startingWill ?? 0,
        _repetitionStep = originalHabit?.repStep ?? 1,
        _repetitionUnitType = originalHabit?.repUnit ?? 'reps' {
    _initializeControllers();
    habitsRepository = GetIt.I<HabitsRepository>();
  }

  static final List<String> _defaultUnitTypes = [
    "stars",
    "reps",
    "grams",
    "litres",
    "minutes",
    "calories"
  ];

  // Inside HabitFormController class

// Update the nature property to use proper getter/setter
  // ature method that properly notifies listeners
  void updateNature(HabitNature newNature) {
    // Only update if there's a change to avoid unnecessary rebuilds
    if (nature != newNature) {
      // Update the nature
      nature = newNature;

      // If it's a negative habit, update weekly schedule to all days
      if (newNature == HabitNature.negative) {
        updateWeeklySchedule(const WeeklySchedule(
          monday: true,
          tuesday: true,
          wednesday: true,
          thursday: true,
          friday: true,
          saturday: true,
          sunday: true,
        ));
      }

      // Update will-related values if will is enabled
      if (willEnabled) {
        // Ensure will values have correct sign based on nature
        if (newNature == HabitNature.negative) {
          willPerRep = -willPerRep.abs();
          maxWill = -maxWill.abs();
        } else {
          willPerRep = willPerRep.abs();
          maxWill = maxWill.abs();
        }

        // Update controller text values
        willPerRepController.text = willPerRep.abs().toString();
        maxWillController.text = maxWill.abs().toString();
      }

      // Notify listeners of the change
      notifyListeners();
    }
  }

  // Add a modifiable list for custom unit types
  final List<String> _customUnitTypes = [];

  // Getter that combines both default and custom unit types
  List<String> get unitTypes => [..._defaultUnitTypes, ..._customUnitTypes];

  bool _isEditingUnitType = false;
  bool get isEditingUnitType => _isEditingUnitType;

  void updateRepetitionUnitType(String value) {
    print("Updating unit type to: $value");
    _repetitionUnitType = value;
    unitTypeController.text = value;
    notifyListeners();
  }

  void updateRepetitionStep(int step) {
    _repetitionStep = step;
    notifyListeners();
  }

  void toggleUnitTypeEditing() {
    _isEditingUnitType = !_isEditingUnitType;
    if (_isEditingUnitType) {
      unitTypeController.text = _repetitionUnitType;
    } else {
      // When finishing editing, validate and add the unit type if it's new
      final newType = unitTypeController.text.trim();
      if (newType.isNotEmpty && !unitTypes.contains(newType)) {
        _customUnitTypes.add(newType);
      }
      _repetitionUnitType = unitTypeController.text;
    }
    notifyListeners();
  }

  // ... other methods ...

  @override
  void dispose() {
    unitTypeController.dispose();
    nameController.dispose();
    maxScoreController.dispose();
    willPerRepController.dispose();
    maxWillController.dispose();
    willPerMinuteController.dispose();
    startingWillController.dispose();
    super.dispose();
  }

  void updateFrequencyType(FrequencyType type) {
    _frequencyType = type;

    // If switching to daily, ensure at least one day is selected
    if (type == FrequencyType.daily &&
        weeklySchedule.toMap().values.every((day) => !day)) {
      updateWeeklySchedule(const WeeklySchedule(
        monday: true,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: true,
        saturday: true,
        sunday: true,
      ));
    }

    notifyListeners();
  }

  bool _isBoundedTarget = true;
  int _repetitionUnits = 1;

  bool get isBoundedTarget => _isBoundedTarget;
  int get repetitionUnits => _repetitionUnits;

  set isBoundedTarget(bool value) {
    _isBoundedTarget = value;
    notifyListeners();
  }

  void updateRepetitionUnits(int value) {
    _repetitionUnits = value;
    notifyListeners();
  }

  void updateWeeklySchedule(WeeklySchedule schedule) {
    _weeklySchedule = schedule;
    notifyListeners();
  }

  void toggleDay(String day) {
    final Map<String, dynamic> currentSchedule = _weeklySchedule.toMap();
    currentSchedule[day] = !currentSchedule[day]!;
    _weeklySchedule = WeeklySchedule.fromMap(currentSchedule);
    notifyListeners();
  }

  void _initializeControllers() {
    // Set will per rep controller
    if (willPerRep != 0) {
      willPerRepController.text = willPerRep.abs().toString();
    } else {
      willPerRepController.text = "1"; // Default value
    }

    // Set max will controller
    if (originalHabit?.maxWill != null) {
      maxWill = originalHabit!.maxWill!;
      maxWillController.text = maxWill.abs().toString();
    } else {
      maxWill = nature == HabitNature.negative ? -10 : 10;
      maxWillController.text = "10"; // Default value
    }

    // Set starting will controller
    if (originalHabit?.startingWill != null) {
      startingWill = originalHabit!.startingWill!;
      startingWillController.text = startingWill.toString();
    } else {
      startingWillController.text = "0"; // Default value
    }
  }

  Future<UserHabit?> submitHabit() async {
    try {
      print("Starting submitHabit method");
      final userId = FirebaseAuth.instance.currentUser!.uid;
      if (userId.isEmpty) {
        print("No user ID found");
        throw Exception("User not signed in");
      }

      print("User ID: $userId");
      print("Name: ${nameController.text}");
      print("Nature: $nature");
      print("Weekly schedule: ${_weeklySchedule.toMap()}");
      print("Repetitions: $repetitions");
      print("Will enabled: $willEnabled");

      // Parse will-related values when enabled
      int? finalWillPerRep = null;
      int? finalMaxWill = null;
      int? finalStartingWill = null;

      if (willEnabled) {
        try {
          finalWillPerRep = int.parse(willPerRepController.text);
          finalMaxWill = int.parse(maxWillController.text);

          if (startingWillController.text.isNotEmpty) {
            finalStartingWill = int.parse(startingWillController.text);
          } else {
            finalStartingWill = 0;
          }

          // Apply negative values for negative habits
          if (nature == HabitNature.negative) {
            finalWillPerRep = -finalWillPerRep.abs();
            finalMaxWill = -finalMaxWill.abs();
          }
        } catch (e) {
          print("Error parsing will values: $e");
          throw Exception("Invalid will values: $e");
        }
      }

      // Generate a new ID if this is a new habit
      final String habitId =
          originalHabit?.id ?? "habit_${DateTime.now().millisecondsSinceEpoch}";

      print("Generated Habit ID: $habitId");

      final habit = UserHabit(
        frequencyType: _frequencyType,
        uid: userId,
        id: habitId,
        name: nameController.text,
        habitType: HabitType.regular,
        nature: nature,
        weeklySchedule: _weeklySchedule,
        targetReps: repetitions,
        willPerRep: finalWillPerRep,
        maxWill: finalMaxWill,
        startingWill: finalStartingWill,
        createdAt: originalHabit?.createdAt ?? DateTime.now(),
        isArchived: originalHabit?.isArchived ?? false,
        repStep: _repetitionStep,
        repUnit: _repetitionUnitType,
      );

      // Debug the created habit
      print("Preparing to save habit: ${habit.toMap()}");

      if (originalHabit == null) {
        // Create new habit
        print("Creating new habit in repository...");
        await habitsRepository.createHabit(userId, habit);
        print("Habit created successfully in repository");
      } else {
        // Update existing habit
        print("Updating existing habit...");
        await habitsRepository.updateHabit(userId, habit);
        print("Habit updated successfully");
      }

      return habit;
    } catch (e) {
      print("Error creating/updating habit: $e");
      throw Exception("Failed to save habit: $e");
    }
  }

  // Add the setter for weeklySchedule
  set weeklySchedule(WeeklySchedule schedule) {
    _weeklySchedule = schedule;
    notifyListeners();
  }
}

// File: components/name_section.dart
class NameSection extends StatelessWidget {
  final HabitFormController controller;

  const NameSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
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
          controller: controller.nameController,
          style: const TextStyle(color: Colors.white),
          decoration: CustomInputDecorations.textField(
            hintText: 'Workout',
            suffixIcon: Icons.add,
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
}

class HabitTypeSection extends StatelessWidget {
  final HabitFormController controller;

  const HabitTypeSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
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
              selectedNature: controller.nature,
              onChanged: controller.updateNature,
              positiveColor: const Color(0xFF4CAF50),
              negativeColor: const Color(0xFFE53935),
              backgroundColor: const Color(0xFF2A2A2A),
              textColor: Colors.white,
            ),
          ],
        );
      },
    );
  }
}

class FrequencySection extends StatefulWidget {
  final HabitFormController controller;

  const FrequencySection({
    super.key,
    required this.controller,
  });

  @override
  State<FrequencySection> createState() => _FrequencySectionState();
}

class _FrequencySectionState extends State<FrequencySection> {
  @override
  void initState() {
    super.initState();
    // Set default schedule with all days selected if needed
    if (widget.controller.weeklySchedule.toMap().values.every((day) => !day)) {
      widget.controller.updateWeeklySchedule(const WeeklySchedule(
        monday: true,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: true,
        saturday: true,
        sunday: true,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
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
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _FrequencyTypeButton(
                    title: 'Today',
                    isSelected: widget.controller.frequencyType ==
                        FrequencyType.onetime,
                    onTap: () => widget.controller
                        .updateFrequencyType(FrequencyType.onetime),
                  ),
                  _FrequencyTypeButton(
                    title: 'Daily',
                    isSelected:
                        widget.controller.frequencyType == FrequencyType.daily,
                    onTap: () => widget.controller
                        .updateFrequencyType(FrequencyType.daily),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (widget.controller.frequencyType == FrequencyType.daily &&
                widget.controller.nature == HabitNature.positive) ...[
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              WeeklyScheduleSelector(
                schedule: widget.controller.weeklySchedule,
                onChanged: widget.controller.updateWeeklySchedule,
                backgroundColor: const Color(0xFF2A2A2A),
                selectedColor: Colors.white,
                unselectedColor: const Color(0xFF3D3D3D),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FrequencyTypeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyTypeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklySchedule extends StatelessWidget {
  final Map<String, bool> schedule;
  final Function(String) onToggleDay;

  const _WeeklySchedule({
    required this.schedule,
    required this.onToggleDay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildWeekRow(['Monday', 'Tuesday', 'Wednesday']),
          const Divider(height: 1, color: Colors.white10),
          _buildWeekRow(['Thursday', 'Friday', 'Saturday']),
          const Divider(height: 1, color: Colors.white10),
          _buildWeekRow(['Sunday']),
        ],
      ),
    );
  }

  Widget _buildWeekRow(List<String> days) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: days
            .map((day) => _DayButton(
                  day: day,
                  isSelected: schedule[day] ?? false,
                  onToggle: () => onToggleDay(day),
                ))
            .toList(),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  final String day;
  final bool isSelected;
  final VoidCallback onToggle;

  const _DayButton({
    required this.day,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white24,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            day.substring(0, 3), // Show first 3 letters
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

// File: components/goal_section.dart
// Updated CircularIconButton to handle nullable callback
class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap; // Make callback nullable
  final Color backgroundColor;
  final Color iconColor;

  const CircularIconButton({
    super.key,
    required this.icon,
    this.onTap, // Make it optional
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap, // InkWell accepts nullable callback
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

// Updated Target Section with proper callback handling
class TargetSection extends StatelessWidget {
  final HabitFormController controller;

  const TargetSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              controller._nature == HabitNature.positive ? 'Target' : 'Threshold',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Step input for increment value
            _buildStepInput(context),

            const SizedBox(height: 16),

            // Target repetitions section
            _buildRepetitionsSection(),

            // Will settings
            if (controller.willEnabled) ...[
              const SizedBox(height: 24),
              _buildWillSettings(),
            ],

            // Toggle for will points
            const SizedBox(height: 24),
            _buildWillToggle(),
          ],
        );
      },
    );
  }

  Widget _buildStepInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    return TextFormField(
                      initialValue: controller.repetitionStep.toString(),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        suffixText: ' ${controller.repetitionUnitType}',
                        suffixStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      onChanged: (text) {
                        final newValue = int.tryParse(text);
                        if (newValue != null && newValue > 0) {
                          controller.updateRepetitionStep(newValue);
                        }
                      },
                    );
                  },
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showUnitTypeDialog(context),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepetitionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller._nature == HabitNature.positive ? 'Target' : 'Threshold',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              return TextFormField(
                initialValue: controller.repetitions.toString(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  suffixText: ' ${controller.repetitionUnitType}',
                  suffixStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  // First validate that it's a valid repetition value
                  final baseValidation =
                      FormValidators.validateRepetitions(value);
                  if (baseValidation != null) {
                    return baseValidation;
                  }

                  // Then check if it's a multiple of the step
                  final repetitions = int.tryParse(value ?? '');
                  if (repetitions != null && controller.repetitionStep > 1) {
                    if (repetitions % controller.repetitionStep != 0) {
                      return 'Target must be a multiple of ${controller.repetitionStep}';
                    }
                  }
                  return null;
                },
                onChanged: (text) {
                  final newValue = int.tryParse(text);
                  if (newValue != null && newValue >= 0) {
                    controller.repetitions = newValue;
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'The number of times you want to perform this habit',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildWillSettings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WillInputField(
            title: 'Starting Will',
            controller: controller.startingWillController,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                controller.startingWill = intValue;
                controller.notifyListeners();
              }
            },
            isNegative: false,
          ),
          const SizedBox(height: 16),
          _buildDynamicWillInput(),
          const SizedBox(height: 16),
          WillInputField(
            title: controller.nature == HabitNature.negative
                ? 'Maximum Will Losable'
                : 'Maximum Will Gainable',
            controller: controller.maxWillController,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                controller.maxWill = controller.nature == HabitNature.negative
                    ? -intValue.abs()
                    : intValue;
                controller.maxWillController.text = intValue.abs().toString();
                controller.notifyListeners();
              }
            },
            isNegative: controller.nature == HabitNature.negative,
          ),
        ],
      ),
    );
  }

  Widget _buildWillToggle() {
    return WillToggle(controller: controller);
  }

  Widget _buildDynamicWillInput() {
    return WillInputField(
      title: controller.nature == HabitNature.negative
          ? 'Will Lost Per ${controller.repetitionUnitType}'
          : 'Will Gained Per ${controller.repetitionUnitType}',
      controller: controller.willPerRepController,
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null) {
          controller.willPerRep = controller.nature == HabitNature.negative
              ? -intValue.abs()
              : intValue;
          controller.willPerRepController.text = intValue.abs().toString();

          // Update maxWill based on the new willPerRep value
          controller.maxWill = controller.repetitions * controller.willPerRep;
          controller.maxWillController.text =
              controller.maxWill.abs().toString();

          controller.notifyListeners();
        }
      },
      isNegative: controller.nature == HabitNature.negative,
    );
  }

  void _showUnitTypeDialog(BuildContext context) {
    final TextEditingController textController =
        TextEditingController(text: controller.repetitionUnitType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Edit Unit Type',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter unit type (e.g., reps, minutes)',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Predefined Types:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: controller.unitTypes
                  .map((unitType) => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A3A3A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          textController.text = unitType;
                        },
                        child: Text(unitType),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save', style: TextStyle(color: Colors.blue)),
            onPressed: () {
              if (textController.text.isNotEmpty) {
                controller.updateRepetitionUnitType(textController.text.trim());
                print("Unit type updated to: ${controller.repetitionUnitType}");
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

// File: utils/custom_input_decorations.dart
class CustomInputDecorations {
  static InputDecoration textField({
    required String hintText,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon != null
          ? Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF3A3A3A),
              ),
              child: Icon(suffixIcon, color: Colors.white70),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  static InputDecoration willInput({
    bool isNegative = false,
  }) {
    return InputDecoration(
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
    );
  }
}

// File: widgets/circular_i

// File: components/goal_input_control.dart
class GoalInputControl extends StatelessWidget {
  final String title;
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const GoalInputControl({
    super.key,
    required this.title,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularIconButton(
              icon: Icons.remove,
              onTap: onDecrease,
              backgroundColor: const Color(0xFF592B2B),
              iconColor: Colors.red[300]!,
            ),
            const SizedBox(width: 24),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 24),
            CircularIconButton(
              icon: Icons.add,
              onTap: onIncrease,
              backgroundColor: const Color(0xFF1B4B1B),
              iconColor: Colors.green[300]!,
            ),
          ],
        ),
      ],
    );
  }
}

// File: components/will_section.dart
class WillSection extends StatelessWidget {
  final HabitFormController controller;

  const WillSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WillToggle(controller: controller),
              if (controller.willEnabled) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WillInputField(
                        title: 'Starting Will',
                        controller: controller.startingWillController,
                        onChanged: (value) {
                          final intValue = int.tryParse(value);
                          if (intValue != null) {
                            controller.startingWill = intValue;
                            controller.notifyListeners();
                          }
                        },
                        isNegative: false,
                      ),
                      const SizedBox(height: 16),
                      _buildDynamicWillInput(),
                      const SizedBox(height: 16),
                      WillInputField(
                        title: controller.nature == HabitNature.negative
                            ? 'Maximum Will Losable'
                            : 'Maximum Will Gainable',
                        controller: controller.maxWillController,
                        onChanged: (value) {
                          final intValue = int.tryParse(value);
                          if (intValue != null) {
                            controller.maxWill =
                                controller.nature == HabitNature.negative
                                    ? -intValue.abs()
                                    : intValue;
                            controller.maxWillController.text =
                                intValue.abs().toString();
                            controller.notifyListeners();
                          }
                        },
                        isNegative: controller.nature == HabitNature.negative,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        });
  }

  Widget _buildDynamicWillInput() {
    return WillInputField(
      title: controller.nature == HabitNature.negative
          ? 'Will Lost Per ${controller.repetitionUnitType}'
          : 'Will Gained Per ${controller.repetitionUnitType}',
      controller: controller.willPerRepController,
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null) {
          controller.willPerRep = controller.nature == HabitNature.negative
              ? -intValue.abs()
              : intValue;
          controller.willPerRepController.text = intValue.abs().toString();

          // Update maxWill based on the new willPerRep value
          controller.maxWill = controller.repetitions * controller.willPerRep;
          controller.maxWillController.text =
              controller.maxWill.abs().toString();

          controller.notifyListeners();
        }
      },
      isNegative: controller.nature == HabitNature.negative,
    );
  }
}

// File: components/will_toggle.dart
class WillToggle extends StatelessWidget {
  final HabitFormController controller;

  const WillToggle({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
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
                color: controller.willEnabled ? Colors.white : Colors.grey,
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
                    controller.willEnabled
                        ? 'Track your will power'
                        : 'Will tracking disabled',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          controller.willEnabled ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: controller.willEnabled,
            onChanged: (bool value) {
              controller.willEnabled = value;
              controller.notifyListeners();
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
}

// File: components/will_input_field.dart
class WillInputField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final Function(String) onChanged;
  final bool isNegative;

  const WillInputField({
    super.key,
    required this.title,
    required this.controller,
    required this.onChanged,
    required this.isNegative,
  });

  @override
  Widget build(BuildContext context) {
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
          decoration: CustomInputDecorations.willInput(isNegative: isNegative),
          validator: (value) {
            // Special validation for Starting Will

            // Default validation for other fields
            return FormValidators.validateInteger(value, title);
          },
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class SubmitButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final HabitFormController controller;
  final bool isEdit;
  final VoidCallback onSubmit;

  const SubmitButton({
    super.key,
    required this.formKey,
    required this.controller,
    required this.isEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        // Add debug prints to trace execution
        print("Submit button pressed");

        if (_validateForm()) {
          print("Form validated successfully");
          try {
            // Call onSubmit callback
            onSubmit();
          } catch (e) {
            print("Error during habit submission: $e");
            _showErrorDialog(context, e.toString());
          }
        } else {
          print("Form validation failed");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fix the form errors')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Text(
        isEdit ? 'Save Changes' : 'Create Habit',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _validateForm() {
    // Debug the form validation
    print("Validating form...");

    // Basic form field validation
    if (!formKey.currentState!.validate()) {
      print("Form field validation failed");
      return false;
    }
    print("Form field validation passed");

    // Validate name
    if (controller.nameController.text.isEmpty) {
      print("Name is required");
      ScaffoldMessenger.of(formKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Habit name is required')),
      );
      return false;
    }

    // Skip weekly schedule validation for negative habits
    if (controller.nature != HabitNature.negative) {
      // Validate weekly schedule for non-negative habits
      final scheduleError =
          FormValidators.validateWeeklySchedule(controller.weeklySchedule);
      if (scheduleError != null) {
        print("Weekly schedule validation failed: $scheduleError");
        ScaffoldMessenger.of(formKey.currentContext!).showSnackBar(
          SnackBar(content: Text(scheduleError)),
        );
        return false;
      }
    }
    print("Weekly schedule validation passed");

    // If will is enabled, validate will-related fields
    if (controller.willEnabled) {
      // Validate willPerRep
      if (controller.willPerRepController.text.isEmpty) {
        print("Will per rep is required");
        ScaffoldMessenger.of(formKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('Will per rep is required')),
        );
        return false;
      }

      // Validate maxWill
      if (controller.maxWillController.text.isEmpty) {
        print("Max Will is required");
        ScaffoldMessenger.of(formKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('Max Will is required')),
        );
        return false;
      }
    }

    print("All validations passed!");
    return true;
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content:
            Text('Failed to ${isEdit ? 'update' : 'create'} habit: $error'),
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

// File: validators/form_validators.dart

class FormValidators {
  /// Validates that the input is a positive integer
  static String? validateInteger(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (int.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }

    // Special case for Target Repetitions - allow zero
    if (fieldName == 'Target Repetitions' || fieldName == 'Target') {
      if (int.parse(value) < 0) {
        return 'Target must be greater than or equal to 0';
      }
    }
    // Special case for Starting Will - allow zero
    else if (fieldName == 'Starting Will') {
      if (int.parse(value) < 0) {
        return 'Starting Will must be greater than or equal to 0';
      }
    } else {
      // For other fields, require positive values
      if (int.parse(value) <= 0) {
        return '$fieldName must be greater than 0';
      }
    }
    return null;
  }

  /// Validates a name field
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    // Check for valid characters (letters, numbers, spaces, and basic punctuation)
    final validCharacters = RegExp(r'^[a-zA-Z0-9\s\-_.]+$');
    if (!validCharacters.hasMatch(value)) {
      return 'Name can only contain letters, numbers, spaces, and basic punctuation';
    }
    return null;
  }

  /// Validates will-related input fields
  static String? validateWillInput(String? value, String fieldName,
      {bool allowNegative = false}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }

    // Special case for Starting Will
    if (fieldName == 'Starting Will') {
      if (number < 0) {
        return 'Starting Will must be greater than or equal to 0';
      }
    } else {
      // For other fields
      if (!allowNegative && number < 0) {
        return '$fieldName cannot be negative';
      }

      if (allowNegative && number > 0) {
        return '$fieldName must be negative for negative habits';
      }
    }

    if (number.abs() > 10000) {
      return '$fieldName cannot exceed 10000';
    }

    return null;
  }

  /// Validates repetition count
  static String? validateRepetitions(String? value) {
    if (value == null || value.isEmpty) {
      return 'Repetitions are required';
    }

    final reps = int.tryParse(value);
    if (reps == null) {
      return 'Repetitions must be a valid number';
    }

    // Allow 0 as a valid value for repetitions
    if (reps < 0) {
      return 'Repetitions must be at least 0';
    }

    if (reps > 1000) {
      return 'Repetitions cannot exceed 1000';
    }

    return null;
  }

  /// Validates duration in minutes
  static String? validateDuration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Duration is required';
    }

    final minutes = int.tryParse(value);
    if (minutes == null) {
      return 'Duration must be a valid number';
    }

    if (minutes < 1) {
      return 'Duration must be at least 1 minute';
    }

    if (minutes > 1440) {
      // 24 hours
      return 'Duration cannot exceed 24 hours (1440 minutes)';
    }

    return null;
  }

  /// Validates max will value
  static String? validateMaxWill(String? value, {required bool isNegative}) {
    if (value == null || value.isEmpty) {
      return 'Maximum will is required';
    }

    final willValue = int.tryParse(value);
    if (willValue == null) {
      return 'Maximum will must be a valid number';
    }

    // For negative habits, we'll allow positive input values that will be converted to negative
    if (isNegative) {
      // Just check the absolute value is within range
      if (willValue.abs() > 10000) {
        return 'Maximum will cannot exceed 10000';
      }
    } else {
      // For positive habits, enforce positive values
      if (willValue < 0) {
        return 'Maximum will must be positive for positive habits';
      }
      if (willValue > 10000) {
        return 'Maximum will cannot exceed 10000';
      }
    }

    return null;
  }

  /// Validates weekly schedule
  static String? validateWeeklySchedule(WeeklySchedule schedule) {
    if (!schedule.monday &&
        !schedule.tuesday &&
        !schedule.wednesday &&
        !schedule.thursday &&
        !schedule.friday &&
        !schedule.saturday &&
        !schedule.sunday) {
      return 'At least one day must be selected';
    }
    return null;
  }

  /// Validates will per repetition
  static String? validateWillPerRep(String? value, {required bool isNegative}) {
    if (value == null || value.isEmpty) {
      return 'Will per repetition is required';
    }

    final willValue = int.tryParse(value);
    if (willValue == null) {
      return 'Will per repetition must be a valid number';
    }

    // For negative habits, we'll allow positive input values that will be converted to negative
    if (isNegative) {
      // Just check the absolute value is within range
      if (willValue.abs() > 1000) {
        return 'Will per repetition cannot exceed 1000';
      }
    } else {
      // For positive habits, enforce positive values
      if (willValue < 0) {
        return 'Will per repetition must be positive for positive habits';
      }
      if (willValue > 1000) {
        return 'Will per repetition cannot exceed 1000';
      }
    }

    return null;
  }

  /// Validates will per minute
  static String? validateWillPerMinute(String? value,
      {required bool isNegative}) {
    if (value == null || value.isEmpty) {
      return 'Will per minute is required';
    }

    final willValue = int.tryParse(value);
    if (willValue == null) {
      return 'Will per minute must be a valid number';
    }

    if (isNegative) {
      if (willValue > 0) {
        return 'Will per minute must be negative for negative habits';
      }
    } else {
      if (willValue < 0) {
        return 'Will per minute must be positive for positive habits';
      }
    }

    if (willValue.abs() > 100) {
      return 'Will per minute cannot exceed 100';
    }

    return null;
  }

  /// Validates the entire form
  static Map<String, String> validateForm({
    required String name,
    required WeeklySchedule schedule,
    required String repetitions,
    required String duration,
    required bool willEnabled,
    String? startingWill,
    String? maxWill,
    String? willPerRep,
    String? willPerMinute,
    required bool isNegative,
  }) {
    final errors = <String, String>{};

    // Validate name
    final nameError = validateName(name);
    if (nameError != null) {
      errors['name'] = nameError;
    }

    // Validate schedule
    final scheduleError = validateWeeklySchedule(schedule);
    if (scheduleError != null) {
      errors['schedule'] = scheduleError;
    }

    // Validate will-related fields if enabled
    if (willEnabled) {
      final maxWillError = validateMaxWill(maxWill, isNegative: isNegative);
      if (maxWillError != null) {
        errors['maxWill'] = maxWillError;
      }
    }

    return errors;
  }
}
