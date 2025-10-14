import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/time_entry_provider.dart';
import 'screens/add_time_entry_screen.dart';
import 'screens/home_screen.dart';
import 'screens/project_task_management_screen.dart';

void main() {
  runApp(const TimeTrackerApp());
}

class TimeTrackerApp extends StatelessWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimeEntryProvider()..initialize(),
      child: MaterialApp(
        title: 'Time Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        initialRoute: HomeScreen.routeName,
        routes: {
          HomeScreen.routeName: (context) => const HomeScreen(),
          AddTimeEntryScreen.routeName: (context) => const AddTimeEntryScreen(),
          ProjectTaskManagementScreen.routeName: (context) =>
              const ProjectTaskManagementScreen(),
        },
      ),
    );
  }
}
