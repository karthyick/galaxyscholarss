import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _geminiAccessKey = 'geminiaccesskey'; // Constant key name

  // Save the Gemini API Key
  static Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _geminiAccessKey, value: apiKey);
  }

  // Retrieve the Gemini API Key
  static Future<String?> getApiKey() async {
    return await _storage.read(key: _geminiAccessKey);
  }

  // Delete the Gemini API Key
  static Future<void> deleteApiKey() async {
    await _storage.delete(key: _geminiAccessKey);
  }
}
