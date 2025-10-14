import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/time_entry_provider.dart';

class ProjectTaskManagementScreen extends StatefulWidget {
  const ProjectTaskManagementScreen({super.key});

  static const routeName = '/project-task-management';

  @override
  State<ProjectTaskManagementScreen> createState() =>
      _ProjectTaskManagementScreenState();
}

class _ProjectTaskManagementScreenState
    extends State<ProjectTaskManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimeEntryProvider>();
    final projects = provider.projects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects & Tasks'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isLoading ? null : () => _showAddProjectDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Project'),
      ),
      body: provider.isLoading && !provider.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const _EmptyProjectsMessage()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _ProjectCard(
                      project: project,
                      onAddTask: () => _showAddTaskDialog(project),
                      onDelete: () => _confirmDeleteProject(project),
                      onDeleteTask: (task) => _confirmDeleteTask(project, task),
                    );
                  },
                ),
    );
  }

  Future<void> _showAddProjectDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Project'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Project name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a name';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration:
                      const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TimeEntryProvider>();
      final project = Project(
        id: provider.generateId(),
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );
      await provider.addProject(project);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project "${project.name}" created.')),
      );
    }
  }

  Future<void> _showAddTaskDialog(Project project) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add task to ${project.name}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Task name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a name';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration:
                      const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TimeEntryProvider>();
      final task = Task(
        id: provider.generateId(),
        projectId: project.id,
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );
      await provider.addTask(project.id, task);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task "${task.name}" added.')),
      );
    }
  }

  Future<void> _confirmDeleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${project.name}?'),
          content: const Text(
            'Deleting a project will remove its tasks and time entries. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TimeEntryProvider>();
      await provider.deleteProject(project.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project "${project.name}" deleted.')),
      );
    }
  }

  Future<void> _confirmDeleteTask(Project project, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove task "${task.name}"?'),
          content: const Text(
            'Time entries linked to this task will be retained but will move to the General bucket.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TimeEntryProvider>();
      await provider.deleteTask(project.id, task.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task "${task.name}" removed.')),
      );
    }
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onAddTask,
    required this.onDelete,
    required this.onDeleteTask,
  });

  final Project project;
  final VoidCallback onAddTask;
  final VoidCallback onDelete;
  final ValueChanged<Task> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final taskCount = project.taskCount;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(project.name),
        subtitle: Text(
          project.description == null
              ? '$taskCount task${taskCount == 1 ? '' : 's'}'
              : '${project.description} • $taskCount task${taskCount == 1 ? '' : 's'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_task),
              tooltip: 'Add task',
              onPressed: onAddTask,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete project',
              onPressed: onDelete,
            ),
          ],
        ),
        children: [
          if (project.tasks.isEmpty)
            const ListTile(
              title: Text('No tasks yet. Add one to organize your time.'),
            )
          else
            ...project.tasks.map(
              (task) => ListTile(
                title: Text(task.name),
                subtitle: task.description == null
                    ? null
                    : Text(task.description!),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onDeleteTask(task),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EmptyProjectsMessage extends StatelessWidget {
  const _EmptyProjectsMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.folder_open, size: 72),
            SizedBox(height: 16),
            Text(
              'No projects yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first project to start organizing tasks.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
