import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TransactionModel {
  final String id;
  final String type;
  final String label;
  final String date;
  final String sub;
  final int amount;
  final String status;
  final String? sessionId;
  final String? stationId;
  final double? energyKwh;
  final int? durationSeconds;
  final double? balanceBefore;
  final double? balanceAfter;
  final DateTime? createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.label,
    required this.date,
    required this.sub,
    required this.amount,
    this.status = 'success',
    this.sessionId,
    this.stationId,
    this.energyKwh,
    this.durationSeconds,
    this.balanceBefore,
    this.balanceAfter,
    this.createdAt,
  });

  String get monthGroup {
    if (createdAt != null) {
      return DateFormat('MMMM yyyy', 'id_ID').format(createdAt!);
    }
    final parts = date.split(' ');
    if (parts.length >= 3) return '${parts[1]} ${parts[2].replaceAll(',', '')}';
    return '';
  }

  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ts = data['createdAt'];
    final created = ts is Timestamp ? ts.toDate() : null;
    final dateStr = created != null
        ? DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(created)
        : '';
    return TransactionModel(
      id: doc.id,
      type: data['type'] as String? ?? 'charging',
      label: data['label'] as String? ?? 'Transaksi',
      date: dateStr,
      sub: data['sub'] as String? ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'success',
      sessionId: data['sessionId'] as String?,
      stationId: data['stationId'] as String?,
      energyKwh: (data['energyKwh'] as num?)?.toDouble(),
      durationSeconds: (data['durationSeconds'] as num?)?.toInt(),
      balanceBefore: (data['balanceBefore'] as num?)?.toDouble(),
      balanceAfter: (data['balanceAfter'] as num?)?.toDouble(),
      createdAt: created,
    );
  }
}
