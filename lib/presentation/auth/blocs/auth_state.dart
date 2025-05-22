part of 'auth_bloc.dart';

enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage; // Untuk error saat operasi (sign up, sign in)
  final String? message;      // Untuk pesan informatif (misal: "cek email verifikasi")

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.message,
  });

  factory AuthState.unknown() => const AuthState(status: AuthStatus.unknown);

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);

  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  factory AuthState.unauthenticated({String? message}) => AuthState(
        status: AuthStatus.unauthenticated,
        message: message,
      );

  factory AuthState.failure(String errorMessage) => AuthState(
        status: AuthStatus.failure,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, user, errorMessage, message];
}