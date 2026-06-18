import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/simulator_drawer.dart';
import 'dashboard_screen.dart';
import 'ammonia_screen.dart';
import 'feed_history_screen.dart';
import 'alerts_screen.dart';

class _Toast {
  final int id;
  final String message;
  final String severity;
  _Toast(this.id, this.message, this.severity);
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  final List<_Toast> _toasts = [];
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  AppState? _appState;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(_pulseCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _appState = context.read<AppState>();
        _appState!.addListener(_onStateChange);
      }
    });
  }

  void _onStateChange() {
    if (!mounted) return;
    final state = _appState;
    if (state == null) return;
    final pending = state.pendingToasts.toList();
    state.consumeToasts();
    for (final t in pending) {
      _showToast(t.message, t.severity);
    }
  }

  void _showToast(String message, String severity) {
    final item = _Toast(DateTime.now().microsecondsSinceEpoch, message, severity);
    if (mounted) setState(() => _toasts.add(item));
    Future.delayed(const Duration(milliseconds: 5500), () {
      _removeToast(item.id);
    });
  }

  void _removeToast(int id) {
    if (mounted) setState(() => _toasts.removeWhere((t) => t.id == id));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _appState?.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final banner = state.bannerInfo;

    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                _buildHeader(state),

                // ── Status Banner ─────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: banner.bg,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: banner.border, width: 1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: banner.iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_bannerIcon(banner.isCritical, state.bannerStatus),
                            color: banner.iconColor, size: 14),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(banner.title,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                                color: banner.textColor, letterSpacing: 1)),
                        Text(banner.desc,
                            style: TextStyle(fontSize: 10, color: banner.textColor.withOpacity(0.7))),
                      ]),
                      const Spacer(),
                      if (state.combinedRisk)
                        _AnimatedBounce(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.amber500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.amber500.withOpacity(0.3)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: const [
                              Icon(Icons.warning_amber_rounded,
                                  color: AppColors.amber700, size: 10),
                              SizedBox(width: 4),
                              Text('Combined Risk',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                      color: AppColors.amber700, letterSpacing: 0.5)),
                            ]),
                          ),
                        ),
                    ]),
                  ),
                ),

                // ── Screens (IndexedStack preserves scroll/chart state) ──
                Expanded(
                  child: IndexedStack(
                    index: state.activeTab,
                    children: const [
                      DashboardScreen(),
                      AmmoniaScreen(),
                      FeedHistoryScreen(),
                      AlertsScreen(),
                    ],
                  ),
                ),
              ],
            ),

            // ── Simulator drawer scrim ─────────────────────────────────
            if (state.simulatorOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => state.setSimulatorOpen(false),
                  child: Container(color: Colors.black.withOpacity(0.35)),
                ),
              ),

            // ── Simulator drawer ───────────────────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOutCubic,
                offset: state.simulatorOpen ? Offset.zero : const Offset(0, 1),
                child: IgnorePointer(
                  ignoring: !state.simulatorOpen,
                  child: const SimulatorDrawer(),
                ),
              ),
            ),

            // ── Toast container ────────────────────────────────────────
            Positioned(
              top: 72, left: 16, right: 16,
              child: Column(
                children: _toasts.map((t) => _ToastItem(t: t, onClose: () => _removeToast(t.id))).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(state),
    );
  }

  Widget _buildHeader(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.slate100)),
        boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Opacity(
            opacity: _pulseAnim.value,
            child: Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: AppColors.blue600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('ARDUINO MONITOR',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.slate500, letterSpacing: 1.5)),
        const Spacer(),
        _HeaterBadge(active: state.relayActiveHeater),
        const SizedBox(width: 8),
        _FanBadge(active: state.relayActiveFan, full: state.ammonia >= 50 || state.temp > 40),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => state.setSimulatorOpen(!state.simulatorOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blue600,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: AppColors.blue600.withOpacity(0.3),
                  blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.tune, color: Colors.white, size: 12),
              SizedBox(width: 4),
              Text('Sim', style: TextStyle(color: Colors.white,
                  fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildBottomNav(AppState state) {
    final items = [
      (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
      (Icons.science_outlined, Icons.science, 'Ammonia'),
      (Icons.bar_chart, Icons.bar_chart, 'Feed History'),
      (Icons.notifications_outlined, Icons.notifications, 'Alert Log'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.slate100)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final active = state.activeTab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => state.setActiveTab(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(active ? items[i].$2 : items[i].$1,
                              color: active ? AppColors.blue600 : AppColors.slate400,
                              size: 22),
                          if (i == 3 && state.alerts.isNotEmpty)
                            Positioned(
                              top: -4, right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.rose500,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text('${state.alerts.length}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 8,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(items[i].$3,
                          style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: active ? AppColors.blue600 : AppColors.slate400)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  IconData _bannerIcon(bool isCritical, int status) {
    if (status == 2) return Icons.warning_amber_rounded;
    if (status == 1) return Icons.error_outline;
    return Icons.check_circle_outline;
  }
}

// ── Relay Badges ─────────────────────────────────────────────────────────────

class _HeaterBadge extends StatelessWidget {
  final bool active;
  const _HeaterBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.orange50 : AppColors.slate50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? AppColors.orange200 : AppColors.slate200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_fire_department,
            size: 11, color: active ? AppColors.orange600 : AppColors.slate400),
        const SizedBox(width: 4),
        Text(active ? 'HEATER ON' : 'HTR OFF',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: active ? AppColors.orange600 : AppColors.slate500)),
      ]),
    );
  }
}

class _FanBadge extends StatefulWidget {
  final bool active;
  final bool full;
  const _FanBadge({required this.active, required this.full});

  @override
  State<_FanBadge> createState() => _FanBadgeState();
}

class _FanBadgeState extends State<_FanBadge> with SingleTickerProviderStateMixin {
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat();
  }

  @override
  void dispose() { _spin.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.active ? AppColors.blue50 : AppColors.slate50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: widget.active ? AppColors.blue200 : AppColors.slate200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        widget.active
            ? RotationTransition(
                turns: _spin,
                child: const Icon(Icons.air, size: 11, color: AppColors.blue600),
              )
            : const Icon(Icons.air, size: 11, color: AppColors.slate400),
        const SizedBox(width: 4),
        Text(
          widget.active ? (widget.full ? 'FAN FAST' : 'FAN ON') : 'FAN OFF',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
              color: widget.active ? AppColors.blue600 : AppColors.slate500),
        ),
      ]),
    );
  }
}

// ── Animated Bounce wrapper ───────────────────────────────────────────────────

class _AnimatedBounce extends StatefulWidget {
  final Widget child;
  const _AnimatedBounce({required this.child});

  @override
  State<_AnimatedBounce> createState() => _AnimatedBounceState();
}

class _AnimatedBounceState extends State<_AnimatedBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, child) =>
            Transform.translate(offset: Offset(0, _anim.value), child: child),
        child: widget.child,
      );
}

// ── Toast Item ────────────────────────────────────────────────────────────────

class _ToastItem extends StatefulWidget {
  final _Toast t;
  final VoidCallback onClose;
  const _ToastItem({required this.t, required this.onClose, super.key});

  @override
  State<_ToastItem> createState() => _ToastItemState();
}

class _ToastItemState extends State<_ToastItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<double>(begin: -8, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = widget.t.severity;
    Color bg, border, fg;
    if (s == 'Critical' || s == 'Emergency') {
      bg = AppColors.rose50; border = AppColors.rose100; fg = AppColors.rose700;
    } else if (s == 'Warning') {
      bg = AppColors.amber50; border = AppColors.amber100; fg = AppColors.amber700;
    } else {
      bg = Colors.white; border = AppColors.blue100; fg = AppColors.blue600;
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(offset: Offset(0, _slide.value), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Icon(Icons.notifications, color: fg, size: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.t.message,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onClose,
            child: Icon(Icons.close, color: fg.withOpacity(0.6), size: 14),
          ),
        ]),
      ),
    );
  }
}
