class Activity {
  final String id;
  final String text;
  final DateTime createdAt;
  final ActivityType type;

  Activity({
    required this.id,
    required this.text,
    required this.createdAt,
    this.type = ActivityType.voice,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'type': type.name,
      };

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        type: ActivityType.values.byName(json['type'] as String),
      );
}

enum ActivityType { voice, manual }
