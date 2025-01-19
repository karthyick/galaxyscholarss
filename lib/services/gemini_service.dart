import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';

class GeminiService {
  String? _apiKey;

  GeminiService();

  /// Initialize the Gemini service by fetching the API key from secure storage
  Future<void> initialize() async {
    _apiKey = await SecureStorageService.getApiKey();
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
          "Gemini API key is missing. Please set it in the secure storage.");
    }
  }

  /// Fetch subjects
  Future<List<String>> fetchSubjects({
    required String board,
    required int standard,
  }) async {
    if (_apiKey == null) {
      throw Exception("Gemini API key is not initialized.");
    }

    final requestBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text":
                  "For board $board and standard $standard, list all subjects available in the book in this format: [Subject1, Subject2, Subject3]",
            },
          ]
        }
      ]
    };

    final jsonContent = jsonEncode(requestBody);
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonContent,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        final subjects = _extractListFromResponse(text);
        return subjects;
      } else {
        throw Exception("Failed to call Gemini API: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error calling Gemini API: $e");
    }
  }

  /// Fetch content for the six sections
  Future<Map<String, String>> fetchContent({
    required String board,
    required int standard,
    required String subject,
    required String topic,
  }) async {
    if (_apiKey == null) {
      throw Exception("Gemini API key is not initialized.");
    }

    final requestBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text":
                  "For board $board, standard $standard, subject $subject, and topic $topic, provide detailed content for the following sections in this JSON format: {\"Official Definition\": \"...\", \"Layman Explanation\": \"...\", \"Inventor\": \"...\", \"Current Innovations\": \"...\", \"Puzzle Activity\": \"...\", \"Diagram\": \"...\"}. All lot more maximum details to all sections, refer lot documents and books. and give me detailed, lot more detail should help me to understand about that, include how this topic contributed in today's world. Each section minimum 1000 words",
            },
          ]
        }
      ]
    };

    final jsonContent = jsonEncode(requestBody);
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonContent,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        final cleanText =
            text.replaceAll('```json', '').replaceAll('```', '').trim();
        // Parse the JSON string response into a Map
        final Map<String, dynamic> contentMap = jsonDecode(cleanText);

        // Convert to Map<String, String> and return
        return contentMap.map((key, value) => MapEntry(key, value.toString()));
      } else {
        throw Exception("Failed to call Gemini API: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error calling Gemini API: $e");
    }
  }

  /// Fetch topics
  Future<List<String>> fetchTopics({
    required String board,
    required int standard,
    required String subject,
  }) async {
    if (_apiKey == null) {
      throw Exception("Gemini API key is not initialized.");
    }

    final requestBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text":
                  "For board $board, standard $standard, and subject $subject, list all topics available in this format: [Topic1, Topic2, Topic3]",
            },
          ]
        }
      ]
    };

    final jsonContent = jsonEncode(requestBody);
    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonContent,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        final topics = _extractListFromResponse(text);
        return topics;
      } else {
        throw Exception("Failed to call Gemini API: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error calling Gemini API: $e");
    }
  }

  /// Helper function to extract a list from a Gemini response
  List<String> _extractListFromResponse(String response) {
    final regex = RegExp(r'\[([^\]]+)\]');
    final match = regex.firstMatch(response);
    if (match != null) {
      final listString = match.group(1);
      return listString!.split(',').map((s) => s.trim()).toList();
    }
    return [];
  }
}
