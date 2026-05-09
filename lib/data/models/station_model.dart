import 'package:cloud_firestore/cloud_firestore.dart';

class StationModel {
  final String id;
  final String slot;
  final String address;
  final String distance;
  final int tariff;
  final String status;
  final double maxKw;
  final double posX;
  final double posY;

  const StationModel({
    required this.id,
    required this.slot,
    required this.address,
    required this.distance,
    required this.tariff,
    required this.status,
    required this.maxKw,
    required this.posX,
    required this.posY,
  });

  factory StationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return StationModel(
      id: doc.id,
      slot: (data['slot'] as String? ?? '').trim(),
      address: (data['address'] as String? ?? '').trim(),
      distance: (data['distance'] as String? ?? '—').trim(),
      tariff: (data['tariff'] as num?)?.toInt() ?? 0,
      status: (data['status'] as String? ?? 'offline').trim().toLowerCase(),
      maxKw: (data['maxKw'] as num?)?.toDouble() ?? 0,
      posX: (data['posX'] as num?)?.toDouble() ?? 50,
      posY: (data['posY'] as num?)?.toDouble() ?? 50,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'slot': slot,
        'address': address,
        'distance': distance,
        'tariff': tariff,
        'status': status,
        'maxKw': maxKw,
        'posX': posX,
        'posY': posY,
      };
}
