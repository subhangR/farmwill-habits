import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farmwill_habits/providers/auth_provider.dart';
import 'package:farmwill_habits/routes/main_routes.dart';
import 'package:farmwill_habits/views/habits/user_habits_page.dart';
import 'package:farmwill_habits/views/user/login_page.dart';
import 'package:farmwill_habits/views/user/user_details_input_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'init.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Init.initialize();
  runApp(MyApp());
}




class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(),
    );
  }
}
class AuthWrapper extends ConsumerStatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isProfileComplete = false;
  bool _isUserProfileComplete = false;
  bool _isHunterProfileComplete = false;
  bool _isSigningOut = false;

  void _onUserProfileComplete(FreeUser freeUser) {
    ref.read(authProviderRef).setFreeUser(freeUser);
    setState(() {
      _isUserProfileComplete = true;
    });
  }

  void _onHunterProfileComplete() {
    setState(() {
      _isHunterProfileComplete = true;
      _isProfileComplete = true;
    });
  }

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });
    try {
      // Clear any local user data
      await SharedPreferences.getInstance().then((prefs) => prefs.clear());

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Reset app state
      setState(() {
        _isProfileComplete = false;
        // Reset any other state variables
      });
    } catch (e) {
      print("Error signing out: $e");
    } finally {
      setState(() {
        _isSigningOut = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isSigningOut) {
      return Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("USer aUth Event!");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Text("Loading..."));
        } else if (snapshot.hasData) {
          User? user = snapshot.data;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
            builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> freeUserSnapshot) {
              if (freeUserSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Center(child: Text("hello"),));
              }

              if (freeUserSnapshot.hasError) {
                return Center(child: Text("Error: ${freeUserSnapshot.error}"));
              }

              if (freeUserSnapshot.hasData && freeUserSnapshot.data!.exists) {
                Map<String, dynamic> userData = freeUserSnapshot.data!.data() as Map<String, dynamic>;
                FreeUser? freeUser = FreeUser.fromJson(user.uid, userData);

                return SafeArea(
                  child: Scaffold(
                    body: MaterialApp.router(routerConfig: mainRouterV2),
                  ),
                );
              } else {
                return UserDetailsInputPage(user: user, onComplete: _onUserProfileComplete);
              }
            },
          );
        } else {
          return SigninPage();
        }
      },
    );
  }
}



