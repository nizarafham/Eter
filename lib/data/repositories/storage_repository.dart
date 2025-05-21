import 'dart:io';

abstract class StorageRepository {
  /// Uploads a file to a specified Supabase storage bucket and path.
  ///
  /// [file]: The file to upload.
  /// [bucketName]: The name of the Supabase storage bucket (e.g., SupabaseConstants.profileAvatarsBucket).
  /// [path]: The path within the bucket where the file will be stored (e.g., 'user_id/image.jpg').
  ///
  /// Returns the public URL of the uploaded file.
  Future<String> uploadFile(File file, String bucketName, String path);

  // You can add other storage-related methods here if needed,
  // e.g., downloadFile, deleteFile, getPublicUrl
  // Future<void> deleteFile(String bucketName, String path);
  // Future<String> getPublicUrl(String bucketName, String path);
}