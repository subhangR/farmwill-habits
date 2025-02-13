// import 'package:farmwill_habits/views/habits/today_page.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_speed_dial/flutter_speed_dial.dart';
// import 'package:intl/intl.dart';
//
// import '../../models/habits.dart';
// import '../../repositories/habits_repository.dart';
// import '../habits/create_habit_page.dart';
//
// class UserHabitsPage extends StatefulWidget {
//   const UserHabitsPage({Key? key}) : super(key: key);
//
//   @override
//   State<UserHabitsPage> createState() => _UserHabitsPageState();
// }
//
// class _UserHabitsPageState extends State<UserHabitsPage> {
//   final HabitsRepository _repository = HabitsRepository();
//   DateTime _selectedDate = DateTime.now();
//   bool _isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final userId = FirebaseAuth.instance.currentUser?.uid;
//     if (userId == null) {
//       return const Center(child: Text('Please sign in to view habits'));
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('My Habits'),
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () => _selectDate(context),
//           ),
//         ],
//       ),
//       body: RefreshIndicator(
//         onRefresh: () async {
//           setState(() {});
//         },
//         child: CustomScrollView(
//           slivers: [
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       DateFormat('EEEE, MMMM d').format(_selectedDate),
//                       style: Theme.of(context).textTheme.headlineSmall,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Your habits for today',
//                       style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                             color: Colors.grey[600],
//                           ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             _buildHabitsList(userId),
//           ],
//         ),
//       ),
//       floatingActionButton: buildSpeedDial(context),
//     );
//   }
//
//   Widget _buildHabitsList(String userId) {
//     return FutureBuilder<List<UserHabit>>(
//       future: _repository.getAllHabits(
//         userId,
//       ),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const SliverFillRemaining(
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         if (snapshot.hasError) {
//           return SliverFillRemaining(
//             child: Center(child: Text('Error: ${snapshot.error}')),
//           );
//         }
//
//         final habits = snapshot.data ?? [];
//         if (habits.isEmpty) {
//           return const SliverFillRemaining(
//             child: Center(
//               child: Text('No habits scheduled for today'),
//             ),
//           );
//         }
//
//         return SliverList(
//           delegate: SliverChildBuilderDelegate(
//             (context, index) {
//               final habit = habits[index];
//               return _buildHabitCard(habit, userId);
//             },
//             childCount: habits.length,
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildHabitCard(UserHabit habit, String userId) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: InkWell(
//         onTap: () => _showHabitDetails(habit),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     habit.nature == HabitNature.positive
//                         ? Icons.add_circle_outline
//                         : Icons.remove_circle_outline,
//                     color: habit.nature == HabitNature.positive
//                         ? Colors.green
//                         : Colors.red,
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       habit.name,
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                   ),
//                   PopupMenuButton<String>(
//                     onSelected: (value) {
//                       switch (value) {
//                         case 'edit':
//                           _editHabit(habit);
//                           break;
//                         case 'archive':
//                           _archiveHabit(userId, habit.id!);
//                           break;
//                         case 'delete':
//                           _deleteHabit(userId, habit.id!);
//                           break;
//                       }
//                     },
//                     itemBuilder: (context) => [
//                       const PopupMenuItem(
//                         value: 'edit',
//                         child: Text('Edit'),
//                       ),
//                       const PopupMenuItem(
//                         value: 'archive',
//                         child: Text('Archive'),
//                       ),
//                       const PopupMenuItem(
//                         value: 'delete',
//                         child: Text('Delete'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               if (habit.goal != null) ...[
//                 const SizedBox(height: 8),
//                 LinearProgressIndicator(
//                   value: habit.goal!.progress / habit.goal!.target,
//                   backgroundColor: Colors.grey[200],
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '${habit.goal!.progress.toInt()}/${habit.goal!.target} ${habit.goal!.type == GoalType.duration ? 'minutes' : 'times'}',
//                   style: Theme.of(context).textTheme.bodySmall,
//                 ),
//               ],
//               const SizedBox(height: 8),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2025),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }
//
//   Future<void> _showAddHabitDialog(BuildContext context) async {
//     // Implement add habit dialog
//     // This would open a form to create a new habit
//   }
//
//   void _showHabitDetails(UserHabit habit) {
//     // Implement habit details view
//     // This would show a detailed view of the habit
//   }
//
//   Future<void> _editHabit(UserHabit habit) async {
//     // Implement edit habit functionality
//   }
//
//   Future<void> _archiveHabit(String userId, String habitId) async {
//     try {
//       await _repository.archiveHabit(userId, habitId);
//       setState(() {});
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Habit archived')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error archiving habit: $e')),
//         );
//       }
//     }
//   }
//
//   Future<void> _deleteHabit(String userId, String habitId) async {
//     try {
//       await _repository.deleteHabit(userId, habitId);
//       setState(() {});
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Habit deleted')),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error deleting habit: $e')),
//         );
//       }
//     }
//   }
//
//   Future<void> _logHabitCompletion(UserHabit habit, String userId) async {
//     try {
//       final log = UserHabitLog(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         habitId: habit.id!,
//         eventType: LogEventType.click,
//         timestamp: DateTime.now(),
//         value: 1,
//       );
//
//
//       // Update progress if goal exists
//       if (habit.goal != null) {
//         final newProgress = habit.goal!.progress + 1;
//         await _repository.updateHabitProgress(userId, habit.id!, newProgress);
//       }
//
//       setState(() {});
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error logging habit: $e')),
//         );
//       }
//     }
//   }
//
//   void _startTimeTracking(UserHabit habit, String userId) {
//     // Implement time tracking functionality
//     // This would start a timer and create a time-tracked log
//   }
//
//   SpeedDial buildSpeedDial(BuildContext context) {
//     return SpeedDial(
//       icon: Icons.add,
//       activeIcon: Icons.close,
//       spacing: 3,
//       childPadding: const EdgeInsets.all(5),
//       spaceBetweenChildren: 4,
//       tooltip: 'Add Habit',
//       heroTag: 'speed-dial-hero-tag',
//       backgroundColor: Theme.of(context).primaryColor,
//       foregroundColor: Colors.white,
//       elevation: 8.0,
//       isOpenOnStart: false,
//       children: [
//         SpeedDialChild(
//           child: const Icon(Icons.repeat),
//           backgroundColor: Colors.green,
//           foregroundColor: Colors.white,
//           label: 'Regular Habit',
//           onTap: () async {
//             final result = await Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) =>  TodayPage(),
//               ),
//             );
//
//             if (result != null) {
//               // Handle the new regular habit
//               // You might want to add a method to handle saving the habit
//               final userId = FirebaseAuth.instance.currentUser?.uid;
//               if (userId != null) {
//                 try {
//                   await HabitsRepository().createHabit(userId, result);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Regular habit created successfully')),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Error creating habit: $e')),
//                   );
//                 }
//               }
//             }
//           },
//         ),
//       ],
//     );
//   }
// }
//
//
