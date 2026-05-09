import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/station_model.dart';

class StationService {
  StationService(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _stations =>
      _db.collection('stations');

  Stream<List<StationModel>> streamAll() {
    return _stations.orderBy(FieldPath.documentId).snapshots().map(
          (snap) =>
              snap.docs.map((doc) => StationModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<StationModel?> streamById(String id) {
    return _stations.doc(id).snapshots().map(
          (doc) => doc.exists ? StationModel.fromFirestore(doc) : null,
        );
  }

  Future<StationModel?> getOnce(String id) async {
    final doc = await _stations.doc(id).get();
    if (!doc.exists) return null;
    return StationModel.fromFirestore(doc);
  }

  Future<void> updateStatus(String id, String status) {
    return _stations.doc(id).update({'status': status});
  }

  Future<int> seedSampleStations() async {
    const samples = [
      {
        'id': 'STN001',
        'slot': 'Slot A',
        'address': 'Jl. Malioboro No.1, Yogyakarta',
        'distance': '0.3 km',
        'tariff': 2500,
        'status': 'available',
        'maxKw': 3.3,
        'posX': 38.0,
        'posY': 42.0,
      },
      {
        'id': 'STN002',
        'slot': 'Slot B',
        'address': 'Jl. Sudirman No.45, Yogyakarta',
        'distance': '0.5 km',
        'tariff': 2500,
        'status': 'charging',
        'maxKw': 3.3,
        'posX': 62.0,
        'posY': 35.0,
      },
      {
        'id': 'STN003',
        'slot': 'Slot C',
        'address': 'Jl. Solo Km 8, Yogyakarta',
        'distance': '1.2 km',
        'tariff': 3000,
        'status': 'offline',
        'maxKw': 7.0,
        'posX': 24.0,
        'posY': 68.0,
      },
      {
        'id': 'STN004',
        'slot': 'Slot D',
        'address': 'Jl. Kaliurang Km 5, Yogyakarta',
        'distance': '1.8 km',
        'tariff': 2500,
        'status': 'available',
        'maxKw': 3.3,
        'posX': 75.0,
        'posY': 60.0,
      },
      {
        'id': 'STN005',
        'slot': 'Slot E',
        'address': 'Jl. Affandi, Yogyakarta',
        'distance': '2.4 km',
        'tariff': 3000,
        'status': 'maintenance',
        'maxKw': 7.0,
        'posX': 50.0,
        'posY': 75.0,
      },
    ];

    final batch = _db.batch();
    int written = 0;
    for (final s in samples) {
      final id = s['id'] as String;
      final exists = (await _stations.doc(id).get()).exists;
      if (exists) continue;
      final data = Map<String, dynamic>.from(s)..remove('id');
      batch.set(_stations.doc(id), data);
      written++;
    }
    if (written > 0) await batch.commit();
    return written;
  }
}
