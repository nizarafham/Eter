// TODO Implement this library.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/core/di/service_locator.dart';
import 'package:chat_app/core/utils/image_helper.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:chat_app/presentation/friends/blocs/friends_bloc.dart'; // Untuk mendapatkan daftar teman
import 'package:chat_app/presentation/groups/blocs/groups_bloc.dart';
import 'package:chat_app/presentation/chat/screens/chat_detail_screen.dart'; // Navigasi setelah grup dibuat

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  File? _selectedAvatar;
  final List<UserModel> _selectedMembers = [];
  List<UserModel> _availableFriends = [];

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final imageHelper = sl<ImageHelper>();
    final image = await imageHelper.pickImageFromGallery(); // Atau dari kamera
    if (image != null) {
      setState(() {
        _selectedAvatar = image;
      });
    }
  }

  void _toggleMemberSelection(UserModel friend) {
    setState(() {
      if (_selectedMembers.any((member) => member.id == friend.id)) {
        _selectedMembers.removeWhere((member) => member.id == friend.id);
      } else {
        _selectedMembers.add(friend);
      }
    });
  }

  void _createGroup() {
    if (_formKey.currentState!.validate()) {
      // Anggota yang dipilih oleh pengguna (tidak termasuk diri sendiri secara eksplisit di sini,
      // karena GroupsBloc akan menambahkan currentUserId)
      final memberIds = _selectedMembers.map((m) => m.id).toList();

      // Minimal harus ada 1 anggota yang dipilih (selain diri sendiri yang akan ditambahkan oleh BLoC)
      // atau sesuaikan logikanya jika grup bisa dibuat hanya dengan 1 orang (pembuat)
      if (memberIds.isEmpty && _selectedMembers.length < 1) { // Contoh: grup minimal 2 orang (pembuat + 1)
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih minimal satu anggota untuk grup."), backgroundColor: Colors.orangeAccent),
        );
        return;
      }


      context.read<GroupsBloc>().add(CreateGroup(
            name: _groupNameController.text.trim(),
            memberIds: memberIds, // GroupsBloc akan menambahkan currentUserId
            avatarImage: _selectedAvatar,
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthBloc>().state.user?.id ?? "";

    // Menyediakan FriendsBloc untuk mendapatkan daftar teman dan GroupsBloc untuk aksi grup
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<FriendsBloc>(param1: currentUserId)..add(LoadFriendsAndRequestsEvent()),
        ),
        // GroupsBloc biasanya sudah di-provide di atasnya jika layar ini adalah bagian dari flow yang lebih besar,
        // atau jika tidak, bisa di-provide di sini jika hanya untuk create.
        // Untuk contoh ini, kita asumsikan GroupsBloc bisa diakses dari context.read<GroupsBloc>()
        // Jika belum, Anda perlu: BlocProvider(create: (context) => sl<GroupsBloc>(param1: currentUserId)),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text("Buat Grup Baru")),
        body: BlocConsumer<GroupsBloc, GroupsState>(
          listener: (context, groupState) {
            if (groupState is GroupOperationSuccess && groupState.message.contains("berhasil dibuat")) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(groupState.message), backgroundColor: Colors.green),
              );
              if (groupState.conversationId != null && groupState.group != null) {
                // Ganti semua rute hingga root, lalu push ke ChatDetailScreen
                Navigator.of(context).popUntil((route) => route.isFirst); // Kembali ke HomeScreen
                Navigator.of(context).push(MaterialPageRoute( // Push ke chat grup baru
                  builder: (_) => ChatDetailScreen(
                    conversationId: groupState.conversationId!,
                    otherUserName: groupState.group!.name,
                  ),
                ));
              } else {
                 if (Navigator.canPop(context)) Navigator.pop(context);
              }
            } else if (groupState is GroupsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(groupState.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, groupState) {
            if (groupState is GroupsLoading && groupState.operationMessage == "Membuat grup...") {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          backgroundImage: _selectedAvatar != null ? FileImage(_selectedAvatar!) : null,
                          child: _selectedAvatar == null
                              ? Icon(Icons.group_add_rounded, size: 60, color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _groupNameController,
                      decoration: InputDecoration(
                        labelText: "Nama Grup",
                        hintText: "Masukkan nama grup",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.group_work_outlined)
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Nama grup tidak boleh kosong.";
                        }
                        if (value.trim().length < 3) {
                          return "Nama grup minimal 3 karakter.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text("Pilih Anggota:", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    BlocBuilder<FriendsBloc, FriendsState>( // Untuk menampilkan daftar teman
                      builder: (context, friendsState) {
                        if (friendsState is FriendsLoading && friendsState.currentFriends.isEmpty) {
                          return const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2,)));
                        }
                        if (friendsState is FriendsLoaded) {
                          // Ambil detail teman dari FriendshipModel
                          _availableFriends = friendsState.friends
                              .map((f) => f.getFriend(currentUserId)) // Menggunakan getFriend dari FriendshipModel
                              .whereType<UserModel>() // Filter hanya UserModel yang valid (tidak null)
                              .toList();

                          if (_availableFriends.isEmpty) {
                            return Card(
                              elevation: 0,
                              color: Theme.of(context).colorScheme.surfaceContainerLowest,
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("Anda belum memiliki teman untuk ditambahkan ke grup. Tambah teman terlebih dahulu.", textAlign: TextAlign.center,),
                              ),
                            );
                          }
                          return Container(
                            constraints: const BoxConstraints(maxHeight: 300), // Batasi tinggi list
                            decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(8)
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _availableFriends.length,
                              separatorBuilder: (ctx, idx) => const Divider(height: 1),
                              itemBuilder: (ctx, index) {
                                final friend = _availableFriends[index];
                                final isSelected = _selectedMembers.any((m) => m.id == friend.id);
                                return CheckboxListTile(
                                  title: Text(friend.username),
                                  secondary: CircleAvatar(
                                    backgroundImage: friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty ? NetworkImage(friend.avatarUrl!) : null,
                                    child: friend.avatarUrl == null || friend.avatarUrl!.isEmpty ? Text(friend.username.isNotEmpty ? friend.username[0].toUpperCase() : "?") : null,
                                  ),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    _toggleMemberSelection(friend);
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                );
                              },
                            ),
                          );
                        }
                        if(friendsState is FriendsError){
                            return Text("Gagal memuat daftar teman: ${friendsState.message}", style: TextStyle(color: Theme.of(context).colorScheme.error));
                        }
                        return const Text("Memuat daftar teman...");
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text("Buat Grup"),
                      onPressed: (groupState is GroupsLoading && groupState.operationMessage == "Membuat grup...") ? null : _createGroup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}