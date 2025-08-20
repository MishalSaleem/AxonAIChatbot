// lib/models/chat_message.dart

enum Sender { user, model }
enum MessageType { text, image, voice, generatedImage } // Added generatedImage

class ChatMessage {
  final String id;
  final String text;
  final Sender sender;
  final DateTime timestamp;
  final MessageType type;
  String? filePath; // Can be a local path, a Base64 URI, or a remote URL
  final Duration? audioDuration;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.type = MessageType.text,
    this.filePath,
    this.audioDuration,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();

  bool get isUser => sender == Sender.user;

  Map<String, dynamic> toApiJson() {
    String role = isUser ? 'user' : 'assistant';
    dynamic content = text;

    if (type == MessageType.image && filePath != null && filePath!.startsWith('data:')) {
      content = [
        {"type": "text", "text": text},
        {
          "type": "image_url",
          "image_url": {"url": filePath}
        }
      ];
    }
    return {'role': role, 'content': content};
  }
}