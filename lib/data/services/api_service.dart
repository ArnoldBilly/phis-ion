import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/scan_result_model.dart';

/// HTTP client for the Python FastAPI backend.
/// Implements the cache-first check on the backend side.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const Duration _timeout = Duration(seconds: 30);

  Future<ScanResultModel> analyzeUrl(String url) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/analyze');

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'url': url}),
          )
          .timeout(_timeout);
    } on SocketException {
      throw Exception(
          'Cannot connect to backend. Make sure FastAPI is running.');
    } on TimeoutException {
      throw Exception(
          'Request timed out. The server is taking too long to respond.');
    } on HttpException catch (e) {
      throw Exception('HTTP error: $e');
    } catch (e) {
      throw Exception('Network error: $e');
    }

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ScanResultModel.fromJson(json);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['detail'] ?? 'Server error ${response.statusCode}');
    }
  }

  /// Ping the backend health endpoint.
  Future<bool> isBackendReachable() async {
    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
