class SupabaseConstants {
  // Table Names
  static const String profilesTable = 'profiles';
  static const String messagesTable = 'messages';
  static const String conversationsTable = 'conversations'; // For grouping DMs and Group Chats
  static const String groupMembersTable = 'group_members';
  static const String friendsTable = 'friends'; // user1_id, user2_id, status (pending, accepted, blocked)
  static const String notificationsTable = 'notifications'; // user_id, type, content, reference_id, created_at, is_read
  static const String statusesTable = 'statuses'; // user_id, content_text, content_image_url, created_at, expires_at
  static const String friendshipsTable = 'friendships';
  static const String groupsTable = 'groups'; // For group chats
  
  // Storage Bucket Names
  static const String imagesBucket = 'eter-image'; // As requested for general images
  static const String profileAvatarsBucket = 'profile-avatars'; // Specific for avatars
  static const String statusImagesBucket = 'status-images';
  static const String groupAvatarsBucket = 'eter-image';

  // Specific for status image  s

  // RPC Function Names (if any)
  // static const String searchUsersRpc = 'search_users';
}