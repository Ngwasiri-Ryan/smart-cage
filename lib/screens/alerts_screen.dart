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

    // 1. Gather all alert types
    final List<Map<String, dynamic>> combinedFeed = [];

    // Add traditional fault alerts
    for (var a in state.alerts) {
      combinedFeed.add({
        'id': a.id,
        'type': 'fault',
        'alertType': a.type,
        'date': a.date,
        'description': a.description,
        'severity': a.severity,
      });
    }

    // Add health alerts
    for (var h in state.healthAlerts) {
      final date = DateTime.tryParse(h['createdAt'] as String) ?? DateTime.now();
      combinedFeed.add({
        'id': h['id'],
        'type': 'health',
        'alertType': 'HEALTH',
        'date': date,
        'description': h['description'] as String,
        'severity': 'Warning',
        'score': h['movementScore'] as num,
        'snapshotPath': h['snapshotPath'] as String?,
        'cameraName': h['camera'] != null ? h['camera']['name'] as String : 'Unknown',
      });
    }

    // Add access logs
    for (var l in state.accessLogs) {
      final date = DateTime.tryParse(l['createdAt'] as String) ?? DateTime.now();
      final bool authorized = l['isAuthorized'] as bool;
      combinedFeed.add({
        'id': l['id'],
        'type': 'access',
        'alertType': 'ACCESS CONTROL',
        'date': date,
        'description': "${l['matchedName']} - ${authorized ? 'Authorized Entry' : 'Unauthorized Access Warning'}",
        'severity': authorized ? 'Caution' : 'Critical',
        'authorized': authorized,
        'snapshotPath': l['snapshotPath'] as String?,
        'cameraName': l['camera'] != null ? l['camera']['name'] as String : 'Unknown',
      });
    }

    // 2. Sort chronologically (descending)
    combinedFeed.sort((a, b) => b['date'].compareTo(a['date']));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Unified Alerts Feed',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Real-time stream of coop faults, health alarms, and gate entries',
                      style: TextStyle(fontSize: 11, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => context.read<AppState>().clearAlerts(),
                child: const Text(
                  'Clear Faults',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: combinedFeed.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    itemCount: combinedFeed.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _FeedCard(item: combinedFeed[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _FeedCard({required this.item});

  ({Color bg, Color border, Color fg, IconData icon}) get _style {
    final severity = item['severity'] as String;
    switch (severity) {
      case 'Caution':
        return (
          bg: const Color(0xFFFEFCE8).withOpacity(0.08),
          border: const Color(0xFFFEF9C3).withOpacity(0.15),
          fg: const Color(0xFFEAB308),
          icon: Icons.info_outline
        );
      case 'Warning':
        return (
          bg: AppColors.amber50.withOpacity(0.08),
          border: AppColors.amber100.withOpacity(0.15),
          fg: AppColors.amber500,
          icon: Icons.warning_amber_rounded
        );
      case 'Critical':
      case 'Emergency':
        return (
          bg: AppColors.rose50.withOpacity(0.08),
          border: AppColors.rose100.withOpacity(0.15),
          fg: AppColors.rose500,
          icon: Icons.dangerous_outlined
        );
      default:
        return (
          bg: AppColors.slate50.withOpacity(0.08),
          border: AppColors.slate100.withOpacity(0.15),
          fg: AppColors.slate400,
          icon: Icons.notifications_none
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final dateStr = DateFormat('MM/dd HH:mm:ss').format(item['date'] as DateTime);
    final String? snapPath = item['snapshotPath'] as String?;
    final hasSnap = snapPath != null && snapPath.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Alert header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: s.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: s.border),
                ),
                child: Icon(s.icon, color: s.fg, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          (item['alertType'] as String).toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: s.fg,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 9, color: AppColors.slate500, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['description'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Render details of health score or camera name
          if (item['type'] == 'health' || item['type'] == 'access') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 32),
                Icon(Icons.videocam_outlined, color: AppColors.slate600, size: 10),
                const SizedBox(width: 4),
                Text(
                  "Camera: ${item['cameraName']}",
                  style: const TextStyle(color: AppColors.slate500, fontSize: 9, fontWeight: FontWeight.w600),
                ),
                if (item['type'] == 'health') ...[
                  const SizedBox(width: 16),
                  Icon(Icons.directions_run_outlined, color: AppColors.slate600, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    "Score: ${(item['score'] as num).toStringAsFixed(3)}",
                    style: const TextStyle(color: AppColors.slate500, fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ],

          // Snapshot frame display
          if (hasSnap) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate800),
                color: Colors.black,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                'https://smartcage-backend-production.up.railway.app$snapPath',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.broken_image_outlined, color: AppColors.slate700, size: 24),
                        SizedBox(height: 4),
                        Text('Could not load snapshot frame', style: TextStyle(color: AppColors.slate600, fontSize: 9)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.slate800),
          SizedBox(height: 12),
          Text(
            'All systems green — no alerts',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}
