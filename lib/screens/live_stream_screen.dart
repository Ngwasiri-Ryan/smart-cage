import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  Map<String, dynamic>? _selectedCamera;
  VideoPlayerController? _playerController;
  bool _isPlayerInitialized = false;
  String? _playerError;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  bool _isRegistering = false;

  @override
  void dispose() {
    _playerController?.dispose();
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _zoneCtrl.dispose();
    super.dispose();
  }

  void _initializePlayer(String relativeM3u8Url) {
    _playerController?.dispose();
    setState(() {
      _isPlayerInitialized = false;
      _playerError = null;
    });

    final String absoluteUrl = 'https://smartcage-backend-production.up.railway.app$relativeM3u8Url';
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

  void _openAddCameraDialog(AppState state) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.slate900,
          title: const Text('Register New IP Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Camera Name',
                      labelStyle: TextStyle(color: AppColors.slate400),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.slate700)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.blue500)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _urlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'RTSP Stream URL',
                      labelStyle: TextStyle(color: AppColors.slate400),
                      hintText: 'rtsp://ip:port/h264',
                      hintStyle: TextStyle(color: AppColors.slate600, fontSize: 12),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.slate700)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.blue500)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _zoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Monitoring Zone / Cage ID',
                      labelStyle: TextStyle(color: AppColors.slate400),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.slate700)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.blue500)),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.slate400)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  setState(() => _isRegistering = true);
                  final success = await state.registerCamera(
                    _nameCtrl.text,
                    _urlCtrl.text,
                    _zoneCtrl.text,
                  );
                  if (mounted) {
                    setState(() => _isRegistering = false);
                    _nameCtrl.clear();
                    _urlCtrl.clear();
                    _zoneCtrl.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Camera registered successfully!' : 'Failed to register camera'),
                        backgroundColor: success ? AppColors.emerald600 : AppColors.rose600,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Auto-select first camera if none selected
    if (_selectedCamera == null && state.cameras.isNotEmpty) {
      _selectedCamera = Map<String, dynamic>.from(state.cameras.first);
      // Construct HLS stream URL target
      final int cameraId = _selectedCamera!['id'] as int;
      _initializePlayer('/uploads/streams/$cameraId/index.m3u8');
    }

    return Scaffold(
      backgroundColor: AppColors.slate950,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LIVE POULTRY STREAM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue400,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedCamera != null ? _selectedCamera!['name'] as String : 'No Camera Selected',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 22),
                    onPressed: () => _openAddCameraDialog(state),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stream Selector Dropdown
              if (state.cameras.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.slate900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate800),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      dropdownColor: AppColors.slate900,
                      value: _selectedCamera,
                      items: state.cameras.map((c) {
                        final cameraMap = Map<String, dynamic>.from(c);
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: cameraMap,
                          child: Text(
                            "${cameraMap['name']} (${cameraMap['zone']})",
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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

              // Video Player Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.slate800),
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
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue600),
                                onPressed: () {
                                  if (_selectedCamera != null) {
                                    final int cid = _selectedCamera!['id'] as int;
                                    _initializePlayer('/uploads/streams/$cid/index.m3u8');
                                  }
                                },
                                child: const Text('Retry Connection', style: TextStyle(color: Colors.white)),
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
                            Text('Loading RTSP stream...', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
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
                              color: AppColors.rose950.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.rose500.withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: AppColors.rose500, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'HEALTH CRITICAL: Inactive chick detected in zone!',
                                    style: TextStyle(
                                      color: Colors.white,
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
                              color: Colors.red.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.circle, color: Colors.white, size: 8),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                    color: AppColors.slate900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate800),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.blue500, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Monitoring Zone: ${_selectedCamera!['zone']}",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
