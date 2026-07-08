import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // Production WSS Backend URL:
  // static const String baseUrl = 'https://smartcage-backend-production.up.railway.app';
  // Local Development (Android Emulator loopback to host):
  static const String baseUrl = 'http://10.0.2.2:3000';
  IO.Socket? socket;

  void connect({
    required Function(Map<String, dynamic>) onTelemetryUpdate,
    required Function(Map<String, dynamic>) onFeedUpdate,
    required Function(Map<String, dynamic>) onAlertNew,
    required Function(Map<String, dynamic>) onRelayChange,
    required Function(Map<String, dynamic>) onHealthAlertNew,
    required Function(Map<String, dynamic>) onAccessLogNew,
    Function(bool)? onConnectionStatus,
  }) {
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Force WebSocket only (highly recommended for Flutter/Railway)
          .enableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      print('SocketService: Connected to WSS gateway');
      if (onConnectionStatus != null) onConnectionStatus(true);
    });

    socket!.onDisconnect((_) {
      print('SocketService: Disconnected from WSS gateway');
      if (onConnectionStatus != null) onConnectionStatus(false);
    });

    socket!.onConnectError((err) {
      print('SocketService: Connection error: $err');
    });

    socket!.on('telemetry:update', (data) {
      print('SocketService: telemetry:update: $data');
      if (data != null) {
        onTelemetryUpdate(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('feed:update', (data) {
      print('SocketService: feed:update: $data');
      if (data != null) {
        onFeedUpdate(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('alert:new', (data) {
      print('SocketService: alert:new: $data');
      if (data != null) {
        onAlertNew(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('health-alert:new', (data) {
      print('SocketService: health-alert:new: $data');
      if (data != null) {
        onHealthAlertNew(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('access-log:new', (data) {
      print('SocketService: access-log:new: $data');
      if (data != null) {
        onAccessLogNew(Map<String, dynamic>.from(data));
      }
    });

    socket!.on('relay:change', (data) {
      print('SocketService: relay:change: $data');
      if (data != null) {
        onRelayChange(Map<String, dynamic>.from(data));
      }
    });
  }

  void disconnect() {
    socket?.disconnect();
  }
}
