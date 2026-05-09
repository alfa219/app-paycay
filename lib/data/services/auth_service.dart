import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this._auth);
  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  String mapErrorToIndonesian(Object error) {
    if (error is! FirebaseAuthException) return 'Terjadi kesalahan. Coba lagi.';
    switch (error.code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'user-disabled':
        return 'Akun Anda dinonaktifkan. Hubungi admin.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan masuk.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      default:
        return error.message ?? 'Terjadi kesalahan. Coba lagi.';
    }
  }
}
