import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/topup_methods.dart';
import 'user_service.dart';

class TopupService {
  TopupService(this._db, this._users);
  final FirebaseFirestore _db;
  final UserService _users;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('topupRequests');

  Future<String> submitAutoTopup({
    required String userId,
    required int amount,
    required TopupMethod method,
  }) async {
    final result = await _users.addBalance(
      uid: userId,
      amount: amount,
      transaction: {
        'type': 'topup',
        'label': 'Top Up via ${method.name}',
        'sub': 'Otomatis',
        'methodId': method.id,
        'methodName': method.name,
      },
    );
    final reqRef = _requests.doc();
    await reqRef.set({
      'userId': userId,
      'amount': amount,
      'methodId': method.id,
      'methodName': method.name,
      'methodKind': method.kind,
      'fee': method.fee,
      'total': amount + method.fee,
      'status': 'approved',
      'autoApproved': true,
      'transactionId': result.transactionId,
      'requestedAt': FieldValue.serverTimestamp(),
      'processedAt': FieldValue.serverTimestamp(),
    });
    return reqRef.id;
  }

  Future<String> submitManualTopup({
    required String userId,
    required int amount,
    required TopupMethod method,
    String? note,
  }) async {
    final reqRef = _requests.doc();
    await reqRef.set({
      'userId': userId,
      'amount': amount,
      'methodId': method.id,
      'methodName': method.name,
      'methodKind': method.kind,
      'fee': method.fee,
      'total': amount + method.fee,
      'status': 'pending',
      'note': note ?? '',
      'requestedAt': FieldValue.serverTimestamp(),
    });
    return reqRef.id;
  }

  Stream<List<Map<String, dynamic>>> streamUserRequests(String userId) {
    return _requests
        .where('userId', isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList());
  }

  Stream<List<Map<String, dynamic>>> streamPendingRequests() {
    return _requests
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList());
  }

  Future<void> approveOne({
    required String requestId,
    required String adminUserId,
  }) async {
    final docRef = _requests.doc(requestId);
    final snap = await docRef.get();
    if (!snap.exists) throw StateError('Request tidak ditemukan.');
    final data = snap.data()!;
    if (data['status'] != 'pending') {
      throw StateError('Request sudah diproses.');
    }
    final userId = data['userId'] as String?;
    final amount = (data['amount'] as num?)?.toInt() ?? 0;
    final methodName = data['methodName'] as String? ?? '—';
    final methodId = data['methodId'] as String? ?? '';
    if (userId == null || amount <= 0) {
      throw StateError('Data request tidak valid.');
    }
    final result = await _users.addBalance(
      uid: userId,
      amount: amount,
      transaction: {
        'type': 'topup',
        'label': 'Top Up via $methodName',
        'sub': 'Disetujui Admin',
        'methodId': methodId,
        'methodName': methodName,
        'requestId': requestId,
      },
    );
    await docRef.update({
      'status': 'approved',
      'transactionId': result.transactionId,
      'processedAt': FieldValue.serverTimestamp(),
      'processedBy': adminUserId,
    });
  }

  Future<void> rejectOne({
    required String requestId,
    required String adminUserId,
    String? reason,
  }) async {
    final docRef = _requests.doc(requestId);
    final snap = await docRef.get();
    if (!snap.exists) throw StateError('Request tidak ditemukan.');
    if (snap.data()?['status'] != 'pending') {
      throw StateError('Request sudah diproses.');
    }
    await docRef.update({
      'status': 'rejected',
      'rejectionReason': reason ?? '',
      'processedAt': FieldValue.serverTimestamp(),
      'processedBy': adminUserId,
    });
  }

  Future<int> approveAllPending(String adminUserId) async {
    final snap = await _requests.where('status', isEqualTo: 'pending').get();
    int approved = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final userId = data['userId'] as String?;
      final amount = (data['amount'] as num?)?.toInt() ?? 0;
      final methodName = data['methodName'] as String? ?? '—';
      final methodId = data['methodId'] as String? ?? '';
      if (userId == null || amount <= 0) continue;
      try {
        final result = await _users.addBalance(
          uid: userId,
          amount: amount,
          transaction: {
            'type': 'topup',
            'label': 'Top Up via $methodName',
            'sub': 'Disetujui Admin',
            'methodId': methodId,
            'methodName': methodName,
            'requestId': doc.id,
          },
        );
        await doc.reference.update({
          'status': 'approved',
          'transactionId': result.transactionId,
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': adminUserId,
        });
        approved++;
      } catch (e) {
        await doc.reference.update({
          'status': 'failed',
          'errorMessage': e.toString(),
          'processedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    return approved;
  }
}
