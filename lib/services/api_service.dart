import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://smartcage-backend-production.up.railway.app';

  // Fetch the latest telemetry reading
  Future<Map<String, dynamic>?> fetchLatestTelemetry() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/telemetry/latest'));
      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') return null;
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('ApiService: fetchLatestTelemetry error: $e');
    }
    return null;
  }

  // Fetch telemetry history (last 24 hours)
  Future<List<dynamic>?> fetchTelemetryHistory({int hours = 24}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/telemetry/history?hours=$hours'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('ApiService: fetchTelemetryHistory error: $e');
    }
    return null;
  }

  // Fetch today's feed readings
  Future<Map<String, dynamic>?> fetchTodayFeed() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/feed/today'));
      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') return null;
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('ApiService: fetchTodayFeed error: $e');
    }
    return null;
  }

  // Fetch last 7 days feed history
  Future<List<dynamic>?> fetchFeedHistory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/feed/history'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('ApiService: fetchFeedHistory error: $e');
    }
    return null;
  }

  // Fetch active alerts
  Future<List<dynamic>?> fetchAlerts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/alerts'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('ApiService: fetchAlerts error: $e');
    }
    return null;
  }

  // Fetch today's AI summary
  Future<Map<String, dynamic>?> fetchTodaySummary() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/summary/today'));
      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == 'null') return null;
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('ApiService: fetchTodaySummary error: $e');
    }
    return null;
  }

  // Send a telemetry reading (used by the simulator)
  Future<bool> postTelemetry({
    required double temperature,
    required double ammonia,
    required double feedWeight,
    required bool fanActive,
    required bool heaterActive,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/telemetry'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'temperature': temperature,
          'ammonia': ammonia,
          'feedWeight': feedWeight,
          'fanActive': fanActive,
          'heaterActive': heaterActive,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('ApiService: postTelemetry error: $e');
      return false;
    }
  }

  // Send a feed reading (used by the simulator)
  Future<bool> postFeedReading({
    required String slot,
    required double weightKg,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feed/reading'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'slot': slot.toUpperCase(),
          'weightKg': weightKg,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('ApiService: postFeedReading error: $e');
      return false;
    }
  }

  // Trigger daily AI summary generation
  Future<Map<String, dynamic>?> generateSummary() async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/summary/generate'));
      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('ApiService: generateSummary error: $e');
    }
    return null;
  }

  // Clear all alerts
  Future<bool> clearAlerts() async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/alerts'));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('ApiService: clearAlerts error: $e');
      return false;
    }
  }
}
