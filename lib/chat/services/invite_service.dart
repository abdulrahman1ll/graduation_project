class InviteService {
  const InviteService();

  String generateInviteLink(String groupId) {
    return Uri(
      scheme: 'app',
      host: 'join',
      queryParameters: <String, String>{'groupId': groupId},
    ).toString();
  }

  String? extractGroupId(String inviteLink) {
    final uri = Uri.tryParse(inviteLink);
    if (uri == null || uri.scheme != 'app' || uri.host != 'join') {
      return null;
    }
    final groupId = uri.queryParameters['groupId'];
    if (groupId == null || groupId.trim().isEmpty) {
      return null;
    }
    return groupId.trim();
  }
}
