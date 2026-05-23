import 'package:hive/hive.dart';

part 'activity.g.dart';

@HiveType(typeId: 0)
class Activity extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final ActivityType type;

  Activity({
    required this.id,
    required this.text,
    required this.createdAt,
    this.type = ActivityType.voice,
  });
}

@HiveType(typeId: 1)
enum ActivityType {
  @HiveField(0)
  voice,

  @HiveField(1)
  manual,
}
