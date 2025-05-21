// TODO Implement this library.
import 'package:chat_app/core/constants/supabase_constants.dart'; // Make sure SupabaseConstants is defined
import 'package:chat_app/data/models/notification_model.dart'; // Import your NotificationModel
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // For generating UUIDs for new notifications

abstract class NotificationRemoteDataSource {
  /// Streams a list of notifications for a specific user.
  /// Orders them by creation date, typically newest first.
  Stream<List<NotificationModel>> getNotifications(String userId);

  /// Marks a specific notification as read by updating its 'is_read' status.
  Future<void> markNotificationAsRead(String notificationId);

  /// Marks all notifications for a specific user as read.
  Future<void> markAllNotificationsAsRead(String userId);

  /// Deletes a specific notification record from the database.
  Future<void> deleteNotification(String notificationId);

  /// Inserts a new notification record into the database.
  Future<void> sendNotification(NotificationModel notification);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient _supabaseClient;
  final Uuid _uuid = const Uuid(); // For generating notification IDs

  NotificationRemoteDataSourceImpl(this._supabaseClient);

  @override
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _supabaseClient
        .from(SupabaseConstants.notificationsTable) // You'll define this constant
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false) // Newest notifications first
        .map((maps) => maps.map((map) => NotificationModel.fromMap(map)).toList());
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    await _supabaseClient
        .from(SupabaseConstants.notificationsTable)
        .update({'is_read': true, 'updated_at': DateTime.now().toIso8601String()}) // Add updated_at
        .eq('id', notificationId)
        .eq('recipient_id', _supabaseClient.auth.currentUser!.id); // Ensure user can only mark their own
  }

  @override
  Future<void> markAllNotificationsAsRead(String userId) async {
    await _supabaseClient
        .from(SupabaseConstants.notificationsTable)
        .update({'is_read': true, 'updated_at': DateTime.now().toIso8601String()}) // Add updated_at
        .eq('recipient_id', userId)
        .eq('is_read', false); // Only update unread ones
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _supabaseClient
        .from(SupabaseConstants.notificationsTable)
        .delete()
        .eq('id', notificationId)
        .eq('recipient_id', _supabaseClient.auth.currentUser!.id); // Ensure user can only delete their own
  }

  @override
  Future<void> sendNotification(NotificationModel notification) async {
    // Use the toInsertMap and let Supabase handle id, is_read, created_at
    await _supabaseClient
        .from(SupabaseConstants.notificationsTable)
        .insert(notification.toInsertMap());
        // If you need the ID back, you can add .select('id').single()
  }
}