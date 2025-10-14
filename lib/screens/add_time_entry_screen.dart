import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/time_entry_provider.dart';
import 'project_task_management_screen.dart';

class AddTimeEntryScreen extends StatefulWidget {
  const AddTimeEntryScreen({super.key});

  static const routeName = '/add-time-entry';

  @override
  State<AddTimeEntryScreen> createState() => _AddTimeEntryScreenState();
}

class _AddTimeEntryScreenState extends State<AddTimeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedProjectId;
  String? _selectedTaskId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TimeEntryProvider>();
      if (!provider.isInitialized) {
        provider.initialize();
      }
      final projects = provider.projects;
      if (projects.isNotEmpty) {
        setState(() {
          _selectedProjectId = projects.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimeEntryProvider>();
    final projects = provider.projects;
    final projectTasks = _selectedProjectId == null
        ? const <Task>[]
        : provider.tasksForProject(_selectedProjectId!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Time Entry'),
      ),
      body: projects.isEmpty
          ? _NoProjectsMessage(onManageProjects: _openManageProjects)
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProjectDropdown(
                        projects: projects,
                        selectedProjectId: _selectedProjectId,
                        onChanged: (value) {
                          setState(() {
                            _selectedProjectId = value;
                            _selectedTaskId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _TaskDropdown(
                        tasks: projectTasks,
                        selectedTaskId: _selectedTaskId,
                        onChanged: (value) => setState(() {
                          _selectedTaskId = value;
                        }),
                      ),
                      const SizedBox(height: 16),
                      _DatePickerField(
                        selectedDate: _selectedDate,
                        onPickDate: _pickDate,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _hoursController,
                              decoration: const InputDecoration(
                                labelText: 'Hours',
                                hintText: '0',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }
                                final parsed = int.tryParse(value.trim());
                                if (parsed == null || parsed < 0) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minutesController,
                              decoration: const InputDecoration(
                                labelText: 'Minutes',
                                hintText: '0',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final trimmed = value?.trim() ?? '0';
                                final parsed = int.tryParse(trimmed);
                                if (parsed == null || parsed < 0 || parsed > 59) {
                                  return '0-59';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check),
                          onPressed: provider.isLoading ? null : _submit,
                          label: const Text('Save Entry'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project.')),
      );
      return;
    }

    final hours = int.tryParse(_hoursController.text.trim().isEmpty
            ? '0'
            : _hoursController.text.trim()) ??
        0;
    final minutes = int.tryParse(_minutesController.text.trim().isEmpty
            ? '0'
            : _minutesController.text.trim()) ??
        0;
    final totalMinutes = (hours * 60) + minutes;

    if (totalMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least 1 minute.')),
      );
      return;
    }

    final provider = context.read<TimeEntryProvider>();
    final entry = TimeEntry(
      id: provider.generateId(),
      projectId: _selectedProjectId!,
      taskId: _selectedTaskId,
      minutesSpent: totalMinutes,
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await provider.addTimeEntry(entry);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openManageProjects() async {
    await Navigator.of(context)
        .pushNamed(ProjectTaskManagementScreen.routeName);
    if (!mounted) return;
    final provider = context.read<TimeEntryProvider>();
    final projects = provider.projects;
    if (projects.isNotEmpty) {
      setState(() {
        _selectedProjectId = projects.first.id;
      });
    }
  }
}

class _ProjectDropdown extends StatelessWidget {
  const _ProjectDropdown({
    required this.projects,
    required this.selectedProjectId,
    required this.onChanged,
  });

  final List<Project> projects;
  final String? selectedProjectId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedProjectId,
      items: projects
          .map(
            (project) => DropdownMenuItem<String>(
              value: project.id,
              child: Text(project.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Project',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Select a project';
        }
        return null;
      },
    );
  }
}

class _TaskDropdown extends StatelessWidget {
  const _TaskDropdown({
    required this.tasks,
    required this.selectedTaskId,
    required this.onChanged,
  });

  final List<Task> tasks;
  final String? selectedTaskId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: selectedTaskId,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('General'),
        ),
        ...tasks.map(
          (task) => DropdownMenuItem<String?>(
            value: task.id,
            child: Text(task.name),
          ),
        ),
      ],
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Task',
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.selectedDate,
    required this.onPickDate,
  });

  final DateTime selectedDate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd();
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dateFormat.format(selectedDate)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}

class _NoProjectsMessage extends StatelessWidget {
  const _NoProjectsMessage({required this.onManageProjects});

  final VoidCallback onManageProjects;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No projects found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a project before adding time entries.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onManageProjects,
              child: const Text('Manage Projects'),
            ),
          ],
        ),
      ),
    );
  }
}
