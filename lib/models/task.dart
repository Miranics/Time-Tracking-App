class Task {
  final String id;
  final String projectId;
  final String name;
  final String? description;

  const Task({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
  });

  Task copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'description': description,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.projectId == projectId &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(id, projectId, name, description);
}
