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
