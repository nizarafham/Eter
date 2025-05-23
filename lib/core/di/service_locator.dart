import 'package:chat_app/presentation/conversations/blocs/conversations_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Utils
import 'package:chat_app/core/utils/image_helper.dart';

// Data Sources
import 'package:chat_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/chat_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/profile_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/storage_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/friends_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/notification_remote_data_source.dart';
import 'package:chat_app/data/datasources/remote/status_remote_data_source.dart';
// import 'package:chat_app/data/datasources/remote/group_remote_data_source.dart';

// Repositories - Interfaces
import 'package:chat_app/data/repositories/auth_repository.dart';
import 'package:chat_app/data/repositories/chat_repository.dart';
import 'package:chat_app/data/repositories/profile_repository.dart';
import 'package:chat_app/data/repositories/storage_repository.dart';
import 'package:chat_app/data/repositories/friendship_repository.dart';
import 'package:chat_app/data/repositories/notification_repository.dart';
import 'package:chat_app/data/repositories/status_repository.dart';
// import 'package:chat_app/data/repositories/group_repository.dart';

// Repositories - Implementations
import 'package:chat_app/data/repositories/auth_repository_impl.dart';
import 'package:chat_app/data/repositories/chat_repository_impl.dart';
import 'package:chat_app/data/repositories/profile_repository_impl.dart'; // Pastikan tidak ada duplikat impor/definisi
import 'package:chat_app/data/repositories/storage_repository_impl.dart';
import 'package:chat_app/data/repositories/friendship_repository_impl.dart';
import 'package:chat_app/data/repositories/notification_repository_impl.dart';
import 'package:chat_app/data/repositories/status_repository_impl.dart';
// import 'package:chat_app/data/repositories/group_repository_impl.dart';

// BLoCs / Cubits (Pastikan path impor sesuai struktur folder Anda)
import 'package:chat_app/presentation/auth/blocs/auth_bloc.dart';
import 'package:chat_app/presentation/chat/blocs/chat_bloc.dart';
// import 'package:chat_app/presentation/conversations/blocs/conversations_bloc.dart';
import 'package:chat_app/presentation/message_input/blocs/message_input_cubit.dart';
import 'package:chat_app/presentation/profile/blocs/profile_cubit.dart';
import 'package:chat_app/presentation/user_search/blocs/user_search_cubit.dart';
import 'package:chat_app/presentation/friends/blocs/friends_bloc.dart';
import 'package:chat_app/presentation/notifications/blocs/notifications_bloc.dart';
import 'package:chat_app/presentation/status/blocs/status_bloc.dart';
// import 'package:chat_app/presentation/groups/blocs/groups_bloc.dart';


final sl = GetIt.instance;

Future<void> init() async {
  // Supabase Client
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // Utils
  sl.registerLazySingleton<ImageHelper>(() => ImageHelper());

  // --- Data Sources ---
  // Pastikan semua konstruktor DataSourceImpl(SupabaseClient client)
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl<SupabaseClient>()));
  sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(sl<SupabaseClient>()));
  sl.registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(sl<SupabaseClient>()));
  sl.registerLazySingleton<StorageRemoteDataSource>(
      () => StorageRemoteDataSourceImpl(sl<SupabaseClient>()));
  sl.registerLazySingleton<FriendsRemoteDataSource>(
      () => FriendsRemoteDataSourceImpl(sl<SupabaseClient>()));
  sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(sl<SupabaseClient>()));
  sl.registerLazySingleton<StatusRemoteDataSource>(
      () => StatusRemoteDataSourceImpl(sl<SupabaseClient>()));
  // sl.registerLazySingleton<GroupRemoteDataSource>(() => GroupRemoteDataSourceImpl(sl<SupabaseClient>()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(sl<ProfileRemoteDataSource>(), sl<StorageRemoteDataSource>())); 

  // --- Repositories ---
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl<SupabaseClient>()));

  // ProfileRepositoryImpl: Pastikan konstruktornya: ProfileRepositoryImpl(this.profileRDS, this.storageRDS)
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(
        sl<ProfileRemoteDataSource>(), // Argumen positional pertama
        sl<StorageRemoteDataSource>(),  // Argumen positional kedua
      ));

  sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(sl<ChatRemoteDataSource>()));
  sl.registerLazySingleton<StorageRepository>(
      () => StorageRepositoryImpl(sl<StorageRemoteDataSource>()));
  sl.registerLazySingleton<FriendsRepository>(
      () => FriendsRepositoryImpl(sl<FriendsRemoteDataSource>()));
  sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(sl<NotificationRemoteDataSource>()));

  // StatusRepositoryImpl: Menggunakan argumen POSITIONAL sesuai definisi sebelumnya
  sl.registerLazySingleton<StatusRepository>(() => StatusRepositoryImpl(
        sl<StatusRemoteDataSource>(),    // Argumen positional pertama
        sl<StorageRemoteDataSource>(),   // Argumen positional kedua
        sl<FriendsRemoteDataSource>(),   // Argumen positional ketiga
      ));
  // sl.registerLazySingleton<GroupRepository>(() => GroupRepositoryImpl(sl<GroupRemoteDataSource>(), sl<StorageRemoteDataSource>()));


  // --- BLoCs / Cubits ---
  // Pastikan semua BLoC/Cubit memiliki konstruktor dengan named parameter yang sesuai.
  sl.registerFactory<AuthBloc>(
      () => AuthBloc(authRepository: sl<AuthRepository>()));

  sl.registerFactory<ProfileCubit>(() => ProfileCubit(
        profileRepository: sl<ProfileRepository>(),
        authBloc: sl<AuthBloc>(), // Pastikan ProfileCubit punya named param 'authBloc'
      ));

  sl.registerFactory<UserSearchCubit>(() => UserSearchCubit(
        profileRepository: sl<ProfileRepository>(),
      ));

  sl.registerFactoryParam<ChatBloc, String?, void>((conversationId, _) => ChatBloc(
        chatRepository: sl<ChatRepository>(),
        authBloc: sl<AuthBloc>(), // Pastikan ChatBloc punya named param 'authBloc'
        conversationId: conversationId!,
      ));

  sl.registerFactory<MessageInputCubit>(() => MessageInputCubit(
        chatRepository: sl<ChatRepository>(),
        authBloc: sl<AuthBloc>(), // Pastikan MessageInputCubit punya named param 'authBloc'
      ));

  sl.registerFactoryParam<FriendsBloc, String, void>((currentUserId, _) => FriendsBloc(
        friendsRepository: sl<FriendsRepository>(),
        currentUserId: currentUserId!,
      ));


 sl.registerFactoryParam<ConversationsBloc, String, void>((currentUserId, _) => ConversationsBloc(
      chatRepository: sl<ChatRepository>(),
      profileRepository: sl<ProfileRepository>(), // Tambahkan ini jika EnsureDmConversation menggunakan ProfileRepository
      currentUserId: currentUserId!,
    ));

  sl.registerFactoryParam<NotificationsBloc, String, void>((currentUserId, _) => NotificationsBloc(
        notificationRepository: sl<NotificationRepository>(),
        currentUserId: currentUserId!,
      ));

  sl.registerFactoryParam<StatusBloc, String, void>((currentUserId, _) => StatusBloc(
        statusRepository: sl<StatusRepository>(),
        currentUserId: currentUserId!,
      ));

  // // sl.registerFactoryParam<GroupsBloc, String, void>((currentUserId, _) => GroupsBloc(
  // //       groupRepository: sl<GroupRepository>(),
  // //       currentUserId: currentUserId!,
  // //     ));
}