import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

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
  // Services
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();
  bool isConnected = false;

  // Onboarding
  int onboardingSlide = 0;
  bool onboardingComplete = false;

  // Navigation
  int activeTab = 0;

  // Simulator drawer
  bool simulatorOpen = false;

  // Sensor readings (synchronized with backend)
  double temp = 0;
  double ammonia = 0;
  double feedToday = 0;
  List<double> feedIntervals = [0, 0, 0];
  double weatherTemp = 22;
  double weatherRain = 10;
  DateTime lastUpdated = DateTime.now();

  // History (synchronized with backend)
  List<double> feedHistory = [0, 0, 0, 0, 0, 0, 0];
  List<double> ammoniaHistory = [0, 0, 0, 0, 0, 0, 0, 0];
  List<double> heatmapData = [];

  // Relay states (synchronized with backend)
  bool relayActiveFan = false;
  bool relayActiveHeater = false;

  // Alerts (synchronized with backend)
  List<AlertItem> alerts = [];

  // AI summary (synchronized with backend)
  String aiSummary = '"No summary loaded..."';
  bool aiLoading = false;

  // Pending toasts consumed by the UI
  final List<ToastData> _pendingToasts = [];
  List<ToastData> get pendingToasts => List.unmodifiable(_pendingToasts);

  AppState() {
    _initHeatmapData();
    _updateRelays();

    // Phase 12: Fetch initial data from REST API and setup real-time WSS
    // Skip if running in unit test environment to avoid pending timers/network errors
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _loadInitialData();
      _setupWebSocket();
    }
  }

  // Fetch all initial dashboard states from Railway DB on launch
  Future<void> _loadInitialData() async {
    try {
      // 1. Fetch latest telemetry
      final latestTelemetry = await _apiService.fetchLatestTelemetry();
      if (latestTelemetry != null) {
        temp = (latestTelemetry['temperature'] as num).toDouble();
        ammonia = (latestTelemetry['ammonia'] as num).toDouble();
        relayActiveFan = latestTelemetry['fanActive'] as bool;
        relayActiveHeater = latestTelemetry['heaterActive'] as bool;
        if (latestTelemetry['createdAt'] != null) {
          lastUpdated = DateTime.parse(latestTelemetry['createdAt'] as String);
        }
        ammoniaHistory[7] = ammonia;
        _updateHeatmapToday();
      }

      // 2. Fetch today's feed
      final todayFeed = await _apiService.fetchTodayFeed();
      if (todayFeed != null) {
        final intervalsMap = todayFeed['intervals'] as Map<String, dynamic>;
        feedIntervals = [
          intervalsMap['MORNING'] != null ? (intervalsMap['MORNING'] as num).toDouble() : 0.0,
          intervalsMap['AFTERNOON'] != null ? (intervalsMap['AFTERNOON'] as num).toDouble() : 0.0,
          intervalsMap['NIGHT'] != null ? (intervalsMap['NIGHT'] as num).toDouble() : 0.0,
        ];
        feedToday = (todayFeed['totalKg'] as num).toDouble();
      }

      // 3. Fetch feed history
      final history = await _apiService.fetchFeedHistory();
      if (history != null && history.isNotEmpty) {
        // Map the last 7 days from the server to feedHistory
        final mappedHistory = history.map((item) => (item['totalKg'] as num).toDouble()).toList();
        // Make sure we have 7 days in the list
        if (mappedHistory.length == 7) {
          feedHistory = mappedHistory;
        } else {
          // Fallback/merge if server returns fewer than 7 records
          for (int i = 0; i < mappedHistory.length && i < 7; i++) {
            feedHistory[6 - i] = mappedHistory[mappedHistory.length - 1 - i];
          }
        }
      }

      // 4. Fetch alerts
      final alertsList = await _apiService.fetchAlerts();
      if (alertsList != null) {
        alerts = alertsList.map((item) {
          return AlertItem(
            id: item['id'] as int,
            date: DateTime.parse(item['createdAt'] as String),
            type: _capitalize(item['type'] as String),
            description: item['description'] as String,
            severity: _capitalize(item['severity'] as String),
          );
        }).toList();
      }

      // 5. Fetch AI summary
      final todaySummary = await _apiService.fetchTodaySummary();
      if (todaySummary != null) {
        aiSummary = '"${todaySummary['summary']}"';
      } else {
        aiSummary = '"No summary generated for today yet."';
      }
    } catch (e) {
      print('AppState: _loadInitialData error: $e');
    }
    notifyListeners();
  }

  // Subscribe to real-time events via Socket.io
  void _setupWebSocket() {
    _socketService.connect(
      onConnectionStatus: (status) {
        isConnected = status;
        if (status) {
          _toast('Connected to ChirpGuard server', 'Caution');
          _loadInitialData(); // Load live data from REST API immediately on connection success
        }
        notifyListeners();
      },
      onTelemetryUpdate: (data) {
        temp = (data['temperature'] as num).toDouble();
        ammonia = (data['ammonia'] as num).toDouble();
        if (data['createdAt'] != null) {
          lastUpdated = DateTime.parse(data['createdAt'] as String);
        }
        ammoniaHistory[7] = ammonia;
        _updateHeatmapToday();
        _updateRelays();
        notifyListeners();
      },
      onFeedUpdate: (data) {
        final intervalsMap = data['intervals'] as Map<String, dynamic>;
        feedIntervals = [
          intervalsMap['MORNING'] != null ? (intervalsMap['MORNING'] as num).toDouble() : 0.0,
          intervalsMap['AFTERNOON'] != null ? (intervalsMap['AFTERNOON'] as num).toDouble() : 0.0,
          intervalsMap['NIGHT'] != null ? (intervalsMap['NIGHT'] as num).toDouble() : 0.0,
        ];
        feedToday = (data['totalKg'] as num).toDouble();
        feedHistory[6] = feedToday;
        notifyListeners();
      },
      onAlertNew: (data) {
        final newAlert = AlertItem(
          id: data['id'] as int,
          date: DateTime.parse(data['createdAt'] as String),
          type: _capitalize(data['type'] as String),
          description: data['description'] as String,
          severity: _capitalize(data['severity'] as String),
        );
        if (!alerts.any((a) => a.id == newAlert.id)) {
          alerts.insert(0, newAlert);
          _toast(newAlert.description, newAlert.severity);
        }
        notifyListeners();
      },
      onRelayChange: (data) {
        relayActiveFan = data['fanActive'] as bool;
        relayActiveHeater = data['heaterActive'] as bool;
        notifyListeners();
      },
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
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

  void _updateRelays() {
    relayActiveHeater = temp < 15;
    relayActiveFan = ammonia >= 25 || temp > 40;
  }

  void _updateHeatmapToday() {
    if (heatmapData.isNotEmpty) {
      heatmapData[90] = max(heatmapData[90], ammonia);
    }
  }

  // Update temperature (posts live to Railway)
  void updateTemp(double value) {
    temp = value;
    _updateRelays();
    _updateHeatmapToday();
    lastUpdated = DateTime.now();
    notifyListeners();

    // Async REST update to DB
    _apiService.postTelemetry(
      temperature: temp,
      ammonia: ammonia,
      fanActive: relayActiveFan,
      heaterActive: relayActiveHeater,
    );
  }

  // Update ammonia (posts live to Railway)
  void updateAmmonia(double value) {
    ammonia = value;
    ammoniaHistory[7] = value;
    _updateRelays();
    _updateHeatmapToday();
    lastUpdated = DateTime.now();
    notifyListeners();

    // Async REST update to DB
    _apiService.postTelemetry(
      temperature: temp,
      ammonia: ammonia,
      fanActive: relayActiveFan,
      heaterActive: relayActiveHeater,
    );
  }

  // Update feed readings (posts live to Railway)
  void updateFeedReadings(double f1, double f2, double f3) {
    if (f1 != feedIntervals[0]) {
      _apiService.postFeedReading(slot: 'MORNING', weightKg: f1);
    }
    if (f2 != feedIntervals[1]) {
      _apiService.postFeedReading(slot: 'AFTERNOON', weightKg: f2);
    }
    if (f3 != feedIntervals[2]) {
      _apiService.postFeedReading(slot: 'NIGHT', weightKg: f3);
    }

    feedIntervals = [f1, f2, f3];
    feedToday = f1 + f2 + f3;
    feedHistory[6] = feedToday;
    lastUpdated = DateTime.now();
    notifyListeners();
  }

  // Trigger scenario preset on live DB
  void triggerScenario(String preset) {
    alerts.clear();
    _pendingToasts.clear();

    switch (preset) {
      case 'healthy':
        _apiService.postTelemetry(temperature: 24, ammonia: 8, fanActive: false, heaterActive: false);
        _apiService.postFeedReading(slot: 'MORNING', weightKg: 15);
        _apiService.postFeedReading(slot: 'AFTERNOON', weightKg: 15);
        _apiService.postFeedReading(slot: 'NIGHT', weightKg: 15);
        _toast('Healthy farm environment preset loaded', 'Caution');
        break;
      case 'cold':
        _apiService.postTelemetry(temperature: 8, ammonia: 6, fanActive: false, heaterActive: true);
        _toast('Extreme cold — Heater automatically engaged', 'Warning');
        break;
      case 'hot':
        _apiService.postTelemetry(temperature: 42, ammonia: 8, fanActive: true, heaterActive: false);
        _toast('Extreme heat — Fan engaged on High speed', 'Warning');
        break;
      case 'combined':
        _apiService.postTelemetry(temperature: 24, ammonia: 58, fanActive: true, heaterActive: false);
        _toast('Combined Hazard Scenario Active!', 'Critical');
        break;
    }

    simulatorOpen = false;
    notifyListeners();
  }

  // Clear all alerts from live DB
  void clearAlerts() {
    _apiService.clearAlerts();
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

  // Generates AI summary on the live server and updates AppState
  Future<void> generateLocalAISummary() async {
    aiLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.generateSummary();
      if (res != null) {
        aiSummary = '"${res['summary']}"';
      } else {
        _toast('Failed to generate summary', 'Warning');
      }
    } catch (e) {
      print('AppState: generateLocalAISummary error: $e');
    } finally {
      aiLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}
