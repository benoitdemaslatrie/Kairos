import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';

class ActivityStore extends ValueNotifier<List<Activity>> {
  static final ActivityStore instance = ActivityStore._();
  ActivityStore._() : super([]);

  static const _key = 'activities';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    value = raw
        .map((s) => Activity.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(Activity activity) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = [...value, activity];
    await prefs.setStringList(
      _key,
      updated.map((a) => jsonEncode(a.toJson())).toList(),
    );
    value = updated;
  }
}
