part of 'notifications_bloc.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {
  final List<NotificationModel> currentNotifications; // Keep current data while loading
  const NotificationsLoading({this.currentNotifications = const []});
   @override
  List<Object?> get props => [currentNotifications];
}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? successMessage; // For transient success messages

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    this.successMessage,
  });

  @override
  List<Object?> get props => [notifications, unreadCount, successMessage];

  NotificationsLoaded copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      successMessage: clearSuccessMessage ? null : successMessage ?? this.successMessage,
    );
  }
}

/// Could be used if a specific action takes time, while still showing the list.
/// Alternatively, just use NotificationsLoaded with a success message or rely on stream updates.
// class NotificationActionInProgress extends NotificationsLoaded {
//   const NotificationActionInProgress({required super.notifications, required super.unreadCount});
// }

class NotificationsError extends NotificationsState {
  final String message;
  final List<NotificationModel> currentNotifications; // Keep current data on error
  const NotificationsError(this.message, {this.currentNotifications = const []});

  @override
  List<Object?> get props => [message, currentNotifications];
}

/// State to indicate navigation is required based on notification tap.
class NavigateToNotificationTarget extends NotificationsState {
  final NotificationModel notification; // The original notification
  // Add specific navigation parameters if needed, e.g.,
  // final String? conversationId;
  // final String? friendRequestId;

  const NavigateToNotificationTarget(this.notification);

  @override
  List<Object?> get props => [notification];
}