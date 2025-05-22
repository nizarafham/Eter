import 'package:chat_app/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepositoryImpl(this._supabaseClient);

  @override
  User? get currentUser => _supabaseClient.auth.currentUser;

  @override
  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final AuthResponse response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    if (response.user == null) {
      throw Exception('Sign up failed: User is null');
    }
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final AuthResponse response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Sign in failed: User is null');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _supabaseClient.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _supabaseClient.auth.currentUser;
    
    // Asumsi emailConfirmedAt adalah String (ISO 8601)
    bool isEmailVerified = false;
    if (user != null && user.emailConfirmedAt != null) {
      try {
        final confirmedAt = DateTime.parse(user.emailConfirmedAt!);
        // Memeriksa apakah tanggal konfirmasi email ada dan setelah tanggal 'epoch' yang masuk akal
        // Misalnya, setelah 1 Januari 2000, untuk memastikan itu nilai yang valid.
        isEmailVerified = confirmedAt.isAfter(DateTime(2000));
      } catch (e) {
        // Handle parsing error, maybe log it
        print('Error parsing emailConfirmedAt: $e');
        isEmailVerified = false;
      }
    }

    if (user != null && !isEmailVerified) {
      await _supabaseClient.auth.resend(
        type: OtpType.email,
        email: user.email!,
      );
    } else if (user == null) {
      throw Exception('No current user to send email verification to.');
    }
  }
}