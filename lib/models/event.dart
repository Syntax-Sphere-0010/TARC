enum RepeatType {
  none('None'),
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly'),
  custom('Custom');

  final String label;
  const RepeatType(this.label);

  static RepeatType fromString(String value) {
    return RepeatType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => RepeatType.none,
    );
  }
}

class EventReminder {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time; // e.g. "10:30 AM"
  final DateTime reminderDateTime;
  final String repeatType; // 'None', 'Daily', 'Weekly', 'Monthly', 'Yearly', 'Custom'
  final int repeatInterval; // for custom repeat: every N days
  final bool isCompleted;
  final int notificationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String priority; // 'high', 'medium', 'low'

  const EventReminder({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    required this.time,
    required this.reminderDateTime,
    this.repeatType = 'None',
    this.repeatInterval = 1,
    this.isCompleted = false,
    required this.notificationId,
    required this.createdAt,
    required this.updatedAt,
    this.priority = 'medium',
  });

  RepeatType get repeatTypeEnum => RepeatType.fromString(repeatType);

  bool get isOverdue {
    if (isCompleted) return false;
    return reminderDateTime.isBefore(DateTime.now());
  }

  EventReminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? time,
    DateTime? reminderDateTime,
    String? repeatType,
    int? repeatInterval,
    bool? isCompleted,
    int? notificationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? priority,
  }) {
    return EventReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      repeatType: repeatType ?? this.repeatType,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'reminderDateTime': reminderDateTime.toIso8601String(),
      'repeatType': repeatType,
      'repeatInterval': repeatInterval,
      'isCompleted': isCompleted ? 1 : 0,
      'notificationId': notificationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'priority': priority,
    };
  }

  factory EventReminder.fromMap(Map<String, dynamic> map) {
    return EventReminder(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String,
      reminderDateTime: DateTime.parse(map['reminderDateTime'] as String),
      repeatType: (map['repeatType'] as String?) ?? 'None',
      repeatInterval: (map['repeatInterval'] as int?) ?? 1,
      isCompleted: (map['isCompleted'] as int) == 1,
      notificationId: map['notificationId'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      priority: (map['priority'] as String?) ?? 'medium',
    );
  }
}
