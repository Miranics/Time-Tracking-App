import 'package:collection/collection.dart';

import 'task.dart';

class Project {
  final String id;
  final String name;
  final String? description;
  final List<Task> tasks;

  Project({
    required this.id,
    required this.name,
    this.description,
    List<Task>? tasks,
  }) : tasks = List.unmodifiable(tasks ?? const []);

  int get taskCount => tasks.length;

  Project copyWith({
    String? id,
    String? name,
    String? description,
    List<Task>? tasks,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    final tasksJson = json['tasks'] as List<dynamic>?;
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      tasks: tasksJson == null
          ? const []
          : tasksJson
              .cast<Map<String, dynamic>>()
              .map(Task.fromJson)
              .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        const DeepCollectionEquality().equals(other.tasks, tasks);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        const DeepCollectionEquality().hash(tasks),
      );
}
