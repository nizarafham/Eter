import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/presentation/profile/blocs/profile_cubit.dart';
import 'package:chat_app/core/utils/image_helper.dart'; // Assuming you have this
import 'package:chat_app/core/di/service_locator.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  File? _selectedAvatarImage;
  final _formKey = GlobalKey<FormState>();
  final ImageHelper _imageHelper = sl<ImageHelper>(); // Get ImageHelper via GetIt

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUser.username);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imageHelper.pickImageFromGallery();
    if (pickedFile != null) {
      setState(() {
        _selectedAvatarImage = pickedFile;
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileCubit>().updateUserProfile(
            username: _usernameController.text.trim(),
            avatarImage: _selectedAvatarImage,
          );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              if (state is ProfileUpdating) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveProfile,
              );
            },
          ),
        ],
      ),
      body: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green));
            Navigator.of(context).pop(true); // Pop and indicate success
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: _selectedAvatarImage != null
                            ? FileImage(_selectedAvatarImage!)
                            : (widget.currentUser.avatarUrl != null && widget.currentUser.avatarUrl!.isNotEmpty
                                ? NetworkImage(widget.currentUser.avatarUrl!)
                                : null) as ImageProvider?,
                        child: (_selectedAvatarImage == null && (widget.currentUser.avatarUrl == null || widget.currentUser.avatarUrl!.isEmpty))
                            ? Icon(Icons.person, size: 70, color: Theme.of(context).colorScheme.onSurfaceVariant)
                            : null,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your new username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline)
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username cannot be empty.';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters long.';
                    }
                    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(value.trim())) {
                      return 'Only letters, numbers, and underscores allowed.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_outlined),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 16)
                  ),
                  onPressed: () {
                    // Check if ProfileCubit is in ProfileUpdating state before calling _saveProfile
                    final profileState = context.read<ProfileCubit>().state;
                    if (profileState is! ProfileUpdating) {
                       _saveProfile();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}