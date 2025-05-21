import 'package:chat_app/data/models/notification_model.dart'; // You'll need to create this model

abstract class NotificationRepository {
  /// Streams a list of notifications for a specific user.
  Stream<List<NotificationModel>> getNotifications(String userId);

  /// Marks a specific notification as read.
  Future<void> markNotificationAsRead(String notificationId);

  /// Marks all notifications for a specific user as read.
  Future<void> markAllNotificationsAsRead(String userId);

  /// Deletes a specific notification.
  Future<void> deleteNotification(String notificationId);

  /// Sends a new notification. This might involve an RPC (Remote Procedure Call)
  /// or a direct insert into the database.
  Future<void> sendNotification(NotificationModel notification);
}