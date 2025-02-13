import 'package:farmwill_habits/repositories/habits_repository.dart';
import 'package:farmwill_habits/services/auth_service.dart';
import 'package:get_it/get_it.dart';


class Init {
  static Future<bool> initialize() async {
    _registerCloudFunctions();
    _registerServices();
    _registerDatabases();
    return true;
  }

  static _registerServices() {


    GetIt.I.registerLazySingleton<AuthService>(
        () => AuthService());
    GetIt.I.registerLazySingleton<HabitsRepository>(
            () => HabitsRepository());

  }

  static _registerCloudFunctions() {


  }

  static _registerDatabases() {

  }

}
