import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/chat_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/profile_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/storage_remote_data_source.dart';
import 'package:chat_app/data/repositories/auth_repository_impl.dart';
import 'package:chat_app/data/repositories/chat_repository_impl.dart';
import 'package:chat_app/data/repositories/profile_repository_impl.dart';
import 'package:chat_app/data/repositories/storage_repository_impl.dart';
import 'package:chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:chat_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:chat_app/presentation/blocs/message_input/message_input_cubit.dart';
import 'package:chat_app/presentation/blocs/profile/profile_cubit.dart';
import 'package:chat_app/presentation/blocs/user_search/user_search_cubit.dart';
// Add other imports for data sources, repositories, and BLoCs/Cubits

final sl = GetIt.instance; // Service Locator instance

Future<void> init() async {
  // Supabase Client
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // --- Data Sources ---
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<StorageRemoteDataSource>(
      () => StorageRemoteDataSourceImpl(sl()));
  // Add other data sources (e.g., Friends, Groups, Status, Notifications)

  // --- Repositories ---
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
  sl.registerLazySingleton<StorageRepository>(
      () => StorageRepositoryImpl(sl()));
  // Add other repositories

  // --- BLoCs / Cubits ---
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
  sl.registerFactory<ProfileCubit>(() => ProfileCubit(sl()));
  sl.registerFactory<UserSearchCubit>(() => UserSearchCubit(sl()));
  sl.registerFactoryParam<ChatBloc, String?, void>((conversationId, _) =>
      ChatBloc(chatRepository: sl(), conversationId: conversationId)); // For specific chat rooms
  sl.registerFactory<MessageInputCubit>(() => MessageInputCubit(sl(), sl()));
  // Add other BLoCs/Cubits
}