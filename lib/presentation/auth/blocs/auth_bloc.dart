import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:chat_app/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter show AuthException, AuthState, AuthChangeEvent;


part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<supabase_flutter.AuthState>? _authStateSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super( AuthState.unknown()) {
    on<AppStarted>(_onAppStarted);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<EmailVerificationRequested>(_onEmailVerificationRequested);
    on<AuthStatusChanged>(_onAuthStatusChanged);

    _authStateSubscription = _authRepository.authStateChanges.listen((supabase_flutter.AuthState supabaseAuthState) {
      switch (supabaseAuthState.event) {
        case supabase_flutter.AuthChangeEvent.signedIn:
          add(AuthStatusChanged(AuthStatus.authenticated, user: supabaseAuthState.session?.user));
          break;
        case supabase_flutter.AuthChangeEvent.signedOut:
          add( AuthStatusChanged(AuthStatus.unauthenticated));
          break;
        case supabase_flutter.AuthChangeEvent.tokenRefreshed:
        case supabase_flutter.AuthChangeEvent.userUpdated:
          // Jika pengguna diperbarui atau token direfresh, statusnya tetap authenticated
          add(AuthStatusChanged(AuthStatus.authenticated, user: supabaseAuthState.session?.user));
          break;
        case supabase_flutter.AuthChangeEvent.userDeleted:
          add( AuthStatusChanged(AuthStatus.unauthenticated));
          break;
        case supabase_flutter.AuthChangeEvent.passwordRecovery:
          // Event ini mungkin tidak selalu berarti status otentikasi berubah,
          // tapi bisa jadi indikator untuk UI agar menampilkan pesan.
          // Untuk saat ini, kita tidak mengubah status otentikasi di sini.
          break;
        // Perbaikan: Hapus case mfaChallenge dan mfaRequired yang tidak ada
        // case supabase_flutter.AuthChangeEvent.mfaChallenge:
        // case supabase_flutter.AuthChangeEvent.mfaRequired:
        //   break;
        case supabase_flutter.AuthChangeEvent.initialSession:
          // TODO: Handle this case.
          throw UnimplementedError();
        case supabase_flutter.AuthChangeEvent.mfaChallengeVerified:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    });
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      emit(AuthState.authenticated(currentUser)); // Hapus ''
    } else {
      emit( AuthState.unauthenticated());
    }
  }

  Future<void> _onSignUpRequested(
      SignUpRequested event, Emitter<AuthState> emit) async {
    emit( AuthState.loading());
    try {
      await _authRepository.signUp(
        email: event.email,
        password: event.password,
        username: event.username,
      );
      emit(AuthState.unauthenticated( // Hapus ''
          message: 'Pendaftaran berhasil! Silakan cek email Anda untuk verifikasi.'));
    } on supabase_flutter.AuthException catch (e) {
      emit(AuthState.failure(e.message)); // Hapus ''
    } catch (e) {
      emit(AuthState.failure('Gagal mendaftar: ${e.toString()}')); // Hapus ''
    }
  }

  Future<void> _onSignInRequested(
      SignInRequested event, Emitter<AuthState> emit) async {
    emit( AuthState.loading());
    try {
      await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
    } on supabase_flutter.AuthException catch (e) {
      emit(AuthState.failure(e.message)); // Hapus ''
    } catch (e) {
      emit(AuthState.failure('Gagal masuk: ${e.toString()}')); // Hapus ''
    }
  }

  Future<void> _onSignOutRequested(
      SignOutRequested event, Emitter<AuthState> emit) async {
    emit( AuthState.loading());
    try {
      await _authRepository.signOut();
    } on supabase_flutter.AuthException catch (e) {
       emit(AuthState.failure(e.message)); // Hapus ''
    } catch (e) {
      emit(AuthState.failure('Gagal keluar: ${e.toString()}')); // Hapus ''
    }
  }

  Future<void> _onPasswordResetRequested(
      PasswordResetRequested event, Emitter<AuthState> emit) async {
    emit( AuthState.loading());
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(AuthState.unauthenticated( // Hapus ''
          message: 'Email reset kata sandi telah dikirim.'));
    } on supabase_flutter.AuthException catch (e) {
      emit(AuthState.failure(e.message)); // Hapus ''
    } catch (e) {
      emit( AuthState.failure('Gagal mengirim email reset kata sandi.'));
    }
  }

  Future<void> _onEmailVerificationRequested(
      EmailVerificationRequested event, Emitter<AuthState> emit) async {
    emit( AuthState.loading());
    try {
      await _authRepository.sendEmailVerification();
      emit(AuthState.unauthenticated( // Hapus ''
          message: 'Email verifikasi telah dikirim.'));
    } on supabase_flutter.AuthException catch (e) {
      emit(AuthState.failure(e.message)); // Hapus ''
    } catch (e) {
      emit( AuthState.failure('Gagal mengirim email verifikasi.'));
    }
  }

  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    switch (event.status) {
      case AuthStatus.authenticated:
        if (event.user != null) {
          emit(AuthState.authenticated(event.user!)); // Hapus ''
        } else {
          emit( AuthState.unauthenticated(message: 'Sesi tidak valid.'));
        }
        break;
      case AuthStatus.unauthenticated:
        emit( AuthState.unauthenticated());
        break;
      case AuthStatus.unknown:
      case AuthStatus.loading:
      case AuthStatus.failure:
        // Case ini tidak menyebabkan perubahan state eksplisit di sini,
        // karena AuthStatusChanged lebih fokus pada status authenticated/unauthenticated
        // yang datang dari listener Supabase.
        break;
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}