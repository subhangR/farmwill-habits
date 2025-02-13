import 'package:farmwill_habits/views/unused/today_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../views/habits/habit_list_screen.dart';
import '../views/unused/history_page.dart';
import '../views/habits/widgets/habit_card.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final mainRouterV2 = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/today',
  routes: <RouteBase>[
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavbarV2(navigationShell);
      },
      branches: [
        StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/today',
                builder: (context, state) => HabitListScreen(),
              ),
            ]),
        // StatefulShellBranch(
        //     routes: <RouteBase>[
        //       GoRoute(
        //         path: '/solve',
        //         builder: (context, state) => QuestionsListPage(),
        //       ),
        //     ]),
        StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/history',
                builder: (context, state) => HistoryPage(),
              ),
            ]),
      ],
    ),
  ],
);


class ScaffoldWithNavbarV2 extends StatelessWidget {
  const ScaffoldWithNavbarV2(this.navigationShell, {super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MagicalNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }

  void _onTap(index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class MagicalNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MagicalNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black87,
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.room, 'Today', 0),
              // _buildNavItem(Icons.search, 'solve', 1),
              _buildNavItem(Icons.library_books, 'Insights', 1),
            ],
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: MediaQuery.of(context).size.width / 2 * currentIndex,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width / 2,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.white10 : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.white60,
              size: 28,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}