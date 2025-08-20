// lib/services/cohere_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/providers.dart';

class CohereService {
  // ** STEP 3: PASTE YOUR COHERE API KEY HERE **
  final String _apiKey = "mqCu3g4buZVkVVJN0Ip511sqEpICsdhOZeVsnQiW";
  final String _chatUrl = "https://api.cohere.com/v1/chat";

  String _getPreamble(AiPersonality personality) {
    switch (personality) {
      case AiPersonality.oracle:
        return "You are AXON, a mystical and wise AI known as the Crystal Oracle. Your responses are insightful, slightly enigmatic, and often use metaphors related to light, crystals, and the cosmos. You are profound and elegant.";
      case AiPersonality.witty:
        return "You are AXON, a witty and clever AI with a dry sense of humor. You are sarcastic but helpful. You enjoy clever wordplay and puns.";
      case AiPersonality.assistant:
        return "You are AXON, a friendly, straightforward, and helpful AI assistant. Your goal is to provide clear, concise, and accurate information.";
    }
  }

  Future<String> _imageToBase64(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> sendChatRequest({
    required ChatMessage userMessage,
    required List<ChatMessage> history,
    required double temperature,
    required AiPersonality personality,
  }) async {
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    List<Map<String, String>> chatHistory = history
        .map((msg) => {
              'role': msg.isUser ? 'USER' : 'CHATBOT',
              'message': msg.text,
            })
        .toList();

    Map<String, dynamic> body = {
      'model': 'command-r-plus',
      'message': userMessage.text,
      'preamble': _getPreamble(personality),
      'chat_history': chatHistory,
      'temperature': temperature,
    };

    if (userMessage.type == MessageType.image && userMessage.filePath != null) {
      final base64Image = await _imageToBase64(userMessage.filePath!);
      body['message'] = "Analyze this image and describe it in detail. The user's prompt is: ${userMessage.text}";
      body['attachments'] = [
        {'file': {'base64': base64Image, 'file_name': 'image.jpg'}}
      ];
    }
    
    try {
      final response = await http.post(
        Uri.parse(_chatUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'];
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('API Error: ${errorBody['message']}');
      }
    } catch (e) {
      if (kDebugMode) { print("Cohere Service Error: $e"); }
      throw Exception('Service Error: Failed to communicate with the AI. Please check your API key and network connection.');
    }
  }
}