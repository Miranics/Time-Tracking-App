import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/time_entry_provider.dart';

class LocalStorageViewerScreen extends StatefulWidget {
  const LocalStorageViewerScreen({super.key});

  static const routeName = '/storage-viewer';

  @override
  State<LocalStorageViewerScreen> createState() => _LocalStorageViewerScreenState();
}

class _LocalStorageViewerScreenState extends State<LocalStorageViewerScreen> {
  late Future<_StorageSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<_StorageSnapshot> _loadSnapshot() async {
    final provider = context.read<TimeEntryProvider>();
    await provider.ensureInitialized();
    final projectsJson = provider.projects.map((project) => project.toJson()).toList();
    final entriesJson = provider.entries.map((entry) => entry.toJson()).toList();

    return _StorageSnapshot(
      prettyProjects: const JsonEncoder.withIndent('  ').convert(projectsJson),
      prettyEntries: const JsonEncoder.withIndent('  ').convert(entriesJson),
      projectCount: projectsJson.length,
      entryCount: entriesJson.length,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear all data?'),
          content: const Text(
            'This will remove all projects, tasks, and time entries. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear all'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final provider = context.read<TimeEntryProvider>();
      await provider.clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All local data cleared.')),
      );
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Storage Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh snapshot',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear all data',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: FutureBuilder<_StorageSnapshot>(
        future: _snapshotFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading storage: ${snapshot.error}'),
              ),
            );
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _StorageSummary(
                  projectCount: data.projectCount,
                  entryCount: data.entryCount,
                ),
                const SizedBox(height: 16),
                _JsonSection(
                  title: 'Projects JSON',
                  json: data.prettyProjects,
                ),
                const SizedBox(height: 16),
                _JsonSection(
                  title: 'Time Entries JSON',
                  json: data.prettyEntries,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StorageSnapshot {
  _StorageSnapshot({
    required this.prettyProjects,
    required this.prettyEntries,
    required this.projectCount,
    required this.entryCount,
  });

  final String prettyProjects;
  final String prettyEntries;
  final int projectCount;
  final int entryCount;
}

class _StorageSummary extends StatelessWidget {
  const _StorageSummary({
    required this.projectCount,
    required this.entryCount,
  });

  final int projectCount;
  final int entryCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text('Projects stored: $projectCount'),
            Text('Time entries stored: $entryCount'),
          ],
        ),
      ),
    );
  }
}

class _JsonSection extends StatelessWidget {
  const _JsonSection({
    required this.title,
    required this.json,
  });

  final String title;
  final String json;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surface,
              child: SelectableText(
                json,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
