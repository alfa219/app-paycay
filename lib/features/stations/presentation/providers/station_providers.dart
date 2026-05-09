import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/station_model.dart';
import '../../../../data/services/station_service.dart';

final stationServiceProvider = Provider<StationService>((ref) {
  return StationService(FirebaseFirestore.instance);
});

final stationsStreamProvider = StreamProvider<List<StationModel>>((ref) {
  return ref.watch(stationServiceProvider).streamAll();
});

final stationByIdProvider =
    StreamProvider.family<StationModel?, String>((ref, id) {
  return ref.watch(stationServiceProvider).streamById(id);
});
