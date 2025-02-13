// import 'package:farmwill_habits/views/habits/habit_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import '../../models/habits.dart';
// import '../../repositories/habits_repository.dart';
//
// class TodayPage extends StatefulWidget {
//   const TodayPage({Key? key}) : super(key: key);
//
//   @override
//   State<TodayPage> createState() => _TodayPageState();
// }
//
// class _TodayPageState extends State<TodayPage> {
//   DateTime selectedDate = DateTime.now();
//   final HabitsRepository _habitsRepository = HabitsRepository();
//   final String userId = FirebaseAuth.instance.currentUser!.uid;
//
//   // Utility function to group logs by habitId
//   Map<String, List<UserHabitLog>> _groupLogsByHabit(List<UserHabitLog> logs) {
//     final Map<String, List<UserHabitLog>> grouped = {};
//     for (var log in logs) {
//       if (!grouped.containsKey(log.habitId)) {
//         grouped[log.habitId] = [];
//       }
//       grouped[log.habitId]!.add(log);
//     }
//     return grouped;
//   }
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2025),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//     }
//   }
//   //
//   // Future<void> _logHabitEvent(UserHabit habit) async {
//   //   try {
//   //     final log = UserHabitLog(
//   //       id: "yo",
//   //       habitId: habit.id,
//   //       eventType: habit.goal?.type == GoalType.duration
//   //           ? LogEventType.timeTracked
//   //           : LogEventType.click,
//   //       timestamp: selectedDate,
//   //       value: 1.0,
//   //     );
//   //
//   //     await _habitsRepository.logHabitEvent(userId, habit, log);
//   //     setState(() {}); // Refresh to show updated status
//   //
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text('Habit logged successfully!')),
//   //     );
//   //   } catch (e) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Error logging habit: $e')),
//   //     );
//   //   }
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             Text(DateFormat('EEEE, MMMM d').format(selectedDate)),
//             IconButton(
//               icon: const Icon(Icons.calendar_today),
//               onPressed: () => _selectDate(context),
//             ),
//           ],
//         ),
//       ),
//       body: FutureBuilder<UserMonthLog?>(
//         future: _habitsRepository.getMonthLogs(userId, selectedDate),
//         builder: (context, monthLogSnapshot) {
//           if (monthLogSnapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (monthLogSnapshot.hasError) {
//             return Center(child: Text('Error: ${monthLogSnapshot.error}'));
//           }
//
//           final monthLog = monthLogSnapshot.data;
//
//           return FutureBuilder<List<UserHabit>>(
//             future: _habitsRepository.getHabitsForWeekday(userId, selectedDate.weekday),
//             builder: (context, habitSnapshot) {
//               if (habitSnapshot.connectionState == ConnectionState.waiting) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//
//               if (habitSnapshot.hasError) {
//                 return Center(child: Text('Error: ${habitSnapshot.error}'));
//               }
//
//               final habits = habitSnapshot.data ?? [];
//               if (habits.isEmpty) {
//                 return const Center(child: Text('No habits scheduled for today'));
//               }
//
//               // Get the day log from month log
//               final dayKey = selectedDate.day.toString();
//               final dayLog = monthLog?.days[dayKey];
//               print("Found DAy logs!! ");
//
//               // Extract statuses from day log
//               Map<String, UserHabitStatus> statuses = {};
//               if (dayLog != null) {
//                 final habitLogs = dayLog.logs;
//                 final groupedLogs = _groupLogsByHabit(habitLogs!);
//
//                 // Calculate status for each habit
//                 for (var habit in habits) {
//                   final habitLogs = groupedLogs[habit.id] ?? [];
//                   double progress = 0;
//                   bool completed = false;
//
//
//                   statuses[habit.id] = UserHabitStatus(
//                     habitId: habit.id,
//                     date: selectedDate,
//                     completed: completed,
//                     progress: progress,
//                   );
//                 }
//               }
//
//               return ListView.builder(
//                 itemCount: habits.length,
//                 itemBuilder: (context, index) {
//                   final habit = habits[index];
//                   final status = statuses[habit.id];
//                   return _HabitDayCard(
//                     habit: habit,
//                     status: status,
//                     onLogEvent: () => _logHabitEvent(habit),
//                     onHabitTap: (habit) {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => UserHabitDetailsPage(
//                             habit: habit,
//                             selectedDate: selectedDate,
//                             dayLog: dayLog,
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
//
// class _HabitDayCard extends StatelessWidget {
//   final UserHabit habit;
//   final UserHabitStatus? status;
//   final VoidCallback onLogEvent;
//   final Function(UserHabit) onHabitTap;
//
//   const _HabitDayCard({
//     required this.habit,
//     this.status,
//     required this.onLogEvent,
//     required this.onHabitTap,
//   });
//
//   // Widget _buildProgressIndicator(ThemeData theme) {
//   //   if (habit.goal == null) return const SizedBox.shrink();
//   //
//   //   final progress = status?.progress ?? 0;
//   //   final target = habit.goal!.target;
//   //
//   //   return Column(
//   //     crossAxisAlignment: CrossAxisAlignment.start,
//   //     children: [
//   //       LinearProgressIndicator(
//   //         value: progress / target,
//   //         backgroundColor: Colors.grey[200],
//   //         valueColor: AlwaysStoppedAnimation<Color>(
//   //           habit.nature == HabitNature.positive
//   //               ? Colors.green
//   //               : Colors.red,
//   //         ),
//   //       ),
//   //       const SizedBox(height: 4),
//   //       Text(
//   //         '${progress.toInt()}/${target} '
//   //             '${habit.goal!.type == GoalType.duration ? 'minutes' : 'times'}',
//   //         style: theme.textTheme.bodySmall,
//   //       ),
//   //     ],
//   //   );
//   // }
//
//
//   // Widget _buildEventControl(ThemeData theme) {
//   //   if (habit.goal == null) {
//   //     // Simple checkbox for habits without goals
//   //     return Checkbox(
//   //       value: status?.completed ?? false,
//   //       onChanged: (_) => onLogEvent(),
//   //       activeColor: habit.nature == HabitNature.positive
//   //           ? Colors.green
//   //           : Colors.red,
//   //     );
//   //   }
//   //
//   //   // Increment button for repetitions or duration
//   //   final buttonText = habit.goal!.type == GoalType.duration ? '+1 min' : '+1';
//   //
//   //   return ElevatedButton(
//   //     onPressed: onLogEvent,
//   //     style: ElevatedButton.styleFrom(
//   //       backgroundColor: habit.nature == HabitNature.positive
//   //           ? Colors.green
//   //           : Colors.red,
//   //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//   //     ),
//   //     child: Text(buttonText),
//   //   );
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final bool isCompleted = status?.completed ?? false;
//
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: IntrinsicHeight(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Left section - Habit details
//             Expanded(
//               flex: 3,
//               child: InkWell(
//                 onTap: () => onHabitTap(habit),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         habit.name,
//                         style: theme.textTheme.titleLarge?.copyWith(
//                           decoration: isCompleted ? TextDecoration.lineThrough : null,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       const SizedBox(height: 4),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             // Vertical divider
//             Container(
//               width: 1,
//               color: Colors.grey[300],
//             ),
//             // Right section - Event controls
//
//           ],
//         ),
//       ),
//     );
//   }
// }