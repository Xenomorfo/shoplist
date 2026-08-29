import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActionLoggerService {
  static const String _key = 'action_logs';
  final int limit;

  const ActionLoggerService({this.limit = 8});

  Future<void> addAction(String message) async {
    final prefs = await SharedPreferences.getInstance();
    var logs = prefs.getStringList(_key) ?? <String>[];

    final event = {
      'message': message.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    logs.add(jsonEncode(event));
    if (logs.length > limit) {
      logs = logs.sublist(logs.length - limit);
    }
    await prefs.setStringList(_key, logs);
  }

  Future<List<Map<String, dynamic>>> getActions() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList(_key) ?? <String>[];
    final actions = <Map<String, dynamic>>[];

    for (final raw in logs.reversed) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final timestamp = decoded['timestamp'];
        actions.add({
          'message': decoded['message']?.toString() ?? '',
          'timestamp': timestamp is int
              ? DateTime.fromMillisecondsSinceEpoch(timestamp)
              : DateTime.now(),
        });
      } catch (_) {
        // Ignora entradas antigas ou corrompidas sem impedir a abertura da app.
      }
    }

    return actions;
  }

  Future<void> clearActions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
