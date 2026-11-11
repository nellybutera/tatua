import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../shared/explore_screen.dart';
import '../shared/profile_screen.dart';
import 'my_reports_screen.dart';
import 'report_form_screen.dart';
import 'student_home_screen.dart';

/// Bottom navigation for students: Home, My Reports, [+], Explore, Profile.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  void _openReportForm() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportFormScreen()));

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentHomeScreen(onOpenTab: (i) => setState(() => _index = i), onReport: _openReportForm),
      const MyReportsScreen(),
      const SizedBox.shrink(), // centre "+" button opens the form instead
      const ExploreScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Report an issue',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: _openReportForm,
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primarySoft,
        onDestinationSelected: (i) => i == 2 ? _openReportForm() : setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description_rounded), label: 'My Reports'),
          NavigationDestination(icon: SizedBox(width: 24), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
