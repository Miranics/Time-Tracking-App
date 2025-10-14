import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

import 'package:time_tracker/providers/time_entry_provider.dart';
import 'package:time_tracker/screens/project_task_management_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('adding a project shows it in the list', (tester) async {
    final storage = LocalStorage(
      'project_task_management_widget_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    final provider = TimeEntryProvider(storage: storage);
    await provider.initialize();
    await provider.clearAll();

    await tester.pumpWidget(
      ChangeNotifierProvider<TimeEntryProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: ProjectTaskManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No projects yet'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Widget Project');

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Widget Project'), findsOneWidget);

    await provider.clearAll();
    provider.dispose();
  });
}