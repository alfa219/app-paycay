import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/transaction_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final userTransactionsStreamProvider =
    StreamProvider<List<TransactionModel>>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(const []);

  final query = FirebaseFirestore.instance
      .collection('transactions')
      .where('userId', isEqualTo: auth.uid)
      .orderBy('createdAt', descending: true)
      .limit(100);

  return query.snapshots().map(
        (snap) =>
            snap.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList(),
      );
});
