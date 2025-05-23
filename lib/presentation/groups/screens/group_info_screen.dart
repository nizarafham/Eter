import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/core/di/service_locator.dart';
import 'package:chat_app/data/models/group_model.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:chat_app/presentation/groups/blocs/groups_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:chat_app/presentation/friends/screens/add_friend_screen.dart'; // Untuk menambah anggota

class GroupInfoScreen extends StatelessWidget {
  final String groupId;

  const GroupInfoScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthBloc>().state.user?.id ?? "";

    return BlocProvider(
      create: (context) => sl<GroupsBloc>(param1: currentUserId) // param1 adalah currentUserId
        ..add(LoadGroupDetails(groupId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Info Grup"),
          actions: [
            BlocBuilder<GroupsBloc, GroupsState>(
              builder: (context, state) {
                if (state is GroupDetailsLoaded) {
                  // Tombol edit hanya jika pengguna adalah pembuat grup (logika admin sederhana)
                  if (state.group.createdBy == currentUserId) {
                    return IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: "Edit Grup",
                      onPressed: () {
                        // TODO: Navigasi ke layar edit info grup
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Fitur edit grup akan datang!")),
                        );
                      },
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            )
          ],
        ),
        body: BlocConsumer<GroupsBloc, GroupsState>(
          listener: (context, state) {
            if (state is GroupOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
              if (state.message.contains("keluar dari grup")) {
                // Kembali ke root atau HomeScreen setelah keluar grup
                 Navigator.of(context).popUntil((route) => route.isFirst);
              }
              // Tidak perlu refresh detail di sini karena BLoC akan emit GroupDetailsLoaded lagi jika ada perubahan anggota
            } else if (state is GroupsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is GroupsLoading && state.operationMessage == "Memuat detail grup...") {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is GroupDetailsLoaded) {
              final group = state.group;
              final members = state.members;
              final bool isAdmin = group.createdBy == currentUserId; // Logika admin sederhana

              return ListView(
                children: [
                  _buildGroupHeader(context, group, isAdmin),
                  _buildMembersSection(context, groupId, members, isAdmin, currentUserId),
                  const Divider(height: 20),
                  _buildGroupActions(context, groupId, isAdmin),
                ],
              );
            }
            if (state is GroupsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Gagal memuat detail grup: ${state.message}", textAlign: TextAlign.center),
                )
              );
            }
            return const Center(child: Text("Memuat..."));
          },
        ),
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context, GroupModel group, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(group.avatarUrl!)
                : null,
            child: (group.avatarUrl == null || group.avatarUrl!.isEmpty)
                ? Icon(Icons.group_work_rounded, size: 60, color: Theme.of(context).colorScheme.primary)
                : null,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 16),
          Text(
            group.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            "${group.members?.length ?? 'Memuat'} anggota", // Members ada di state.group.members atau state.members
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(BuildContext context, String groupId, List<UserModel> members, bool isAdmin, String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Anggota (${members.length})",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (isAdmin)
                TextButton.icon(
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
                  label: const Text("Tambah"),
                  onPressed: () {
                    // TODO: Navigasi ke layar pilih anggota (mirip AddFriendScreen tapi untuk grup)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Fitur tambah anggota akan datang!")),
                    );
                  },
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          itemBuilder: (ctx, index) {
            final member = members[index];
            final bool isSelf = member.id == currentUserId;
            // Logika admin sederhana: pembuat grup adalah admin
            final bool isGroupCreator = context.read<GroupsBloc>().state is GroupDetailsLoaded &&
                                        (context.read<GroupsBloc>().state as GroupDetailsLoaded).group.createdBy == member.id;


            return ListTile(
              leading: CircleAvatar(
                backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(member.avatarUrl!)
                    : null,
                child: (member.avatarUrl == null || member.avatarUrl!.isEmpty)
                    ? Text(member.username.isNotEmpty ? member.username[0].toUpperCase() : "?")
                    : null,
              ),
              title: Text(member.username + (isSelf ? " (Anda)" : "")),
              subtitle: isGroupCreator ? Text("Admin", style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)) : null,
              trailing: (isAdmin && !isSelf && !isGroupCreator) // Admin bisa hapus anggota lain yg bukan admin
                  ? IconButton(
                      icon: Icon(Icons.remove_circle_outline_rounded, color: Theme.of(context).colorScheme.error),
                      tooltip: "Keluarkan dari grup",
                      onPressed: () {
                        showDialog(context: context, builder: (dCtx) => AlertDialog(
                          title: const Text("Keluarkan Anggota"),
                          content: Text("Yakin ingin mengeluarkan ${member.username} dari grup?"),
                          actions: [
                            TextButton(onPressed: ()=> Navigator.of(dCtx).pop(), child: const Text("Batal")),
                            TextButton(onPressed: (){
                              Navigator.of(dCtx).pop();
                              context.read<GroupsBloc>().add(RemoveMemberFromGroup(groupId: groupId, userIdToRemove: member.id));
                            }, child: Text("Keluarkan", style: TextStyle(color: Theme.of(context).colorScheme.error))),
                          ],
                        ));
                      },
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildGroupActions(BuildContext context, String groupId, bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        children: [
          // Opsi lain bisa ditambahkan di sini, misalnya "Edit Grup" jika admin
          // if (isAdmin)
          //   ListTile(
          //     leading: Icon(Icons.edit_outlined, color: Theme.of(context).primaryColor),
          //     title: Text("Edit Info Grup", style: TextStyle(color: Theme.of(context).primaryColor)),
          //     onTap: () {
          //       // TODO: Navigasi ke layar edit info grup
          //     },
          //   ),
          // if (isAdmin) const Divider(),
          ListTile(
            leading: Icon(Icons.exit_to_app_rounded, color: Theme.of(context).colorScheme.error),
            title: Text("Keluar dari Grup", style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500)),
            onTap: () {
               showDialog(context: context, builder: (dCtx) => AlertDialog(
                title: const Text("Keluar Grup"),
                content: const Text("Apakah Anda yakin ingin keluar dari grup ini?"),
                actions: [
                  TextButton(onPressed: ()=> Navigator.of(dCtx).pop(), child: const Text("Batal")),
                  TextButton(onPressed: (){
                    Navigator.of(dCtx).pop();
                    context.read<GroupsBloc>().add(LeaveGroup(groupId));
                  }, child: Text("Keluar", style: TextStyle(color: Theme.of(context).colorScheme.error))),
                ],
              ));
            },
          ),
        ],
      ),
    );
  }
}