import 'package:chat_app/data/models/status_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/presentation/status/blocs/status_bloc.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:chat_app/core/di/service_locator.dart';
import 'package:chat_app/presentation/status/screens/create_status_screen.dart';
import 'package:chat_app/presentation/status/screens/view_status_screen.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:timeago/timeago.dart' as timeago; // Untuk format waktu relatif

class StatusFeedScreen extends StatelessWidget {
  const StatusFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthBloc>().state.user?.id;
    final authUser = context.watch<AuthBloc>().state.user;

    if (currentUserId == null || authUser == null) {
      return const Center(child: Text("User not authenticated."));
    }

    // Konversi Supabase User ke UserModel aplikasi Anda
    final appCurrentUserModel = UserModel(
      id: authUser.id,
      username: authUser.userMetadata?['username'] ?? 'You',
      avatarUrl: authUser.userMetadata?['avatar_url'],
      createdAt: DateTime.parse(authUser.createdAt!),
      email: authUser.email
    );

    return BlocProvider(
      create: (context) => sl<StatusBloc>(param1: currentUserId) // param1 adalah currentUserId
        ..add(LoadStatuses()),
      child: Scaffold(
        body: BlocConsumer<StatusBloc, StatusState>(
          listener: (context, state) {
            if (state is StatusLoaded && state.successMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.successMessage!), backgroundColor: Colors.green));
              // Hapus pesan setelah ditampilkan
              context.read<StatusBloc>().emit(state.copyWith(clearSuccessMessage: true));
            } else if (state is StatusError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
            }
          },
          builder: (context, state) {
            if (state is StatusInitial || (state is StatusLoading && state.currentGroupedStatuses.isEmpty && state.currentUserStatusGroup == null)) {
              return const Center(child: CircularProgressIndicator());
            }

            List<GroupedStatus> friendStatusGroups = [];
            GroupedStatus? currentUserStatusGroup;

            // Ambil data dari state saat ini
            if (state is StatusLoaded) {
              friendStatusGroups = state.groupedStatuses;
              currentUserStatusGroup = state.currentUserStatusGroup;
            } else if (state is StatusLoading) { // Tampilkan data lama saat loading
              friendStatusGroups = state.currentGroupedStatuses;
              currentUserStatusGroup = state.currentUserStatusGroup;
            } else if (state is StatusError) { // Tampilkan data lama saat error
              friendStatusGroups = state.currentGroupedStatuses;
              currentUserStatusGroup = state.currentUserStatusGroup;
            } else if (state is StatusPosting) { // Tampilkan data lama saat posting
              friendStatusGroups = state.currentGroupedStatuses;
              currentUserStatusGroup = state.currentUserStatusGroup;
            }

            return RefreshIndicator(
              onRefresh: () async {
                 context.read<StatusBloc>().add(LoadStatuses());
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildMyStatusTile(context, appCurrentUserModel, currentUserStatusGroup),
                  ),
                  if (friendStatusGroups.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          "Recent updates",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 14),
                        ),
                      ),
                    ),
                  if (friendStatusGroups.isEmpty && (currentUserStatusGroup == null || currentUserStatusGroup.statuses.isEmpty))
                     SliverFillRemaining( // Pesan jika tidak ada status sama sekali
                        hasScrollBody: false, // Penting jika konten tidak cukup untuk scroll
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Icon(Icons.camera_roll_outlined, size: 70, color: Colors.grey[500]),
                                  const SizedBox(height:16),
                                  const Text("No status updates yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                                  const SizedBox(height:8),
                                  Text("Post your own or see updates from friends here.", style: TextStyle(fontSize: 15, color: Colors.grey[600]), textAlign: TextAlign.center,),
                              ],
                            ),
                          )
                        ),
                      )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final group = friendStatusGroups[index];
                          return _buildFriendStatusTile(context, group);
                        },
                        childCount: friendStatusGroups.length,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateStatusScreen()))
              .then((success) { // Optional: Refresh status setelah kembali dari layar buat status jika ada postingan baru
                  if (success == true) { // CreateStatusScreen bisa mengembalikan true jika posting berhasil
                     final currentUserId = context.read<AuthBloc>().state.user?.id;
                     if (currentUserId != null) {
                       context.read<StatusBloc>().add(LoadStatuses());
                     }
                  }
              });
          },
          tooltip: "Add Status",
          child: const Icon(Icons.camera_alt_outlined),
        ),
      ),
    );
  }

  Widget _buildMyStatusTile(BuildContext context, UserModel currentUser, GroupedStatus? myStatusGroup) {
    bool hasStatus = myStatusGroup != null && myStatusGroup.statuses.isNotEmpty;
    String subtitle = hasStatus ? "Tap to view your status" : "Tap to add status update";
    if (hasStatus) {
       // Menampilkan waktu status terakhir atau jumlah status
       subtitle = "${myStatusGroup!.statuses.length} updates • ${timeago.format(myStatusGroup.statuses.last.createdAt.toLocal())}";
    }

    return Material(
      color: Theme.of(context).cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 30,
              // Warna border menandakan apakah semua status sudah dilihat atau ada yang belum
              backgroundColor: hasStatus ? (myStatusGroup!.allViewed ? Colors.grey.shade400 : Theme.of(context).primaryColor) : Colors.grey.shade300,
              child: CircleAvatar(
                radius: hasStatus ? 27 : 30,
                backgroundImage: hasStatus && myStatusGroup!.statuses.first.type == StatusType.image && myStatusGroup.statuses.first.mediaUrl != null
                    ? NetworkImage(myStatusGroup.statuses.first.mediaUrl!) // Pratinjau status gambar pertama
                    : (currentUser.avatarUrl != null ? NetworkImage(currentUser.avatarUrl!) : null),
                child: (hasStatus && myStatusGroup!.statuses.first.type == StatusType.image && myStatusGroup.statuses.first.mediaUrl != null) || currentUser.avatarUrl != null
                    ? null
                    : Icon(Icons.person, color: Colors.grey[700], size: 30),
                backgroundColor: hasStatus && myStatusGroup!.statuses.first.type == StatusType.text
                    ? _parseColor(myStatusGroup.statuses.first.backgroundColor) // Latar belakang status teks pertama
                    : Colors.grey[200],
              ),
            ),
            if (!hasStatus) // Tombol '+' jika belum ada status
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).cardColor, width: 2)
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              )
          ],
        ),
        title: const Text("My Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        onTap: () {
          if (hasStatus) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ViewStatusScreen(
                    userStatuses: myStatusGroup!.statuses, // Status diurutkan dari terlama ke terbaru
                    user: myStatusGroup.user, // Seharusnya currentUserModel
                    initialStatusIndex: 0,
                   )));
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateStatusScreen()))
             .then((success) {
                  if (success == true) {
                     final currentUserId = context.read<AuthBloc>().state.user?.id;
                     if (currentUserId != null) {
                       context.read<StatusBloc>().add(LoadStatuses());
                     }
                  }
              });
          }
        },
      ),
    );
  }

  Widget _buildFriendStatusTile(BuildContext context, GroupedStatus friendGroup) {
     final String lastStatusTime = friendGroup.statuses.isNotEmpty
        ? timeago.format(friendGroup.statuses.last.createdAt.toLocal()) // Waktu status terakhir
        : "No updates";

    return Material(
       color: Theme.of(context).cardColor,
       child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: friendGroup.allViewed ? Colors.grey.shade400 : Theme.of(context).primaryColor,
          child: CircleAvatar(
            radius: 27,
             backgroundImage: friendGroup.statuses.first.type == StatusType.image && friendGroup.statuses.first.mediaUrl != null
                ? NetworkImage(friendGroup.statuses.first.mediaUrl!)
                : (friendGroup.user.avatarUrl != null ? NetworkImage(friendGroup.user.avatarUrl!) : null),
            child: (friendGroup.statuses.first.type == StatusType.image && friendGroup.statuses.first.mediaUrl != null) || friendGroup.user.avatarUrl != null
                ? null
                : Text(friendGroup.user.username.isNotEmpty ? friendGroup.user.username[0].toUpperCase() : "?", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            backgroundColor: friendGroup.statuses.first.type == StatusType.text
                ? _parseColor(friendGroup.statuses.first.backgroundColor)
                : Colors.grey[200],
          ),
        ),
        title: Text(friendGroup.user.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(lastStatusTime, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        onTap: () {
           Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ViewStatusScreen(
                    userStatuses: friendGroup.statuses, // Status diurutkan dari terlama ke terbaru
                    user: friendGroup.user,
                    initialStatusIndex: 0,
                   )));
        },
      ),
    );
  }

   Color _parseColor(String? hexColor) {
    hexColor = hexColor?.toUpperCase().replaceAll("#", "");
    if (hexColor == null || hexColor.length != 6) {
      return Colors.blueGrey; // Warna default jika parsing gagal
    }
    try {
      return Color(int.parse(hexColor, radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blueGrey;
    }
  }
}