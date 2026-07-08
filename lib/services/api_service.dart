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

  // Fetch cameras
  Future<List<dynamic>?> fetchCameras() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cameras'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('ApiService: fetchCameras error: $e');
    }
    return null;
  }

  // Register camera
  Future<Map<String, dynamic>?> registerCamera(String name, String rtspUrl, String zone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cameras'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'rtspUrl': rtspUrl, 'zone': zone}),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('ApiService: registerCamera error: $e');
    }
    return null;
  }

  // Fetch personnel
  Future<List<dynamic>?> fetchPersonnel() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/personnel'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('ApiService: fetchPersonnel error: $e');
    }
    return null;
  }

  // Register personnel
  Future<Map<String, dynamic>?> registerPersonnel(String name, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/personnel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'role': role}),
      );
      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('ApiService: registerPersonnel error: $e');
    }
    return null;
  }

  // Upload face photo
  Future<bool> uploadFace(int id, String angle, List<int> bytes, String fileName) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/personnel/$id/face'));
      request.fields['angle'] = angle;
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('ApiService: uploadFace error: $e');
      return false;
    }
  }

  // Fetch health alerts
  Future<List<dynamic>?> fetchHealthAlerts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health-alerts'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('ApiService: fetchHealthAlerts error: $e');
    }
    return null;
  }

  // Fetch access logs
  Future<List<dynamic>?> fetchAccessLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/access-logs'));
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print('ApiService: fetchAccessLogs error: $e');
    }
    return null;
  }

  // Update camera
  Future<Map<String, dynamic>?> updateCamera(int id, String name, String rtspUrl, String zone, bool active) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/cameras/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'rtspUrl': rtspUrl, 'zone': zone, 'active': active}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('ApiService: updateCamera error: $e');
    }
    return null;
  }

  // Delete camera
  Future<bool> deleteCamera(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/cameras/$id'));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('ApiService: deleteCamera error: $e');
      return false;
    }
  }
}
