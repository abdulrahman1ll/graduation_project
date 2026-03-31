class InviteService {
  const InviteService();

  String generateInviteLink(String groupId) {
    return Uri(
      scheme: 'https',
      host: 'kashta.app',
      path: '/join',
      queryParameters: <String, String>{'groupId': groupId},
    ).toString();
  }

  String? extractGroupId(String inviteLink) {
    final uri = Uri.tryParse(inviteLink);
    if (uri == null) {
      return null;
    }

    final isAppInvite = uri.scheme == 'app' && uri.host == 'join';
    final isWebInvite =
        uri.scheme == 'https' &&
        uri.host == 'kashta.app' &&
        uri.path == '/join';
    if (!isAppInvite && !isWebInvite) {
      return null;
    }

    final groupId = uri.queryParameters['groupId'];
    if (groupId == null || groupId.trim().isEmpty) {
      return null;
    }
    return groupId.trim();
  }
}
