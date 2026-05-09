import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  UserService(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Future<void> createUserDoc({
    required String uid,
    required String name,
    required String email,
  }) {
    final firstName = name.trim().isEmpty ? '' : name.trim().split(' ').first;
    return _users.doc(uid).set({
      'name': name.trim(),
      'firstName': firstName,
      'email': email.trim(),
      'phone': '',
      'balance': 0,
      'rfid': '',
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<UserModel?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<UserModel?> getUserOnce(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<({double balanceBefore, double balanceAfter, String transactionId})>
      addBalance({
    required String uid,
    required int amount,
    required Map<String, dynamic> transaction,
  }) async {
    return _db.runTransaction((tx) async {
      final userRef = _users.doc(uid);
      final txRef = _db.collection('transactions').doc();
      final snap = await tx.get(userRef);
      if (!snap.exists) {
        throw StateError('User document tidak ditemukan.');
      }
      final before = (snap.data()?['balance'] as num?)?.toDouble() ?? 0;
      final after = before + amount;
      tx.update(userRef, {'balance': after});
      tx.set(
        txRef,
        {
          ...transaction,
          'userId': uid,
          'amount': amount,
          'status': 'success',
          'balanceBefore': before,
          'balanceAfter': after,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      return (
        balanceBefore: before,
        balanceAfter: after,
        transactionId: txRef.id,
      );
    });
  }

  Future<({double balanceBefore, double balanceAfter, String transactionId})>
      deductBalance({
    required String uid,
    required int amount,
    required Map<String, dynamic> transaction,
  }) async {
    return _db.runTransaction((tx) async {
      final userRef = _users.doc(uid);
      final txRef = _db.collection('transactions').doc();
      final snap = await tx.get(userRef);
      if (!snap.exists) {
        throw StateError('User document tidak ditemukan.');
      }
      final before = (snap.data()?['balance'] as num?)?.toDouble() ?? 0;
      if (before < amount) {
        throw StateError('Saldo tidak cukup.');
      }
      final after = before - amount;
      tx.update(userRef, {'balance': after});
      tx.set(
        txRef,
        {
          ...transaction,
          'userId': uid,
          'amount': -amount,
          'status': 'success',
          'balanceBefore': before,
          'balanceAfter': after,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
      return (
        balanceBefore: before,
        balanceAfter: after,
        transactionId: txRef.id,
      );
    });
  }
}
