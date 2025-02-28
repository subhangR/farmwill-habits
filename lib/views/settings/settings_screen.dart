import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // Account section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // Logout button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF2A2A2A),
                  title: const Text('Logout',
                      style: TextStyle(color: Colors.white)),
                  content: const Text('Are you sure you want to logout?',
                      style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await ref.read(authProvider.notifier).signOut();
                // Navigate to login screen after logout
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
          ),

          const Divider(color: Colors.grey),

          // About section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          const ListTile(
            leading: Icon(Icons.info_outline, color: Colors.white70),
            title: Text('App Version', style: TextStyle(color: Colors.white)),
            subtitle: Text('1.0.0', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
