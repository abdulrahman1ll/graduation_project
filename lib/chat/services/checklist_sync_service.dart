import 'chat_service.dart';

class ChecklistSyncService {
  ChecklistSyncService({ChatService? chatService})
      : _chatService = chatService ?? ChatService();

  final ChatService _chatService;

  Future<void> notifyItemAdded({
    required String groupId,
    required String actorName,
    required String itemName,
  }) {
    return _chatService.sendChecklistItemAddedMessage(
      groupId: groupId,
      actorName: actorName,
      itemName: itemName,
    );
  }

  Future<void> notifyItemCompleted({
    required String groupId,
    required String actorName,
    required String itemName,
  }) {
    return _chatService.sendChecklistItemCompletedMessage(
      groupId: groupId,
      actorName: actorName,
      itemName: itemName,
    );
  }
}
