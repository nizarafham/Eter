import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:chat_app/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException, AuthStateSubscription, User;

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
final AuthRepository _authRepository;
StreamSubscription<User?>? _userSubscription;
late final AuthStateSubscription _authStateSubscription;

AuthBloc(this._authRepository) : super(const AuthState.unknown()) {
on<AuthAppStarted>(_onAppStarted);
on<AuthSignUpRequested>(_onSignUpRequested);
on<AuthSignInRequested>(_onSignInRequested);
on<AuthSignOutRequested>(_onSignOutRequested);
on<_AuthUserChanged>(_onAuthUserChanged); // Listen to internal user changes

// Subscribe to Supabase auth state changes
_authStateSubscription = _authRepository.authStateChanges.listen((authState) {
   add(_AuthUserChanged(authState.session?.user));
});
}

void _onAppStarted(AuthAppStarted event, Emitter<AuthState> emit) {
final currentUser = _authRepository.getCurrentUser();
if (currentUser != null) {
emit(AuthState.authenticated(currentUser));
} else {
emit(const AuthState.unauthenticated());
}
}

Future<void> _onSignUpRequested(
AuthSignUpRequested event, Emitter<AuthState> emit) async {
emit(const AuthState.loading());
try {
final user = await _authRepository.signUp(event.email, event.password, event.username);
if (user != null) {
// Supabase handles email verification, so user might not be "active" yet
// For this app, we'll consider signup successful if user object is returned
// You might want a specific state for "awaiting confirmation"
emit(const AuthState.unauthenticated(message: 'Signup successful! Please check your email for confirmation.'));
} else {
emit(const AuthState.failure('Sign up failed. Please try again.'));
}
} on AuthException catch (e) {
emit(AuthState.failure(e.message));
} catch (e) {
emit(AuthState.failure('An unexpected error occurred: $e'));
}
}

Future<void> _onSignInRequested(
AuthSignInRequested event, Emitter<AuthState> emit) async {
emit(const AuthState.loading());
try {
final user = await _authRepository.signIn(event.email, event.password);
if (user != null) {
// User will be emitted by the _AuthUserChanged via the stream subscription
// emit(AuthState.authenticated(user)); // No need to emit here directly
} else {
// This case might not be hit if Supabase throws AuthException for failed login
emit(const AuthState.unauthenticated(message: 'Sign in failed. Invalid credentials.'));
}
} on AuthException catch (e) {
emit(AuthState.unauthenticated(message: e.message));
} catch (e) {
emit(AuthState.unauthenticated(message: 'An unexpected error occurred: $e'));
}
}

Future<void> _onSignOutRequested(
AuthSignOutRequested event, Emitter<AuthState> emit) async {
emit(const AuthState.loading());
try {
await _authRepository.signOut();
// State will change to unauthenticated via the _AuthUserChanged event
} catch (e) {
emit(AuthState.failure('Sign out failed: $e'));
}
}

void _onAuthUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
if (event.user != null) {
emit(AuthState.authenticated(event.user!));
} else {
emit(const AuthState.unauthenticated());
}
}

@override
Future<void> close() {
_userSubscription?.cancel();
_authStateSubscription.cancel();
return super.close();
}
}