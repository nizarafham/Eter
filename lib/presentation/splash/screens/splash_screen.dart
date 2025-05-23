// lib/presentation/splash/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
// Ganti LoginScreen dengan AuthScreen jika Anda memiliki satu layar utama untuk autentikasi
import 'package:chat_app/presentation/auth/pages/login_screen.dart'; // atau .../screens/auth_screen.dart
import 'package:chat_app/presentation/home/screens/home_screen.dart'; // Layar utama setelah login

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        Future.delayed(const Duration(milliseconds: 1200), () { // Sesuaikan durasi jika perlu
          if (!mounted) return;

          if (state.status == AuthStatus.authenticated) {
            // Navigasi ke HomeScreen setelah login berhasil
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (state.status == AuthStatus.unauthenticated ||
                     state.status == AuthStatus.failure ||
                     state.status == AuthStatus.unknown) {
            // Navigasi ke LoginScreen (atau AuthScreen) jika belum login
            Navigator.of(context).pushReplacement(
              // Jika Anda memiliki AuthScreen yang menangani login dan signup, gunakan itu.
              // Jika LoginScreen adalah titik masuk khusus, ini tidak apa-apa.
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        });
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                "Memuat Aplikasi...",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}