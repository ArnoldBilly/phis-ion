import '../entities/scan_result.dart';
import '../repositories/scan_repository.dart';

/// Use case: analyze a URL for phishing
/// Delegates to repository which handles the cache-first strategy
class AnalyzeUrlUseCase {
  final ScanRepository _repository;

  const AnalyzeUrlUseCase(this._repository);

  Future<ScanResult> call(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('URL cannot be empty');
    }
    return _repository.analyzeUrl(trimmed);
  }
}
