import 'widgets/video/heygen_video_player.dart';
import 'package:flutter/material.dart';
import 'services/gemini_service.dart';
import 'services/heygen_service.dart'; // We'll create this service for Heygen API
import 'widgets/video/avatar_voice_selector.dart';
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

class _LearnersPageState extends State<LearnersPage> with SingleTickerProviderStateMixin {
  final GeminiService _geminiService = GeminiService();
  final HeygenService _heygenService = HeygenService(); // New service for Heygen

  // Tab Controller
  late TabController _tabController;

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
  bool isLoadingVideo = false;

  String? error;
  Map<String, dynamic> contentSections = {}; // Store the six content sections
  String ideaText = ''; // For discussion input
  
  // Video related properties
  String? videoUrl;
  bool videoGenerated = false;
    /// Generate video using Heygen API with the Official Definition
  bool _showAvatarSelector = false;
String? _selectedAvatarId;
String? _selectedVoiceId;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAndFetchSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        videoGenerated = false; // Reset video status when new content is loaded
        videoUrl = null;
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


// Update the method to accept avatar and voice IDs
Future<void> _generateVideo(String avatarId, String voiceId) async {
  if (contentSections.isEmpty || contentSections['Official Definition'] == null) {
    setState(() {
      error = "No content available for video generation.";
    });
    return;
  }

  try {
    setState(() {
      isLoadingVideo = true;
      error = null;
    });

    // Extract the official definition for the script
    String script = contentSections['Official Definition'] as String;
    
    // Estimate: Roughly 150 characters per minute of speech
    // So for 3 minutes (180 seconds) limit, keep to around 450 characters
    const int maxCharLimit = 450;
    
    if (script.length > maxCharLimit) {
      script = script.substring(0, maxCharLimit);
      script += "... (content trimmed to fit within video length limitations)";
      
      // Show a warning that content was trimmed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Content was trimmed to fit within the 3-minute video limitation."),
          duration: Duration(seconds: 5),
        ),
      );
    }
    
    // Call Heygen API to generate video with selected avatar and voice
    final generatedVideoUrl = await _heygenService.generateVideo(
      script: script,
      title: "$selectedSubject - $selectedTopic - $selectedSubtopic",
      avatarId: avatarId,
      voiceId: voiceId,
    );

    setState(() {
      videoUrl = generatedVideoUrl;
      videoGenerated = true;
      isLoadingVideo = false;
    });
  } catch (e) {
    setState(() {
      error = "Video generation error: ${e.toString()}";
      isLoadingVideo = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learning Page - ${widget.board} (Grade ${widget.standard})'),
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
        _buildTabBar(),
        Expanded(child: _buildTabBarView()),
        _buildBottomRow(context),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(
          icon: Icon(Icons.video_library),
          text: "Video Explanation",
        ),
        Tab(
          icon: Icon(Icons.menu_book),
          text: "Content Sections",
        ),
      ],
      labelColor: Colors.deepPurple,
      unselectedLabelColor: Colors.grey,
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildVideoTab(),
        _buildContentTab(),
      ],
    );
  }

 Widget _buildVideoTab() {
  if (selectedSubtopic == null) {
    return const Center(
      child: Text(
        'Please select a subject, topic, and subtopic.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  if (isLoadingVideo) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Generating video... This may take a minute or two."),
        ],
      ),
    );
  }

  if (!videoGenerated) {
    // Show avatar and voice selection if not yet generated
    if (_showAvatarSelector) {
      return AvatarVoiceSelector(
        heygenService: _heygenService, 
        onSelectionComplete: (avatarId, voiceId) {
          setState(() {
            _selectedAvatarId = avatarId;
            _selectedVoiceId = voiceId;
            _showAvatarSelector = false;
          });
        },
      );
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Generate a video explanation using Heygen AI',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text("Select Avatar & Voice"),
                onPressed: contentSections.isEmpty 
                    ? null 
                    : () {
                        setState(() {
                          _showAvatarSelector = true;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.video_call),
                label: const Text("Generate Video"),
                onPressed: contentSections.isEmpty || _selectedAvatarId == null || _selectedVoiceId == null
                    ? null 
                    : () => _generateVideo(_selectedAvatarId!, _selectedVoiceId!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          if (_selectedAvatarId != null && _selectedVoiceId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text("Avatar and voice selected"),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 400,
          padding: const EdgeInsets.all(16),
          child: videoUrl != null ? 
            HeygenVideoPlayer(videoUrl: videoUrl!, autoPlay: true) 
            : const Center(child: Text("Video not available")),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text("Change Avatar"),
              onPressed: () {
                setState(() {
                  _showAvatarSelector = true;
                });
              },
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Regenerate Video"),
              onPressed: _selectedAvatarId != null && _selectedVoiceId != null 
                  ? () => _generateVideo(_selectedAvatarId!, _selectedVoiceId!)
                  : null,
            ),
          ],
        ),
      ],
    ),
  );
}

  
  // Widget for video player - would integrate with a video player package
  Widget _buildVideoPlayer(String url) {
  return HeygenVideoPlayer(
    videoUrl: url,
    autoPlay: true,
  );
}

  Widget _buildContentTab() {
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

    if (expandedSection != null) {
      return _buildExpandedSection(context);
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
        return GestureDetector(
          onTap: () {
            setState(() {
              expandedSection = section;
            });
          },
          child: Card(
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
                        _parseHighlightedContent(contentSections[section] ??
                            "No content available."),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
                  videoUrl = null;
                  videoGenerated = false;
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
                  videoUrl = null;
                  videoGenerated = false;
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
                  videoUrl = null;
                  videoGenerated = false;
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
                videoUrl = null;
                videoGenerated = false;
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedSection(BuildContext context) {
    final content =
        contentSections[expandedSection!] ?? "No content available.";

    return Scaffold(
      appBar: AppBar(
        title: Text(expandedSection!),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              expandedSection = null;
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: SelectableText.rich(
            _parseHighlightedContent(content),
          ),
        ),
      ),
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