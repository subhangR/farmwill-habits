// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get_it/get_it.dart';
//
// import '../../../models/habit_data.dart';
// import '../../../models/habits.dart';
// import '../../../repositories/habits_repository.dart';
// import '../habit_details_page.dart';
// import '../habit_state.dart';
// import 'habit_input_modal.dart';
//
//
// class HabitCardV2 extends ConsumerStatefulWidget {
//   final UserHabit userHabit;
//
//   const HabitCardV2({
//     Key? key,
//     required this.userHabit,
//   }) : super(key: key);
//
//   @override
//   ConsumerState<HabitCardV2> createState() => _HabitCardState();
// }
//
// class _HabitCardState extends ConsumerState<HabitCardV2> with SingleTickerProviderStateMixin {
//   late final HabitProgressController _progressController;
//   late final HabitDataManager _dataManager;
//   late final AnimationController _animationController;
//   late final Animation<double> _scaleAnimation;
//   bool _isInitialized = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeControllers();
//     _loadInitialData();
//   }
//
//   void _initializeControllers() {
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );
//
//     _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.bounceIn),
//     );
//
//     _progressController = HabitProgressController(
//       onProgressUpdate: _handleProgressUpdate,
//     );
//
//     _dataManager = HabitDataManager(
//       habitsRepository: GetIt.I<HabitsRepository>(),
//       userId: FirebaseAuth.instance.currentUser!.uid,
//       habitId: widget.userHabit.id,
//       ref: ref,
//       userHabit: widget.userHabit,
//       onError: _handleError,
//       onCompletion: _handleCompletion,
//     );
//   }
//
//   Future<void> _loadInitialData() async {
//     await _dataManager.loadData();
//     _progressController.initializeProgress(_dataManager.currentProgress);
//     setState(() => _isInitialized = true);
//   }
//
//   void _handleProgressUpdate(double progress) {
//     setState(() {});
//   }
//
//   void _handleError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message))
//     );
//   }
//
//   void _handleCompletion() {
//     ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Habit Completed!'))
//     );
//   }
//
//   Future<void> _handleTap() async {
//     if (_dataManager.isCompleted) return;
//
//     _animationController.forward().then((_) => _animationController.reverse());
//     await _dataManager.incrementProgress();
//     _progressController.animateToProgress(_dataManager.currentProgress);
//   }
//
//   void _handleLongPress() {
//     _progressController.stopAnimation();
//     HabitUpdateModal.show(
//       context,
//       userHabit: widget.userHabit,
//       currentReps: _dataManager._currentReps,
//       targetReps: widget.userHabit.targetReps ?? 0,
//       currentDuration: _dataManager._currentMinutes,
//       targetDuration: widget.userHabit.targetMinutes ?? 0,
//       onUpdate: _dataManager.updateProgress,
//     );
//   }
//
//
//   Future<void> _handleRemove() async {
//     if (!_dataManager.hasStarted) return;
//
//     _animationController.forward().then((_) => _animationController.reverse());
//     await _dataManager.decrementProgress();
//     _progressController.animateToProgress(_dataManager.currentProgress);
//   }
//
//   void _navigateToDetails() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => HabitDetailsPage(userHabit: widget.userHabit),
//       ),
//     ).then((_) => _loadInitialData());
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_isInitialized) {
//       return const SizedBox(
//         height: 80,
//         child: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         GestureDetector(
//           onDoubleTap: _navigateToDetails,
//           onTap: _handleTap,
//           onLongPress: _handleLongPress,
//           child: AnimatedBuilder(
//             animation: _scaleAnimation,
//             builder: (context, child) => Transform.scale(
//               scale: _scaleAnimation.value,
//               child: HabitCardContent(
//                 userHabit: widget.userHabit,
//                 progressController: _progressController,
//                 dataManager: _dataManager,
//               ),
//             ),
//           ),
//         ),
//         if (_dataManager.hasStarted || _dataManager.isCompleted)
//           HabitActionButton(
//             isCompleted: _dataManager.isCompleted,
//             isPositive: widget.userHabit.nature == HabitNature.positive,
//             onTap: _handleRemove,
//             onLongPress: _handleLongPress,
//           ),
//       ],
//     );
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _progressController.dispose();
//     super.dispose();
//   }
// }
//
// // lib/src/features/habits/widgets/habit_progress_controller.dart
// class HabitProgressController {
//   final void Function(double) onProgressUpdate;
//   bool _isAnimating = false;
//   double _currentProgress = 0.0;
//   double _targetProgress = 0.0;
//   Timer? _animationTimer;
//
//   HabitProgressController({required this.onProgressUpdate});
//
//   void initializeProgress(double progress) {
//     _currentProgress = progress;
//     _targetProgress = progress;
//     onProgressUpdate(progress);
//   }
//
//   void animateToProgress(double targetProgress) {
//     _targetProgress = targetProgress;
//     _startAnimation();
//   }
//
//   void _startAnimation() {
//     if (_isAnimating) return;
//     _isAnimating = true;
//
//     const animationDuration = Duration(milliseconds: 150);
//     final startTime = DateTime.now();
//     final startProgress = _currentProgress;
//
//     void updateProgress() {
//       if (!_isAnimating) return;
//
//       final elapsedTime = DateTime.now().difference(startTime);
//       final progress = (elapsedTime.inMilliseconds / animationDuration.inMilliseconds)
//           .clamp(0.0, 1.0);
//
//       _currentProgress = startProgress + (_targetProgress - startProgress) * progress;
//       onProgressUpdate(_currentProgress);
//
//       if (progress < 1.0 && _isAnimating) {
//         _animationTimer = Timer(const Duration(milliseconds: 16), updateProgress);
//       } else {
//         _isAnimating = false;
//       }
//     }
//
//     updateProgress();
//   }
//
//   void stopAnimation() {
//     _isAnimating = false;
//     _animationTimer?.cancel();
//     _currentProgress = _targetProgress;
//     onProgressUpdate(_currentProgress);
//   }
//
//   void dispose() {
//     stopAnimation();
//     _animationTimer?.cancel();
//   }
// }
//
// // lib/src/features/habits/widgets/habit_data_manager.dart
// class HabitDataManager {
//   final HabitsRepository habitsRepository;
//   final String userId;
//   final String habitId;
//   final WidgetRef ref;
//   final UserHabit userHabit;
//   final Function(String) onError;
//   final VoidCallback onCompletion;
//
//   int _currentReps = 0;
//   int _currentMinutes = 0;
//   static const int _minutesIncrement = 5;
//   DateTime? _lastLoadedDate;
//
//   HabitDataManager({
//     required this.habitsRepository,
//     required this.userId,
//     required this.habitId,
//     required this.ref,
//     required this.userHabit,
//     required this.onError,
//     required this.onCompletion,
//   });
//
//   bool get isCompleted {
//     if (userHabit.goalType == GoalType.repetitions) {
//       return _currentReps >= (userHabit.targetReps ?? 0);
//     } else {
//       return _currentMinutes >= (userHabit.targetMinutes ?? 0);
//     }
//   }
//
//   bool get hasStarted {
//     return userHabit.goalType == GoalType.repetitions
//         ? _currentReps > 0
//         : _currentMinutes > 0;
//   }
//
//   double get currentProgress {
//     if (userHabit.goalType == GoalType.repetitions) {
//       if (userHabit.targetReps! > 0) {
//         return _currentReps / userHabit.targetReps!;
//       }
//     } else {
//       final targetMinutes = userHabit.targetMinutes ?? 0;
//       if (targetMinutes > 0) {
//         return _currentMinutes / targetMinutes;
//       }
//     }
//     return 0.0;
//   }
//
//   Future<void> loadData() async {
//     final habitState = ref.read(habitStateProvider);
//     final selectedDate = habitState.selectedDate;
//
//     if (_shouldReload(selectedDate)) {
//       final dayLog = habitState.getDayLog(selectedDate);
//       _lastLoadedDate = selectedDate;
//
//       if (dayLog?.habits[habitId] != null) {
//         final habitData = dayLog!.habits[habitId]!;
//         _currentReps = habitData.reps;
//         _currentMinutes = habitData.duration;
//       } else {
//         _currentReps = 0;
//         _currentMinutes = 0;
//       }
//     }
//   }
//
//   bool _shouldReload(DateTime selectedDate) {
//     return _lastLoadedDate == null ||
//         _lastLoadedDate!.year != selectedDate.year ||
//         _lastLoadedDate!.month != selectedDate.month ||
//         _lastLoadedDate!.day != selectedDate.day;
//   }
//
//   Future<void> incrementProgress() async {
//     final previousReps = _currentReps;
//     final previousMinutes = _currentMinutes;
//
//     if (userHabit.goalType == GoalType.repetitions) {
//       _currentReps++;
//     } else {
//       _currentMinutes += _minutesIncrement;
//     }
//
//     try {
//       await _updateHabitData();
//       if (isCompleted) onCompletion();
//     } catch (e) {
//       _currentReps = previousReps;
//       _currentMinutes = previousMinutes;
//       onError('Failed to update habit: $e');
//     }
//   }
//
//   Future<void> decrementProgress() async {
//     final previousReps = _currentReps;
//     final previousMinutes = _currentMinutes;
//
//     if (userHabit.goalType == GoalType.repetitions) {
//       if (_currentReps > 0) _currentReps--;
//     } else {
//       if (_currentMinutes >= _minutesIncrement) {
//         _currentMinutes -= _minutesIncrement;
//       }
//     }
//
//     try {
//       await _updateHabitData();
//     } catch (e) {
//       _currentReps = previousReps;
//       _currentMinutes = previousMinutes;
//       onError('Failed to update habit: $e');
//     }
//   }
//
//   Future<void> updateProgress(int reps, int duration, bool completed) async {
//     final previousReps = _currentReps;
//     final previousMinutes = _currentMinutes;
//
//     _currentReps = reps;
//     _currentMinutes = duration;
//
//     try {
//       await _updateHabitData();
//       if (completed) onCompletion();
//     } catch (e) {
//       _currentReps = previousReps;
//       _currentMinutes = previousMinutes;
//       onError('Failed to update habit: $e');
//     }
//   }
//
//   Future<void> _updateHabitData() async {
//     final habitState = ref.read(habitStateProvider);
//     final willObtained = _calculateWillObtained();
//
//     final habitData = HabitData(
//       reps: _currentReps,
//       duration: _currentMinutes,
//       goalType: userHabit.goalType,
//       willObtained: willObtained,
//       targetReps: userHabit.targetReps ?? 0,
//       targetDuration: userHabit.targetMinutes ?? 0,
//       targetWill: userHabit.maxWill ?? 0,
//       willPerRep: userHabit.willPerRep ?? 0,
//       willPerDuration: userHabit.willPerMin ?? 0,
//       maxWill: userHabit.maxWill ?? 0,
//       startingWill: userHabit.startingWill ?? 0,
//       isCompleted: isCompleted,
//     );
//
//     await habitsRepository.updateHabitData(
//       habitId: habitId,
//       userId: userId,
//       habitData: habitData,
//       date: habitState.selectedDate,
//     );
//
//     // Update will points
//     _updateWillPoints(willObtained);
//
//     await habitState.loadHabitsAndData(userId);
//   }
//
//   int _calculateWillObtained() {
//     if (userHabit.goalType == GoalType.repetitions) {
//       return userHabit.willPerRep != null ?
//       _currentReps * userHabit.willPerRep! : 0;
//     } else {
//       return userHabit.willPerMin != null ?
//       _currentMinutes * userHabit.willPerMin! : 0;
//     }
//   }
//
//   void _updateWillPoints(int willObtained) {
//     final habitState = ref.read(habitStateProvider);
//     final previousWill = habitState.getDayLog(habitState.selectedDate)
//         ?.habits[habitId]?.willObtained ?? 0;
//     final willChange = willObtained - previousWill;
//
//     if (willChange != 0) {
//       habitState.updateWillPoints(willChange);
//     }
//   }
// }
//
// // Continuing habit_card_content.dart
// class HabitCardContent extends StatelessWidget {
//   final UserHabit userHabit;
//   final HabitProgressController progressController;
//   final HabitDataManager dataManager;
//
//   const HabitCardContent({
//     Key? key,
//     required this.userHabit,
//     required this.progressController,
//     required this.dataManager,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 0,
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       color: Colors.transparent,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(
//           color: _getBorderColor(),
//           width: 2,
//         ),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: Stack(
//           children: [
//             _buildBackgroundLayer(),
//             _buildProgressLayer(),
//             _buildContentLayer(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBackgroundLayer() {
//     if (!dataManager.hasStarted) return const SizedBox.shrink();
//
//     return Positioned.fill(
//       child: Container(
//         color: _getFillColor(),
//       ),
//     );
//   }
//
//   Widget _buildProgressLayer() {
//     if (!dataManager.hasStarted) return const SizedBox.shrink();
//
//     return Positioned.fill(
//       child: FractionallySizedBox(
//         alignment: Alignment.centerLeft,
//         widthFactor: dataManager.currentProgress.clamp(0.0, 1.0),
//         child: Container(
//           color: _getProgressColor(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildContentLayer() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: const Color(0xFF2D2D2D).withOpacity(0.3),
//       ),
//       child: Row(
//         children: [
//           _buildHabitIcon(),
//           const SizedBox(width: 16),
//           Expanded(
//             child: _buildHabitInfo(),
//           ),
//           _buildHabitStats(),
//           const SizedBox(width: 48),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHabitIcon() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.3),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Icon(
//         Icons.check_circle,
//         size: 32,
//         color: dataManager.isCompleted ? Colors.green : Colors.white,
//       ),
//     );
//   }
//
//   Widget _buildHabitInfo() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           userHabit.name,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         const SizedBox(height: 4),
//         AnimatedSwitcher(
//           duration: const Duration(milliseconds: 300),
//           child: Text(
//             _getGoalProgressText(),
//             key: ValueKey('${dataManager.currentProgress}'),
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey.shade300,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildHabitStats() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.end,
//       children: [
//         _buildWillPoints(),
//         const SizedBox(height: 4),
//         _buildFrequencyText(),
//       ],
//     );
//   }
//
//   Widget _buildWillPoints() {
//     return Padding(
//       padding: const EdgeInsets.only(right: 5),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(
//             Icons.local_fire_department,
//             size: 20,
//             color: Colors.orange,
//           ),
//           const SizedBox(width: 4),
//           Text(
//             _calculateWillPoints().toString(),
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFrequencyText() {
//     return Text(
//       _getFrequencyText(),
//       style: TextStyle(
//         fontSize: 13,
//         fontWeight: FontWeight.w600,
//         color: Colors.grey.shade300,
//       ),
//     );
//   }
//
//   Color _getBorderColor() {
//     return userHabit.nature == HabitNature.positive
//         ? Colors.green.withOpacity(0.7)
//         : Colors.red.withOpacity(0.7);
//   }
//
//   Color _getFillColor() {
//     if (userHabit.nature == HabitNature.positive) {
//       return dataManager.isCompleted
//           ? Colors.green.shade700.withOpacity(0.3)
//           : Colors.green.shade300.withOpacity(0.3);
//     } else {
//       return dataManager.isCompleted
//           ? Colors.red.shade700.withOpacity(0.3)
//           : Colors.red.shade300.withOpacity(0.3);
//     }
//   }
//
//   Color _getProgressColor() {
//     if (userHabit.nature == HabitNature.positive) {
//       return dataManager.isCompleted
//           ? Colors.green.shade700.withOpacity(0.5)
//           : Colors.green.shade300.withOpacity(0.5);
//     } else {
//       return dataManager.isCompleted
//           ? Colors.red.shade700.withOpacity(0.5)
//           : Colors.red.shade300.withOpacity(0.5);
//     }
//   }
//
//   String _getGoalProgressText() {
//     if (userHabit.nature == HabitNature.negative) {
//       return dataManager.isCompleted
//           ? 'Completed'
//           : dataManager.hasStarted
//           ? 'In progress'
//           : 'Not started';
//     }
//
//     if (userHabit.goalType == GoalType.repetitions) {
//       return userHabit.targetReps == 1
//           ? dataManager.isCompleted
//           ? 'Completed'
//           : 'Not completed'
//           : '${dataManager._currentReps}/${userHabit.targetReps} reps';
//     } else {
//       return '${dataManager._currentMinutes}/${userHabit.targetMinutes} min';
//     }
//   }
//   String _getFrequencyText() {
//     WeeklySchedule schedule = userHabit.weeklySchedule!;
//     int daysCount = [
//       schedule.monday,
//       schedule.tuesday,
//       schedule.wednesday,
//       schedule.thursday,
//       schedule.friday,
//       schedule.saturday,
//       schedule.sunday
//     ].where((day) => day == true).length;  // Explicitly compare with true
//
//     return daysCount == 7 ? 'Daily' : '${daysCount}x/week';
//   }
//
//   int _calculateWillPoints() {
//     if (userHabit.goalType == GoalType.repetitions) {
//       return userHabit.willPerRep != null
//           ? dataManager._currentReps * userHabit.willPerRep!
//           : 0;
//     } else {
//       return userHabit.willPerMin != null
//           ? dataManager._currentMinutes * userHabit.willPerMin!
//           : 0;
//     }
//   }
// }
//
// // lib/src/features/habits/widgets/habit_action_button.dart
// class HabitActionButton extends StatelessWidget {
//   final bool isCompleted;
//   final bool isPositive;
//   final VoidCallback onTap;
//   final VoidCallback onLongPress;
//
//   const HabitActionButton({
//     Key? key,
//     required this.isCompleted,
//     required this.isPositive,
//     required this.onTap,
//     required this.onLongPress,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final baseColor = isPositive ? Colors.green : Colors.red;
//
//     return Positioned(
//       top: 0,
//       right: 24,
//       child: Transform.translate(
//         offset: const Offset(0, -12),
//         child: Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: (isCompleted ? baseColor.shade700 : baseColor.shade300)
//                     .withOpacity(0.3),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: onTap,
//               onLongPress: onLongPress,
//               borderRadius: BorderRadius.circular(20),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: isCompleted ? baseColor.shade700 : baseColor.shade300,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   transitionBuilder: (Widget child, Animation<double> animation) {
//                     return ScaleTransition(
//                       scale: animation,
//                       child: RotationTransition(
//                         turns: animation,
//                         child: child,
//                       ),
//                     );
//                   },
//                   child: Icon(
//                     isCompleted ? Icons.check_circle : Icons.remove_circle,
//                     key: ValueKey(isCompleted),
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }