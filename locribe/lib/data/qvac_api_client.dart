import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class QvacApiClient {
  final String baseUrl = 'http://127.0.0.1:8000';

  Map<String, dynamic> _parse(http.Response res, String label) {
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception('$label failed: $body');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('$label: unexpected response: $body');
    }
    return decoded;
  }

  String _requireString(Map<String, dynamic> data, String key, String label) {
    final value = data[key];
    if (value is! String) {
      throw Exception('$label: "$key" missing in response: $data');
    }
    return value;
  }

  /// GET /status -> {"status": "ready"}
  Future<bool> checkStatus() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/status'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) {
        debugPrint('[LoCribe] Status check failed: HTTP ${res.statusCode}');
        return false;
      }

      final body = utf8.decode(res.bodyBytes);
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('[LoCribe] Status check failed: unexpected payload');
        return false;
      }

      return decoded['status'] == 'ready';
    } catch (e) {
      debugPrint('[LoCribe] Status check failed: $e');
      return false;
    }
  }

  /// POST /transcribe  ->  {"text": "..."}
  Future<String> transcribeAudio(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/transcribe'),
    )..files.add(await http.MultipartFile.fromPath('file', filePath));
    final res = await http.Response.fromStream(await request.send());
    return _requireString(
      _parse(res, 'Transcription'),
      'text',
      'Transcription',
    );
  }

  /// POST /summarize  ->  {"summary": "..."}
  Future<String> summarizeText(
    String text, {
    String mode = 'concise',
    int maxBullets = 3,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/summarize'),
      body: {'text': text, 'mode': mode, 'max_bullets': maxBullets.toString()},
    );
    return _requireString(
      _parse(res, 'Summarization'),
      'summary',
      'Summarization',
    );
  }
}
