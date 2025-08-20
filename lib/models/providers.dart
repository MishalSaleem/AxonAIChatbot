// lib/models/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/cohere_service.dart';
import 'chat_message.dart';

var uuid = const Uuid();

enum AiPersonality { oracle, witty, assistant }

class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
  });

  ChatSession copyWith({String? title, List<ChatMessage>? messages}) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt,
    );
  }
}

final cohereProvider = Provider<CohereService>((ref) => CohereService());
final isLoadingProvider = StateProvider<bool>((ref) => false);
final activeSessionIdProvider = StateProvider<String?>((ref) => null);
final temperatureProvider = StateProvider<double>((ref) => 0.3);
final selectedPersonalityProvider = StateProvider<AiPersonality>((ref) => AiPersonality.oracle);

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, List<ChatSession>>((ref) {
  return SessionsNotifier(ref);
});

class SessionsNotifier extends StateNotifier<List<ChatSession>> {
  final Ref _ref;
  SessionsNotifier(this._ref) : super([]);

  void createNewSession() {
    final newSession = ChatSession(
      id: uuid.v4(),
      title: "New Chat",
      messages: [],
      createdAt: DateTime.now(),
    );
    state = [newSession, ...state];
    _ref.read(activeSessionIdProvider.notifier).state = newSession.id;
  }

  void deleteSession(String sessionId) {
    state = state.where((s) => s.id != sessionId).toList();
    if (_ref.read(activeSessionIdProvider) == sessionId) {
      _ref.read(activeSessionIdProvider.notifier).state =
          state.isNotEmpty ? state.first.id : null;
    }
  }

  void clearAllSessions() {
    state = [];
    _ref.read(activeSessionIdProvider.notifier).state = null;
  }

  Future<void> sendMessage(ChatMessage userMessage) async {
    final activeId = _ref.read(activeSessionIdProvider);
    if (activeId == null) return;

    final isLoadingNotifier = _ref.read(isLoadingProvider.notifier);
    final aiService = _ref.read(cohereProvider);
    final temp = _ref.read(temperatureProvider);
    final personality = _ref.read(selectedPersonalityProvider);

    _addMessageToSession(activeId, userMessage);
    isLoadingNotifier.state = true;

    try {
      final activeSession = state.firstWhere((s) => s.id == activeId);
      
      final history = activeSession.messages.length > 8
          ? activeSession.messages.sublist(activeSession.messages.length - 8)
          : activeSession.messages;

      final aiResponseText = await aiService.sendChatRequest(
        userMessage: userMessage,
        history: history.where((m) => m.id != userMessage.id).toList(),
        temperature: temp,
        personality: personality,
      );

      final aiMessage = ChatMessage(
          text: aiResponseText,
          sender: Sender.model,
          timestamp: DateTime.now());
      _addMessageToSession(activeId, aiMessage);
    } catch (e) {
      final errorMessage = ChatMessage(
          text: e.toString().replaceFirst("Exception: ", ""),
          sender: Sender.model, 
          timestamp: DateTime.now());
      _addMessageToSession(activeId, errorMessage);
    } finally {
      isLoadingNotifier.state = false;
    }
  }

  void _addMessageToSession(String sessionId, ChatMessage message) {
    state = [
      for (final session in state)
        if (session.id == sessionId)
          session.copyWith(
            title: session.messages.isEmpty && message.isUser
                ? (message.text.length > 30 ? '${message.text.substring(0, 30)}...' : message.text)
                : session.title,
            messages: [...session.messages, message],
          )
        else
          session,
    ];
  }
}