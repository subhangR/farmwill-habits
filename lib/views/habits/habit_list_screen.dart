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
  willPerStep,
  maxWill,
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
  bool _showSortButton = true;

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

      case HabitSortOption.willPerStep:
        sortedHabits.sort((a, b) {
          final aWill = a.willPerRep ?? 0;
          final bWill = b.willPerRep ?? 0;
          return _sortAscending
              ? aWill.compareTo(bWill)
              : bWill.compareTo(aWill);
        });
        break;

      case HabitSortOption.maxWill:
        sortedHabits.sort((a, b) {
          final aMax = (a.willPerRep ?? 0) * (a.targetReps ?? 1);
          final bMax = (b.willPerRep ?? 0) * (b.targetReps ?? 1);
          return _sortAscending ? aMax.compareTo(bMax) : bMax.compareTo(aMax);
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
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sort By',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          setState(() => _sortAscending = !_sortAscending);
                          this.setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.grey),
                _buildSortTile(
                  'Name',
                  Icons.sort_by_alpha,
                  HabitSortOption.name,
                  setState,
                ),
                _buildSortTile(
                  'Will/Step',
                  Icons.bolt,
                  HabitSortOption.willPerStep,
                  setState,
                ),
                _buildSortTile(
                  'Max Will',
                  Icons.star,
                  HabitSortOption.maxWill,
                  setState,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSortTile(
    String title,
    IconData icon,
    HabitSortOption option,
    StateSetter setState,
  ) {
    final isSelected = _currentSortOption == option;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        setState(() => _currentSortOption = option);
        this.setState(() {});
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
        child: Stack(
          children: [
            Column(
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

                // Habits List Section with top padding for the sort button
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo is ScrollUpdateNotification) {
                        setState(() {
                          _showSortButton = scrollInfo.metrics.pixels <= 10;
                        });
                      }
                      return true;
                    },
                    child: _buildHabitsList(userHabitState, sortedHabits),
                  ),
                ),
              ],
            ),

            // Sort button overlay
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showSortButton ? 1.0 : 0.0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1A1A1A),
                        const Color(0xFF1A1A1A).withOpacity(0.9),
                        const Color(0xFF1A1A1A).withOpacity(0),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildSortButton(),
                    ],
                  ),
                ),
              ),
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
      padding: EdgeInsets.fromLTRB(16.0, 72.0, 16.0, 16.0),
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
      case HabitSortOption.willPerStep:
        return Icons.bolt;
      case HabitSortOption.maxWill:
        return Icons.star;
      default:
        return Icons.sort;
    }
  }

  // Helper method to get the name of the current sort option
  String _getSortName() {
    switch (_currentSortOption) {
      case HabitSortOption.name:
        return 'Name';
      case HabitSortOption.willPerStep:
        return 'Will/Step';
      case HabitSortOption.maxWill:
        return 'Max Will';
      default:
        return 'Default';
    }
  }

  Widget _buildSortButton() {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        icon: Icon(_getSortIcon(), size: 18),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getSortName()),
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
            ),
          ],
        ),
        onPressed: _showSortOptions,
      ),
    );
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
