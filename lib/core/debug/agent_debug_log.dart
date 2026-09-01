import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Debug logger for agent session 3bc34e.
class AgentDebugLog {
  AgentDebugLog._();

  static const _sessionId = '3bc34e';
  static const _endpoint =
      'http://127.0.0.1:7478/ingest/448d5e9b-b774-4c0e-837a-cd8a170b08ea';

  static void log({
    required String location,
    required String message,
    required String hypothesisId,
    Map<String, dynamic>? data,
    String runId = 'pre-fix',
  }) {
    final payload = <String, dynamic>{
      'sessionId': _sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'hypothesisId': hypothesisId,
      'data': data ?? const {},
      'runId': runId,
    };
    // #region agent log
    debugPrint('AGENT_DEBUG:3bc34e ${jsonEncode(payload)}');
    unawaited(_post(payload));
    // #endregion
  }

  static Future<void> _post(Map<String, dynamic> payload) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(_endpoint));
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('X-Debug-Session-Id', _sessionId);
      request.write(jsonEncode(payload));
      await request.close();
      client.close();
    } catch (_) {}
  }
}
