import 'dart:io';
import 'package:chat_app/core/constants/supabase_constants.dart';
import 'package:chat_app/data/datasources/remote/profile_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/storage_remote_data_source.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/repositories/profile_repository.dart'; // Interface
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class StorageRemoteDataSource {
  Future<String> uploadFile(File file, String bucketName, String filePath);
  // Add other storage-related methods here if needed, e.g., downloadFile, deleteFile
}

class StorageRemoteDataSourceImpl implements StorageRemoteDataSource {
  final SupabaseClient _supabaseClient;

  StorageRemoteDataSourceImpl(this._supabaseClient);

  @override
  Future<String> uploadFile(File file, String bucketName, String filePath) async {
    final storageResponse = await _supabaseClient.storage
        .from(bucketName)
        .upload(filePath, file);

    // Get the public URL of the uploaded file
    final publicUrlResponse = _supabaseClient.storage
        .from(bucketName)
        .getPublicUrl(filePath);

    return publicUrlResponse;
  }
}

