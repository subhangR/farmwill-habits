import 'package:farmwill_habits/views/habits/widgets/calendar_widget.dart';
import 'package:farmwill_habits/views/habits/widgets/habit_card.dart';
import 'package:farmwill_habits/views/habits/widgets/will_widget.dart';
import 'package:farmwill_habits/views/habits/will_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../models/habit_data.dart';
import '../../models/habits.dart';
import '../../repositories/habits_repository.dart';
import 'create_habit_page_v2.dart';
import 'habit_state.dart';
import 'habit_details_page.dart';

// Define sort options
enum HabitSortOption {
  name,
  willPerRep,
  willGained,
}

class HabitListScreen extends ConsumerStatefulWidget {
  const HabitListScreen({super.key});

  @override
  ConsumerState<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends ConsumerState<HabitListScreen> {
  bool _showCalendar = false;
  DateTime _selectedDate = DateTime.now();
  final HabitsRepository _habitsRepository = GetIt.I<HabitsRepository>();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  HabitSortOption _currentSortOption = HabitSortOption.name;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid modifying provider during build
    Future.microtask(() => _loadHabitsAndData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use Future.microtask to avoid modifying provider during build
    Future.microtask(() => _loadHabitsAndData());
  }

  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
    });
  }

  UserDayLog? getDayLog(DateTime date) {
    final userHabitState = ref.read(habitStateProvider);
    return userHabitState.getDayLog(date);
  }

  Future<void> _loadHabitsAndData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userHabitState = ref.read(habitStateProvider);
      await userHabitState.loadHabitsAndData(_userId, _selectedDate);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    // Update habits data for the selected date through the provider
    final userHabitState = ref.read(habitStateProvider);
    userHabitState.updateSelectedDate(date);
  }

  // Sort habits based on current sort option
  List<UserHabit> _getSortedHabits(
      List<UserHabit> habits, Map<String, HabitData> habitsData) {
    final sortedHabits = List<UserHabit>.from(habits);

    switch (_currentSortOption) {
      case HabitSortOption.name:
        sortedHabits.sort((a, b) => _sortAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;

      case HabitSortOption.willPerRep:
        sortedHabits.sort((a, b) {
          final aWillPerRep = a.willPerRep ?? 0;
          final bWillPerRep = b.willPerRep ?? 0;
          return _sortAscending
              ? aWillPerRep.compareTo(bWillPerRep)
              : bWillPerRep.compareTo(aWillPerRep);
        });
        break;

      case HabitSortOption.willGained:
        sortedHabits.sort((a, b) {
          final aWillGained = habitsData[a.id]?.willObtained ?? 0;
          final bWillGained = habitsData[b.id]?.willObtained ?? 0;
          return _sortAscending
              ? aWillGained.compareTo(bWillGained)
              : bWillGained.compareTo(aWillGained);
        });
        break;
    }

    return sortedHabits;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Sort Habits By',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildSortOption(
                title: 'Name',
                icon: Icons.sort_by_alpha,
                sortOption: HabitSortOption.name,
              ),
              _buildSortOption(
                title: 'Will Per Rep',
                icon: Icons.bolt,
                sortOption: HabitSortOption.willPerRep,
              ),
              _buildSortOption(
                title: 'Will Gained',
                icon: Icons.trending_up,
                sortOption: HabitSortOption.willGained,
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.blue,
                ),
                title: Text(
                  _sortAscending ? 'Ascending' : 'Descending',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    _sortAscending = !_sortAscending;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption({
    required String title,
    required IconData icon,
    required HabitSortOption sortOption,
  }) {
    final isSelected = _currentSortOption == sortOption;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        setState(() {
          _currentSortOption = sortOption;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the ref from the ConsumerState
    final userHabitState = ref.watch(habitStateProvider);
    final habits = userHabitState.habits;
    final habitsData = userHabitState.habitsData;
    final willPoints = userHabitState.willPoints;
    final hasError = userHabitState.error != null;

    // Apply sorting
    final sortedHabits = _getSortedHabits(habits, habitsData);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('My Habits', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WillHistoryPage(
                      habits: userHabitState.habits,
                      habitsData: userHabitState.habitsData,
                      title: 'Overall Will History',
                    ),
                  ),
                );
              },
              child: WillWidget(willPoints: willPoints),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.calendar_month, color: Colors.white, size: 24),
            onPressed: _toggleCalendar,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ClipOval(
              child: Material(
                color: Colors.blue.shade500,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const EditHabitPageV2()),
                      );
                      // Reload habits after returning from create page
                      _loadHabitsAndData();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHabitsAndData,
        child: Column(
          children: [
            // Calendar Section
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _showCalendar ? null : 0,
              child: _showCalendar
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CalendarWidget(
                        initialDate: _selectedDate,
                        onDateSelected: _onDateSelected,
                      ),
                    )
                  : null,
            ),

            // Sort button and indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Sort button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showSortOptions,
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getSortIcon(),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getSortName(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Habits List Section
            Expanded(
              child: _buildHabitsList(userHabitState, sortedHabits),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsList(
      UserHabitState userHabitState, List<UserHabit> sortedHabits) {
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
              onPressed: _loadHabitsAndData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (userHabitState.habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No habits yet',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const EditHabitPageV2()),
                );
                _loadHabitsAndData();
              },
              child: const Text('Create Your First Habit'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sortedHabits.length,
      itemBuilder: (context, index) {
        final habit = sortedHabits[index];
        final habitData = userHabitState.habitsData[habit.id];
        return HabitCard(
          userHabit: habit,
          habitData: habitData,
          selectedDate: _selectedDate,
        );
      
      },
    );
  }

  // Helper method to get the appropriate icon for the current sort option
  IconData _getSortIcon() {
    switch (_currentSortOption) {
      case HabitSortOption.name:
        return Icons.sort_by_alpha;
      case HabitSortOption.willPerRep:
        return Icons.bolt;
      case HabitSortOption.willGained:
        return Icons.trending_up;
      default:
        return Icons.sort;
    }
  }

  // Helper method to get the name of the current sort option
  String _getSortName() {
    switch (_currentSortOption) {
      case HabitSortOption.name:
        return 'Name';
      case HabitSortOption.willPerRep:
        return 'Will Per Rep';
      case HabitSortOption.willGained:
        return 'Will Gained';
      default:
        return 'Default';
    }
  }

  void _navigateToHabitDetails(UserHabit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailsPage(userHabit: habit),
      ),
    ).then((result) {
      // If result is true, a habit was deleted or updated
      if (result == true) {
        print("Habit was deleted or updated, refreshing list");
        // Refresh the habit list
        final habitState = ref.read(habitStateProvider);
        habitState.loadHabitsAndData(_userId);
      }
    });
  }

  void _showHabitOptions(UserHabit habit) {
    // Implement the logic to show the habit options
  }
}
