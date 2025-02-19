import 'package:farmwill_habits/models/habits.dart';
import 'package:farmwill_habits/services/habit_service.dart';
import 'package:get_it/get_it.dart';

class HabitServiceTest {

  HabitService habitService = GetIt.I<HabitService>();
  
  void test() async {
    List<UserHabit> habits = await habitService.getAllHabits("0GOqPQJveSW7qdKzxOxUKKEkR7c2");
    print(habits);
  }
}