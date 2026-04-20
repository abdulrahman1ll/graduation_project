enum ChatMessageType {
  text('text'),
  link('link'),
  system('system');

  const ChatMessageType(this.value);

  final String value;

  static ChatMessageType fromValue(String value) {
    return ChatMessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChatMessageType.text,
    );
  }
}

enum GroupRole {
  admin('admin'),
  member('member');

  const GroupRole(this.value);

  final String value;

  static GroupRole fromValue(String value) {
    return GroupRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => GroupRole.member,
    );
  }
}
