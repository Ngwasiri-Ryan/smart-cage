import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ToastData {
  final String message;
  final String severity;
  ToastData(this.message, this.severity);
}

class AlertItem {
  final int id;
  final DateTime date;
  final String type;
  final String description;
  final String severity;

  AlertItem({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    required this.severity,
  });
}

class AppState extends ChangeNotifier {
  // Onboarding
  int onboardingSlide = 0;
  bool onboardingComplete = false;

  // Navigation
  int activeTab = 0;

  // Simulator drawer
  bool simulatorOpen = false;

  // Sensor readings
  double temp = 24;
  double ammonia = 8;
  double feedToday = 45;
  List<double> feedIntervals = [15, 15, 15];
  double weatherTemp = 22;
  double weatherRain = 10;
  DateTime lastUpdated = DateTime.now();

  // History
  List<double> feedHistory = [48, 47.5, 46.5, 44, 43.5, 42.5, 45];
  List<double> ammoniaHistory = [8, 9, 12, 14, 11, 8, 8, 8];
  List<double> heatmapData = [];

  // Relay states
  bool relayActiveFan = false;
  bool relayActiveHeater = false;

  // Alerts
  List<AlertItem> alerts = [];

  // AI summary
  String aiSummary = '"Temperature and ammonia are within safe limits. Feed intake is steady."';
  bool aiLoading = false;

  // Pending toasts consumed by the UI
  final List<ToastData> _pendingToasts = [];
  List<ToastData> get pendingToasts => List.unmodifiable(_pendingToasts);

  AppState() {
    _generateInitialAlerts();
    _initHeatmapData();
    _updateRelays();
  }

  void _generateInitialAlerts() {
    alerts = [
      AlertItem(
        id: 1,
        date: DateTime.now().subtract(const Duration(hours: 10)),
        type: 'Ammonia',
        description: 'Ammonia level entering watch zone (Caution)',
        severity: 'Caution',
      ),
    ];
  }

  void _initHeatmapData() {
    final rng = Random();
    heatmapData = List.generate(91, (i) {
      double val = 4 + rng.nextInt(6).toDouble();
      if (i % 12 == 0) val = 12 + rng.nextInt(8).toDouble();
      else if (i % 25 == 0) val = 26 + rng.nextInt(14).toDouble();
      else if (i % 44 == 0) val = 52 + rng.nextInt(25).toDouble();
      return val;
    });
    heatmapData[90] = ammonia;
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get feedTrendIsDeclining {
    final yesterday = feedHistory[5];
    final twoDaysAgo = feedHistory[4];
    return feedToday < yesterday && yesterday < twoDaysAgo;
  }

  bool get combinedRisk => ammonia > 25 && feedTrendIsDeclining;

  String get tempLabel {
    if (temp < 15) return '❄️ Cold (Heater ON)';
    if (temp > 40) return '🔥 Hot (Fan FULL)';
    return 'Perfect Range';
  }

  Color get tempDotColor {
    if (temp < 15) return AppColors.amber500;
    if (temp > 40) return AppColors.rose500;
    return AppColors.emerald500;
  }

  bool get tempDotPulse => temp < 15 || temp > 40;

  String get nh3Label {
    if (ammonia < 10)  return '✅ Safe level';
    if (ammonia < 25)  return '⚠️ Watch caution';
    if (ammonia < 50)  return '🟠 Warning high';
    if (ammonia <= 100) return '🔴 Critical hazard';
    return '☠️ Emergency severe';
  }

  Color get nh3DotColor {
    if (ammonia < 10)  return AppColors.emerald500;
    if (ammonia < 25)  return AppColors.yellow500;
    if (ammonia < 50)  return AppColors.orange500;
    if (ammonia <= 100) return AppColors.rose500;
    return const Color(0xFF7F1D1D);
  }

  bool get nh3DotPulse => ammonia >= 25;

  String get feedTrendLabel {
    if (feedTrendIsDeclining) return '↘ Feed down 2 days';
    if (feedToday > feedHistory[5]) return '↗ Feed improving';
    return '→ Feed stable';
  }

  Color get feedTrendColor {
    if (feedTrendIsDeclining) return AppColors.amber600;
    if (feedToday > feedHistory[5]) return AppColors.emerald600;
    return AppColors.slate400;
  }

  IconData get feedTrendIcon {
    if (feedTrendIsDeclining) return Icons.trending_down;
    if (feedToday > feedHistory[5]) return Icons.trending_up;
    return Icons.remove;
  }

  // 0 = good, 1 = warning, 2 = critical
  int get bannerStatus {
    if (ammonia >= 50 || temp > 40) return 2;
    final hasCritical = alerts.any(
        (a) => a.severity == 'Critical' || a.severity == 'Emergency');
    if (hasCritical) return 2;
    final hasWarning = alerts.any((a) => a.severity == 'Warning');
    if (hasWarning || feedTrendIsDeclining) return 1;
    return 0;
  }

  ({String title, String desc, Color bg, Color border, Color textColor, Color iconColor, bool isCritical}) get bannerInfo {
    switch (bannerStatus) {
      case 2:
        return (
          title: '🔴 ALERT — CHECK BIRDS',
          desc: 'Critical environmental threats active',
          bg: AppColors.rose50,
          border: AppColors.rose100,
          textColor: const Color(0xFF9F1239),
          iconColor: AppColors.rose500,
          isCritical: true,
        );
      case 1:
        return (
          title: '🟠 CHECK FEED / COOP',
          desc: 'Cautionary indicators active',
          bg: AppColors.amber50,
          border: AppColors.amber100,
          textColor: const Color(0xFF92400E),
          iconColor: AppColors.amber500,
          isCritical: false,
        );
      default:
        return (
          title: '🟢 ALL GOOD',
          desc: 'Conditions within optimum metrics',
          bg: AppColors.emerald50,
          border: AppColors.emerald100,
          textColor: const Color(0xFF065F46),
          iconColor: AppColors.emerald500,
          isCritical: false,
        );
    }
  }

  String get ammoniaClinicalText {
    if (ammonia < 10) {
      return 'Air conditions are clean and optimal. To maintain these levels, verify that dry wood shavings are distributed evenly and that natural side curtains remain unblocked.';
    } else if (ammonia < 25) {
      return 'Ammonia is accumulating slightly. Consider increasing ventilation monitoring. Ensure coop bedding is completely dry, as moist litter dramatically accelerates biological nitrogen gas conversion.';
    } else if (ammonia < 50) {
      return 'Warning threshold exceeded. Automated ventilation fans have been triggered to evacuate excess moisture. Recommend physically inspecting the coops and applying safe clay-based litter treatments to neutralize biological runoff.';
    }
    return 'CRITICAL NITROGEN HAZARD! Severe exposure risks causing respiratory damage, cornea swelling, and heavy flock mortality. Maintain maximum ventilation and safely check flock immediately.';
  }

  Color get chamberBubbleColor {
    if (ammonia < 10)  return const Color(0x5910B981);
    if (ammonia < 25)  return const Color(0x73EAB308);
    if (ammonia < 50)  return const Color(0x8CF97316);
    return const Color(0xBFF43F5E);
  }

  int get chamberBubbleCount => min((ammonia * 0.8 + 3).toInt(), 50);

  // ── Actions ──────────────────────────────────────────────────────────────

  void consumeToasts() {
    _pendingToasts.clear();
  }

  void _toast(String message, String severity) {
    _pendingToasts.add(ToastData(message, severity));
  }

  void _triggerAlertOnce(String type, String description, String severity) {
    final exists = alerts.any((a) => a.description == description);
    if (!exists) {
      alerts.insert(
        0,
        AlertItem(
          id: DateTime.now().microsecondsSinceEpoch,
          date: DateTime.now(),
          type: type,
          description: description,
          severity: severity,
        ),
      );
      _toast(description, severity);
    }
  }

  void _checkAlerts() {
    if (temp < 15) {
      _triggerAlertOnce('Temperature',
          'Very cold temperatures detected — check heating', 'Warning');
    }
    if (temp > 40) {
      _triggerAlertOnce('Temperature',
          'Very hot temperatures detected — check ventilation', 'Warning');
    }
    if (ammonia >= 10 && ammonia < 25) {
      _triggerAlertOnce(
          'Ammonia', 'Ammonia level entering watch zone (Caution)', 'Caution');
    }
    if (ammonia >= 25 && ammonia < 50) {
      _triggerAlertOnce('Ammonia',
          'Elevated Ammonia - ventilation automated (Warning)', 'Warning');
    }
    if (ammonia >= 50 && ammonia <= 100) {
      _triggerAlertOnce('Ammonia',
          'Hazardous Ammonia: ventilation at full cap (Critical)', 'Critical');
    }
    if (ammonia > 100) {
      _triggerAlertOnce('Ammonia',
          'Severe Ammonia: Evacuate birds immediately (Emergency)', 'Emergency');
    }
    if (feedTrendIsDeclining) {
      _triggerAlertOnce(
          'Feed',
          'Feed consumption declining for 2 consecutive days — check bird health',
          'Warning');
    }
    if (combinedRisk) {
      _triggerAlertOnce(
          'Combined',
          'Ammonia high and feed consumption down (Combined Risk)',
          'Warning');
    }
    final last3Avg = (feedHistory[5] + feedHistory[4] + feedHistory[3]) / 3;
    final intervalAvg = last3Avg / 3;
    for (final r in feedIntervals) {
      if (r < intervalAvg * 0.05) {
        _triggerAlertOnce(
            'Feed',
            'Feeder may be blocked (8-hour cycle very low) — check equipment',
            'Warning');
        break;
      }
    }
  }

  void _updateRelays() {
    relayActiveHeater = temp < 15;
    relayActiveFan = ammonia >= 25 || temp > 40;
  }

  void _updateHeatmapToday() {
    if (heatmapData.isNotEmpty) {
      heatmapData[90] = max(heatmapData[90], ammonia);
    }
  }

  void updateTemp(double value) {
    temp = value;
    _updateRelays();
    _checkAlerts();
    lastUpdated = DateTime.now();
    notifyListeners();
  }

  void updateAmmonia(double value) {
    ammonia = value;
    ammoniaHistory[7] = value;
    _updateHeatmapToday();
    _updateRelays();
    _checkAlerts();
    lastUpdated = DateTime.now();
    notifyListeners();
  }

  void updateFeedReadings(double f1, double f2, double f3) {
    feedIntervals = [f1, f2, f3];
    feedToday = f1 + f2 + f3;
    feedHistory[6] = feedToday;
    _checkAlerts();
    lastUpdated = DateTime.now();
    notifyListeners();
  }

  void triggerScenario(String preset) {
    alerts.clear();
    _pendingToasts.clear();

    switch (preset) {
      case 'healthy':
        temp = 24; ammonia = 8;
        feedIntervals = [15, 15, 15]; feedToday = 45;
        feedHistory = [44, 44.5, 43.8, 44.2, 45, 43.9, 45];
        ammoniaHistory = [8, 9, 10, 8, 9, 8, 8, 8];
        _toast('Healthy farm environment preset loaded', 'Caution');
        break;
      case 'cold':
        temp = 8; ammonia = 6;
        feedIntervals = [14, 14.5, 14]; feedToday = 42.5;
        _toast('Extreme cold — Heater automatically engaged', 'Warning');
        break;
      case 'hot':
        temp = 42; ammonia = 8;
        feedIntervals = [13, 13, 12]; feedToday = 38;
        _toast('Extreme heat — Fan engaged on High speed', 'Warning');
        break;
      case 'combined':
        temp = 24; ammonia = 58;
        feedIntervals = [10, 10, 11]; feedToday = 31;
        feedHistory = [48, 45, 41, 38, 36, 34, 31];
        ammoniaHistory = [12, 18, 26, 34, 42, 50, 58, 58];
        _toast('Combined Hazard Scenario Active!', 'Critical');
        break;
    }
    feedHistory[6] = feedToday;
    _updateHeatmapToday();
    _updateRelays();
    _checkAlerts();
    lastUpdated = DateTime.now();
    simulatorOpen = false;
    notifyListeners();
  }

  void clearAlerts() {
    alerts.clear();
    _toast('Alert logs cleared successfully', 'Caution');
    notifyListeners();
  }

  void setActiveTab(int tab) {
    activeTab = tab;
    notifyListeners();
  }

  void setSimulatorOpen(bool open) {
    simulatorOpen = open;
    notifyListeners();
  }

  void nextOnboardingSlide() {
    if (onboardingSlide < 2) {
      onboardingSlide++;
    } else {
      onboardingComplete = true;
    }
    notifyListeners();
  }

  void previousOnboardingSlide() {
    if (onboardingSlide > 0) {
      onboardingSlide--;
      notifyListeners();
    }
  }

  void skipOnboarding() {
    onboardingComplete = true;
    notifyListeners();
  }

  void restartOnboarding() {
    onboardingSlide = 0;
    onboardingComplete = false;
    simulatorOpen = false;
    notifyListeners();
  }

  void generateLocalAISummary() {
    String summary;
    if (ammonia >= 50) {
      summary = 'Critical ammonia hazard! Automated fans are fully engaged. Inspect coop immediately.';
    } else if (temp < 15) {
      summary = 'Low temperature threshold crossed. Heater relay engaged to safeguard chicks.';
    } else if (temp > 40) {
      summary = 'Extreme heat stress risk. Fan relays working at maximum speed capacity.';
    } else if (feedTrendIsDeclining && ammonia >= 25) {
      summary = 'Combined Risk: Ammonia high and feed intake dropping. High risk of flock illness.';
    } else if (feedTrendIsDeclining) {
      summary = 'Feed intake is dropping consecutive days. Assess flock for clinical symptoms.';
    } else if (ammonia >= 25) {
      summary = 'Ammonia levels high. Automated ventilation fans activated to restore equilibrium.';
    } else {
      summary = 'Temperature and ammonia are within safe limits. Feed intake is steady.';
    }
    aiSummary = '"$summary"';
    notifyListeners();
  }
}
