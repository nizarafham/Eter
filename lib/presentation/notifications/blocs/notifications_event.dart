part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered to load initial notifications and set up the stream.
class LoadNotifications extends NotificationsEvent {}

/// Internal event when the list of notifications is updated from the stream.
class _NotificationsUpdated extends NotificationsEvent {
  final List<NotificationModel> notifications;
  const _NotificationsUpdated(this.notifications);

  @override
  List<Object?> get props => [notifications];
}

/// Marks a specific notification as read.
class MarkNotificationAsRead extends NotificationsEvent {
  final String notificationId;
  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Marks all unread notifications for the current user as read.
class MarkAllNotificationsAsRead extends NotificationsEvent {}

/// Deletes a specific notification.
class DeleteNotification extends NotificationsEvent {
  final String notificationId;
  const DeleteNotification(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

/// Handles tapping on a notification, potentially leading to navigation or other actions.
class NotificationTapped extends NotificationsEvent {
  final NotificationModel notification;
  const NotificationTapped(this.notification);

  @override
  List<Object?> get props => [notification];
}