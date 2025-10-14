import 'package:flutter_test/flutter_test.dart';
import 'package:localstorage/localstorage.dart';

import 'package:time_tracker/models/models.dart';
import 'package:time_tracker/providers/time_entry_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimeEntryProvider', () {
    late TimeEntryProvider provider;

    setUp(() async {
      final storage = LocalStorage(
        'time_tracker_test_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      provider = TimeEntryProvider(storage: storage);
      await provider.initialize();
      await provider.clearAll();
    });

    tearDown(() async {
      await provider.clearAll();
    });

    test('can add and retrieve projects', () async {
      final project = Project(
        id: provider.generateId(),
        name: 'Client A',
        description: 'Website redesign',
      );

      await provider.addProject(project);

      expect(provider.projects, hasLength(1));
      expect(provider.projects.first.name, 'Client A');
    });

    test('projects persist after reload', () async {
      final project = Project(
        id: provider.generateId(),
        name: 'Reloadable Project',
      );

      await provider.addProject(project);

      await provider.reload();

      final reloaded = provider.projects;

      expect(reloaded, hasLength(1));
      expect(reloaded.first.name, 'Reloadable Project');
    });

    test('can add tasks and time entries and group by project', () async {
      final project = Project(
        id: provider.generateId(),
        name: 'Internal',
      );
      await provider.addProject(project);

      final task = Task(
        id: provider.generateId(),
        projectId: project.id,
        name: 'Planning',
      );
      await provider.addTask(project.id, task);

      final entry = TimeEntry(
        id: provider.generateId(),
        projectId: project.id,
        taskId: task.id,
        minutesSpent: 90,
        date: DateTime.now(),
        notes: 'Sprint planning session',
      );
      await provider.addTimeEntry(entry);

      expect(provider.entries, hasLength(1));
      expect(provider.entries.first.taskId, task.id);
      expect(provider.totalMinutesForProject(project.id), 90);
      expect(provider.entriesGroupedByProject[project.id], isNotNull);
      expect(provider.entriesGroupedByProject[project.id], hasLength(1));
    });

    test('delete project removes associated entries', () async {
      final project = Project(
        id: provider.generateId(),
        name: 'Cleanup',
      );
      await provider.addProject(project);

      final entry = TimeEntry(
        id: provider.generateId(),
        projectId: project.id,
        minutesSpent: 30,
        date: DateTime.now(),
      );
      await provider.addTimeEntry(entry);

      expect(provider.entries, hasLength(1));

      await provider.deleteProject(project.id);

      expect(provider.projects, isEmpty);
      expect(provider.entries, isEmpty);
    });
  });
}
