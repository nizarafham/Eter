import 'dart:io';
import 'package:chat_app/data/models/status_model.dart'; // You'll need to create this model

abstract class StatusRepository {
  /// Posts a new text-based status for a user.
  Future<void> postTextStatus(String userId, String textContent, String backgroundColor);

  /// Posts a new image-based status for a user.
  /// [imageFile]: The image file to upload.
  /// [caption]: Optional text caption for the image status.
  Future<void> postImageStatus(String userId, File imageFile, {String? caption});

  /// Streams a list of statuses from a user's accepted friends.
  /// This typically involves fetching statuses and filtering by friend relationships.
  Stream<List<StatusModel>> getFriendsStatuses(String userId);

  /// Fetches a specific status by its ID.
  Future<StatusModel?> getStatusById(String statusId);

  /// Marks a status as viewed by a specific user.
  /// This helps in tracking who has seen whose statuses.
  Future<void> markStatusAsViewed(String statusId, String viewerId);

  /// Deletes a user's own status.
  Future<void> deleteStatus(String statusId, String userId);
}