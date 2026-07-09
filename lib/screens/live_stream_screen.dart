import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

class LiveStreamScreen extends StatefulWidget {
  final Map<String, dynamic>? initialCamera;
  const LiveStreamScreen({super.key, this.initialCamera});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  Map<String, dynamic>? _selectedCamera;
  VideoPlayerController? _playerController;
  bool _isPlayerInitialized = false;
  String? _playerError;

  @override
  void initState() {
    super.initState();
    if (widget.initialCamera != null) {
      _selectedCamera = widget.initialCamera;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-select first camera if none selected and no initial camera injected
    if (_selectedCamera == null) {
      final state = Provider.of<AppState>(context);
      if (state.cameras.isNotEmpty) {
        _selectedCamera = Map<String, dynamic>.from(state.cameras.first);
      }
    }

    if (_selectedCamera != null && _playerController == null) {
      final int cid = _selectedCamera!['id'] as int;
      _initializePlayer('/uploads/streams/$cid/index.m3u8');
    }
  }

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  void _initializePlayer(String relativeM3u8Url) {
    _playerController?.dispose();
    setState(() {
      _isPlayerInitialized = false;
      _playerError = null;
    });

    final String absoluteUrl = '${ApiService.baseUrl}$relativeM3u8Url';
    print('[LiveStreamScreen] Connecting to HLS stream: $absoluteUrl');

    _playerController = VideoPlayerController.networkUrl(Uri.parse(absoluteUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isPlayerInitialized = true;
          });
          _playerController!.setLooping(true);
          _playerController!.play();
        }
      }).catchError((err) {
        if (mounted) {
          setState(() {
            _playerError = 'Could not load live video stream.\nEnsure FFmpeg transcoder is running.';
          });
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.slate100, width: 1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.slate800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedCamera != null ? _selectedCamera!['name'] as String : 'Live Video Stream',
          style: const TextStyle(
            color: AppColors.slate800,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE POULTRY MONITOR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedCamera != null
                        ? "${_selectedCamera!['name']} - ${_selectedCamera!['zone']}"
                        : 'No Camera Streaming',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dropdown selector (only show if multiple cameras exist)
              if (state.cameras.length > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate100),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      value: _selectedCamera,
                      items: state.cameras.map((c) {
                        final cameraMap = Map<String, dynamic>.from(c);
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: cameraMap,
                          child: Text(
                            "${cameraMap['name']} (${cameraMap['zone']})",
                            style: const TextStyle(color: AppColors.slate800, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (newCam) {
                        if (newCam != null) {
                          setState(() {
                            _selectedCamera = newCam;
                          });
                          final int cid = newCam['id'] as int;
                          _initializePlayer('/uploads/streams/$cid/index.m3u8');
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Video Player Card Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slate100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video Player
                      if (_isPlayerInitialized && _playerController != null)
                        AspectRatio(
                          aspectRatio: _playerController!.value.aspectRatio,
                          child: VideoPlayer(_playerController!),
                        )
                      else if (_playerError != null)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_off_outlined, color: AppColors.rose500, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                _playerError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.slate400, fontSize: 12, height: 1.5),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue600,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  if (_selectedCamera != null) {
                                    final int cid = _selectedCamera!['id'] as int;
                                    _initializePlayer('/uploads/streams/$cid/index.m3u8');
                                  }
                                },
                                child: const Text('Retry Connection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(color: AppColors.blue500),
                            SizedBox(height: 16),
                            Text('Connecting to RTSP stream...', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                          ],
                        ),

                      // Low Chick Movement Health Alert Banner
                      if (state.isLowMovementFlagged)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.rose50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.rose100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: AppColors.rose700, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'HEALTH CRITICAL: Inactive chick detected in zone!',
                                    style: TextStyle(
                                      color: AppColors.rose700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Live indicator overlay
                      if (_isPlayerInitialized)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.rose500.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.circle, color: Colors.white, size: 6),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Camera details info card
              if (_selectedCamera != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.blue600, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Monitoring Zone: ${_selectedCamera!['zone']}",
                            style: const TextStyle(color: AppColors.slate800, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Source: ${_selectedCamera!['rtspUrl']}",
                        style: const TextStyle(color: AppColors.slate500, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
