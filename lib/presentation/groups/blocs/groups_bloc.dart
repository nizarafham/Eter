import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:chat_app/data/models/group_model.dart';
import 'package:chat_app/data/models/user_model.dart';
import 'package:chat_app/data/repositories/group_repository.dart';
import 'package:chat_app/data/repositories/chat_repository.dart';

part 'groups_event.dart';
part 'groups_state.dart';

class GroupsBloc extends Bloc<GroupsEvent, GroupsState> {
  final GroupRepository _groupRepository;
  final ChatRepository _chatRepository;
  final String _currentUserId;

  GroupsBloc({
    required GroupRepository groupRepository,
    required ChatRepository chatRepository,
    required String currentUserId,
  })  : _groupRepository = groupRepository,
        _chatRepository = chatRepository,
        _currentUserId = currentUserId,
        super(GroupsInitial()) {
    on<CreateGroup>(_onCreateGroup);
    on<LoadGroupDetails>(_onLoadGroupDetails);
    on<AddMembersToGroup>(_onAddMembersToGroup);
    on<RemoveMemberFromGroup>(_onRemoveMemberFromGroup);
    on<LeaveGroup>(_onLeaveGroup);
    on<UpdateGroupInfo>(_onUpdateGroupInfo);
  }

  Future<void> _onCreateGroup(CreateGroup event, Emitter<GroupsState> emit) async {
    emit(const GroupsLoading(operationMessage: "Membuat grup..."));
    try {
      final allMemberIds = List<String>.from(event.memberIds);
      if (!allMemberIds.contains(_currentUserId)) {
        allMemberIds.add(_currentUserId);
      }

      // Menggunakan positional arguments sesuai definisi GroupRepository Anda
      final group = await _groupRepository.createGroup(
        event.name, // name
        _currentUserId, // createdByUserId
        allMemberIds, // memberIds
        avatarImage: event.avatarImage, // avatarImage (named)
      );

      if (group != null) {
        final conversationId = await _chatRepository.createGroupConversation(
            groupId: group.id,
            groupName: group.name,
            memberIds: allMemberIds,
            groupAvatarUrl: group.avatarUrl,
            createdBy: _currentUserId,
        );
        emit(GroupOperationSuccess("Grup berhasil dibuat!", group: group, conversationId: conversationId));
      } else {
        emit(const GroupsError("Gagal membuat grup. Tidak ada data grup dikembalikan."));
      }
    } catch (e) {
      emit(GroupsError("Gagal membuat grup: ${e.toString()}"));
    }
  }

  Future<void> _onLoadGroupDetails(LoadGroupDetails event, Emitter<GroupsState> emit) async {
    emit(const GroupsLoading(operationMessage: "Memuat detail grup..."));
    try {
      final group = await _groupRepository.getGroupDetails(event.groupId);
      // Mengambil emisi pertama dari stream untuk daftar anggota awal
      final members = await _groupRepository.getGroupMembers(event.groupId).first;
      if (group != null) {
        emit(GroupDetailsLoaded(group: group, members: members));
      } else {
        emit(const GroupsError("Grup tidak ditemukan."));
      }
    } catch (e) {
      emit(GroupsError("Gagal memuat detail grup: ${e.toString()}"));
    }
  }

  Future<void> _onAddMembersToGroup(AddMembersToGroup event, Emitter<GroupsState> emit) async {
     emit(const GroupsLoading(operationMessage: "Menambahkan anggota..."));
    try {
      await _groupRepository.addMembersToGroup(event.groupId, event.userIdsToAdd);
      emit(const GroupOperationSuccess("Anggota berhasil ditambahkan."));
      add(LoadGroupDetails(event.groupId));
    } catch (e) {
      emit(GroupsError("Gagal menambahkan anggota: ${e.toString()}"));
    }
  }

  Future<void> _onRemoveMemberFromGroup(RemoveMemberFromGroup event, Emitter<GroupsState> emit) async {
    emit(const GroupsLoading(operationMessage: "Menghapus anggota..."));
    try {
      // Menghapus parameter 'removedBy' karena tidak ada di interface GroupRepository Anda
      await _groupRepository.removeMemberFromGroup(event.groupId, event.userIdToRemove);
      emit(const GroupOperationSuccess("Anggota berhasil dihapus."));
      add(LoadGroupDetails(event.groupId));
    } catch (e) {
      emit(GroupsError("Gagal menghapus anggota: ${e.toString()}"));
    }
  }

  Future<void> _onLeaveGroup(LeaveGroup event, Emitter<GroupsState> emit) async {
    emit(const GroupsLoading(operationMessage: "Keluar dari grup..."));
    try {
      await _groupRepository.leaveGroup(event.groupId, _currentUserId);
      emit(const GroupOperationSuccess("Anda telah keluar dari grup."));
    } catch (e) {
      emit(GroupsError("Gagal keluar dari grup: ${e.toString()}"));
    }
  }

  Future<void> _onUpdateGroupInfo(UpdateGroupInfo event, Emitter<GroupsState> emit) async {
     emit(const GroupsLoading(operationMessage: "Memperbarui info grup..."));
    try {
      // Menghapus parameter 'updatedBy'
      await _groupRepository.updateGroupInfo(
          event.groupId,
          name: event.newName, // named parameter
          avatarImage: event.newAvatarImage, // named parameter
      );
      emit(const GroupOperationSuccess("Info grup berhasil diperbarui."));
      add(LoadGroupDetails(event.groupId));
    } catch (e) {
      emit(GroupsError("Gagal memperbarui info grup: ${e.toString()}"));
    }
  }
}