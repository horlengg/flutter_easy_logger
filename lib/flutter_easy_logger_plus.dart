import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart';

class EasyLogger {
  static final EasyLogger instance = EasyLogger._internal();
  EasyLogger._internal();

  Socket? _socket;
  bool _isConnecting = false;
  final List<_LogRequest> _pendingLogs = [];

  bool get _isEnableLog =>
      const bool.fromEnvironment('ENABLE_LOG', defaultValue: false);

  void initialize(String url) {
    if (!_isEnableLog) return;
    _isConnecting = true;

    _socket = io(
      url,
      OptionBuilder().setTransports(['websocket']).disableAutoConnect().build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Logger socket connected $url');
      _isConnecting = false;
      _flushPendingLogs();
    });

    _socket!.onDisconnect((_) {
      print('Logger socket disconnected');
      _isConnecting = false;
    });

    _socket!.onConnectError((e) {
      print('Logger socket error: $e');
      _isConnecting = false;
    });
  }

  void _flushPendingLogs() {
    for (final log in _pendingLogs) {
      _socket!.emit('send-logs', log.toJson());
    }
    _pendingLogs.clear();
  }

  bool get _isLoggerAvailable {
    if (!_isEnableLog) return false;
    if (_socket == null && !_isConnecting) {
      print("Error : Missing initialize EasyLogger");
      print(
        "Please call EasyLogger.initialize(url:'Your local server')\n\n\n\n",
      );
      return false;
    }
    return true;
  }

  void _sendToServer(_LogRequest request) {
    if (_isConnecting || !(_socket?.connected ?? false)) {
      _pendingLogs.add(request);
      return;
    }
    _socket!.emit('send-logs', request.toJson());
  }

  void debug(String message, {String? tag}) {
    if (!_isLoggerAvailable) return;
    _sendToServer(
      _LogRequest(message: message, tag: tag ?? "DEFAULT", type: LogType.debug),
    );
  }

  void warning(String message, {String? tag}) {
    if (!_isLoggerAvailable) return;
    _sendToServer(
      _LogRequest(
        message: message,
        tag: tag ?? "DEFAULT",
        type: LogType.warning,
      ),
    );
  }

  void error(String message, {String? tag}) {
    if (!_isLoggerAvailable) return;
    _sendToServer(
      _LogRequest(message: message, tag: tag ?? "DEFAULT", type: LogType.error),
    );
  }

  void clear() {
    if (!_isLoggerAvailable) return;
    _socket!.emit('clear');
  }

  void dispose() {
    _pendingLogs.clear();
    _socket?.dispose();
  }

  String toJSONString(dynamic data) {
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }

}

enum LogType { debug, warning, error }

extension LogTypeExtension on LogType {
  int get value => switch (this) {
    LogType.debug => 0,
    LogType.warning => 1,
    LogType.error => 2,
  };
}

class _LogRequest {
  String message;
  String tag;
  LogType type;

  _LogRequest({required this.message, required this.tag, required this.type});

  Map<String, dynamic> toJson() => {
    "message": message,
    "tag": tag,
    "type": type.value,
  };
}