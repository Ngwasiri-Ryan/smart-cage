import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AiSummaryCard(state: state),
        const SizedBox(height: 16),
        _SensorGrid(state: state),
        const SizedBox(height: 16),
        _WeatherForecastCard(),
        const SizedBox(height: 16),
        _TempChartCard(state: state),
        const SizedBox(height: 12),
        _LastUpdatedFooter(state: state),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── AI Summary Card ───────────────────────────────────────────────────────────

class _AiSummaryCard extends StatelessWidget {
  final AppState state;
  const _AiSummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue600, AppColors.indigo700],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.blue600.withOpacity(0.15),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.auto_awesome, color: AppColors.blue200, size: 14),
              const SizedBox(width: 8),
              const Text('DAILY HEALTH SUMMARY',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: AppColors.blue200, letterSpacing: 1.5)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.read<AppState>().generateLocalAISummary(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.refresh, color: Colors.white, size: 10),
                    SizedBox(width: 4),
                    Text('Regen', style: TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            if (state.aiLoading)
              Row(children: [
                _Dot(delay: 0), _Dot(delay: 150), _Dot(delay: 300),
                const SizedBox(width: 8),
                const Text('Analyzing flock telemetry...',
                    style: TextStyle(fontSize: 10, color: AppColors.blue200)),
              ])
            else
              Text(state.aiSummary,
                  style: const TextStyle(fontSize: 12, color: AppColors.blue50,
                      fontStyle: FontStyle.italic, height: 1.6)),
          ]),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: -5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _anim.value), child: child,
        ),
        child: Container(
          width: 6, height: 6, margin: const EdgeInsets.only(right: 4),
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        ),
      );
}

// ── Sensor Grid ───────────────────────────────────────────────────────────────

class _SensorGrid extends StatelessWidget {
  final AppState state;
  const _SensorGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _TempCard(state: state)),
          const SizedBox(width: 12),
          Expanded(child: _Nh3Card(state: state)),
        ]),
      ),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _FeedCard(state: state)),
          const SizedBox(width: 12),
          Expanded(child: _WeatherCard(state: state)),
        ]),
      ),
    ]);
  }
}

class _SensorCard extends StatelessWidget {
  final Widget child;
  const _SensorCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _TempCard extends StatelessWidget {
  final AppState state;
  const _TempCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SensorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Text('TEMPERATURE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.slate400, letterSpacing: 1)),
            const Spacer(),
            _PulseDot(color: state.tempDotColor, pulse: state.tempDotPulse),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: RichText(text: TextSpan(children: [
              TextSpan(text: state.temp.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900,
                      color: AppColors.slate800, letterSpacing: -1)),
              const TextSpan(text: ' °C',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.slate400)),
            ])),
          ),
          Row(children: [
            const Icon(Icons.thermostat, size: 12, color: AppColors.blue500),
            const SizedBox(width: 4),
            Expanded(
              child: Text(state.tempLabel,
                  style: const TextStyle(fontSize: 10, color: AppColors.slate500,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Nh3Card extends StatelessWidget {
  final AppState state;
  const _Nh3Card({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SensorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Text('AMMONIA',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.slate400, letterSpacing: 1)),
            const Spacer(),
            _PulseDot(color: state.nh3DotColor, pulse: state.nh3DotPulse),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: RichText(text: TextSpan(children: [
              TextSpan(text: state.ammonia.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900,
                      color: AppColors.slate800, letterSpacing: -1)),
              const TextSpan(text: ' ppm',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.slate400)),
            ])),
          ),
          Row(children: [
            const Icon(Icons.air, size: 12, color: Color(0xFF38BDF8)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(state.nh3Label,
                  style: const TextStyle(fontSize: 10, color: AppColors.slate500,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final AppState state;
  const _FeedCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SensorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Text('FEED TODAY',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.slate400, letterSpacing: 1)),
            const Spacer(),
            Icon(state.feedTrendIcon, size: 12, color: state.feedTrendColor),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: RichText(text: TextSpan(children: [
              TextSpan(text: state.feedToday.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900,
                      color: AppColors.slate800, letterSpacing: -1)),
              const TextSpan(text: ' kg',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.slate400)),
            ])),
          ),
          Row(children: [
            const Icon(Icons.grass, size: 12, color: AppColors.amber500),
            const SizedBox(width: 4),
            Expanded(
              child: Text(state.feedTrendLabel,
                  style: TextStyle(fontSize: 10, color: state.feedTrendColor,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  final AppState state;
  const _WeatherCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return _SensorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Text('OUTSIDE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.slate400, letterSpacing: 1)),
            const Spacer(),
            const Icon(Icons.wb_sunny, size: 14, color: AppColors.amber500),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: RichText(text: TextSpan(children: [
              TextSpan(text: state.weatherTemp.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900,
                      color: AppColors.slate800, letterSpacing: -1)),
              const TextSpan(text: ' °C',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.slate400)),
            ])),
          ),
          Row(
            children: [
              Expanded(
                child: Text('Rain: ${state.weatherRain.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 10, color: AppColors.slate500,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('Coop Ext',
                    style: TextStyle(fontSize: 8, color: AppColors.blue600,
                        fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pulse Dot ─────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  final bool pulse;
  const _PulseDot({required this.color, required this.pulse});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulse) {
      return Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color));
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Opacity(opacity: _anim.value, child: child),
      child: Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
    );
  }
}

// ── 7-Day Forecast ────────────────────────────────────────────────────────────

class _WeatherForecastCard extends StatelessWidget {
  final _days = const [
    ('Mon', Icons.wb_sunny, AppColors.amber500, '23°', '0%', false),
    ('Tue', Icons.cloud, AppColors.blue400, '22°', '10%', false),
    ('Wed', Icons.cloud, AppColors.blue400, '24°', '15%', false),
    ('Thu', Icons.thunderstorm, AppColors.blue500, '18°', '80%', true),
    ('Fri', Icons.grain, AppColors.blue400, '19°', '65%', true),
    ('Sat', Icons.cloud, AppColors.slate400, '21°', '20%', false),
    ('Sun', Icons.wb_sunny, AppColors.amber500, '25°', '0%', false),
  ];

  const _WeatherForecastCard();

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
            Text('COOP PLANNING TOOL',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.slate400, letterSpacing: 1)),
            SizedBox(height: 2),
            Text('7-Day Local Weather Forecast',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.slate800)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.blue50,
                borderRadius: BorderRadius.circular(6)),
            child: const Text('Precipitation Alerts',
                style: TextStyle(fontSize: 9, color: AppColors.blue600,
                    fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          children: _days.map((d) {
            final rain = d.$6;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: rain ? AppColors.blue50.withOpacity(0.5) : AppColors.slate50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: rain ? AppColors.blue100.withOpacity(0.5) : AppColors.slate100),
                ),
                child: Column(children: [
                  Text(d.$1,
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                          color: rain ? AppColors.blue600 : AppColors.slate500)),
                  const SizedBox(height: 4),
                  Icon(d.$2, size: 12, color: d.$3),
                  const SizedBox(height: 4),
                  Text(d.$4,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                          color: AppColors.slate800)),
                  Text(d.$5,
                      style: TextStyle(fontSize: 8,
                          color: rain ? AppColors.blue600 : AppColors.slate400,
                          fontWeight: rain ? FontWeight.w700 : FontWeight.w400)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: const [
            Icon(Icons.info_outline, color: AppColors.blue600, size: 12),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Rain forecast Thursday. Prepare litter management to protect ammonia spikes.',
                style: TextStyle(fontSize: 9, color: AppColors.slate500, height: 1.4),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Temperature Chart ─────────────────────────────────────────────────────────

class _TempChartCard extends StatelessWidget {
  final AppState state;
  const _TempChartCard({required this.state});

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
            Text('INTERNAL COOP TEMP',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: AppColors.slate400, letterSpacing: 1)),
            SizedBox(height: 2),
            Text('Past 24 Hours Telemetry',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.slate800)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.slate50,
                borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: const [
              Icon(Icons.circle, color: AppColors.blue600, size: 7),
              SizedBox(width: 4),
              Text('DHT Sensor',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                      color: AppColors.slate500)),
            ]),
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
                      if (i < 0 || i >= state.telemetryTimeLabels.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(state.telemetryTimeLabels[i],
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                                color: AppColors.slate500)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 5,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}°',
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                            color: AppColors.slate500)),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(state.tempHistory.length,
                          (i) => FlSpot(i.toDouble(), state.tempHistory[i])),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.blue600,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 3.5,
                      color: AppColors.blue600,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [
                        AppColors.blue600.withOpacity(0.25),
                        AppColors.blue600.withOpacity(0),
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

// ── Last Updated Footer ───────────────────────────────────────────────────────

class _LastUpdatedFooter extends StatefulWidget {
  final AppState state;
  const _LastUpdatedFooter({required this.state});

  @override
  State<_LastUpdatedFooter> createState() => _LastUpdatedFooterState();
}

class _LastUpdatedFooterState extends State<_LastUpdatedFooter> {
  late String _label;

  @override
  void initState() {
    super.initState();
    _update();
    Stream.periodic(const Duration(seconds: 5)).listen((_) { if (mounted) _update(); });
  }

  void _update() {
    final diff = DateTime.now().difference(widget.state.lastUpdated).inSeconds;
    setState(() {
      if (diff < 5) {
        _label = 'Just now';
      } else if (diff < 60) {
        _label = '${diff}s ago';
      } else {
        _label = '${diff ~/ 60}m ago';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.history, size: 12, color: AppColors.slate300),
      const SizedBox(width: 4),
      const Text('Telemetry updated: ',
          style: TextStyle(fontSize: 10, color: AppColors.slate400)),
      Text(_label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: AppColors.slate500)),
    ]);
  }
}
