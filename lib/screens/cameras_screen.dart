import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';
import 'live_stream_screen.dart';

class CamerasScreen extends StatefulWidget {
  const CamerasScreen({super.key});

  @override
  State<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  bool _isActive = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _zoneCtrl.dispose();
    super.dispose();
  }

  void _openAddCameraDialog(BuildContext context, AppState state) {
    _nameCtrl.clear();
    _urlCtrl.clear();
    _zoneCtrl.clear();
    _isActive = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: const Text(
            'Register New Camera',
            style: TextStyle(color: AppColors.slate800, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'Camera Name',
                    hint: 'e.g. Coop A Feed Area',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _urlCtrl,
                    label: 'RTSP Stream URL',
                    hint: 'e.g. rtsp://192.168.1.100:554/stream',
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _zoneCtrl,
                    label: 'Zone / Cage ID',
                    hint: 'e.g. Zone A',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final name = _nameCtrl.text;
                  final url = _urlCtrl.text;
                  final zone = _zoneCtrl.text;
                  Navigator.pop(ctx);
                  final ok = await state.registerCamera(name, url, zone);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Camera registered successfully!' : 'Failed to register camera'),
                        backgroundColor: ok ? AppColors.emerald600 : AppColors.rose700,
                      ),
                    );
                  }
                }
              },
              child: const Text('Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openEditCameraDialog(BuildContext context, AppState state, Map<String, dynamic> camera) {
    _nameCtrl.text = camera['name'] as String;
    _urlCtrl.text = camera['rtspUrl'] as String;
    _zoneCtrl.text = camera['zone'] as String;
    _isActive = camera['active'] as bool;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
              title: const Text(
                'Edit Camera Settings',
                style: TextStyle(color: AppColors.slate800, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller: _nameCtrl,
                        label: 'Camera Name',
                        hint: 'e.g. Coop A Feed Area',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _urlCtrl,
                        label: 'RTSP Stream URL',
                        hint: 'e.g. rtsp://192.168.1.100:554/stream',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _zoneCtrl,
                        label: 'Zone / Cage ID',
                        hint: 'e.g. Zone A',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active / Online',
                            style: TextStyle(color: AppColors.slate700, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          Switch(
                            value: _isActive,
                            activeColor: AppColors.blue600,
                            onChanged: (val) {
                              setDialogState(() {
                                _isActive = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final name = _nameCtrl.text;
                      final url = _urlCtrl.text;
                      final zone = _zoneCtrl.text;
                      final active = _isActive;
                      Navigator.pop(ctx);
                      final ok = await state.updateCamera(
                        camera['id'] as int,
                        name,
                        url,
                        zone,
                        active,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? 'Camera updated successfully!' : 'Failed to update camera'),
                            backgroundColor: ok ? AppColors.emerald600 : AppColors.rose700,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCamera(BuildContext context, AppState state, Map<String, dynamic> camera) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: const Text(
            'Delete Camera',
            style: TextStyle(color: AppColors.slate800, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          content: Text(
            'Are you sure you want to permanently delete the camera "${camera['name']}"? This action cannot be undone.',
            style: const TextStyle(color: AppColors.slate600, fontSize: 12, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rose700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await state.deleteCamera(camera['id'] as int);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Camera deleted successfully!' : 'Failed to delete camera'),
                      backgroundColor: ok ? AppColors.emerald600 : AppColors.rose700,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.slate500, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate800),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            fillColor: AppColors.slate50,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.blue600, width: 1.5),
            ),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'MONITORING DEVICES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.blue600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'IP Cameras',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.slate800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage active video monitoring streams and endpoints',
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _openAddCameraDialog(context, state),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.blue100),
                  ),
                  child: const Icon(Icons.add, color: AppColors.blue600, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Camera List
          Expanded(
            child: state.cameras.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.videocam_off_outlined, size: 48, color: AppColors.slate300),
                        SizedBox(height: 12),
                        Text(
                          'No cameras registered yet',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: state.cameras.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final cam = Map<String, dynamic>.from(state.cameras[idx]);
                      final bool active = cam['active'] as bool? ?? false;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveStreamScreen(initialCamera: cam),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
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
                          child: Row(
                            children: [
                              // Icon Block
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.blue50 : AppColors.slate50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: active ? AppColors.blue100 : AppColors.slate200),
                                ),
                                child: Icon(
                                  Icons.videocam_outlined,
                                  color: active ? AppColors.blue600 : AppColors.slate400,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cam['name'] as String,
                                      style: const TextStyle(
                                        color: AppColors.slate800,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Zone: ${cam['zone']}",
                                      style: const TextStyle(color: AppColors.slate500, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),

                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.emerald50 : AppColors.slate100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: active ? AppColors.emerald100 : AppColors.slate200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      color: active ? AppColors.emerald500 : AppColors.slate400,
                                      size: 6,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      active ? 'ONLINE' : 'OFFLINE',
                                      style: TextStyle(
                                        color: active ? AppColors.emerald600 : AppColors.slate500,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Actions Block
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.slate400, size: 18),
                                onPressed: () => _openEditCameraDialog(context, state, cam),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.rose500, size: 18),
                                onPressed: () => _confirmDeleteCamera(context, state, cam),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
