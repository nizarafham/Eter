part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.username,
  });

  @override
  List<Object?> get props => [email, password, username];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class EmailVerificationRequested extends AuthEvent {}

// Event baru untuk menangani perubahan status otentikasi yang datang dari repository
class AuthStatusChanged extends AuthEvent {
  final AuthStatus status;
  final User? user;
  final String? message; // Opsional: untuk pesan internal jika diperlukan

  const AuthStatusChanged(this.status, {this.user, this.message});

  @override
  List<Object?> get props => [status, user, message];
}