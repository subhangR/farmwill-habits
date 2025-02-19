import 'package:farmwill_habits/views/habits/widgets/calendar_widget.dart';
import 'package:farmwill_habits/views/habits/widgets/habit_card.dart';
import 'package:farmwill_habits/views/habits/widgets/personal_drawer.dart';
import 'package:farmwill_habits/views/habits/widgets/will_widget.dart';
import 'package:farmwill_habits/views/habits/will_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../models/habit_data.dart';
import '../../models/habits.dart';
import '../../repositories/habits_repository.dart';
import 'create_habit_page.dart';
import 'habit_state.dart';

class HabitListScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends ConsumerState<HabitListScreen> {
  bool _showCalendar = false;
  DateTime _selectedDate = DateTime.now();
  final HabitsRepository _habitsRepository = GetIt.I<HabitsRepository>();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabitsAndData();
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

  @override
  Widget build(BuildContext context) {
    // Watch the user habit state for changes
    final userHabitState = ref.watch(habitStateProvider);
    final willPoints = userHabitState.willPoints;
    final hasError = userHabitState.error != null;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('My Habits', style: TextStyle(color: Colors.white)),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => WillHistoryPage()),
                );
              },
              child: WillWidget(willPoints: willPoints),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white, size: 24),
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
                        MaterialPageRoute(builder: (context) => EditHabitPage()),
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

            // Habits List Section
            Expanded(
              child: _buildHabitsList(userHabitState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsList(UserHabitState userHabitState) {
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
                  MaterialPageRoute(builder: (context) => EditHabitPage()),
                );
                _loadHabitsAndData();
              },
              child: const Text('Create Your First Habit'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: userHabitState.habits.length,
      itemBuilder: (context, index) {
        final habit = userHabitState.habits[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 10),
          child: HabitCard(
            userHabit: habit,
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF2D2D2D), // Dark background
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue.shade700, // A slightly lighter shade for the header
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end, // Align to the bottom
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  // Add your profile image here
                  // backgroundImage: AssetImage('assets/profile_image.png'),
                ),
                SizedBox(height: 10),
                Text(
                  'Your Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'your.email@example.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Drawer items with icons and rounded corners
          _buildDrawerItem(Icons.settings, 'Settings', () {
            // Navigate to settings
          }),
          _buildDrawerItem(Icons.info_outline, 'About', () {
            // Show about dialog or page
          }),
          _buildDrawerItem(Icons.logout, 'Logout', () {
            // Handle logout
          }),
        ],
      ),
    );
  }

  // Helper method to create drawer items with rounded corners
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Material(
        color: Colors.transparent, // Transparent background for InkWell
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15), // Rounded corners for InkWell
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800, // Slightly lighter background for items
              borderRadius: BorderRadius.circular(15),
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
              children: [
                Icon(icon, color: Colors.white70),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
