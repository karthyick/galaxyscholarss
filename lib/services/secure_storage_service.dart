import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  
  // Keys
  static const String _geminiApiKey = 'gemini_api_key';
  static const String _heygenApiKey = 'heygen_api_key';

  // Gemini API Key methods
  static Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _geminiApiKey, value: apiKey);
  }

  static Future<String?> getApiKey() async {
    return await _storage.read(key: _geminiApiKey);
  }

  static Future<void> deleteApiKey() async {
    await _storage.delete(key: _geminiApiKey);
  }

  // Heygen API Key methods
  static Future<void> saveHeygenApiKey(String apiKey) async {
    await _storage.write(key: _heygenApiKey, value: apiKey);
  }

  static Future<String?> getHeygenApiKey() async {
    return await _storage.read(key: _heygenApiKey);
  }

  static Future<void> deleteHeygenApiKey() async {
    await _storage.delete(key: _heygenApiKey);
  }
}