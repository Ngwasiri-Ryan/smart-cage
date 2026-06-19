import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class FeedHistoryScreen extends StatelessWidget {
  const FeedHistoryScreen({super.key});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Today'];

  bool _isDeclineBar(List<double> history, int index) {
    if (index < 2) return false;
    return history[index] < history[index - 1] &&
        history[index - 1] < history[index - 2];
  }

  Color _getBarColor(double value, bool isDecline) {
    if (isDecline) return AppColors.amber600;
    if (value < 35) return AppColors.blue200;
    if (value < 42) return AppColors.blue400;
    if (value < 46) return AppColors.blue500;
    if (value < 48) return AppColors.blue600;
    return AppColors.blue700;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final history = state.feedHistory;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Feed Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                  color: AppColors.slate800)),
          SizedBox(height: 4),
          Text('Monitoring consumption volumes is vital for flock clinical warnings',
              style: TextStyle(fontSize: 12, color: AppColors.slate500, height: 1.5)),
        ]),
        const SizedBox(height: 16),

        // Bar chart card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('FEED CONSUMPTION',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                        color: AppColors.slate400, letterSpacing: 1)),
                SizedBox(height: 2),
                Text('Last 7 Days (kg)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.slate800)),
              ]),
              const Spacer(),
              if (state.feedTrendIsDeclining)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Drop Warning Active',
                      style: TextStyle(fontSize: 9, color: AppColors.amber700,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (history.reduce((a, b) => a > b ? a : b) * 1.2),
                  barGroups: List.generate(history.length, (i) {
                    final isDecline = _isDeclineBar(history, i);
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: history[i],
                          color: _getBarColor(history[i], isDecline),
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: history.reduce((a, b) => a > b ? a : b) * 1.2,
                            color: AppColors.slate50,
                          ),
                        ),
                      ],
                    );
                  }),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: AppColors.slate100, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= _dayLabels.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_dayLabels[i],
                                style: const TextStyle(fontSize: 9,
                                    fontWeight: FontWeight.w700, color: AppColors.slate500)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}kg',
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                                color: AppColors.slate500)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blue50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.blue100),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, color: AppColors.blue600, size: 14),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Days with consecutive daily drops of feed are highlighted in amber. Immediate coop intervention is recommended to prevent respiratory blockages or bird lethargy.',
                    style: TextStyle(fontSize: 10, color: AppColors.slate500, height: 1.5),
                  ),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Today's interval readings
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.slate100),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("TODAY'S FEEDING TELEMETRY (8-HOUR INTERVALS)",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppColors.slate800, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _IntervalCell(label: '06:00 AM',
                  value: '${state.feedIntervals[0].toStringAsFixed(1)} kg')),
              const SizedBox(width: 8),
              Expanded(child: _IntervalCell(label: '02:00 PM',
                  value: '${state.feedIntervals[1].toStringAsFixed(1)} kg')),
              const SizedBox(width: 8),
              Expanded(child: _IntervalCell(label: '10:00 PM',
                  value: '${state.feedIntervals[2].toStringAsFixed(1)} kg')),
            ]),
          ]),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _IntervalCell extends StatelessWidget {
  final String label;
  final String value;
  const _IntervalCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(children: [
        Text(label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: AppColors.slate500, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                color: AppColors.blue600)),
      ]),
    );
  }
}
