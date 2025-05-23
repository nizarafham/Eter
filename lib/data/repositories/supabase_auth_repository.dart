// supabase_auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    await _client.auth.signUp(email: email, password: password, data: {
      'username': username,
    });
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> sendEmailVerification() async {
    // Supabase tidak punya email verification built-in untuk saat ini
    // Kamu bisa atur secara manual jika perlu
  }
}
