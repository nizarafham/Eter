import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/notification_model.dart';
import 'package:chat_app/data/repositories/notification_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationRepository _notificationRepository;
  final String _currentUserId;
  StreamSubscription? _notificationsSubscription;

  NotificationsBloc({
    required NotificationRepository notificationRepository,
    required String currentUserId,
  })  : _notificationRepository = notificationRepository,
        _currentUserId = currentUserId,
        super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<_NotificationsUpdated>(_onNotificationsUpdated);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<NotificationTapped>(_onNotificationTapped);
  }

  List<NotificationModel> _getCurrentNotificationsFromState() {
    if (state is NotificationsLoaded) return (state as NotificationsLoaded).notifications;
    if (state is NotificationsLoading) return (state as NotificationsLoading).currentNotifications;
    if (state is NotificationsError) return (state as NotificationsError).currentNotifications;
    return const [];
  }

  void _onLoadNotifications(LoadNotifications event, Emitter<NotificationsState> emit) {
    emit(NotificationsLoading(currentNotifications: _getCurrentNotificationsFromState()));
    _notificationsSubscription?.cancel();
    _notificationsSubscription = _notificationRepository.getNotifications(_currentUserId).listen(
      (notifications) {
        add(_NotificationsUpdated(notifications));
      },
      onError: (error) => emit(NotificationsError(
        "Failed to load notifications: ${error.toString()}",
        currentNotifications: _getCurrentNotificationsFromState(),
      )),
    );
  }

  void _onNotificationsUpdated(_NotificationsUpdated event, Emitter<NotificationsState> emit) {
    final unreadCount = event.notifications.where((n) => !n.isRead).length;
    emit(NotificationsLoaded(notifications: event.notifications, unreadCount: unreadCount));
  }

  Future<void> _onMarkNotificationAsRead(MarkNotificationAsRead event, Emitter<NotificationsState> emit) async {
    final currentNotifications = _getCurrentNotificationsFromState();
    // Optimistically update UI if needed, or wait for stream
    try {
      await _notificationRepository.markNotificationAsRead(event.notificationId);
      // Stream will eventually update the list. For immediate feedback:
      final updatedNotifications = currentNotifications.map((n) {
        if (n.id == event.notificationId) {
          // Create a new instance with isRead: true
          return NotificationModel(
              id: n.id, recipientId: n.recipientId, type: n.type, title: n.title, body: n.body,
              senderId: n.senderId, referenceId: n.referenceId, data: n.data, isRead: true, createdAt: n.createdAt
          );
        }
        return n;
      }).toList();
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      emit(NotificationsLoaded(notifications: updatedNotifications, unreadCount: unreadCount, successMessage: "Notification marked as read."));
    } catch (e) {
      emit(NotificationsError("Failed to mark as read: ${e.toString()}", currentNotifications: currentNotifications));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(MarkAllNotificationsAsRead event, Emitter<NotificationsState> emit) async {
    final currentNotifications = _getCurrentNotificationsFromState();
    try {
      await _notificationRepository.markAllNotificationsAsRead(_currentUserId);
      // Stream will update, or optimistically update:
       final updatedNotifications = currentNotifications.map((n) =>
          NotificationModel(
              id: n.id, recipientId: n.recipientId, type: n.type, title: n.title, body: n.body,
              senderId: n.senderId, referenceId: n.referenceId, data: n.data, isRead: true, createdAt: n.createdAt
          )
      ).toList();
      emit(NotificationsLoaded(notifications: updatedNotifications, unreadCount: 0, successMessage: "All notifications marked as read."));
    } catch (e) {
      emit(NotificationsError("Failed to mark all as read: ${e.toString()}", currentNotifications: currentNotifications));
    }
  }

  Future<void> _onDeleteNotification(DeleteNotification event, Emitter<NotificationsState> emit) async {
    final currentNotifications = _getCurrentNotificationsFromState();
    try {
      await _notificationRepository.deleteNotification(event.notificationId);
      // Stream will update, or optimistically update:
      final updatedNotifications = currentNotifications.where((n) => n.id != event.notificationId).toList();
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      emit(NotificationsLoaded(notifications: updatedNotifications, unreadCount: unreadCount, successMessage: "Notification deleted."));
    } catch (e) {
      emit(NotificationsError("Failed to delete notification: ${e.toString()}", currentNotifications: currentNotifications));
    }
  }

  Future<void> _onNotificationTapped(NotificationTapped event, Emitter<NotificationsState> emit) async {
    // Mark as read first, if not already read
    if (!event.notification.isRead) {
      add(MarkNotificationAsRead(event.notification.id));
      // Wait for the state to potentially update if MarkNotificationAsRead emits quickly,
      // or proceed with the navigation logic.
      // For simplicity, we'll emit navigation directly. The list will update via stream.
    }
    // Emit a navigation state or handle navigation logic directly
    emit(NavigateToNotificationTarget(event.notification));
    
    // After emitting navigation, revert to a stable 'Loaded' state so the UI doesn't get stuck
    // This might be tricky if navigation is asynchronous.
    // A common pattern is for the UI to listen for NavigateToNotificationTarget, perform navigation,
    // and then potentially dispatch an event to clear the navigation state or simply rely on
    // the next _NotificationsUpdated event to refresh the list.
    // For now, we assume the UI handles the navigation and this BLoC focuses on data.
    // To ensure the UI doesn't stay on NavigateToNotificationTarget:
    Future.delayed(const Duration(milliseconds: 50), () {
        if (state is NavigateToNotificationTarget) {
             final currentNotifications = _getCurrentNotificationsFromState();
             final unreadCount = currentNotifications.where((n) => !n.isRead).length;
             emit(NotificationsLoaded(notifications: currentNotifications, unreadCount: unreadCount));
        }
    });
  }


  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    return super.close();
  }
}