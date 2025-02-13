// import 'package:farmwill_habits/repositories/habits_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../models/habits.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class UserHabitDetailsPage extends StatefulWidget {
//   final UserHabit habit;
//   final DateTime selectedDate;
//   final UserDayLog? dayLog;
//
//   const UserHabitDetailsPage({
//     Key? key,
//     required this.habit,
//     required this.selectedDate,
//     required this.dayLog,
//   }) : super(key: key);
//
//   @override
//   State<UserHabitDetailsPage> createState() => _UserHabitDetailsPageState();
// }
//
//
// class _UserHabitDetailsPageState extends State<UserHabitDetailsPage> {
//   late HabitsRepository _habitsRepository = HabitsRepository();
//   DateTime selectedDate = DateTime.now();
//   final String userId = FirebaseAuth.instance.currentUser!.uid;
//
//   @override
//   void initState() {
//     super.initState();
//     _habitsRepository = HabitsRepository();
//   }
//
//
//   List<UserHabitLog> _getHabitLogs() {
//     if (widget.dayLog == null) return [];
//     if(widget.dayLog!.logs == null) return [];
//     return widget.dayLog!.logs!
//         .where((log) => log.habitId == widget.habit.id)
//         .toList();
//   }
//
//
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate,
//       firstDate: widget.habit.createdAt,
//       lastDate: DateTime.now(),
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//     }
//   }
//
//   Widget _buildHabitHeader(BuildContext context, UserHabitStatus? status) {
//     final theme = Theme.of(context);
//     final completedToday = status?.completed ?? false;
//
//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     widget.habit.name,
//                     style: theme.textTheme.headlineSmall,
//                   ),
//                 ),
//                 Icon(
//                   widget.habit.nature == HabitNature.positive
//                       ? Icons.add_circle
//                       : Icons.remove_circle,
//                   color: widget.habit.nature == HabitNature.positive
//                       ? Colors.green
//                       : Colors.red,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             // Frequency type
//             if (widget.habit.weeklySchedule != null) ...[
//               const SizedBox(height: 4),
//               _buildWeeklySchedule(theme),
//             ],
//             // Score info
//
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildWeeklySchedule(ThemeData theme) {
//     final schedule = widget.habit.weeklySchedule!;
//     final days = [
//       {'name': 'M', 'enabled': schedule.monday},
//       {'name': 'T', 'enabled': schedule.tuesday},
//       {'name': 'W', 'enabled': schedule.wednesday},
//       {'name': 'T', 'enabled': schedule.thursday},
//       {'name': 'F', 'enabled': schedule.friday},
//       {'name': 'S', 'enabled': schedule.saturday},
//       {'name': 'S', 'enabled': schedule.sunday},
//     ];
//
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: days.map((day) {
//         return Container(
//           width: 30,
//           height: 30,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: day['enabled'] == true ? theme.primaryColor : Colors.grey[300],
//           ),
//           child: Center(
//             child: Text(
//               day['name'] as String,
//               style: TextStyle(
//                 color: day['enabled'] == true ? Colors.white : Colors.grey[600],
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   Widget _buildLogsList(List<UserHabitLog> logs) {
//     if (logs.isEmpty) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Text('No logs for this day'),
//         ),
//       );
//     }
//
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: logs.length,
//       itemBuilder: (context, index) {
//         final log = logs[index];
//         return Card(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//           child: ListTile(
//             leading: Icon(
//               log.eventType == LogEventType.click
//                   ? Icons.check_circle
//                   : Icons.timer,
//               color: widget.habit.nature == HabitNature.positive
//                   ? Colors.green
//                   : Colors.red,
//             ),
//             title: Text(
//               log.eventType == LogEventType.click
//                   ? 'Completed'
//                   : '${log.value?.toInt() ?? 0} minutes',
//             ),
//             subtitle: Text(
//               DateFormat('HH:mm').format(log.timestamp),
//             ),
//             trailing: log.note != null
//                 ? IconButton(
//               icon: const Icon(Icons.note),
//               onPressed: () {
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     title: const Text('Note'),
//                     content: Text(log.note!),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('Close'),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             )
//                 : null,
//           ),
//         );
//       },
//     );
//   }
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
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.edit),
//             onPressed: () {
//               // TODO: Navigate to edit habit page
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             FutureBuilder<UserHabitStatus?>(
//               future: _habitsRepository.getHabitStatus(
//                 userId,
//                 widget.habit.id,
//                 selectedDate,
//               ),
//               builder: (context, statusSnapshot) {
//                 return _buildHabitHeader(context, statusSnapshot.data);
//               },
//             ),
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: Text(
//                 'Activity Log',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             FutureBuilder<UserDayLog?>(
//               future: _habitsRepository.getDayLogs(userId, selectedDate),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 if (snapshot.hasError) {
//                   return Center(child: Text('Error: ${snapshot.error}'));
//                 }
//
//                 final dayLog = snapshot.data;
//                 final habitLogs = dayLog?.logs!
//                     .where((log) => log.habitId == widget.habit.id)
//                     .toList() ??
//                     [];
//
//                 return _buildLogsList(habitLogs);
//               },
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           // Show dialog to add new log
//           showDialog(
//             context: context,
//             builder: (context) => _AddLogDialog(
//               habit: widget.habit,
//               onAdd: (log) async {
//                 await _habitsRepository.logHabitEvent(userId, widget.habit, log);
//                 setState(() {}); // Refresh the page
//               },
//             ),
//           );
//         },
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
//
// class _AddLogDialog extends StatefulWidget {
//   final UserHabit habit;
//   final Function(UserHabitLog) onAdd;
//
//   const _AddLogDialog({
//     required this.habit,
//     required this.onAdd,
//   });
//
//   @override
//   State<_AddLogDialog> createState() => _AddLogDialogState();
// }
//
// class _AddLogDialogState extends State<_AddLogDialog> {
//   final _noteController = TextEditingController();
//   double _value = 1.0;
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Add Log'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           TextField(
//             controller: _noteController,
//             decoration: const InputDecoration(
//               labelText: 'Note (optional)',
//             ),
//           ),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         TextButton(
//           onPressed: () {
//             final log = UserHabitLog(
//               id: "yo",
//               habitId: widget.habit.id,
//               eventType: widget.habit.goal?.type == GoalType.duration
//                   ? LogEventType.timeTracked
//                   : LogEventType.click,
//               timestamp: DateTime.now(),
//               value: widget.habit.goal?.type == GoalType.duration ? _value : 1.0,
//               note: _noteController.text.isEmpty ? null : _noteController.text,
//             );
//             widget.onAdd(log);
//             Navigator.pop(context);
//           },
//           child: const Text('Add'),
//         ),
//       ],
//     );
//   }
// }