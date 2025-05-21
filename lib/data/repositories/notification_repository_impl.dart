import 'package:chat_app/data/datasources/remote/notification_remote_data_source.dart'; // You'll need to create this
import 'package:chat_app/data/models/notification_model.dart'; // Ensure this model exists
import 'package:chat_app/data/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<NotificationModel>> getNotifications(String userId) {
    try {
      return _remoteDataSource.getNotifications(userId);
    } catch (e) {
      // print('NotificationRepositoryImpl getNotifications error: $e');
      rethrow;
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _remoteDataSource.markNotificationAsRead(notificationId);
    } catch (e) {
      // print('NotificationRepositoryImpl markNotificationAsRead error: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      await _remoteDataSource.markAllNotificationsAsRead(userId);
    } catch (e) {
      // print('NotificationRepositoryImpl markAllNotificationsAsRead error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _remoteDataSource.deleteNotification(notificationId);
    } catch (e) {
      // print('NotificationRepositoryImpl deleteNotification error: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _remoteDataSource.sendNotification(notification);
    } catch (e) {
      // print('NotificationRepositoryImpl sendNotification error: $e');
      rethrow;
    }
  }
}