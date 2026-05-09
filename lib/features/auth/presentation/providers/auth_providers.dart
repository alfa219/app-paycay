import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/user_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(FirebaseFirestore.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final currentUserDataProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userServiceProvider).streamUser(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value(null),
  );
});
