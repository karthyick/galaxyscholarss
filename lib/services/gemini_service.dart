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

  /// Retry helper function
  Future<T> _retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 10,
    Duration delay = const Duration(seconds: 2),
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          rethrow; // Rethrow the exception if max attempts are reached
        }
        await Future.delayed(delay);
      }
    }
  }

  /// Fetch subjects
  Future<List<String>> fetchSubjects({
    required String board,
    required int standard,
  }) async {
    return _retry(() async {
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
        return _extractListFromResponse(text);
      } else {
        throw Exception("Failed to call Gemini API: ${response.body}");
      }
    });
  }

  /// Fetch topics
  Future<List<String>> fetchTopics({
    required String board,
    required int standard,
    required String subject,
  }) async {
    return _retry(() async {
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
        return _extractListFromResponse(text);
      } else {
        throw Exception("Failed to call Gemini API: ${response.body}");
      }
    });
  }

  /// Fetch subtopics
  Future<List<String>> fetchSubtopics({
    required String board,
    required int standard,
    required String subject,
    required String topic,
  }) async {
    return _retry(() async {
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
                    "For board $board, standard $standard, subject $subject, and topic $topic, list all subtopics available in this format: [Subtopic1, Subtopic2, Subtopic3].",
              },
            ]
          }
        ]
      };

      final jsonContent = jsonEncode(requestBody);
      final url =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey";

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
        return _extractListFromResponse(text);
      } else {
        throw Exception("Failed to call Gemini API: ${response.body}");
      }
    });
  }

  /// Fetch content for the six sections
  Future<Map<String, String>> fetchContent({
    required String board,
    required int standard,
    required String subject,
    required String topic,
    required String subtopic,
  }) async {
    return _retry(() async {
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
                    "You are an expert educator tasked with creating highly detailed and engaging learning content. Your goal is to develop a comprehensive resource for a specific concept, tailored for a particular educational context.\n\nGenerate comprehensive and deeply informative content for the following concept:\n\n**Board:** $board\n**Standard:** $standard\n**Subject:** $subject\n**Topic:** $topic\n**Subtopic:** $subtopic\n\nOrganize your response into the following sections using the precise JSON format provided below. Each section should be treated as an independent unit, ensuring a thorough exploration of the given subtopic from multiple perspectives.\n\n```json\n{\n  \"Official Definition\": {\n    \"content\": \"Provide a precise, comprehensive, and academically rigorous definition of the concept, citing authoritative sources where applicable. Include relevant technical terminology and formulas, if any, and explain their significance. Aim for accuracy and clarity, suitable for a learner with some prior knowledge of the subject. Use at least 500 words.\",\n    \"sources\": [\"List at least 3 reputable sources used for this definition\"]\n  },\n\n  \"Layman Explanation\": {\n    \"content\": \"Explain the concept in a manner easily understood by someone with no prior knowledge of the subject. Break down complex ideas into small, digestible paragraphs, using simple language and real-world analogies. Avoid jargon and focus on building an intuitive understanding. Use at least 500 words and ensure the explanation is divided into at least 5 separate paragraphs, each focusing on a specific aspect of the concept. Use **bold text** to highlight key ideas and concepts.\",\n    \"example\": \"Include at least one real-world example to illustrate the concept in a practical context. Explain how this example demonstrates the key principles of the concept.\"\n  },\n\n  \"History\": {\n    \"content\": \"Trace the historical development of the concept from its origins to its present form. Highlight key milestones, influential figures, and major breakthroughs. Include information about **early conceptualizations, initial applications, and significant refinements over time**. Provide a narrative that showcases the evolution of understanding and the interplay of ideas that shaped the concept. Include the latest advancements and research, if applicable. Detail the companies and individuals currently working on developing or applying this concept. Aim for a minimum of 1000 words.\",\n    \"timeline\": [\n      {\"year\": \"Year of event\", \"event\": \"Brief description of a significant event in the history of the concept\"},\n      {\"year\": \"Another year\", \"event\": \"Description of another event\"}\n    ]\n  },\n\n  \"Current Innovations\": {\n    \"content\": \"Explore the latest innovations and advancements related to the concept. Describe ongoing research, emerging technologies, and potential future developments. Provide specific examples of companies and individuals driving innovation in this area. Discuss the **potential impact of these innovations on various industries and society as a whole**. This section should be forward-looking and inspirational, offering insights into the cutting edge of the field. Include information for at least 5 different innovations, and dedicate at least 200 words to each. Aim for a minimum of 1000 words in total.\",\n    \"innovations\": [\n      {\"name\": \"Innovation Name\", \"description\": \"Detailed description of the innovation, its purpose, and its potential impact\", \"companies\": [\"List of companies involved in developing this innovation\"], \"people\": [\"List of key individuals leading research or development of this innovation\"]}\n    ]\n  },\n\n  \"Activity\": {\n    \"content\": \"Design at least 3 engaging and interactive  activities that help learners understand the concept in a fun and challenging way. These activities should encourage active learning and critical thinking. Provide clear instructions for each activity and specify the learning objectives. Examples include: **crossword puzzles with clues related to the concept, matching games pairing terms with definitions, problem-solving scenarios requiring application of the concept, coding challenges for computational concepts, or creative design tasks for artistic concepts**. Make the activities progressively challenging. Explain how each puzzle aids in understanding specific aspects of the concept. Aim for a minimum of 1000 words of the puzzles.\",\n    \"activity_types\": [\"Example: Crossword\", \"Example: Matching Game\", \"Example: Problem-Solving Scenario\"]\n  },\n\n  \"Diagram\": {\n    \"content\": \"Create a detailed textual description of a visual diagram that effectively illustrates the concept. The diagram should be designed to enhance understanding and provide a clear visual representation of the key elements and their relationships. Explain each component of the diagram and how it relates to the overall concept. The explanation should be so detailed that someone could recreate the diagram based solely on your text. Also describe multiple alternative diagrams that could be used and explain why the chosen one is most suitable. Mention specific software or tools that could be used to create such diagrams. Aim for a minimum of 1000 words.\",\n    \"diagram_elements\": [\"List of key elements in the diagram and their relationships\"]\n  }\n}\n```"
              }
            ]
          }
        ]
      };

      final jsonContent = jsonEncode(requestBody);
      final url =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey";

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
        final Map<String, dynamic> contentMap = jsonDecode(cleanText);
        return contentMap.map((key, value) => MapEntry(key, value.toString()));
      } else {
        throw Exception("Failed to call Gemini API: ${response.body}");
      }
    });
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
