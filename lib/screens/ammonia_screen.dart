import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/gas_chamber.dart';

class AmmoniaScreen extends StatelessWidget {
  const AmmoniaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        GasChamber(state: state),
        const SizedBox(height: 16),
        _ClinicalCard(state: state),
        const SizedBox(height: 16),
        _HeatmapCard(state: state),
        const SizedBox(height: 16),
        _AmmoniaChartCard(state: state),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Text('GAS SAFETY MONITOR',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: AppColors.blue600, letterSpacing: 1.5)),
      SizedBox(height: 4),
      Text('Ammonia (NH3) Levels',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
              color: AppColors.slate800)),
      SizedBox(height: 4),
      Text('Real-time analysis of hazardous gas saturation and clinical threats.',
          style: TextStyle(fontSize: 12, color: AppColors.slate500, height: 1.5)),
    ]);
  }
}

// ── Clinical Suggestions Card ─────────────────────────────────────────────────

class _ClinicalCard extends StatelessWidget {
  final AppState state;
  const _ClinicalCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.indigo50, AppColors.blue50],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 26, height: 26,
            decoration: const BoxDecoration(
              color: AppColors.blue600, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.memory, color: Colors.white, size: 12),
          ),
          const SizedBox(width: 10),
          const Text('AUTOMATED DIAGNOSTICS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                  color: AppColors.slate800, letterSpacing: 1)),
        ]),
        const SizedBox(height: 10),
        Text(state.ammoniaClinicalText,
            style: const TextStyle(fontSize: 12, color: AppColors.slate600,
                height: 1.6)),
      ]),
    );
  }
}

// ── Heatmap Card ──────────────────────────────────────────────────────────────

class _HeatmapCard extends StatelessWidget {
  final AppState state;
  const _HeatmapCard({required this.state});

  static const _weekdayLabels = ['Mon', '', 'Wed', '', 'Fri', '', 'Sun'];

  Color _cellColor(double v) {
    if (v <= 0)  return AppColors.slate100;
    if (v < 10)  return AppColors.blue50;
    if (v < 25)  return AppColors.blue200;
    if (v < 50)  return AppColors.blue400;
    if (v < 100) return AppColors.blue600;
    return AppColors.blue900;
  }

  String _cellLabel(double v) {
    if (v <= 0)  return 'None';
    if (v < 10)  return 'Safe';
    if (v < 25)  return 'Caution';
    if (v < 50)  return 'Warning';
    if (v < 100) return 'Critical';
    return 'Emergency';
  }

  @override
  Widget build(BuildContext context) {
    final data = state.heatmapData;

    return Container(
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
            Text('HISTORY TRACKER',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.slate400, letterSpacing: 1)),
            SizedBox(height: 2),
            Text('Peak Ammonia Heatmap (Past 12 Weeks)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.slate800)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.blue50,
                borderRadius: BorderRadius.circular(6)),
            child: const Text('Log History',
                style: TextStyle(fontSize: 9, color: AppColors.blue600,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),

        // Grid
        LayoutBuilder(builder: (context, constraints) {
          const numCols = 13;
          const numRows = 7;
          const gap = 3.0;
          final weekdayWidth = 24.0;
          final gridWidth = constraints.maxWidth - weekdayWidth - 8;
          final cellSize = (gridWidth - gap * (numCols - 1)) / numCols;
          final gridHeight = cellSize * numRows + gap * (numRows - 1);

          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: weekdayWidth,
              height: gridHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _weekdayLabels.map((l) => Text(l,
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                        color: AppColors.slate400))).toList(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: gridWidth,
              height: gridHeight,
              child: data.isEmpty
                  ? const SizedBox()
                  : Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      direction: Axis.vertical,
                      children: List.generate(data.length, (i) {
                        final v = data[i];
                        final daysAgo = data.length - 1 - i;
                        final d = DateTime.now().subtract(Duration(days: daysAgo));
                        final label =
                            '${d.month}/${d.day} • Peak: ${v.toStringAsFixed(0)} ppm (${_cellLabel(v)})';
                        return Tooltip(
                          message: label,
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            decoration: BoxDecoration(
                              color: _cellColor(v),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        );
                      }),
                    ),
            ),
          ]);
        }),

        const SizedBox(height: 12),
        const Divider(color: AppColors.slate100, height: 1),
        const SizedBox(height: 10),
        // Legend
        Row(children: [
          const Text('Peak Readings',
              style: TextStyle(fontSize: 9, color: AppColors.slate400)),
          const Spacer(),
          const Text('Low ',
              style: TextStyle(fontSize: 8, color: AppColors.slate400)),
          ...[AppColors.slate100, AppColors.blue50, AppColors.blue200,
               AppColors.blue400, AppColors.blue600, AppColors.blue900]
              .map((c) => Container(
                width: 10, height: 10,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(2),
                ),
              )),
          const Text(' High',
              style: TextStyle(fontSize: 8, color: AppColors.slate400)),
        ]),
      ]),
    );
  }
}

// ── Ammonia Trend Chart ───────────────────────────────────────────────────────

class _AmmoniaChartCard extends StatelessWidget {
  final AppState state;
  const _AmmoniaChartCard({required this.state});

  static const _labels = ['06:00', '09:00', '12:00', '15:00', '18:00', '21:00', '00:00', 'Today'];

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Text('GAS TRAJECTORY',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.slate400, letterSpacing: 1)),
            SizedBox(height: 2),
            Text('Past 24 Hours NH3 Trend',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.slate800)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.slate50,
                borderRadius: BorderRadius.circular(6)),
            child: const Text('24h Log',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.slate500)),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
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
                    interval: 1,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= _labels.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(_labels[i],
                            style: const TextStyle(fontSize: 8,
                                fontWeight: FontWeight.w700, color: AppColors.slate500)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}',
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                            color: AppColors.slate500)),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(state.ammoniaHistory.length,
                          (i) => FlSpot(i.toDouble(), state.ammoniaHistory[i])),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.indigo600,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3.5,
                      color: AppColors.indigo600,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [
                        AppColors.indigo600.withOpacity(0.25),
                        AppColors.indigo600.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
