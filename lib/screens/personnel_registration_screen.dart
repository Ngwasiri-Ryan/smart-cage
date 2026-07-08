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

  // Face data snapshots. Maps angle name to mock face data (base64 or local description)
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
    // Generate simple dummy face data bytes (representing image bytes)
    // In a real device we would read actual camera file bytes.
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
          // Provide mock face profile images to make demo easy on emulators
          _setMockFace(angle, label);
        },
        child: Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: hasImage ? AppColors.blue900.withOpacity(0.4) : AppColors.slate900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasImage ? AppColors.blue500 : AppColors.slate800,
              width: hasImage ? 2 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (hasImage)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.face_retouching_natural, color: AppColors.blue400, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      '$label Loaded',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text('Tap to re-capture', style: TextStyle(color: AppColors.slate500, fontSize: 8)),
                  ],
                )
              else
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: AppColors.slate500, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(color: AppColors.slate400, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text('Tap to capture', style: TextStyle(color: AppColors.slate600, fontSize: 8)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'ACCESS CONTROL REGISTRATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue400,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Add Personnel Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: AppColors.slate400),
                    filled: true,
                    fillColor: AppColors.slate900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.slate800),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.blue500, width: 1.5),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Role (e.g. Vet, Manager, Feeder)',
                    labelStyle: const TextStyle(color: AppColors.slate400),
                    filled: true,
                    fillColor: AppColors.slate900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.slate800),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.blue500, width: 1.5),
                    ),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a role' : null,
                ),
                const SizedBox(height: 24),

                // Face capture section title
                const Text(
                  'FACE ANGLE SCAN TEMPLATES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // Front, Left, Right slots
                Row(
                  children: [
                    _buildCameraSlot('Front Face', 'FRONT'),
                    _buildCameraSlot('Left Profile', 'LEFT'),
                    _buildCameraSlot('Right Profile', 'RIGHT'),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isRegistering ? null : () => _submitRegistration(state),
                    child: _isRegistering
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Personnel Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                // Quick explanation text
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.slate900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.slate800),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: AppColors.blue400, size: 16),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Scan templates are converted to 512-dimensional face vectors (embeddings) to authenticate entries at the poultry house gate.',
                          style: TextStyle(color: AppColors.slate400, fontSize: 10, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
