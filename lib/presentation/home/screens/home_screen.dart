import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:chat_app/presentation/splash/screens/splash_screen.dart'; // Untuk navigasi saat logout
// Impor untuk layar-layar tab
import 'package:chat_app/presentation/chat_list/screens/chat_list_screen.dart'; // Anda perlu membuat layar ini
import 'package:chat_app/presentation/status/screens/status_feed_screen.dart';
import 'package:chat_app/presentation/notifications/screens/notifications_screen.dart';
// Impor untuk layar dari menu AppBar
import 'package:chat_app/presentation/profile/screens/profile_screen.dart';
import 'package:chat_app/presentation/friends/screens/add_friend_screen.dart';
import 'package:chat_app/presentation/groups/screens/create_group_screen.dart'; // Anda perlu membuat layar ini

// Enum untuk item menu AppBar agar lebih mudah dikelola
enum HomeMenuItem { settings, newGroup, addFriend }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Opsional: jika menggunakan rute bernama
  // static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Indeks default untuk tab "Chats"

  // Daftar widget untuk setiap tab di BottomNavigationBar
  // Pastikan Anda sudah membuat ChatListScreen, StatusFeedScreen, dan NotificationsScreen
  static const List<Widget> _widgetOptions = <Widget>[
    ChatListScreen(), // Tab 0: Daftar Chat
    StatusFeedScreen(), // Tab 1: Status
    NotificationsScreen(), // Tab 2: Notifikasi
  ];

  // Daftar judul AppBar untuk setiap tab
  static const List<String> _appBarTitles = <String>[
    'Chats',
    'Status',
    'Notifications',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleMenuSelection(HomeMenuItem item, BuildContext context) {
    switch (item) {
      case HomeMenuItem.settings:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
      case HomeMenuItem.newGroup:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
        // Jika CreateGroupScreen belum ada:
        // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur "Buat Grup Baru" akan datang!')));
        break;
      case HomeMenuItem.addFriend:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddFriendScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
        // Tombol aksi di AppBar
        actions: [
          // Menu tiga titik (overflow menu)
          PopupMenuButton<HomeMenuItem>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (item) => _handleMenuSelection(item, context),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<HomeMenuItem>>[
              const PopupMenuItem<HomeMenuItem>(
                value: HomeMenuItem.settings,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Pengaturan'),
                ),
              ),
              const PopupMenuItem<HomeMenuItem>(
                value: HomeMenuItem.newGroup,
                child: ListTile(
                  leading: Icon(Icons.group_add_outlined),
                  title: Text('Grup Baru'),
                ),
              ),
              const PopupMenuItem<HomeMenuItem>(
                value: HomeMenuItem.addFriend,
                child: ListTile(
                  leading: Icon(Icons.person_add_alt_1_outlined),
                  title: Text('Tambah Teman'),
                ),
              ),
            ],
          ),
          // Tombol Logout
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: "Logout",
            onPressed: () {
              // Tampilkan dialog konfirmasi sebelum logout
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Konfirmasi Logout"),
                  content: const Text("Apakah Anda yakin ingin keluar?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); // Tutup dialog
                        // Dispatch event logout ke AuthBloc
                        context.read<AuthBloc>().add(SignOutRequested());
                        // Listener AuthBloc di SplashScreen akan menangani navigasi ke AuthScreen
                        // Atau jika ingin langsung dari sini:
                        // Navigator.of(context).pushAndRemoveUntil(
                        //   MaterialPageRoute(builder: (_) => const SplashScreen()), // Kembali ke splash untuk redirect
                        //   (route) => false,
                        // );
                      },
                      child: Text("Logout", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      // Body akan menampilkan widget yang sesuai dengan tab yang dipilih
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_roll_outlined), // Atau Icons.explore_outlined / Icons.amp_stories_outlined
            activeIcon: Icon(Icons.camera_roll_rounded), // Atau Icons.explore / Icons.amp_stories
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_rounded),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Notifikasi',
            // Anda bisa menambahkan Badge di sini jika ada notifikasi yang belum dibaca
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Atau .shifting jika Anda suka efeknya
        // selectedItemColor: Theme.of(context).colorScheme.primary, // Sudah diatur di AppTheme
        // unselectedItemColor: Colors.grey,
        // showUnselectedLabels: false, // Opsional
      ),
    );
  }
}