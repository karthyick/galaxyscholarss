import 'package:flutter/material.dart';
import 'services/gemini_service.dart';

class LearnersPage extends StatefulWidget {
  final String board;
  final int standard;

  const LearnersPage({
    super.key,
    required this.board,
    required this.standard,
  });

  @override
  State<LearnersPage> createState() => _LearnersPageState();
}

class _LearnersPageState extends State<LearnersPage> {
  final GeminiService _geminiService = GeminiService();

  Map<String, List<String>> subjectsAndTopics = {};
  Map<String, List<String>> topicsAndSubtopics = {};
  String? selectedSubject;
  String? selectedTopic;
  String? selectedSubtopic;
  String? expandedSection;

  bool isLoadingSubjects = true;
  bool isLoadingTopics = false;
  bool isLoadingSubtopics = false;
  bool isLoadingContent = false;

  String? error;
  Map<String, dynamic> contentSections = {}; // Store the six content sections
  String ideaText = ''; // For discussion input

  @override
  void initState() {
    super.initState();
    _initializeAndFetchSubjects();
  }

  /// Initialize and fetch all subjects
  Future<void> _initializeAndFetchSubjects() async {
    try {
      setState(() {
        isLoadingSubjects = true;
        error = null;
      });

      await _geminiService.initialize();

      // Fetch subjects
      final fetchedSubjects = await _geminiService.fetchSubjects(
        board: widget.board,
        standard: widget.standard,
      );

      setState(() {
        subjectsAndTopics = {
          for (var subject in fetchedSubjects) subject: [],
        };
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoadingSubjects = false;
      });
    }
  }

  /// Fetch topics for a given subject
  Future<void> _fetchTopics(String subject) async {
    try {
      setState(() {
        isLoadingTopics = true;
        error = null;
      });

      final fetchedTopics = await _geminiService.fetchTopics(
        board: widget.board,
        standard: widget.standard,
        subject: subject,
      );

      setState(() {
        subjectsAndTopics[subject] = fetchedTopics;
        topicsAndSubtopics.clear(); // Reset subtopics
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoadingTopics = false;
      });
    }
  }

  /// Fetch subtopics for a given topic
  Future<void> _fetchSubtopics(String topic) async {
    try {
      setState(() {
        isLoadingSubtopics = true;
        error = null;
      });

      final fetchedSubtopics = await _geminiService.fetchSubtopics(
        board: widget.board,
        standard: widget.standard,
        subject: selectedSubject!,
        topic: topic,
      );

      setState(() {
        topicsAndSubtopics[topic] = fetchedSubtopics;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoadingSubtopics = false;
      });
    }
  }

  /// Fetch content for the six sections
  Future<void> _fetchContent() async {
    if (selectedSubject == null ||
        selectedTopic == null ||
        selectedSubtopic == null) return;

    try {
      setState(() {
        isLoadingContent = true;
        error = null;
      });

      final content = await _geminiService.fetchContent(
        board: widget.board,
        standard: widget.standard,
        subject: selectedSubject!,
        topic: selectedTopic!,
        subtopic: selectedSubtopic!,
      );

      setState(() {
        contentSections = content;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoadingContent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Learning Page - ${widget.board} (Grade ${widget.standard})'),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoadingSubjects
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildTopRow(context),
        Expanded(child: _buildBody(context)),
        _buildBottomRow(context),
      ],
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      color: Colors.grey[300],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Welcome to ${widget.board.toUpperCase()} (Grade ${widget.standard})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Select Subject'),
              value: selectedSubject,
              items: subjectsAndTopics.keys
                  .map((subject) => DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedSubject = value;
                  selectedTopic = null; // Reset topic
                  selectedSubtopic = null; // Reset subtopic
                  contentSections.clear(); // Clear previous content
                });
                if (value != null) {
                  _fetchTopics(value);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Select Topic'),
              value: selectedTopic,
              items: (selectedSubject != null
                      ? subjectsAndTopics[selectedSubject] ?? []
                      : [])
                  .map((topic) => DropdownMenuItem<String>(
                        value: topic,
                        child: Text(topic),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedTopic = value;
                  selectedSubtopic = null; // Reset subtopic
                  contentSections.clear(); // Clear previous content
                });
                if (value != null) {
                  _fetchSubtopics(value);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Select Subtopic'),
              value: selectedSubtopic,
              items: (selectedTopic != null
                      ? topicsAndSubtopics[selectedTopic] ?? []
                      : [])
                  .map((subtopic) => DropdownMenuItem<String>(
                        value: subtopic,
                        child: Text(subtopic),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedSubtopic = value;
                  contentSections.clear(); // Clear previous content
                });
                if (value != null) {
                  _fetchContent();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedSubject = null;
                selectedTopic = null;
                selectedSubtopic = null;
                contentSections.clear();
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (selectedSubtopic == null) {
      return const Center(
        child: Text(
          'Please select a subject, topic, and subtopic.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (isLoadingContent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contentSections.isEmpty) {
      return const Center(
        child: Text(
          'No content available. Select a subject, topic, and subtopic.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final sections = [
      "Official Definition",
      "Layman Explanation",
      "History",
      "Current Innovations",
      "Activity",
      "Diagram",
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText.rich(
                      _parseHighlightedContent(
                          contentSections[section] ?? "No content available."),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TextSpan _parseHighlightedContent(String content) {
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*'); // Match bold text
    final List<String> additionalKeys = [
      'sources',
      'example',
      'activity_types',
      'diagram_elements',
      'timeline',
      'people',
    ];

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    // Parse the main content for bold text
    final matches = exp.allMatches(content);
    for (var match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: content.substring(lastMatchEnd, match.start),
        ));
      }

      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastMatchEnd),
      ));
    }

    // Dynamically handle additional fields like sources, example, etc.
    for (var key in additionalKeys) {
      final keyExp = RegExp('$key:\\s*\\[(.*?)\\]',
          dotAll: true); // Match key and its list
      final match = keyExp.firstMatch(content);

      if (match != null) {
        final String rawValue = match.group(1) ?? '';
        final List<String> values =
            rawValue.split(',').map((e) => e.trim()).toList();

        spans.add(TextSpan(
          text: '\n\n${key[0].toUpperCase()}${key.substring(1)}:\n',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ));

        for (var value in values) {
          spans.add(TextSpan(
            text: '- $value\n',
            style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
          ));
        }
      }
    }

    return TextSpan(children: spans);
  }

  Widget _buildBottomRow(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Idea Discussion:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter your innovative idea...",
            ),
            maxLines: 3,
            onChanged: (value) {
              ideaText = value;
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _startIdeaDiscussion,
            child: const Text("Start Discussion"),
          ),
        ],
      ),
    );
  }

  /// Send idea discussion request to Gemini
  Future<void> _startIdeaDiscussion() async {
    if (ideaText.isEmpty) return;

    try {
      setState(() {
        isLoadingContent = true;
        error = null;
      });

      final response = await _geminiService.discussIdea(
          board: widget.board,
          standard: widget.standard,
          subject: selectedSubject ?? '',
          topic: selectedTopic ?? '',
          subtopic: selectedSubtopic ?? '',
          contentSections: contentSections,
          idea: ideaText);
      // Process and display the response

      final responseModified =
          _parseHighlightedContent(response ?? "No response received.");

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Discussion Result"),
          content: SingleChildScrollView(
            child: Text(
              responseModified.toPlainText(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoadingContent = false;
      });
    }
  }
}
