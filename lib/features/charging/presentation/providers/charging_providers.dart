import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/sensor_data_model.dart';
import '../../../../data/models/transaction_model.dart';
import '../../../../data/services/charging_service.dart';
import '../../../../data/services/rtdb_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'active_session_provider.dart';

final rtdbServiceProvider = Provider<RtdbService>((ref) {
  return RtdbService(FirebaseDatabase.instance);
});

final chargingServiceProvider = Provider<ChargingService>((ref) {
  final rtdb = ref.watch(rtdbServiceProvider);
  final users = ref.watch(userServiceProvider);
  final active = ref.read(activeSessionProvider.notifier);
  return ChargingService(rtdb, users, active);
});

final sensorStreamProvider =
    StreamProvider.family<SensorDataModel, String>((ref, stationId) {
  return ref.watch(rtdbServiceProvider).streamSensor(stationId);
});

final transactionByIdProvider =
    FutureProvider.family<TransactionModel?, String>((ref, txId) async {
  final doc = await FirebaseFirestore.instance
      .collection('transactions')
      .doc(txId)
      .get();
  if (!doc.exists) return null;
  return TransactionModel.fromFirestore(doc);
});
