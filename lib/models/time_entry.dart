class TimeEntry {
  final String id;
  final String projectId;
  final String? taskId;
  final int minutesSpent;
  final DateTime date;
  final String? notes;

  const TimeEntry({
    required this.id,
    required this.projectId,
    this.taskId,
    required this.minutesSpent,
    required this.date,
    this.notes,
  }) : assert(minutesSpent >= 0, 'minutesSpent must be >= 0');

  Duration get duration => Duration(minutes: minutesSpent);

  double get hours => minutesSpent / 60;

  bool get hasNotes => (notes ?? '').trim().isNotEmpty;

  String get formattedDuration {
    final hoursPortion = minutesSpent ~/ 60;
    final minutesPortion = minutesSpent % 60;
    if (hoursPortion == 0) {
      return '${minutesPortion}m';
    }
    return minutesPortion == 0
        ? '${hoursPortion}h'
        : '${hoursPortion}h ${minutesPortion}m';
  }

  TimeEntry copyWith({
    String? id,
    String? projectId,
    String? taskId,
    int? minutesSpent,
    DateTime? date,
    String? notes,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      minutesSpent: minutesSpent ?? this.minutesSpent,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'taskId': taskId,
      'minutesSpent': minutesSpent,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    return TimeEntry(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      taskId: json['taskId'] as String?,
      minutesSpent: json['minutesSpent'] as int,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeEntry &&
        other.id == id &&
        other.projectId == projectId &&
        other.taskId == taskId &&
        other.minutesSpent == minutesSpent &&
        other.date == date &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(id, projectId, taskId, minutesSpent, date, notes);
}
