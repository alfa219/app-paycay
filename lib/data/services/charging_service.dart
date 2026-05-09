import 'dart:async';
import 'dart:math';

import '../../features/charging/presentation/providers/active_session_provider.dart';
import '../models/sensor_data_model.dart';
import 'rtdb_service.dart';
import 'user_service.dart';

typedef StopSessionResult = ({
  double balanceBefore,
  double balanceAfter,
  double finalEnergyKwh,
  int finalCost,
  int durationSeconds,
  String transactionId,
});

class ChargingService {
  ChargingService(this._rtdb, this._users, this._active) {
    final restored = _active.current;
    if (restored != null) {
      _startSimulator(
        restored.stationId,
        restored.startedAt,
        restored.accumulatedKwh,
      );
    }
  }

  final RtdbService _rtdb;
  final UserService _users;
  final ActiveSessionNotifier _active;

  Timer? _simTimer;

  Future<String> startSession({
    required String userId,
    required String stationId,
  }) async {
    final existing = _active.current;
    if (existing != null && existing.stationId != stationId) {
      throw StateError(
          'Anda memiliki sesi aktif di stasiun ${existing.stationId}. Selesaikan dulu sesi tersebut.');
    }
    if (existing != null && existing.stationId == stationId) {
      return existing.sessionId;
    }

    final sessionId = 'SES${DateTime.now().millisecondsSinceEpoch}';
    final startedAt = DateTime.now();

    await _active.set(ActiveSessionData(
      sessionId: sessionId,
      stationId: stationId,
      startedAt: startedAt,
      accumulatedKwh: 0,
    ));

    await _rtdb.sendCommand(
      stationId: stationId,
      action: 'start',
      userId: userId,
      sessionId: sessionId,
    );
    await _rtdb.setStationActiveSession(
      stationId: stationId,
      sessionId: sessionId,
    );

    _startSimulator(stationId, startedAt, 0);
    return sessionId;
  }

  Future<StopSessionResult> stopSession({
    required String userId,
    required String stationId,
    required String sessionId,
    required int tariff,
  }) async {
    _stopSimulator();

    final active = _active.current;
    final duration = active != null
        ? DateTime.now().difference(active.startedAt).inSeconds
        : 0;
    final finalEnergy = active?.accumulatedKwh ?? 0;
    final cost = (finalEnergy * tariff).round();

    await _rtdb.sendCommand(
      stationId: stationId,
      action: 'stop',
      userId: userId,
      sessionId: sessionId,
    );
    await _rtdb.setStationActiveSession(
      stationId: stationId,
      sessionId: null,
    );
    await _rtdb.clearSensor(stationId);

    final balance = await _users.deductBalance(
      uid: userId,
      amount: cost,
      transaction: {
        'type': 'charging',
        'label': 'Pengisian $stationId',
        'sub': '${finalEnergy.toStringAsFixed(2)} kWh',
        'sessionId': sessionId,
        'stationId': stationId,
        'energyKwh': finalEnergy,
        'durationSeconds': duration,
      },
    );

    await _active.clear();

    return (
      balanceBefore: balance.balanceBefore,
      balanceAfter: balance.balanceAfter,
      finalEnergyKwh: finalEnergy,
      finalCost: cost,
      durationSeconds: duration,
      transactionId: balance.transactionId,
    );
  }

  Future<void> abandonSession() async {
    _stopSimulator();
    final active = _active.current;
    if (active != null) {
      try {
        await _rtdb.clearSensor(active.stationId);
        await _rtdb.setStationActiveSession(
          stationId: active.stationId,
          sessionId: null,
        );
      } catch (_) {}
    }
    await _active.clear();
  }

  void _startSimulator(String stationId, DateTime startedAt, double initialKwh) {
    _simTimer?.cancel();
    double accumulated = initialKwh;

    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_active.current == null) {
        _stopSimulator();
        return;
      }
      final elapsed = DateTime.now().difference(startedAt).inSeconds.toDouble();
      final voltage = 220.5 + sin(elapsed / 4) * 0.8;
      final ramp = elapsed < 30 ? 1 + (elapsed / 30) * 4.2 : 5.2;
      final current = ramp + cos(elapsed / 5) * 0.15;
      final power = voltage * current;
      accumulated += (power / 1000) * (2 / 3600);

      try {
        await _rtdb.updateSensor(
          stationId,
          SensorDataModel(
            voltage: voltage,
            current: current,
            power: power,
            energyKwh: accumulated,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        await _active.updateAccumulated(accumulated);
      } catch (_) {
        // ignore intermittent write errors
      }
    });
  }

  void _stopSimulator() {
    _simTimer?.cancel();
    _simTimer = null;
  }
}
