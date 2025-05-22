import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/presentation/profile/blocs/profile_cubit.dart';
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:chat_app/presentation/profile/screens/edit_profile_screen.dart'; // We'll create this
import 'package:chat_app/core/di/service_locator.dart'; // For GetIt

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthBloc>().state.user?.id;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text("User not authenticated.")),
      );
    }

    return BlocProvider(
      create: (context) => sl<ProfileCubit>()..loadUserProfile(currentUserId),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Profile"),
          actions: [
            BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoaded) {
                  return IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(currentUser: state.user),
                        ),
                      ).then((updated) {
                        // Optionally reload profile if EditProfileScreen indicates an update
                        if (updated == true) {
                           context.read<ProfileCubit>().loadUserProfile(currentUserId);
                        }
                      });
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<ProfileCubit, ProfileState>(
          listener: (context, state) {
            if (state is ProfileError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProfileLoaded) {
              final user = state.user;
              return _buildProfileView(context, user);
            }
            if (state is ProfileUpdateSuccess) { // After an update from EditProfileScreen, this might be shown briefly
              final user = state.updatedUser;
              return _buildProfileView(context, user);
            }
            if (state is ProfileError && state.message.contains("User profile not found")) {
                // This case might indicate the profile doesn't exist yet in the 'profiles' table
                // even if auth.user exists. You might offer a "Create Profile" button or auto-create.
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Text("Profile data not found."),
                        const SizedBox(height: 10),
                        ElevatedButton(
                            onPressed: () => context.read<ProfileCubit>().loadUserProfile(currentUserId), // Retry
                            child: const Text("Retry"),
                        )
                    ],
                  )
                );
            }
            // Fallback for other error states if not caught by listener (though listener is better for transient errors)
            return const Center(child: Text("Could not load profile."));
          },
        ),
      ),
    );
  }

  Widget _buildProfileView(BuildContext context, UserModel user) {
    return RefreshIndicator(
      onRefresh: () async {
        final String? userId = context.read<AuthBloc>().state.user?.id;
        if (userId != null) {
          context.read<ProfileCubit>().loadUserProfile(userId);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onSurfaceVariant)
                      : null,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  user.username,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? 'No email provided',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Username'),
            subtitle: Text(user.username),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(user.email ?? 'Not set'),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Joined'),
            subtitle: Text( "${user.createdAt.toLocal().day}/${user.createdAt.toLocal().month}/${user.createdAt.toLocal().year}"),
          ),
          const Divider(),
          const SizedBox(height: 20),
           ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Logout', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () {
              showDialog(context: context, builder: (dialogContext) => AlertDialog(
                title: const Text("Confirm Logout"),
                content: const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text("Cancel")),
                  TextButton(onPressed: () {
                     Navigator.of(dialogContext).pop();
                     context.read<AuthBloc>().add(SignOutRequested());
                  }, child: Text("Logout", style: TextStyle(color: Theme.of(context).colorScheme.error),)),
                ],
              ));
            },
          ),
        ],
      ),
    );
  }
}