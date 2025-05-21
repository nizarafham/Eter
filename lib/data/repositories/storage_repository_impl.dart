import 'dart:io';
// Make sure this path is correct for your project
import 'package:chat_app/data/datasources/remote/storage_remote_data_source.dart';
// Make sure this path is correct for your project
import 'package:chat_app/data/repositories/storage_repository.dart';

class StorageRepositoryImpl implements StorageRepository {
  final StorageRemoteDataSource _remoteDataSource;

  StorageRepositoryImpl(this._remoteDataSource);

  @override
  Future<String> uploadFile(File file, String bucketName, String path) async {
    try {
      // The actual upload logic is delegated to the remote data source
      // This repository acts as an orchestrator and error handler.
      return await _remoteDataSource.uploadFile(file, bucketName, path);
    } catch (e) {
      // It's highly recommended to log the error for debugging purposes.
      // print('StorageRepositoryImpl uploadFile error: $e');
      // Re-throw the exception to allow higher layers (e.g., BLoC/Cubit)
      // to catch and handle it, perhaps by showing an error to the user.
      rethrow;
    }
  }
}