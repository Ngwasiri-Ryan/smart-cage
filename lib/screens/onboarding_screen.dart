import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final slide = state.onboardingSlide;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null) {
                          if (details.primaryVelocity! < -300) {
                            state.nextOnboardingSlide();
                          } else if (details.primaryVelocity! > 300) {
                            state.previousOnboardingSlide();
                          }
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(
                            scale: Tween(begin: 0.95, end: 1.0).animate(anim),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(slide),
                          child: _buildSlide(slide),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottom(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.blue600,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue600.withOpacity(0.3),
                  blurRadius: 4, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Inter', fontSize: 12,
                fontWeight: FontWeight.w800, color: AppColors.slate800,
                letterSpacing: 1,
              ),
              children: const [
                TextSpan(text: 'ChirpGuard'),
                TextSpan(text: '.', style: TextStyle(color: AppColors.blue600)),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.read<AppState>().skipOnboarding(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.slate400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(int slide) {
    switch (slide) {
      case 0: return _buildSlide0();
      case 1: return _buildSlide1();
      default: return _buildSlide2();
    }
  }

  Widget _buildSlide0() {
    return Column(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Back card — white, rotated
              Positioned(
                left: 20, right: 60, top: 10,
                child: Transform.rotate(
                  angle: -0.105,
                  child: _glassCard(
                    height: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('Coop Ammonia',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                  color: AppColors.slate400, letterSpacing: 1)),
                          const Spacer(),
                          Container(width: 8, height: 8,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: AppColors.emerald500)),
                        ]),
                        const SizedBox(height: 6),
                        RichText(text: const TextSpan(children: [
                          TextSpan(text: '8.0 ', style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900,
                              color: AppColors.slate800)),
                          TextSpan(text: 'ppm', style: TextStyle(
                              fontSize: 12, color: AppColors.slate400)),
                        ])),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.emerald50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.check_circle, size: 9, color: AppColors.emerald600),
                            SizedBox(width: 4),
                            Text('Optimal Safe Atmosphere',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                                    color: AppColors.emerald600)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Front card — blue gradient
              Positioned(
                right: 10, bottom: 10,
                child: Transform.rotate(
                  angle: 0.052,
                  child: Container(
                    width: 195, height: 105,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.blue600, AppColors.indigo700],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: AppColors.blue600.withOpacity(0.4),
                            blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          Text('Internal Temp', style: TextStyle(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              color: AppColors.blue200, letterSpacing: 1)),
                          Spacer(),
                          Icon(Icons.thermostat, color: AppColors.blue200, size: 12),
                        ]),
                        const SizedBox(height: 4),
                        const Text('24.5 °C', style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 6,
                            color: Colors.white.withOpacity(0.2),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: 0.65,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bouncing badge
              Positioned(
                bottom: 8, left: 36,
                child: AnimatedBuilder(
                  animation: _bounce,
                  builder: (_, child) =>
                      Transform.translate(offset: Offset(0, _bounce.value), child: child),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.blue600,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.blue600.withOpacity(0.4),
                            blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Text('🌾 45kg',
                        style: TextStyle(fontSize: 9, color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _buildSlideText(
          line1: 'Your Journey to',
          line2: 'Perfect Farm Plan',
          desc: 'Effortlessly track real-time temperature, ammonia levels, and automated feed consumption direct from your offline Arduino.',
        ),
      ],
    );
  }

  Widget _buildSlide1() {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Center(
            child: _glassCard(
              width: 200, height: 155,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('Auto Actuators', style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: AppColors.blue600, letterSpacing: 1)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.slate50,
                          borderRadius: BorderRadius.circular(999)),
                      child: const Text('Arduino Uno',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                              color: AppColors.slate400)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _actuatorIcon(
                        icon: Icons.air,
                        color: AppColors.blue600,
                        bg: AppColors.blue50,
                        border: AppColors.blue100,
                        label: 'Vent Fan',
                        spin: true,
                      ),
                      _actuatorIcon(
                        icon: Icons.local_fire_department,
                        color: AppColors.slate400,
                        bg: AppColors.slate50,
                        border: AppColors.slate200,
                        label: 'Heater',
                        spin: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text('Auto fan triggers at Ammonia ≥ 25ppm',
                        style: TextStyle(fontSize: 8, color: AppColors.slate400,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildSlideText(
          line1: 'Protect Your Birds',
          line2: 'With Auto-Controls',
          desc: 'System reacts instantly to hazard levels, toggling active vent fans and heating elements automatically without requiring manual controls.',
        ),
      ],
    );
  }

  Widget _buildSlide2() {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 240, height: 140,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blue600, AppColors.indigo700],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: AppColors.blue600.withOpacity(0.4),
                          blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Row(children: const [
                          Icon(Icons.auto_awesome, color: AppColors.blue200, size: 10),
                          SizedBox(width: 6),
                          Text('Clinical Assessment',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                  color: AppColors.blue200, letterSpacing: 1)),
                        ]),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(999)),
                          child: const Text('GEMINI',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      const Expanded(
                        child: Text(
                          '"Today\'s feed intake is healthy and steady. Temperature and ammonia levels are fully optimized."',
                          style: TextStyle(fontSize: 11, color: Colors.white,
                              fontStyle: FontStyle.italic, height: 1.5),
                        ),
                      ),
                      const Divider(color: Colors.white24, height: 12),
                      Row(children: const [
                        Text('Generated Daily', style: TextStyle(fontSize: 8, color: AppColors.blue200)),
                        Spacer(),
                        Text('No Internet Required', style: TextStyle(fontSize: 8, color: AppColors.blue200)),
                      ]),
                    ],
                  ),
                ),
                Positioned(
                  top: -10, right: -10,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.emerald100,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1),
                          blurRadius: 4)],
                    ),
                    child: const Icon(Icons.check_circle, color: AppColors.emerald600, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        _buildSlideText(
          line1: 'Stay Updated With',
          line2: 'Top Insights',
          desc: 'Access automated veterinarian-grade assessments generated by AI, helping you identify risks before they spread across your flock.',
        ),
      ],
    );
  }

  Widget _buildSlideText({
    required String line1,
    required String line2,
    required String desc,
  }) {
    return Column(
      children: [
        Text(line1, style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.slate800,
            height: 1.2)),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.blue600, AppColors.indigo700],
          ).createShader(bounds),
          child: Text(line2, style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
        ),
        const SizedBox(height: 12),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 12, color: AppColors.slate500, height: 1.6, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildBottom(AppState state) {
    final isLast = state.onboardingSlide == 2;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final active = i == state.onboardingSlide;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 24 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: active ? AppColors.blue600 : AppColors.slate200,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => state.nextOnboardingSlide(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 280,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.blue600,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(color: AppColors.blue600.withOpacity(0.25),
                    blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
                const SizedBox(width: 8),
                Icon(isLast ? Icons.check_circle : Icons.arrow_forward,
                    color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _glassCard({Widget? child, double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07),
              blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _actuatorIcon({
    required IconData icon,
    required Color color,
    required Color bg,
    required Color border,
    required String label,
    required bool spin,
  }) {
    final iconWidget = Icon(icon, color: color, size: 20);
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: bg, shape: BoxShape.circle,
            border: Border.all(color: border),
          ),
          child: Center(
            child: spin
                ? _SpinWidget(child: iconWidget)
                : iconWidget,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            color: spin ? AppColors.slate500 : AppColors.slate400)),
      ],
    );
  }
}

class _SpinWidget extends StatefulWidget {
  final Widget child;
  const _SpinWidget({required this.child});

  @override
  State<_SpinWidget> createState() => _SpinWidgetState();
}

class _SpinWidgetState extends State<_SpinWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(turns: _ctrl, child: widget.child);
  }
}
