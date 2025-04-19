import 'package:flutter/material.dart';
import '../../services/heygen_service.dart'; // Fixed import path

class AvatarVoiceSelector extends StatefulWidget {
  final Function(String avatarId, String voiceId) onSelectionComplete;
  final HeygenService heygenService;
  
  const AvatarVoiceSelector({
    Key? key,
    required this.onSelectionComplete,
    required this.heygenService,
  }) : super(key: key);

  @override
  State<AvatarVoiceSelector> createState() => _AvatarVoiceSelectorState();
}

class _AvatarVoiceSelectorState extends State<AvatarVoiceSelector> {
  bool _isLoading = true;
  String? _error;
  
  List<Map<String, dynamic>> _avatars = [];
  List<Map<String, dynamic>> _voices = [];
  
  String? _selectedAvatarId;
  String? _selectedVoiceId;
  
  @override
  void initState() {
    super.initState();
    _loadAvatarsAndVoices();
  }
  
  Future<void> _loadAvatarsAndVoices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Initialize service if needed
      await widget.heygenService.initialize();
      
      // Fetch avatars and voices
      final avatars = await widget.heygenService.fetchAvatars();
      final voices = await widget.heygenService.fetchVoices();
      
      if (mounted) {
        setState(() {
          _avatars = avatars;
          _voices = voices;
          
          // Preselect first items if available
          if (_avatars.isNotEmpty) {
            _selectedAvatarId = _avatars.first['avatar_id'];
          }
          if (_voices.isNotEmpty) {
            _selectedVoiceId = _voices.first['voice_id'];
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading avatars and voices...'),
          ],
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAvatarsAndVoices,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_avatars.isEmpty || _voices.isEmpty) {
      return const Center(
        child: Text('No avatars or voices available. Please check your API key.'),
      );
    }
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Avatar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildAvatarGrid(),
            const SizedBox(height: 24),
            const Text(
              'Select Voice',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildVoiceList(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _selectedAvatarId != null && _selectedVoiceId != null
                  ? () => widget.onSelectionComplete(_selectedAvatarId!, _selectedVoiceId!)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Use Selected Avatar & Voice'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvatarGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _avatars.length,
      itemBuilder: (context, index) {
        final avatar = _avatars[index];
        final avatarId = avatar['avatar_id'];
        final avatarName = avatar['name'] ?? 'Avatar ${index + 1}';
        final avatarThumbnail = avatar['preview_url'] ?? '';
        final isSelected = avatarId == _selectedAvatarId;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAvatarId = avatarId;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                    child: avatarThumbnail.isNotEmpty
                        ? Image.network(
                            avatarThumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.person, size: 50),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.person, size: 50),
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
                  ),
                  child: Text(
                    avatarName,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
  
  Widget _buildVoiceList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _voices.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
        itemBuilder: (context, index) {
          final voice = _voices[index];
          final voiceId = voice['voice_id'];
          final voiceName = voice['name'] ?? 'Voice ${index + 1}';
          final voiceGender = voice['gender'] ?? 'Unknown';
          final voiceLanguage = voice['language'] ?? 'English';
          final isSelected = voiceId == _selectedVoiceId;
          
          return ListTile(
            title: Text(
              voiceName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text('$voiceGender · $voiceLanguage'),
            leading: CircleAvatar(
              backgroundColor: isSelected ? Colors.blue : Colors.grey.shade700,
              child: Icon(
                voiceGender.toLowerCase() == 'female' ? Icons.woman : Icons.man,
                color: Colors.white,
              ),
            ),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
            selected: isSelected,
            onTap: () {
              setState(() {
                _selectedVoiceId = voiceId;
              });
            },
          );
        },
      ),
    );
  }
}