import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_app/core/di/service_locator.dart' as di;
import 'package:chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:chat_app/presentation/screens/splash_screen.dart';
import 'package:chat_app/core/theme/app_theme.dart';
import 'package:chat_app/presentation/blocs/simple_bloc_observer.dart'; // Optional: for BLoC logging

// Supabase client instance
late final SupabaseClient supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  supabase = Supabase.instance.client;

  // Initialize dependency injection
  await di.init();

  // Optional: Set up BLoC observer for debugging
  Bloc.observer = SimpleBlocObserver();

  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(AuthAppStarted()),
        ),
        // Add other global BLoCs here if needed, or provide them locally
      ],
      child: MaterialApp(
        title: 'Eter Chat',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}