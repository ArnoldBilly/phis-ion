import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'PhisIon';
  static const String appVersion = '1.0.0';

  // API - loaded from .env
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

  // ML Parameters - loaded from .env
  static double get confidenceThreshold =>
      double.tryParse(dotenv.env['CONFIDENCE_THRESHOLD'] ?? '0.7') ?? 0.7;

  static int get inputSize =>
      int.tryParse(dotenv.env['INPUT_SIZE'] ?? '224') ?? 224;

  // Hive Box Names
  static const String scanHistoryBox = 'scan_history_box';

  // Scan Status
  static const String statusDangerous = 'dangerous';
  static const String statusSafe = 'safe';
  static const String statusSuspicious = 'suspicious';
  static const String statusUnknown = 'unknown';

  // Image Processing
  static const double gaussianSigma = 1.5;
  static const int processingThrottleMs = 500; // throttle OCR calls

  // Scan Modes
  static const String modeQr = 'QR Code';
  static const String modeText = 'Text OCR';
}
