import 'package:flutter/material.dart';
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

  // Face data snapshots. Maps angle name to mock face data
  final Map<String, List<int>> _faceBytes = {};
  final Map<String, String> _facePreviews = {};
  bool _isRegistering = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  // Generates high quality face silhouettes/placeholders for direct mock registration
  void _setMockFace(String angle, String placeholderType) {
    final dummyBytes = List<int>.generate(100, (i) => i);
    setState(() {
      _faceBytes[angle] = dummyBytes;
      _facePreviews[angle] = placeholderType;
    });
  }

  Future<void> _submitRegistration(AppState state) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_faceBytes.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please capture face images for all 3 angles (Front, Left, Right).'),
          backgroundColor: AppColors.rose700,
        ),
      );
      return;
    }

    setState(() => _isRegistering = true);

    // 1. Create personnel profile
    final bool success = await state.registerPersonnel(_nameCtrl.text, _roleCtrl.text);
    if (!success) {
      setState(() => _isRegistering = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to register personnel profile.'),
            backgroundColor: AppColors.rose700,
          ),
        );
      }
      return;
    }

    // 2. Fetch the created personnel ID (which is the first item in the updated list)
    final newPerson = state.personnel.first;
    final int personId = newPerson['id'] as int;

    // 3. Upload embeddings for the three angles
    bool uploadSuccess = true;
    for (String angle in ['FRONT', 'LEFT', 'RIGHT']) {
      final bytes = _faceBytes[angle]!;
      final ok = await state.uploadFace(personId, angle, bytes, "${angle.toLowerCase()}_face.jpg");
      if (!ok) {
        uploadSuccess = false;
        break;
      }
    }

    if (mounted) {
      setState(() => _isRegistering = false);
      if (uploadSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Personnel & face data successfully uploaded!'),
            backgroundColor: AppColors.emerald500,
          ),
        );
        _nameCtrl.clear();
        _roleCtrl.clear();
        setState(() {
          _faceBytes.clear();
          _facePreviews.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile created but failed uploading face templates.'),
            backgroundColor: AppColors.rose700,
          ),
        );
      }
    }
  }

  Widget _buildCameraSlot(String label, String angle) {
    final hasImage = _faceBytes.containsKey(angle);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _setMockFace(angle, label);
        },
        child: Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: hasImage ? AppColors.blue50 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasImage ? AppColors.blue600 : AppColors.slate200,
              width: hasImage ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (hasImage)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.face_retouching_natural, color: AppColors.blue600, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      '$label Loaded',
                      style: const TextStyle(color: AppColors.blue700, fontSize: 9, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    const Text('Tap to re-capture', style: TextStyle(color: AppColors.slate400, fontSize: 7)),
                  ],
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: AppColors.slate400, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(color: AppColors.slate700, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    const Text('Tap to capture', style: TextStyle(color: AppColors.slate400, fontSize: 7)),
                  ],
                ),
            ],
          ),
        ),
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
            fillColor: Colors.white,
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
            'Register and monitor personnel authorized to enter the poultry house',
            style: TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 16),

          // Scrollable layout containing both form and list
          Expanded(
            child: ListView(
              children: [
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
                          label: 'Role (e.g. Veterinarian, Manager, Feeder)',
                          hint: 'e.g. Manager',
                        ),
                        const SizedBox(height: 16),

                        // Face Templates Section
                        const Text(
                          'FACE SCAN SCAN TEMPLATES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildCameraSlot('Front Face', 'FRONT'),
                            _buildCameraSlot('Left Profile', 'LEFT'),
                            _buildCameraSlot('Right Profile', 'RIGHT'),
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
                                    'Register Profile',
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

                    // Check which face angles are registered
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
                          // Profile Circle Avatar
                          CircleAvatar(
                            backgroundColor: AppColors.blue50,
                            radius: 18,
                            child: const Icon(Icons.person_outline, color: AppColors.blue600, size: 18),
                          ),
                          const SizedBox(width: 14),

                          // Name and Role
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

                          // Face Angles Badges
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
