import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scan_repository.dart';
import '../models/scan_result_model.dart';
import '../services/api_service.dart';

/// Concrete implementation of [ScanRepository].
/// Cache order: Hive (local) ← API Service → MongoDB Atlas (on backend).
class ScanRepositoryImpl implements ScanRepository {
  final ApiService _apiService;

  ScanRepositoryImpl({ApiService? apiService})
      : _apiService = apiService ?? ApiService.instance;

  Box<String> get _box => Hive.box<String>(AppConstants.scanHistoryBox);

  @override
  Future<ScanResult> analyzeUrl(String url) async {
    // Delegate cache-first logic to Python backend
    final model = await _apiService.analyzeUrl(url);
    final result = model.toEntity();

    // Also persist locally in Hive for offline history
    await saveScanResult(result);

    return result;
  }

  @override
  Future<List<ScanResult>> getScanHistory() async {
    final values = _box.values.toList().reversed.toList();
    return values
        .map((raw) => ScanResultModel.fromHiveString(raw).toEntity())
        .toList();
  }

  @override
  Future<void> saveScanResult(ScanResult result) async {
    final model = ScanResultModel.fromEntity(result);
    await _box.put(result.id, model.toHiveString());
  }

  @override
  Future<void> clearHistory() async {
    await _box.clear();
  }
}
