import 'dart:math';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class _Bubble {
  final double x;      // 0-1 normalized horizontal
  final double size;   // radius in px
  final double phase;  // 0-1 cycle offset
  final double drift;  // horizontal drift px
  final Color color;

  _Bubble({
    required this.x,
    required this.size,
    required this.phase,
    required this.drift,
    required this.color,
  });
}

class _BubblePainter extends CustomPainter {
  final double t;
  final List<_Bubble> bubbles;

  _BubblePainter(this.t, this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final progress = (t + b.phase) % 1.0;
      final y = size.height * (1.05 - progress * 1.3);
      final x = b.x * size.width + b.drift * progress;

      double opacity;
      if (progress < 0.1) {
        opacity = progress / 0.1 * 0.65;
      } else if (progress > 0.85) {
        opacity = (1.0 - progress) / 0.15 * 0.4;
      } else {
        opacity = 0.4 + sin(progress * pi) * 0.25;
      }

      final paint = Paint()..color = b.color.withOpacity(opacity.clamp(0, 1));
      canvas.drawCircle(Offset(x, y), b.size / 2, paint);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => t != old.t;
}

class GasChamber extends StatefulWidget {
  final AppState state;

  const GasChamber({super.key, required this.state});

  @override
  State<GasChamber> createState() => _GasChamberState();
}

class _GasChamberState extends State<GasChamber> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Bubble> _bubbles;
  double _lastPpm = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _rebuildBubbles(widget.state.ammonia);
  }

  @override
  void didUpdateWidget(GasChamber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.ammonia != _lastPpm) {
      _rebuildBubbles(widget.state.ammonia);
    }
  }

  void _rebuildBubbles(double ppm) {
    _lastPpm = ppm;
    final rng = Random();
    final count = min((ppm * 0.8 + 3).toInt(), 50);
    final color = _bubbleColor(ppm);
    _bubbles = List.generate(count, (_) => _Bubble(
      x: rng.nextDouble(),
      size: (rng.nextInt(20) + 8).toDouble(),
      phase: rng.nextDouble(),
      drift: rng.nextDouble() * 60 - 30,
      color: color,
    ));
  }

  Color _bubbleColor(double ppm) {
    if (ppm < 10)  return const Color(0xFF10B981);
    if (ppm < 25)  return const Color(0xFFEAB308);
    if (ppm < 50)  return const Color(0xFFF97316);
    return const Color(0xFFF43F5E);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ppm = widget.state.ammonia;

    return Container(
      height: 176,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Animated particles
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _BubblePainter(_ctrl.value, _bubbles),
              child: const SizedBox.expand(),
            ),
          ),
          // Content overlay
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Chamber Density Simulation',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppColors.slate400, letterSpacing: 1)),
                  const Spacer(),
                  _statusBadge(ppm),
                ]),
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      const Text('Current Concentration',
                          style: TextStyle(fontSize: 10, color: AppColors.slate400,
                              letterSpacing: 1, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      RichText(text: TextSpan(children: [
                        TextSpan(text: ppm.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900,
                                color: Colors.white, height: 1)),
                        const TextSpan(text: ' ppm',
                            style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                      ])),
                    ],
                  ),
                ),
                const Spacer(),
                const Divider(color: Color(0xFF1E293B), height: 1),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('MQ135 Gas Cell',
                      style: TextStyle(fontSize: 10, color: AppColors.slate400,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  _ventHint(ppm),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(double ppm) {
    String text; Color bg, border, fg;
    if (ppm < 10) {
      text = 'SAFE LEVEL'; bg = const Color(0x1A10B981);
      border = const Color(0x4010B981); fg = AppColors.emerald500;
    } else if (ppm < 25) {
      text = 'WATCH COOP'; bg = const Color(0x1AEAB308);
      border = const Color(0x40EAB308); fg = AppColors.yellow500;
    } else if (ppm < 50) {
      text = 'FANS ENGAGED'; bg = const Color(0x1AF97316);
      border = const Color(0x40F97316); fg = AppColors.orange500;
    } else {
      text = 'TOXIC HAZARD'; bg = const Color(0x1AF43F5E);
      border = const Color(0x40F43F5E); fg = AppColors.rose500;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
          color: fg, letterSpacing: 0.5)),
    );
  }

  Widget _ventHint(double ppm) {
    if (ppm < 10) {
      return Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.check_circle, size: 12, color: AppColors.emerald500),
        SizedBox(width: 4),
        Text('System Stable', style: TextStyle(fontSize: 10, color: AppColors.emerald500,
            fontWeight: FontWeight.w600)),
      ]);
    } else if (ppm < 25) {
      return Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.error_outline, size: 12, color: AppColors.yellow500),
        SizedBox(width: 4),
        Text('Moderate Haze', style: TextStyle(fontSize: 10, color: AppColors.yellow500,
            fontWeight: FontWeight.w600)),
      ]);
    } else if (ppm < 50) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        _SpinIcon(icon: Icons.air, color: AppColors.orange500, size: 12),
        const SizedBox(width: 4),
        const Text('Active Exhaust', style: TextStyle(fontSize: 10, color: AppColors.orange500,
            fontWeight: FontWeight.w600)),
      ]);
    } else {
      return Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.rose500),
        SizedBox(width: 4),
        Text('Severe Exposure', style: TextStyle(fontSize: 10, color: AppColors.rose500,
            fontWeight: FontWeight.w800)),
      ]);
    }
  }
}

class _SpinIcon extends StatefulWidget {
  final IconData icon; final Color color; final double size;
  const _SpinIcon({required this.icon, required this.color, required this.size});

  @override
  State<_SpinIcon> createState() => _SpinIconState();
}

class _SpinIconState extends State<_SpinIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _ctrl, child: Icon(widget.icon, color: widget.color, size: widget.size));
}
