import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'Override sharedPreferencesProvider in main() before runApp.');
});

class ActiveSessionData {
  final String sessionId;
  final String stationId;
  final DateTime startedAt;
  final double accumulatedKwh;

  const ActiveSessionData({
    required this.sessionId,
    required this.stationId,
    required this.startedAt,
    required this.accumulatedKwh,
  });

  ActiveSessionData copyWith({double? accumulatedKwh}) {
    return ActiveSessionData(
      sessionId: sessionId,
      stationId: stationId,
      startedAt: startedAt,
      accumulatedKwh: accumulatedKwh ?? this.accumulatedKwh,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'stationId': stationId,
        'startMillis': startedAt.millisecondsSinceEpoch,
        'accumulatedKwh': accumulatedKwh,
      };

  factory ActiveSessionData.fromJson(Map<String, dynamic> j) =>
      ActiveSessionData(
        sessionId: j['sessionId'] as String,
        stationId: j['stationId'] as String,
        startedAt:
            DateTime.fromMillisecondsSinceEpoch(j['startMillis'] as int),
        accumulatedKwh: (j['accumulatedKwh'] as num).toDouble(),
      );
}

class ActiveSessionNotifier extends StateNotifier<ActiveSessionData?> {
  ActiveSessionNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;
  static const _key = 'activeSession';

  ActiveSessionData? get current => state;

  static ActiveSessionData? _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return ActiveSessionData.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> set(ActiveSessionData data) async {
    state = data;
    await _prefs.setString(_key, jsonEncode(data.toJson()));
  }

  Future<void> updateAccumulated(double kwh) async {
    final cur = state;
    if (cur == null) return;
    final updated = cur.copyWith(accumulatedKwh: kwh);
    state = updated;
    await _prefs.setString(_key, jsonEncode(updated.toJson()));
  }

  Future<void> clear() async {
    state = null;
    await _prefs.remove(_key);
  }
}

final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, ActiveSessionData?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ActiveSessionNotifier(prefs);
});
