import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/services/topup_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final topupServiceProvider = Provider<TopupService>((ref) {
  return TopupService(
    FirebaseFirestore.instance,
    ref.watch(userServiceProvider),
  );
});

final pendingTopupsCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(topupServiceProvider)
      .streamPendingRequests()
      .map((list) => list.length);
});

final pendingTopupsStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(topupServiceProvider).streamPendingRequests();
});
