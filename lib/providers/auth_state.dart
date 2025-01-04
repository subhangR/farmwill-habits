import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthState extends ChangeNotifier {
  String? uid;
  UserCredential? userCredential;
  AuthService authService = GetIt.I.get<AuthService>();
  FreeUser? freeUser;
  bool? isHunterActivated;
  bool isReady = false;

  void logoutUser() {
    userCredential = null;
    notifyListeners();
  }

  String? getUid() {
    if (this.userCredential == null) {
      return null;
    }
    return userCredential!.user!.uid;
  }


  void setCurrentUser(UserCredential userCred) async {
    this.userCredential = userCred;
    notifyListeners();
  }

  void setFreeUser(FreeUser user) {
    this.freeUser = user;
    notifyListeners();
  }



  bool areUserDetailsCaptured(FreeUser? user) {
    if (user == null ||
        user.displayName == null ||
        user.firstName == null ||
        user.lastName == null) {
      return false;
    }
    return true;
  }


  void signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<FreeUser?> refreshUser(User currentUser) async {
    if(freeUser == null || freeUser!.uid != currentUser.uid) {
      freeUser = await authService.fetchUser(currentUser.uid);
    }
    return freeUser;
  }
}
