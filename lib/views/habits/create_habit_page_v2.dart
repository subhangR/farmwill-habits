// File: edit_habit_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
                
                  final habit = await _controller.submitHabit();
                  if (mounted && habit != null) {
                    Navigator.pop(context, habit);
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
  late HabitsRepository habitsRepository;


  HabitNature nature;
  WeeklySchedule _weeklySchedule;
  bool willEnabled;
  int repetitions;
  int willPerRep;
  int maxWill;
  int startingWill;
  FrequencyType _frequencyType;

  final HabitNature _nature;

  FrequencyType get frequencyType => _frequencyType;
  final UserHabit? originalHabit;

  WeeklySchedule get weeklySchedule => _weeklySchedule;

  HabitFormController(this.originalHabit)
      : nameController = TextEditingController(text: originalHabit?.name ?? ''),
        maxScoreController = TextEditingController(),
        willPerRepController = TextEditingController(),
        maxWillController = TextEditingController(),
        willPerMinuteController = TextEditingController(),
        startingWillController = TextEditingController(),
        nature = originalHabit?.nature ?? HabitNature.positive,
        _weeklySchedule = originalHabit?.weeklySchedule ??
            const WeeklySchedule(),
        _frequencyType = FrequencyType.daily,
        repetitions = originalHabit?.targetReps ?? 1,
        willPerRep = originalHabit?.willPerRep ?? 1,
        willEnabled = originalHabit?.willPerRep != null ? true : false,
        maxWill = 1,
        _nature = originalHabit?.nature ?? HabitNature.positive,
        startingWill = originalHabit?.startingWill ?? 0,
        _repetitionStep = originalHabit?.repetitionStep ?? 1,
        _repetitionUnitType = originalHabit?.repetitionUnitType ?? 'reps' {
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
        weeklySchedule = const WeeklySchedule(
          monday: true,
          tuesday: true,
          wednesday: true,
          thursday: true,
          friday: true,
          saturday: true,
          sunday: true,
        );
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

  String _repetitionUnitType = "reps";
  bool _isEditingUnitType = false;
  final TextEditingController unitTypeController = TextEditingController();

  String get repetitionUnitType => _repetitionUnitType;
  bool get isEditingUnitType => _isEditingUnitType;

  void updateRepetitionUnitType(String value) {
    // Validate the value
    if (!_isEditingUnitType && !unitTypes.contains(value)) {
      value = _defaultUnitTypes.first;  // Default to first value if invalid
    }

    _repetitionUnitType = value;
    unitTypeController.text = value;

    // Update will-related labels but keep the values
    if (willEnabled ) {
      notifyListeners();
    }
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
  int _repetitionStep = 1;

  bool get isBoundedTarget => _isBoundedTarget;
  int get repetitionUnits => _repetitionUnits;
  int get repetitionStep => _repetitionStep;

  set isBoundedTarget(bool value) {
    _isBoundedTarget = value;
    notifyListeners();
  }

  void updateRepetitionUnits(int value) {
    _repetitionUnits = value;
    notifyListeners();
  }

  void updateRepetitionStep(int value) {
    _repetitionStep = value;
    notifyListeners();
  }



  set weeklySchedule(WeeklySchedule value) {
    _weeklySchedule = value;
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
    willPerRepController.text = willPerRep.toString();
    maxWillController.text = maxWill.toString();
    startingWillController.text = startingWill.toString();
  }

  Future<UserHabit?> submitHabit() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Debug output
      print("Creating habit with: ");
      print("Name: ${nameController.text}");
      print("Nature: $nature");
      print("willEnabled: $willEnabled");
      print("willPerRep: $willPerRep");
      print("maxWill: $maxWill");
      
      // For negative habits with will enabled, ensure values are negative
      if (nature == HabitNature.negative && willEnabled) {
        // Force negative values for negative habits
        willPerRep = -willPerRep.abs();
        maxWill = -maxWill.abs();
        
        print("Adjusted for negative habit:");
        print("willPerRep: $willPerRep");
        print("maxWill: $maxWill");
      }
      
      // Ensure weekly schedule is set for negative habits
      if (nature == HabitNature.negative) {
        _weeklySchedule = const WeeklySchedule(
          monday: true,
          tuesday: true,
          wednesday: true,
          thursday: true,
          friday: true,
          saturday: true,
          sunday: true,
        );
        print("Set all days for negative habit");
      }
      
      final habit = UserHabit(
        frequencyType: _frequencyType,
        uid: userId,
        id: originalHabit?.id ?? FirebaseFirestore.instance.collection('user_habits').doc().id,
        name: nameController.text,
        habitType: HabitType.regular,
        nature: nature,
        weeklySchedule: _weeklySchedule,
        targetReps: repetitions,
        willPerRep: willEnabled ? willPerRep : null,
        maxWill: willEnabled ? maxWill : null,
        startingWill: willEnabled ? startingWill : null,
        createdAt: originalHabit?.createdAt ?? DateTime.now(),
        isArchived: originalHabit?.isArchived ?? false,
        repetitionStep: _repetitionStep,
        repetitionUnitType: _repetitionUnitType,
      );

      // Debug the created habit
      print("Created habit: ${habit.toMap()}");

      if (originalHabit == null) {
        // Create new habit
        await habitsRepository.createHabit(userId, habit);
        print("Habit created successfully");
      } else {
        // Update existing habit
        await habitsRepository.updateHabit(userId, habit);
        print("Habit updated successfully");
      }

      return habit;
    } catch (e) {
      print("Error creating/updating habit: $e");
      rethrow;
    }
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
                    title: 'One Time',
                    isSelected: widget.controller.frequencyType == FrequencyType.onetime,
                    onTap: () => widget.controller.updateFrequencyType(FrequencyType.onetime),
                  ),
                  _FrequencyTypeButton(
                    title: 'Daily',
                    isSelected: widget.controller.frequencyType == FrequencyType.daily,
                    onTap: () => widget.controller.updateFrequencyType(FrequencyType.daily),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (widget.controller.frequencyType == FrequencyType.daily) ...[
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
            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
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
        children: days.map((day) => _DayButton(
          day: day,
          isSelected: schedule[day] ?? false,
          onToggle: () => onToggleDay(day),
        )).toList(),
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
            day.substring(0, 3),  // Show first 3 letters
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
  final VoidCallback? onTap;  // Make callback nullable
  final Color backgroundColor;
  final Color iconColor;

  const CircularIconButton({
    super.key,
    required this.icon,
    this.onTap,  // Make it optional
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,  // InkWell accepts nullable callback
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
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.grey[800],
        unselectedWidgetColor: Colors.grey[400],
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.grey[400]!,
        ),
      ),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return ExpansionTile(
            title: const Text(
              'Target',
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
                    _buildTargetBoundToggle(),
                    const SizedBox(height: 24),
                    _buildCombinedTargetInput(),
                    const SizedBox(height: 24),
                    _buildStepInput(),
                    const SizedBox(height: 24),
                    WillSection(controller: controller),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCombinedTargetInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target',
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
            border: Border.all(
              color: controller.isBoundedTarget
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              // Number Input
              Expanded(
                flex: 2,
                child: TextFormField(
                  enabled: controller.isBoundedTarget,
                  initialValue: controller.repetitions.toString(),
                  style: TextStyle(
                    color: controller.isBoundedTarget ? Colors.white : Colors.grey,
                    fontSize: 16,
                  ),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    final newValue = int.tryParse(text);
                    if (newValue != null && newValue > 0) {
                      controller.repetitions = newValue;
                      controller.notifyListeners();
                    }
                  },
                ),
              ),
              // Vertical Divider
              Container(
                height: 30,
                width: 1,
                color: Colors.grey.withOpacity(0.3),
              ),
              // Unit Type Input
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: controller.isEditingUnitType
                          ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextFormField(
                          controller: controller.unitTypeController,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          onFieldSubmitted: (value) {
                            if (value.isNotEmpty) {
                              controller.updateRepetitionUnitType(value);
                            }
                            controller.toggleUnitTypeEditing();
                          },
                        ),
                      )
                          : DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: controller.repetitionUnitType,
                          dropdownColor: const Color(0xFF2A2A2A),
                          icon: const SizedBox.shrink(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          items: controller.unitTypes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(value),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              controller.updateRepetitionUnitType(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                    // Edit Button
                    IconButton(
                      icon: Icon(
                        controller.isEditingUnitType ? Icons.check : Icons.edit,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () {
                        if (controller.isEditingUnitType &&
                            controller.unitTypeController.text.isNotEmpty) {
                          controller.updateRepetitionUnitType(
                              controller.unitTypeController.text);
                        }
                        controller.toggleUnitTypeEditing();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepInput() {
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
                child: TextFormField(
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetBoundToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Target Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Switch(
            value: controller.isBoundedTarget,
            onChanged: (value) => controller.isBoundedTarget = value,
            activeColor: Colors.blue,
            activeTrackColor: Colors.blue.withOpacity(0.3),
          ),
          Text(
            controller.isBoundedTarget ? 'Bounded' : 'Boundless',
            style: TextStyle(
              color: controller.isBoundedTarget ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepetitionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Repetitions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: controller.isBoundedTarget
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircularIconButton(
                icon: Icons.remove,
                onTap: controller.isBoundedTarget
                    ? () {
                  if (controller.repetitions > 1) {
                    controller.repetitions -= controller.repetitionStep;
                    controller.notifyListeners();
                  }
                }
                    : null,
                backgroundColor: controller.isBoundedTarget
                    ? const Color(0xFF592B2B)
                    : Colors.grey.withOpacity(0.2),
                iconColor: controller.isBoundedTarget
                    ? Colors.red[300]!
                    : Colors.grey,
              ),
              Text(
                controller.isBoundedTarget
                    ? controller.repetitions.toString()
                    : '∞',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: controller.isBoundedTarget
                      ? Colors.white
                      : Colors.grey,
                ),
              ),
              CircularIconButton(
                icon: Icons.add,
                onTap: controller.isBoundedTarget
                    ? () {
                  controller.repetitions += controller.repetitionStep;
                  controller.notifyListeners();
                }
                    : null,
                backgroundColor: controller.isBoundedTarget
                    ? const Color(0xFF1B4B1B)
                    : Colors.grey.withOpacity(0.2),
                iconColor: controller.isBoundedTarget
                    ? Colors.green[300]!
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepetitionConfigSection() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildUnitInput(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildNumberInput(
            'Step',
            controller.repetitionStep,
                (value) => controller.updateRepetitionStep(value),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Units',
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
              // Text Field
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: controller.repetitions.toString(),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    final newValue = int.tryParse(text);
                    if (newValue != null && newValue > 0) {
                      controller.updateRepetitionUnits(newValue);
                    }
                  },
                ),
              ),
              // Vertical Divider
              Container(
                height: 30,
                width: 1,
                color: Colors.grey.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              // Dropdown
              Expanded(
                flex: 3,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.repetitionUnitType,
                    dropdownColor: const Color(0xFF2A2A2A),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    items: controller.unitTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            value,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        controller.updateRepetitionUnitType(newValue);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput(
      String label,
      int value,
      Function(int) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
          child: TextFormField(
            initialValue: value.toString(),
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            onChanged: (text) {
              final newValue = int.tryParse(text);
              if (newValue != null && newValue > 0) {
                onChanged(newValue);
              }
            },
          ),
        ),
      ],
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
      suffixIcon: suffixIcon != null ? Container(
        margin: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF3A3A3A),
        ),
        child: Icon(suffixIcon, color: Colors.white70),
      ) : null,
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
                ),
              ],
            ],
          );
        }
    );
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
              controller.maxWillController.text = controller.maxWill.abs().toString();


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
                    controller.willEnabled ? 'Track your will power' : 'Will tracking disabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: controller.willEnabled ? Colors.white70 : Colors.grey,
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
  final Future<void> Function() onSubmit;

  const SubmitButton({
    super.key,
    required this.formKey,
    required this.controller,
    required this.isEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_validateForm()) {
            try {
              await onSubmit();
            } catch (e) {
              if (context.mounted) {
                _showErrorDialog(context, e.toString());
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          isEdit ? 'Update habit' : 'Create habit',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  bool _validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    // Validate weekly schedule
    final scheduleError = FormValidators.validateWeeklySchedule(controller.weeklySchedule);
    if (scheduleError != null) {
      return false;
    }

    // If will is enabled, validate will-related fields
    if (controller.willEnabled) {

      final maxWillError = FormValidators.validateMaxWill(
          controller.maxWillController.text,
          isNegative: controller.nature == HabitNature.negative
      );
      if (maxWillError != null) {
        return false;
      }


    }

    return true;
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text('Failed to ${isEdit ? 'update' : 'create'} habit: $error'),
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
    
    // Special case for Starting Will - allow zero
    if (fieldName == 'Starting Will') {
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
  static String? validateWillInput(String? value, String fieldName, {bool allowNegative = false}) {
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

    if (reps < 1) {
      return 'Repetitions must be at least 1';
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

    if (minutes > 1440) { // 24 hours
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
  static String? validateWillPerMinute(String? value, {required bool isNegative}) {
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

