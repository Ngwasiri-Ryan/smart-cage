import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'ammonia_screen.dart';
import 'feed_history_screen.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  int _activeToggle = 0; // 0 = Ammonia, 1 = Feed History

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Premium Segmented Controller
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.slate200.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeToggle = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeToggle == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _activeToggle == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Ammonia Safety',
                        style: TextStyle(
                          color: _activeToggle == 0 ? AppColors.blue600 : AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeToggle = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeToggle == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _activeToggle == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Feed History',
                        style: TextStyle(
                          color: _activeToggle == 1 ? AppColors.blue600 : AppColors.slate500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Display sub-screens
        Expanded(
          child: IndexedStack(
            index: _activeToggle,
            children: const [
              AmmoniaScreen(),
              FeedHistoryScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
