import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class QvacApiClient {
  // Pointing to your local FastAPI server
  static const String _baseUrl = 'http://127.0.0.1:8000';

  /// Pings the server to check if the Python daemon is running
  Future<bool> checkStatus() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/status'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Uploads the audio file to the local QVAC transcribe endpoint
  Future<String> transcribeAudio(String filePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/transcribe'),
    );

    // Attach the local file
    request.files.add(
      await http.MultipartFile.fromPath('file', filePath),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['transcript'];
    } else {
      throw Exception('Transcription failed: ${response.body}');
    }
  }

  /// Sends the raw text to the local LLM for a markdown summary
  Future<String> summarizeText(String rawText) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/summarize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': rawText}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['summary'];
    } else {
      throw Exception('Summarization failed: ${response.body}');
    }
  }
}