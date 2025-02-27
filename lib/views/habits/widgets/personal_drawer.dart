
import 'package:flutter/material.dart';


class PersonalDrawer extends StatelessWidget {
  const PersonalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1A1A1A),  // Matching your dark theme
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2D2D2D),  // Matching your AppBar color
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.blue,  // Matching your add button color
                    radius: 30,
                    child: Text('H', style: TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Habit Tracker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Track your daily progress',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(context, Icons.home_outlined, 'Dashboard'),
            _buildDrawerItem(context, Icons.bar_chart, 'Statistics'),
            _buildDrawerItem(context, Icons.history, 'History'),
            const Divider(color: Colors.grey),
            _buildDrawerItem(context, Icons.star_border, 'Premium Features'),
            _buildDrawerItem(context, Icons.groups_outlined, 'Community'),
            _buildDrawerItem(context, Icons.tips_and_updates_outlined, 'Habit Tips'),
            const Divider(color: Colors.grey),
            _buildDrawerItem(context, Icons.settings_outlined, 'Settings'),
            _buildDrawerItem(context, Icons.help_outline, 'Help & Support'),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,  // Matching your theme
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        // Add navigation logic here
      },
      horizontalTitleGap: 0,
    );
  }
}
