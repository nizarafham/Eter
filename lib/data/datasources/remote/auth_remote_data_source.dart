import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<User?> signUp(String email, String password, String username);
  Future<User?> signIn(String email, String password);
  Future<void> signOut();
  User? getCurrentUser();
  Stream<AuthState> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabaseClient;

  AuthRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<User?> signUp(String email, String password, String username) async {
    final response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {'username': username}, // This goes to raw_user_meta_data by default
    );
    // After signup, you might want to insert into a public 'profiles' table
    if (response.user != null) {
      await _supabaseClient.from('profiles').insert({
        'id': response.user!.id,
        'username': username,
        'email': email, // Storing email in profiles can be useful
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return response.user;
  }

  @override
  Future<User?> signIn(String email, String password) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  @override
  User? getCurrentUser() {
    return _supabaseClient.auth.currentUser;
  }

  @override
  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;
}