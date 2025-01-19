import 'package:flutter/material.dart';
import 'learning_page.dart';
import 'services/secure_storage_service.dart';
import 'services/sqlite_service.dart';

void main() async {
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

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final apiKey = await SecureStorageService.getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      _promptForApiKey();
    }
  }

  void _promptForApiKey({String? previousKey}) {
    final TextEditingController apiKeyController =
        TextEditingController(text: previousKey);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("API Key Required"),
          content: TextField(
            controller: apiKeyController,
            decoration: InputDecoration(
              labelText: "Enter Gemini API Key",
              hintText: "e.g., your-api-key",
              helperText:
                  previousKey != null ? "Previous Key: $previousKey" : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (previousKey == null)
                  _promptForApiKey(); // Reprompt if user cancels during initial setup
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final enteredKey = apiKeyController.text.trim();
                if (enteredKey.isNotEmpty) {
                  await SecureStorageService.saveApiKey(enteredKey);
                  Navigator.of(context).pop();
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

  void _resetApiKey() async {
    final previousKey = await SecureStorageService.getApiKey();

    // Delete the previous key and prompt for a new one
    await SecureStorageService.deleteApiKey();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("API Key has been reset. Please enter a new one."),
      ),
    );
    _promptForApiKey(previousKey: previousKey); // Show the previous key
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GalaxyScholars'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset API Key',
            onPressed: _resetApiKey,
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
