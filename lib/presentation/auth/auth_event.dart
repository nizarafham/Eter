part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthAppStarted extends AuthEvent {}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;

  const AuthSignUpRequested({required this.email, required this.password, required this.username});

  @override
  List<Object?> get props => [email, password, username];
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {}

class _AuthUserChanged extends AuthEvent { // Internal event
  final User? user;
  const _AuthUserChanged(this.user);

   @override
  List<Object?> get props => [user];
}