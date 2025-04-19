import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// A widget that provides a complete video player solution
/// with controls, loading states, and error handling
class HeygenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;

  const HeygenVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
  }) : super(key: key);

  @override
  State<HeygenVideoPlayer> createState() => _HeygenVideoPlayerState();
}

class _HeygenVideoPlayerState extends State<HeygenVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Initialize the video player controller
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      // Wait for the controller to initialize
      await _videoPlayerController.initialize();

      // Configure the controller for UI
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Error playing video: $errorMessage",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializePlayer,
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        },
        aspectRatio: 16 / 9,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        placeholder: const Center(child: CircularProgressIndicator()),
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If video initialization failed, show error
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              "Failed to load video: $_errorMessage",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              onPressed: _initializePlayer,
            ),
          ],
        ),
      );
    }

    // If video is still initializing, show loading
    if (!_isInitialized || _chewieController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                "Loading video...",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Video is ready to play
    return Chewie(controller: _chewieController!);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}