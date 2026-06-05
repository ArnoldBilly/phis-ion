import '../entities/scan_result.dart';

/// Abstract repository — interface boundary (Dependency Inversion - SOLID)
abstract class ScanRepository {
  /// Analyze a URL. Checks MongoDB Atlas cache first, then calls VirusTotal.
  Future<ScanResult> analyzeUrl(String url);

  /// Returns locally cached scan history from Hive.
  Future<List<ScanResult>> getScanHistory();

  /// Persist a scan result to local Hive storage.
  Future<void> saveScanResult(ScanResult result);

  /// Clear all local Hive history.
  Future<void> clearHistory();
}
