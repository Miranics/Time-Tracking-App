import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/time_entry_provider.dart';
import '../widgets/app_drawer.dart';
import 'add_time_entry_screen.dart';
import 'project_task_management_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  Future<void> _openProjectManager(BuildContext context) async {
    final provider = context.read<TimeEntryProvider>();
    await Navigator.of(context)
        .pushNamed(ProjectTaskManagementScreen.routeName);
    if (context.mounted) {
      await provider.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openProjectManager(context),
            tooltip: 'Manage projects and tasks',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: Consumer<TimeEntryProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton(
            onPressed: provider.projects.isEmpty
                ? () => _promptCreateProject(context)
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await Navigator.of(context)
                        .pushNamed(AddTimeEntryScreen.routeName);
                    if (result == true) {
                      await provider.reload();
                      if (context.mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Time entry added.')),
                        );
                      }
                    }
                  },
            child: const Icon(Icons.add),
          );
        },
      ),
      body: Consumer<TimeEntryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.projects.isEmpty) {
            return _EmptyState(
              onManageProjects: () => _openProjectManager(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.reload(),
            child: _ProjectList(provider: provider),
          );
        },
      ),
    );
  }

  void _promptCreateProject(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Create a project first to add time entries.'),
        duration: Duration(seconds: 3),
      ),
    );
    _openProjectManager(context);
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({required this.provider});

  final TimeEntryProvider provider;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final projects = provider.projects;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        final projectEntries = provider.entriesForProject(project.id);
        final totalMinutes = provider.totalMinutesForProject(project.id);
        final totalFormatted = _formatTotal(totalMinutes);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            initiallyExpanded: index == 0,
            title: Text(project.name),
            subtitle: Text(
              projectEntries.isEmpty
                  ? 'No time logged yet'
                  : '$totalFormatted • ${projectEntries.length} entr${projectEntries.length == 1 ? 'y' : 'ies'}',
            ),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (projectEntries.isEmpty)
                const ListTile(
                  title: Text('Tap the + button to add a time entry.'),
                )
              else
                ...projectEntries.map(
                  (entry) => _TimeEntryTile(
                    entry: entry,
                    project: project,
                    dateFormat: dateFormat,
                  ),
                ),
              _TaskSummaryList(project: project, provider: provider),
            ],
          ),
        );
      },
    );
  }

  static String _formatTotal(int minutes) {
    if (minutes == 0) return '0m';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '${remaining}m';
    return remaining == 0 ? '${hours}h' : '${hours}h ${remaining}m';
  }
}

class _TimeEntryTile extends StatelessWidget {
  const _TimeEntryTile({
    required this.entry,
    required this.project,
    required this.dateFormat,
  });

  final TimeEntry entry;
  final Project project;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TimeEntryProvider>();
    final taskName = project.tasks
            .firstWhereOrNull((task) => task.id == entry.taskId)
            ?.name ??
        'General';

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await provider.deleteTimeEntry(entry.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Time entry deleted')),
          );
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        title: Text('${dateFormat.format(entry.date)} • ${entry.formattedDuration}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task: $taskName'),
            if (entry.hasNotes) Text(entry.notes!.trim()),
          ],
        ),
        leading: const Icon(Icons.access_time),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete time entry?'),
          content:
              const Text('This action cannot be undone. Delete this entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onManageProjects});

  final Future<void> Function() onManageProjects;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No projects yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a project to start tracking your time entries.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                onManageProjects();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create project'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSummaryList extends StatelessWidget {
  const _TaskSummaryList({
    required this.project,
    required this.provider,
  });

  final Project project;
  final TimeEntryProvider provider;

  @override
  Widget build(BuildContext context) {
    final projectEntries = provider.entriesForProject(project.id);
    final hasGeneralEntries =
        provider.totalMinutesWithoutTask(project.id) > 0 ||
            projectEntries.any((entry) => entry.taskId == null);

    final hasTasks = project.tasks.isNotEmpty;

    if (!hasTasks && !hasGeneralEntries) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Task breakdown',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (hasGeneralEntries)
          ListTile(
            dense: true,
            leading: const Icon(Icons.workspaces_outline),
            title: const Text('General'),
            subtitle: const Text('Entries without a specific task'),
            trailing: Text(
              _ProjectList._formatTotal(
                provider.totalMinutesWithoutTask(project.id),
              ),
            ),
          ),
        if (hasTasks)
          ...project.tasks.map((task) {
            final minutes =
                provider.totalMinutesForTask(project.id, task.id);
            return ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(task.name),
              subtitle: task.description == null
                  ? null
                  : Text(task.description!),
              trailing: Text(_ProjectList._formatTotal(minutes)),
            );
          }),
      ],
    );
  }
}
