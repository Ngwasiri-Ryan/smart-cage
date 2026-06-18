import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Fault Alerts Log',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                      color: AppColors.slate800)),
              SizedBox(height: 2),
              Text('Threshold and combined risk anomalies detected over time',
                  style: TextStyle(fontSize: 12, color: AppColors.slate500)),
            ]),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.read<AppState>().clearAlerts(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Clear Log',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.slate400)),
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: state.alerts.isEmpty
              ? _EmptyState()
              : ListView.separated(
                  itemCount: state.alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _AlertCard(alert: state.alerts[i]),
                ),
        ),
      ]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  const _AlertCard({required this.alert});

  ({Color bg, Color border, Color fg, IconData icon}) get _style {
    switch (alert.severity) {
      case 'Caution':
        return (bg: const Color(0xFFFEFCE8), border: const Color(0xFFFEF9C3),
            fg: const Color(0xFF854D0E), icon: Icons.info_outline);
      case 'Warning':
        return (bg: AppColors.amber50, border: AppColors.amber100,
            fg: AppColors.amber700, icon: Icons.error_outline);
      case 'Critical':
        return (bg: AppColors.rose50, border: AppColors.rose100,
            fg: AppColors.rose700, icon: Icons.warning_amber_rounded);
      default: // Emergency
        return (bg: const Color(0xFFFEF2F2), border: const Color(0xFFFECACA),
            fg: const Color(0xFF991B1B), icon: Icons.report_problem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final dateStr = DateFormat('MM/dd/yy HH:mm').format(alert.date);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: s.bg, borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(s.icon, color: s.fg, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(alert.type.toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: AppColors.slate400, letterSpacing: 1)),
              const Spacer(),
              Text(dateStr,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: AppColors.slate400)),
            ]),
            const SizedBox(height: 4),
            Text(alert.description,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.slate700, height: 1.4)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: s.bg, borderRadius: BorderRadius.circular(6),
                border: Border.all(color: s.border),
              ),
              child: Text(alert.severity.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                      color: s.fg, letterSpacing: 0.5)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.notifications_off, size: 48, color: AppColors.slate300),
        SizedBox(height: 12),
        Text('All logs are clear!',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.slate400)),
      ]),
    );
  }
}
