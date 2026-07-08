import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class PersonnelRegistrationScreen extends StatefulWidget {
  const PersonnelRegistrationScreen({super.key});

  @override
  State<PersonnelRegistrationScreen> createState() => _PersonnelRegistrationScreenState();
}

class _PersonnelRegistrationScreenState extends State<PersonnelRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _picker = ImagePicker();

  // Selected face images data
  final Map<String, XFile> _faceFiles = {};
  final Map<String, List<int>> _faceBytes = {};
  
  // Specific validation errors received from Python microservice validation
  final Map<String, String> _errors = {};
  bool _isRegistering = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String angle) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.blue600),
                title: const Text('Take Photo', style: TextStyle(color: AppColors.slate800, fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    setState(() {
                      _faceFiles[angle] = file;
                      _faceBytes[angle] = bytes;
                      _errors.remove(angle.toLowerCase()); // Clear previous validation error on retake
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.blue600),
                title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.slate800, fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    setState(() {
                      _faceFiles[angle] = file;
                      _faceBytes[angle] = bytes;
                      _errors.remove(angle.toLowerCase()); // Clear previous validation error on retake
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRegistration(AppState state) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_faceBytes.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture images for all 3 required angles.'),
          backgroundColor: AppColors.rose700,
        ),
      );
      return;
    }

    setState(() {
      _isRegistering = true;
      _errors.clear();
    });

    final res = await state.registerPersonnel(
      name: _nameCtrl.text,
      role: _roleCtrl.text,
      frontBytes: _faceBytes['FRONT']!,
      frontName: _faceFiles['FRONT']!.name,
      leftBytes: _faceBytes['LEFT']!,
      leftName: _faceFiles['LEFT']!.name,
      rightBytes: _faceBytes['RIGHT']!,
      rightName: _faceFiles['RIGHT']!.name,
    );

    setState(() => _isRegistering = false);

    if (mounted) {
      if (res['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile registered and verified successfully!'),
            backgroundColor: AppColors.emerald600,
          ),
        );
        _nameCtrl.clear();
        _roleCtrl.clear();
        setState(() {
          _faceFiles.clear();
          _faceBytes.clear();
          _errors.clear();
        });
      } else if (res['status'] == 'validation_failed') {
        final serverErrors = res['errors'] as Map<String, dynamic>? ?? {};
        setState(() {
          serverErrors.forEach((k, v) {
            _errors[k] = v.toString();
          });
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Face validation failed. Please retake flagged slots.'),
            backgroundColor: AppColors.rose700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Network submission failed.'),
            backgroundColor: AppColors.rose700,
          ),
        );
      }
    }
  }

  Widget _buildCameraSlot(String label, String angle) {
    final file = _faceFiles[angle];
    final error = _errors[angle.toLowerCase()];
    final hasImage = file != null;

    String errorDisplay = '';
    if (error == 'no_face_detected') {
      errorDisplay = 'No face found';
    } else if (error == 'multiple_faces_detected') {
      errorDisplay = 'Multiple faces';
    } else if (error != null) {
      errorDisplay = 'Invalid image';
    }

    return Expanded(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickImage(angle),
            child: Container(
              height: 110,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: error != null
                    ? AppColors.rose50
                    : hasImage
                        ? AppColors.blue50
                        : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: error != null
                      ? AppColors.rose500
                      : hasImage
                          ? AppColors.blue600
                          : AppColors.slate200,
                  width: hasImage || error != null ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (hasImage)
                    Image.file(
                      File(file.path),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  
                  // Darken layer if image loaded to overlay text
                  if (hasImage)
                    Container(color: Colors.black.withOpacity(0.35)),

                  if (hasImage)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
                        const SizedBox(height: 6),
                        Text(
                          '$label Selected',
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        const Text('Tap to retake', style: TextStyle(color: Colors.white70, fontSize: 7)),
                      ],
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          error != null ? Icons.error_outline : Icons.camera_alt_outlined,
                          color: error != null ? AppColors.rose500 : AppColors.slate400,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: error != null ? AppColors.rose700 : AppColors.slate700,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          error != null ? 'Tap to retake' : 'Tap to capture',
                          style: TextStyle(
                            color: error != null ? AppColors.rose500.withOpacity(0.8) : AppColors.slate400,
                            fontSize: 7,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (errorDisplay.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, color: AppColors.rose500, size: 9),
                const SizedBox(width: 3),
                Text(
                  errorDisplay,
                  style: const TextStyle(color: AppColors.rose700, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            fillColor: AppColors.slate50,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.slate200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'ACCESS CONTROL REGISTRATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.blue600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Personnel Profiles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Register and verify personnel authorized to enter the poultry house',
            style: TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              children: [
                // 3-Angle Turn Instructions Guide Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blue50.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.blue100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.blue600, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Face Scan Requirements:',
                              style: TextStyle(color: AppColors.blue900, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '• FRONT: Face the camera directly head-on.\n'
                              '• LEFT: Turn slightly to the left (~30-45° turn, not full side profile).\n'
                              '• RIGHT: Turn slightly to the right (~30-45° turn, not full side profile).',
                              style: TextStyle(color: AppColors.blue700, fontSize: 10, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'e.g. Jane Doe',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _roleCtrl,
                          label: 'Role / Designation',
                          hint: 'e.g. Veterinarian',
                        ),
                        const SizedBox(height: 16),

                        // Face Templates Section
                        const Text(
                          'REQUIRED SCAN SLOTS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCameraSlot('Front Head', 'FRONT'),
                            _buildCameraSlot('Left ¾ Profile', 'LEFT'),
                            _buildCameraSlot('Right ¾ Profile', 'RIGHT'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: _isRegistering ? null : () => _submitRegistration(state),
                            child: _isRegistering
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Verify & Register Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Registered Personnel Section Header
                const Text(
                  'CURRENT TEAM MEMBERS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),

                // Personnel List
                if (state.personnel.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.slate100),
                    ),
                    child: const Center(
                      child: Text(
                        'No personnel registered yet',
                        style: TextStyle(color: AppColors.slate400, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ...state.personnel.map((p) {
                    final person = Map<String, dynamic>.from(p);
                    final facesList = person['faces'] as List<dynamic>? ?? [];

                    final hasFront = facesList.any((f) => f['angle'] == 'FRONT');
                    final hasLeft = facesList.any((f) => f['angle'] == 'LEFT');
                    final hasRight = facesList.any((f) => f['angle'] == 'RIGHT');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.blue50,
                            radius: 18,
                            child: const Icon(Icons.person_outline, color: AppColors.blue600, size: 18),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  person['name'] as String,
                                  style: const TextStyle(
                                    color: AppColors.slate800,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  person['role'] as String,
                                  style: const TextStyle(color: AppColors.slate500, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _angleIndicator('F', hasFront),
                              const SizedBox(width: 4),
                              _angleIndicator('L', hasLeft),
                              const SizedBox(width: 4),
                              _angleIndicator('R', hasRight),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _angleIndicator(String label, bool active) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: active ? AppColors.emerald50 : AppColors.slate100,
        shape: BoxShape.circle,
        border: Border.all(color: active ? AppColors.emerald100 : AppColors.slate200),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.emerald600 : AppColors.slate400,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
