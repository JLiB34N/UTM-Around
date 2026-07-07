import 'package:flutter/material.dart';
import 'main_feed_page.dart'; 
import 'package:utm_around/Settings/settings.dart'; 
import 'search_filter.dart'; 
import 'package:utm_around/constant.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Keep track of which tab is selected (0 = Home, 1 = Search, 2 = Settings)
  int _currentIndex = 0;

  // List of the actual pages to display
  final List<Widget> _pages = [
    const MainFeed(),
    const SearchPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body simply shows the page at the current index
      body: _pages[_currentIndex],
      
      // Bottom Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // When a user taps a tab, update the index and rebuild the screen
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: utmMaroon, // UTM color for the active tab
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10, // Adds a nice shadow above the bar
        type: BottomNavigationBarType.shifting, // shifting/fixed
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.saved_search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}