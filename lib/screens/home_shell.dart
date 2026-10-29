import 'package:flutter/material.dart';

import 'package:yummealprep/screens/browse/browse_screen.dart';
import 'package:yummealprep/screens/favourites/favourites_screen.dart';
import 'package:yummealprep/screens/planner/planner_screen.dart';
import 'package:yummealprep/screens/search/search_screen.dart';

/// The four main tabs. Each keeps its state (scroll position, search text,
/// selected day) while another tab is showing.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _screens = [
    PlannerScreen(),
    BrowseScreen(),
    SearchScreen(),
    FavouritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back from another tab returns to the planner before leaving the app.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Planner',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category),
              label: 'Browse',
            ),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favourites',
            ),
          ],
        ),
      ),
    );
  }
}
