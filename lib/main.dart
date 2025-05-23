import 'package:chat_app/data/repositories/supabase_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'data/repositories/auth_repository.dart';
import 'presentation/auth/blocs/auth_bloc.dart';
import 'presentation/auth/pages/login_screen.dart';
import 'presentation/home/screens/home_screen.dart';
import 'presentation/chat/screens/chat_screen.dart';
import 'presentation/chat/screens/chat_detail_screen.dart';
import 'presentation/chat_list/screens/chat_list_screen.dart';
import 'presentation/friends/screens/add_friend_screen.dart';
import 'presentation/friends/screens/friends_management_screen.dart';
import 'presentation/notifications/screens/notifications_screen.dart';
import 'presentation/profile/screens/edit_profile_screen.dart';
import 'presentation/profile/screens/profile_screen.dart';
import 'presentation/groups/screens/create_group_screen.dart';
import 'presentation/groups/screens/group_info_screen.dart';
import 'presentation/status/screens/view_status_screen.dart';
import 'presentation/status/screens/status_feed_screen.dart';
import 'presentation/status/screens/create_status_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty ||
      supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    // Di aplikasi produksi, tangani error ini dengan lebih baik.
    // print("ERROR: SUPABASE_URL atau SUPABASE_ANON_KEY tidak ditemukan atau kosong di .env!");
    // Mungkin throw exception atau tampilkan UI error.
    throw Exception("SUPABASE_URL atau SUPABASE_ANON_KEY tidak valid di file .env");
  }

  // 2. Inisialisasi Supabase dengan nilai dari .env
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    // print("Error inisialisasi Supabase: $e");
    // Pertimbangkan untuk menampilkan pesan error kepada pengguna di sini.
    return; // Hentikan aplikasi jika Supabase gagal diinisialisasi.
  }

  final authRepository = SupabaseAuthRepository();

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(authRepository: authRepository)..add(AppStarted()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Chat App',
            theme: ThemeData(primarySwatch: Colors.blue),
            initialRoute: '/',
            routes: {
              '/': (context) {
                if (state.status == AuthStatus.authenticated) {
                  return const HomeScreen();
                } else {
                  return const LoginScreen();
                }
              },
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              // '/chat': (context) => const ChatScreen(),
              // '/chat/detail': (context) => const ChatDetailScreen(),
              '/chat/list': (context) => const ChatListScreen(),
              '/friend/add': (context) => const AddFriendScreen(),
              '/friend/manage': (context) => const FriendsManagementScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/profile': (context) => const ProfileScreen(),
              // '/profile/edit': (context) => const EditProfileScreen(),
              '/group/create': (context) => const CreateGroupScreen(),
              // '/group/info': (context) => const GroupInfoScreen(),
              '/status/feed': (context) => const StatusFeedScreen(),
              '/status/create': (context) => const CreateStatusScreen(),
              // '/status/progress': (context) => StoryProgressIndicator(),
            },
          );
        },
      ),
    );
  }
}
