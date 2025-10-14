import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:localstorage/localstorage.dart';

import '../models/models.dart';

class TimeEntryProvider extends ChangeNotifier {
  TimeEntryProvider({LocalStorage? storage})
      : _storage = storage ?? LocalStorage('time_tracker.json');

  final LocalStorage _storage;
  final Random _random = Random();

  bool _isInitialized = false;
  bool _isLoading = false;

  List<Project> _projects = const [];
  List<TimeEntry> _entries = const [];

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  List<Project> get projects => List.unmodifiable(_projects);
  List<TimeEntry> get entries => List.unmodifiable(_entries);

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    await _storage.ready;
    await _loadFromStorage();

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> reload() async {
    _isLoading = true;
    notifyListeners();

    await _storage.ready;
    await _loadFromStorage();

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromStorage() async {
    final projectsRaw = _storage.getItem('projects');
    final entriesRaw = _storage.getItem('timeEntries');

    if (projectsRaw is List) {
      _projects = projectsRaw
          .cast<Map<String, dynamic>>()
          .map(Project.fromJson)
          .toList();
    } else {
      _projects = [];
    }

    if (entriesRaw is List) {
      _entries = entriesRaw
          .cast<Map<String, dynamic>>()
          .map(TimeEntry.fromJson)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } else {
      _entries = [];
    }

  }

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await initialize();
  }

  Future<void> addProject(Project project) async {
    await ensureInitialized();
    _projects = [..._projects, project];
    await _persistAndNotify();
  }

  Future<void> updateProject(Project project) async {
    await ensureInitialized();
    _projects = _projects
        .map((existing) => existing.id == project.id ? project : existing)
        .toList();
    await _persistAndNotify();
  }

  Future<void> deleteProject(String projectId) async {
    await ensureInitialized();
    _projects = _projects.where((proj) => proj.id != projectId).toList();
    _entries = _entries.where((entry) => entry.projectId != projectId).toList();
    await _persistAndNotify();
  }

  Project? getProjectById(String projectId) {
    return _projects.firstWhereOrNull((proj) => proj.id == projectId);
  }

  List<Task> tasksForProject(String projectId) {
    final project = getProjectById(projectId);
    return project?.tasks ?? const [];
  }

  Future<void> addTask(String projectId, Task task) async {
    await ensureInitialized();
    final project = getProjectById(projectId);
    if (project == null) {
      throw ArgumentError('Project not found for id $projectId');
    }
    final updatedProject = project.copyWith(
      tasks: [...project.tasks, task],
    );
    _projects = _projects
        .map((existing) => existing.id == projectId ? updatedProject : existing)
        .toList();
    await _persistAndNotify();
  }

  Future<void> updateTask(String projectId, Task task) async {
    await ensureInitialized();
    final project = getProjectById(projectId);
    if (project == null) {
      throw ArgumentError('Project not found for id $projectId');
    }
    final updatedTasks = project.tasks
        .map((existing) => existing.id == task.id ? task : existing)
        .toList();
    final updatedProject = project.copyWith(tasks: updatedTasks);
    _projects = _projects
        .map((existing) => existing.id == projectId ? updatedProject : existing)
        .toList();
    await _persistAndNotify();
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    await ensureInitialized();
    final project = getProjectById(projectId);
    if (project == null) {
      throw ArgumentError('Project not found for id $projectId');
    }
    final updatedTasks = project.tasks
        .where((task) => task.id != taskId)
        .toList(growable: false);
    final updatedProject = project.copyWith(tasks: updatedTasks);

    _projects = _projects
        .map((existing) => existing.id == projectId ? updatedProject : existing)
        .toList();

    _entries = _entries
        .map((entry) => entry.taskId == taskId
            ? entry.copyWith(taskId: null)
            : entry)
        .toList();

    await _persistAndNotify();
  }

  Future<void> addTimeEntry(TimeEntry entry) async {
    await ensureInitialized();
    _entries = [entry, ..._entries]..sort((a, b) => b.date.compareTo(a.date));
    await _persistAndNotify();
  }

  Future<void> updateTimeEntry(TimeEntry entry) async {
    await ensureInitialized();
    _entries = _entries
        .map((existing) => existing.id == entry.id ? entry : existing)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    await _persistAndNotify();
  }

  Future<void> deleteTimeEntry(String entryId) async {
    await ensureInitialized();
    _entries = _entries.where((entry) => entry.id != entryId).toList();
    await _persistAndNotify();
  }

  Map<String, List<TimeEntry>> get entriesGroupedByProject {
    return groupBy(_entries, (entry) => entry.projectId);
  }

  List<TimeEntry> entriesForProject(String projectId) {
    return _entries
        .where((entry) => entry.projectId == projectId)
        .toList(growable: false);
  }

  List<TimeEntry> entriesForTask(String projectId, String taskId) {
    return _entries
        .where(
          (entry) => entry.projectId == projectId && entry.taskId == taskId,
        )
        .toList(growable: false);
  }

  int totalMinutesForProject(String projectId) {
    return _entries
        .where((entry) => entry.projectId == projectId)
        .fold<int>(0, (total, entry) => total + entry.minutesSpent);
  }

  double totalHoursForProject(String projectId) {
    return totalMinutesForProject(projectId) / 60;
  }

  int totalMinutesForTask(String projectId, String taskId) {
    return _entries
        .where(
          (entry) => entry.projectId == projectId && entry.taskId == taskId,
        )
        .fold<int>(0, (total, entry) => total + entry.minutesSpent);
  }

  int totalMinutesWithoutTask(String projectId) {
    return _entries
        .where((entry) => entry.projectId == projectId && entry.taskId == null)
        .fold<int>(0, (total, entry) => total + entry.minutesSpent);
  }

  String generateId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final randomPortion = _random.nextInt(1 << 32).toUnsigned(32);
    return '$millis-$randomPortion';
  }

  Future<void> clearAll() async {
    await ensureInitialized();
    _projects = [];
    _entries = [];
    await _persistAndNotify();
  }

  Future<void> _persistAndNotify() async {
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.setItem(
      'projects',
      _projects.map((project) => project.toJson()).toList(),
    );
    await _storage.setItem(
      'timeEntries',
      _entries.map((entry) => entry.toJson()).toList(),
    );
  }
}
