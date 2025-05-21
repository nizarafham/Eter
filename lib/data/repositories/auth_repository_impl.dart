import 'package:chat_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:chat_app/data/repositories/auth_repository.dart'; // Assuming interface is in a separate file
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState, User;


class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<User?> signUp(String email, String password, String username) async {
    try {
      return await _remoteDataSource.signUp(email, password, username);
    } catch (e) {
      // Handle exceptions, log, or rethrow custom exceptions
      // print("AuthRepository SignUp Error: $e");
      rethrow; // Or return an error state/result type
    }
  }

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      return await _remoteDataSource.signIn(email, password);
    } catch (e) {
      // print("AuthRepository SignIn Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } catch (e) {
      // print("AuthRepository SignOut Error: $e");
      rethrow;
    }
  }

  @override
  User? getCurrentUser() {
    return _remoteDataSource.getCurrentUser();
  }

  @override
  Stream<AuthState> get authStateChanges => _remoteDataSource.authStateChanges;
}