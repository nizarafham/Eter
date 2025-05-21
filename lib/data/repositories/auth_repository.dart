import 'package:supabase_flutter/supabase_flutter.dart' show AuthState, User; // Show only necessary types

abstract class AuthRepository {
  Future<User?> signUp(String email, String password, String username);
  Future<User?> signIn(String email, String password);
  Future<void> signOut();
  User? getCurrentUser();
  Stream<AuthState> get authStateChanges;
}