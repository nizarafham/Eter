import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/conversation_model.dart';
import 'package:chat_app/data/repositories/chat_repository.dart';
import 'package:chat_app/data/repositories/profile_repository.dart'; // Untuk mengambil detail user lain

part 'conversations_event.dart';
part 'conversations_state.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final ChatRepository _chatRepository;
  final ProfileRepository _profileRepository; // Opsional, untuk mengambil detail user jika DM baru
  final String _currentUserId;
  StreamSubscription? _conversationsSubscription;

  ConversationsBloc({
    required ChatRepository chatRepository,
    required ProfileRepository profileRepository, // Opsional
    required String currentUserId,
  })  : _chatRepository = chatRepository,
        _profileRepository = profileRepository,
        _currentUserId = currentUserId,
        super(ConversationsInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<_ConversationsUpdated>(_onConversationsUpdated);
    on<EnsureDmConversation>(_onEnsureDmConversation);
  }

   List<ConversationModel> _getCurrentConversationsFromState() {
    if (state is ConversationsLoaded) return (state as ConversationsLoaded).conversations;
    if (state is ConversationsLoading) return (state as ConversationsLoading).currentConversations;
    if (state is ConversationsError) return (state as ConversationsError).currentConversations;
    return const [];
  }

  void _onLoadConversations(LoadConversations event, Emitter<ConversationsState> emit) {
    emit(ConversationsLoading(currentConversations: _getCurrentConversationsFromState()));
    _conversationsSubscription?.cancel();
    _conversationsSubscription = _chatRepository.getConversations(_currentUserId).listen(
      (conversations) {
        add(_ConversationsUpdated(conversations));
      },
      onError: (error) => emit(ConversationsError(
          "Gagal memuat percakapan: ${error.toString()}",
          currentConversations: _getCurrentConversationsFromState(),
      )),
    );
  }

  void _onConversationsUpdated(_ConversationsUpdated event, Emitter<ConversationsState> emit) {
    emit(ConversationsLoaded(event.conversations));
  }

  Future<void> _onEnsureDmConversation(EnsureDmConversation event, Emitter<ConversationsState> emit) async {
    // Fungsi ini untuk memastikan percakapan DM ada, dan jika tidak, membuatnya.
    // Kemudian emit NavigateToChatDetail.
    // Ini lebih cocok jika Anda tidak memiliki daftar kontak/teman yang jelas untuk memulai chat.
    // Jika Anda memulai chat dari daftar teman, logika ini mungkin ada di FriendsBloc/FriendsScreen.

    // Tampilkan loading sementara
    final currentConvos = _getCurrentConversationsFromState();
    emit(ConversationsLoading(currentConversations: currentConvos)); // Atau state khusus "ProcessingDM"

    try {
      final conversationId = await _chatRepository.getOrCreateDmConversation(_currentUserId, event.otherUserId);
      if (conversationId != null) {
        // Ambil detail user lain untuk nama tampilan
        final otherUser = await _profileRepository.getUserProfile(event.otherUserId);
        final displayName = otherUser?.username ?? "Chat";
        emit(NavigateToChatDetail(conversationId, displayName));
        // Setelah navigasi, kembali ke state loaded agar UI tidak stuck di loading
        // atau biarkan UI yang menangani navigasi dan BLoC kembali ke state stabil.
        // emit(ConversationsLoaded(currentConvos)); // atau panggil LoadConversations lagi
      } else {
        emit(ConversationsError("Tidak dapat memulai percakapan DM.", currentConversations: currentConvos));
      }
    } catch (e) {
      emit(ConversationsError("Error memulai DM: ${e.toString()}", currentConversations: currentConvos));
    }
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    return super.close();
  }
}