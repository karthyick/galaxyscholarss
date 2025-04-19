import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HeygenService {
  // API Constants
  static const String _baseUrl = 'https://api.heygen.com';
  static const String _apiVersion = 'v2'; // Updated to v2
  
  // Secure storage
  final _storage = const FlutterSecureStorage();
  static const String _apiKeyStorage = 'heygen_api_key';
  
  String? _apiKey;
  
  /// Initialize the Heygen service by loading the API key
  Future<void> initialize() async {
    _apiKey = await _storage.read(key: _apiKeyStorage);
    if (_apiKey == null) {
      throw Exception('Heygen API key not found. Please set it in settings.');
    }
  }
  
  /// Fetch available avatars from Heygen
  Future<List<Map<String, dynamic>>> fetchAvatars() async {
    if (_apiKey == null) {
      await initialize();
    }
    
    final response = await http.get(
      Uri.parse('$_baseUrl/$_apiVersion/avatars'),
      headers: {
        'Accept': 'application/json',
        'X-Api-Key': _apiKey!,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']['avatars']);
    } else {
      throw Exception('Failed to fetch avatars: ${response.body}');
    }
  }
  
  /// Fetch available voices from Heygen
  Future<List<Map<String, dynamic>>> fetchVoices() async {
    if (_apiKey == null) {
      await initialize();
    }
    
    final response = await http.get(
      Uri.parse('$_baseUrl/$_apiVersion/voices'),
      headers: {
        'Accept': 'application/json',
        'X-Api-Key': _apiKey!,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']['voices']);
    } else {
      throw Exception('Failed to fetch voices: ${response.body}');
    }
  }
  
  /// Generate a video using Heygen API v2
  Future<String> generateVideo({
    required String script, 
    required String title,
    String? avatarId,
    String? voiceId
  }) async {
    if (_apiKey == null) {
      await initialize();
    }
    
    // If no avatar or voice is specified, get the first available ones
    String effectiveAvatarId;
    String effectiveVoiceId;
    
    if (avatarId == null || voiceId == null) {
      final avatars = await fetchAvatars();
      final voices = await fetchVoices();
      
      if (avatars.isEmpty) {
        throw Exception('No avatars available');
      }
      if (voices.isEmpty) {
        throw Exception('No voices available');
      }
      
      effectiveAvatarId = avatarId ?? avatars.first['avatar_id'];
      effectiveVoiceId = voiceId ?? voices.first['voice_id'];
    } else {
      effectiveAvatarId = avatarId;
      effectiveVoiceId = voiceId;
    }
    
    try {
      // Step 1: Generate the video
      final videoId = await _generateVideoRequest(script, effectiveAvatarId, effectiveVoiceId);
      
      // Step 2: Poll for video completion
      final videoUrl = await _pollVideoCompletion(videoId);
      
      return videoUrl;
    } catch (e) {
      throw Exception('Failed to generate video: $e');
    }
  }
  
  /// Make the video generation request to Heygen API
  Future<String> _generateVideoRequest(String script, String avatarId, String voiceId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$_apiVersion/video/generate'),
      headers: {
        'Content-Type': 'application/json',
        'X-Api-Key': _apiKey!,
      },
      body: jsonEncode({
        'video_inputs': [
          {
            'character': {
              'type': 'avatar',
              'avatar_id': avatarId,
              'avatar_style': 'normal'
            },
            'voice': {
              'type': 'text',
              'input_text': script,
              'voice_id': voiceId,
              'speed': 1.0
            }
          }
        ],
        'dimension': {
          'width': 1280,
          'height': 720
        }
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['data']['video_id'];
    } else {
      throw Exception('Failed to create video: ${response.body}');
    }
  }
  
  /// Poll for video completion
  Future<String> _pollVideoCompletion(String videoId) async {
    const maxAttempts = 30;
    const pollingInterval = Duration(seconds: 10);
    
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      attempts++;
      
      final response = await http.get(
        Uri.parse('$_baseUrl/v1/video_status.get?video_id=$videoId'),
        headers: {
          'Accept': 'application/json',
          'X-Api-Key': _apiKey!,
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['data']['status'];
        
        if (status == 'completed') {
          return data['data']['video_url'];
        } else if (status == 'failed') {
          throw Exception('Video generation failed: ${data['data']['error'] ?? "Unknown error"}');
        }
        
        await Future.delayed(pollingInterval);
      } else {
        throw Exception('Failed to check video status: ${response.body}');
      }
    }
    
    throw Exception('Video generation timed out after $maxAttempts attempts');
  }
  
  /// Save Heygen API key to secure storage
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyStorage, value: apiKey);
    _apiKey = apiKey;
  }
  
  /// Get Heygen API key from secure storage
  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyStorage);
  }
  
  /// Delete Heygen API key from secure storage
  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyStorage);
    _apiKey = null;
  }
  
  /// Method to check if API key is valid by making a test request
  Future<bool> isApiKeyValid(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiVersion/avatars'),
        headers: {
          'Accept': 'application/json',
          'X-Api-Key': apiKey,
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}