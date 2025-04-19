import 'package:flutter/material.dart';
import 'learning_page.dart';
import 'services/secure_storage_service.dart';
import 'services/sqlite_service.dart';
import 'services/heygen_service.dart'; // Import the Heygen service

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO Database
  // Initialize SQLite database
  // final sqliteService = SQLiteService();
  // await sqliteService.initialize();
  runApp(const GalaxyScholarsApp());
}

class GalaxyScholarsApp extends StatelessWidget {
  const GalaxyScholarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedBoard;
  int? selectedStandard;
  final HeygenService _heygenService = HeygenService(); // Create Heygen service
  bool _isTestingHeygenKey = false;

  @override
  void initState() {
    super.initState();
    _checkApiKeys();
  }

  // Check both Gemini and Heygen API keys
  Future<void> _checkApiKeys() async {
    // Check Gemini API Key
    final geminiApiKey = await SecureStorageService.getApiKey();
    if (geminiApiKey == null || geminiApiKey.isEmpty) {
      _promptForGeminiApiKey();
    }
    
    // Check Heygen API Key
    final heygenApiKey = await _heygenService.getApiKey();
    if (heygenApiKey == null || heygenApiKey.isEmpty) {
      _promptForHeygenApiKey();
    }
  }

  void _promptForGeminiApiKey({String? previousKey}) {
    final TextEditingController apiKeyController =
        TextEditingController(text: previousKey);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Gemini API Key Required"),
          content: TextField(
            controller: apiKeyController,
            decoration: InputDecoration(
              labelText: "Enter Gemini API Key",
              hintText: "e.g., AIzaSyC...",
              helperText:
                  previousKey != null ? "Previous Key: $previousKey" : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (previousKey == null)
                  _promptForGeminiApiKey(); // Reprompt if user cancels during initial setup
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final enteredKey = apiKeyController.text.trim();
                if (enteredKey.isNotEmpty) {
                  await SecureStorageService.saveApiKey(enteredKey);
                  Navigator.of(context).pop();
                  
                  // After setting Gemini key, check Heygen key
                  final heygenApiKey = await _heygenService.getApiKey();
                  if (heygenApiKey == null || heygenApiKey.isEmpty) {
                    _promptForHeygenApiKey();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("API Key cannot be empty."),
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // New method to prompt for Heygen API key with validation
 // Inside the _promptForHeygenApiKey method in main.dart, replace the API key validation dialog:

void _promptForHeygenApiKey({String? previousKey}) {
  final TextEditingController apiKeyController =
      TextEditingController(text: previousKey);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Heygen API Key Required"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: apiKeyController,
                  decoration: InputDecoration(
                    labelText: "Enter Heygen API Key",
                    hintText: "Format: Base64-encoded string",
                    helperText:
                        previousKey != null ? "Previous Key: $previousKey" : null,
                    prefixIcon: const Icon(Icons.key),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "1. Go to https://studio.heygen.com/settings/api-keys",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  "2. Create a new API key with video generation permissions",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  "3. Copy the entire API key",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_isTestingHeygenKey)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text("Validating API key...", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (previousKey == null)
                    _promptForHeygenApiKey(); // Reprompt if user cancels during initial setup
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isTestingHeygenKey ? null : () async {
                  final enteredKey = apiKeyController.text.trim();
                  if (enteredKey.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("API Key cannot be empty."),
                      ),
                    );
                    return;
                  }
                  
                  // Basic validation - just check that it's a reasonable length and format
                  if (enteredKey.length < 20) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("API key seems too short. Please check your key."),
                      ),
                    );
                    return;
                  }
                  
                  // Test the API key
                  setState(() => _isTestingHeygenKey = true);
                  
                  final isValid = await _heygenService.isApiKeyValid(enteredKey);
                  
                  if (isValid) {
                    await _heygenService.saveApiKey(enteredKey);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Heygen API Key verified and saved successfully."),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Invalid Heygen API key. Please check your key and try again."),
                        duration: Duration(seconds: 4),
                      ),
                    );
                    setState(() => _isTestingHeygenKey = false);
                  }
                },
                child: const Text("Verify & Save"),
              ),
            ],
          );
        }
      );
    },
  );
}

  // Method to reset both API keys
  void _resetApiKeys() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("API Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choose which API key to manage:"),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.api, color: Colors.blue),
                title: const Text("Gemini API Key"),
                subtitle: const Text("Used for content generation"),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  Navigator.pop(context);
                  _resetGeminiApiKey();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.green),
                title: const Text("Heygen API Key"),
                subtitle: const Text("Used for video generation"),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  Navigator.pop(context);
                  _resetHeygenApiKey();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _resetGeminiApiKey() async {
    final previousKey = await SecureStorageService.getApiKey();

    // Delete the previous key and prompt for a new one
    await SecureStorageService.deleteApiKey();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Gemini API Key has been reset. Please enter a new one."),
      ),
    );
    _promptForGeminiApiKey(previousKey: previousKey); // Show the previous key
  }

  // New method to reset Heygen API key
  void _resetHeygenApiKey() async {
    final previousKey = await _heygenService.getApiKey();

    // Delete the previous key and prompt for a new one
    await _heygenService.deleteApiKey();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Heygen API Key has been reset. Please enter a new one."),
      ),
    );
    _promptForHeygenApiKey(previousKey: previousKey); // Show the previous key
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GalaxyScholars'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'API Settings',
            onPressed: _resetApiKeys,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('background_image.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GalaxyScholars',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Pacifico',
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 400,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select Board'),
                      value: selectedBoard,
                      items: const [
                        DropdownMenuItem(value: 'cbse', child: Text('CBSE')),
                        DropdownMenuItem(value: 'icse', child: Text('ICSE')),
                        // DropdownMenuItem(
                        //     value: 'state',
                        //     child: Text('Tamilnadu State Board')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedBoard = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 400,
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text('Select Standard'),
                      value: selectedStandard,
                      items: [
                        for (int i = 1; i <= 12; i++)
                          DropdownMenuItem(
                            value: i,
                            child: Text(
                                '$i${i == 1 ? 'st' : i == 2 ? 'nd' : i == 3 ? 'rd' : 'th'}'),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStandard = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () {
                  if (selectedBoard != null && selectedStandard != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LearnersPage(
                          board: selectedBoard!,
                          standard: selectedStandard!,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select both board and standard'),
                      ),
                    );
                  }
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}