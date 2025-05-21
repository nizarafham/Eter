part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState._({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  const AuthState.unknown() : this._();

  const AuthState.loading() : this._(status: AuthStatus.loading);

  const AuthState.authenticated(User user)
      : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated({String? message})
      : this._(status: AuthStatus.unauthenticated, errorMessage: message);

  const AuthState.failure(String message)
      : this._(status: AuthStatus.failure, errorMessage: message);


  @override
  List<Object?> get props => [status, user, errorMessage];
}