import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_state.dart';

final authProviderRef = ChangeNotifierProvider<AuthState>((ref) => AuthState());

// Define the auth provider
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(FirebaseAuth.instance.currentUser) {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      state = user;
    });
  }

  // ... existing methods

  // Add sign out method
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Handle any errors during sign out
      rethrow;
    }
  }
}

// Remove this class since you're using Riverpod's authProviderRef instead
// class AuthProvider with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   
//   User? get currentUser => _auth.currentUser;
//   
//   Future<void> signOut() async {
//     await _auth.signOut();
//     notifyListeners();
//   }
// }

