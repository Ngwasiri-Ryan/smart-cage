import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_colors.dart';

class SimulatorDrawer extends StatefulWidget {
  const SimulatorDrawer({super.key});

  @override
  State<SimulatorDrawer> createState() => _SimulatorDrawerState();
}

class _SimulatorDrawerState extends State<SimulatorDrawer> {
  late TextEditingController _f1Ctrl, _f2Ctrl, _f3Ctrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _f1Ctrl = TextEditingController(text: state.feedIntervals[0].toString());
    _f2Ctrl = TextEditingController(text: state.feedIntervals[1].toString());
    _f3Ctrl = TextEditingController(text: state.feedIntervals[2].toString());
  }

  @override
  void dispose() {
    _f1Ctrl.dispose(); _f2Ctrl.dispose(); _f3Ctrl.dispose();
    super.dispose();
  }

  void _syncFeedInputs(AppState state) {
    final vals = state.feedIntervals;
    if (_f1Ctrl.text != vals[0].toString()) _f1Ctrl.text = vals[0].toString();
    if (_f2Ctrl.text != vals[1].toString()) _f2Ctrl.text = vals[1].toString();
    if (_f3Ctrl.text != vals[2].toString()) _f3Ctrl.text = vals[2].toString();
  }

  void _onFeedChanged(AppState state) {
    final f1 = double.tryParse(_f1Ctrl.text) ?? 0;
    final f2 = double.tryParse(_f2Ctrl.text) ?? 0;
    final f3 = double.tryParse(_f3Ctrl.text) ?? 0;
    state.updateFeedReadings(f1, f2, f3);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _syncFeedInputs(state);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.slate200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        GestureDetector(
          onTap: () => state.setSimulatorOpen(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.slate100)),
            ),
            child: Row(children: [
              const Icon(Icons.memory, color: AppColors.blue600, size: 18),
              const SizedBox(width: 10),
              const Text('Arduino Hardware Simulator',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.slate800)),
              const Spacer(),
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: AppColors.slate400),
              ),
            ]),
          ),
        ),

        // Scrollable content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Temperature slider
              _sliderSection(
                label: 'Coop Temperature (°C)',
                valueLabel: '${state.temp.toStringAsFixed(1)} °C',
                min: 5, max: 50,
                value: state.temp,
                onChanged: (v) => state.updateTemp(v),
                hints: const [
                  (color: AppColors.blue500, text: 'Cold (<15°C) → Heater ON'),
                  (color: AppColors.slate400, text: 'Normal'),
                  (color: AppColors.rose500, text: 'Hot (>40°C) → Fan ON'),
                ],
              ),
              const SizedBox(height: 20),

              // NH3 slider
              _sliderSection(
                label: 'Ammonia Gas Level (ppm)',
                valueLabel: '${state.ammonia.toStringAsFixed(0)} ppm',
                min: 0, max: 120,
                value: state.ammonia,
                onChanged: (v) => state.updateAmmonia(v),
                hints: const [
                  (color: AppColors.slate400, text: '0 ppm'),
                  (color: AppColors.emerald500, text: 'Safe'),
                  (color: AppColors.amber500, text: 'Fan (25+)'),
                  (color: AppColors.rose500, text: 'Critical (50+)'),
                  (color: AppColors.slate400, text: '120'),
                ],
              ),
              const SizedBox(height: 20),

              // Feed readings
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.slate100)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("TODAY'S FEED INTAKE READINGS",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppColors.slate600, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _feedInput('06:00', _f1Ctrl, state)),
                    const SizedBox(width: 8),
                    Expanded(child: _feedInput('14:00', _f2Ctrl, state)),
                    const SizedBox(width: 8),
                    Expanded(child: _feedInput('22:00', _f3Ctrl, state)),
                  ]),
                  const SizedBox(height: 10),
                  RichText(text: TextSpan(
                    style: const TextStyle(fontSize: 9, color: AppColors.slate400),
                    children: [
                      const TextSpan(text: 'Summed intervals total: '),
                      TextSpan(
                        text: '${state.feedToday.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontWeight: FontWeight.w800,
                            color: AppColors.blue600),
                      ),
                    ],
                  )),
                ]),
              ),

              const SizedBox(height: 4),
              const Divider(color: AppColors.slate100),
              const SizedBox(height: 12),

              // Scenario buttons
              const Text('Trigger Preset Scenarios',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.slate600)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _scenarioBtn(
                    icon: Icons.eco,
                    label: 'Healthy Farm',
                    bg: AppColors.emerald50,
                    border: AppColors.emerald100,
                    fg: const Color(0xFF065F46),
                    onTap: () => state.triggerScenario('healthy'),
                  ),
                  _scenarioBtn(
                    icon: Icons.ac_unit,
                    label: 'Extreme Cold',
                    bg: AppColors.blue50,
                    border: AppColors.blue100,
                    fg: AppColors.blue700,
                    onTap: () => state.triggerScenario('cold'),
                  ),
                  _scenarioBtn(
                    icon: Icons.whatshot,
                    label: 'Extreme Heat',
                    bg: AppColors.rose50,
                    border: AppColors.rose100,
                    fg: AppColors.rose700,
                    onTap: () => state.triggerScenario('hot'),
                  ),
                  _scenarioBtn(
                    icon: Icons.warning_amber_rounded,
                    label: 'Combined Danger',
                    bg: AppColors.purple50,
                    border: AppColors.purple100,
                    fg: AppColors.purple800,
                    onTap: () => state.triggerScenario('combined'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => state.restartOnboarding(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                    Icon(Icons.replay, size: 14, color: AppColors.slate700),
                    SizedBox(width: 8),
                    Text('Replay Intro Onboarding',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                            color: AppColors.slate700)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _sliderSection({
    required String label,
    required String valueLabel,
    required double min,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
    required List<({Color color, String text})> hints,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.slate600)),
        const Spacer(),
        Text(valueLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                color: AppColors.blue600)),
      ]),
      const SizedBox(height: 6),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppColors.blue600,
          inactiveTrackColor: AppColors.slate100,
          thumbColor: AppColors.blue600,
          overlayColor: AppColors.blue600.withOpacity(0.1),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        ),
        child: Slider(
          min: min, max: max,
          value: value.clamp(min, max),
          onChanged: onChanged,
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: hints.map((h) => Text(h.text,
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: h.color))).toList(),
      ),
    ]);
  }

  Widget _feedInput(String label, TextEditingController ctrl, AppState state) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
              color: AppColors.slate400, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onSubmitted: (_) => _onFeedChanged(state),
        onEditingComplete: () => _onFeedChanged(state),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
            color: AppColors.slate800),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          fillColor: AppColors.slate50,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.slate200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.slate200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.blue600, width: 1.5),
          ),
        ),
      ),
    ]);
  }

  Widget _scenarioBtn({
    required IconData icon,
    required String label,
    required Color bg,
    required Color border,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
                overflow: TextOverflow.ellipsis),
          ),
          Icon(Icons.chevron_right, size: 12, color: fg.withOpacity(0.6)),
        ]),
      ),
    );
  }
}
