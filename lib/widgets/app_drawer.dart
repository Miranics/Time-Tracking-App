import 'package:flutter/material.dart';

import '../screens/add_time_entry_screen.dart';
import '../screens/home_screen.dart';
import '../screens/local_storage_viewer_screen.dart';
import '../screens/project_task_management_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    void closeDrawer() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    Future<void> navigateTo(String routeName, {bool clearStack = false}) async {
      closeDrawer();
      await Future<void>.delayed(Duration.zero);
      if (clearStack) {
        rootNavigator.pushNamedAndRemoveUntil(routeName, (route) => false);
      } else {
        rootNavigator.pushNamed(routeName);
      }
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Time Tracker',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () => navigateTo(HomeScreen.routeName, clearStack: true),
            ),
            _DrawerItem(
              icon: Icons.add_circle_outline,
              title: 'Add Time Entry',
              onTap: () => navigateTo(AddTimeEntryScreen.routeName),
            ),
            _DrawerItem(
              icon: Icons.folder,
              title: 'Manage Projects & Tasks',
              onTap: () => navigateTo(ProjectTaskManagementScreen.routeName),
            ),
            _DrawerItem(
              icon: Icons.storage,
              title: 'Local Storage Viewer',
              onTap: () => navigateTo(LocalStorageViewerScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
