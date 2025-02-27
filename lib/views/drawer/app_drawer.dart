import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:farmwill_habits/providers/auth_provider.dart';
import 'package:farmwill_habits/views/user/login_page.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              // Close the drawer first
              Navigator.pop(context);
              
              // Sign out
              await FirebaseAuth.instance.signOut();
              
              // Navigate to login screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => SigninPage()),
                (route) => false
              );
            },
          ),
        ],
      ),
    );
  }
} 