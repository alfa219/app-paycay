import 'package:firebase_database/firebase_database.dart';

import '../models/sensor_data_model.dart';

class RtdbService {
  RtdbService(this._db);
  final FirebaseDatabase _db;

  DatabaseReference _sensorRef(String stationId) =>
      _db.ref('stations/$stationId/sensor');

  DatabaseReference _commandRef(String stationId) =>
      _db.ref('commands/$stationId');

  DatabaseReference _stationRef(String stationId) =>
      _db.ref('stations/$stationId');

  Stream<SensorDataModel> streamSensor(String stationId) {
    return _sensorRef(stationId).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return SensorDataModel.fromMap(value);
      }
      return SensorDataModel.empty;
    });
  }

  Future<void> updateSensor(String stationId, SensorDataModel data) {
    return _sensorRef(stationId).set(data.toMap());
  }

  Future<void> clearSensor(String stationId) {
    return _sensorRef(stationId).remove();
  }

  Future<void> sendCommand({
    required String stationId,
    required String action,
    required String userId,
    required String sessionId,
  }) {
    return _commandRef(stationId).set({
      'action': action,
      'userId': userId,
      'sessionId': sessionId,
      'timestamp': ServerValue.timestamp,
    });
  }

  Future<void> setStationActiveSession({
    required String stationId,
    required String? sessionId,
  }) {
    return _stationRef(stationId).update({
      'currentSession': sessionId,
      'lastSeen': ServerValue.timestamp,
    });
  }
}
