import 'package:flutter/material.dart';

import '../features/admin/ui/admin_dashboard_page.dart';
import '../features/explore/ui/explore_page.dart';
import '../features/groups/ui/groups_page.dart';
import '../features/profile/ui/profile_page.dart';
import '../features/trips/ui/trips_page.dart';
import '../core/utils/localization.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.tr,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  final Tr tr;
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ExplorePage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        onToggleLanguage: widget.onToggleLanguage,
      ),
      TripsPage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        onToggleLanguage: widget.onToggleLanguage,
      ),
      GroupsPage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        onToggleLanguage: widget.onToggleLanguage,
      ),
      ProfilePage(
        tr: widget.tr,
        isArabic: widget.isArabic,
        onToggleLanguage: widget.onToggleLanguage,
        onOpenAdminDashboard: _openAdminDashboard,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: widget.tr.t('explore'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.hiking),
            label: widget.tr.t('trips'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group),
            label: widget.tr.t('groups'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: widget.tr.t('profile'),
          ),
        ],
      ),
    );
  }

  void _openAdminDashboard() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
  }
}


