import '../entities/scan_result.dart';
import '../repositories/scan_repository.dart';

/// Use case: retrieve scan history from local Hive storage
class GetScanHistoryUseCase {
  final ScanRepository _repository;

  const GetScanHistoryUseCase(this._repository);

  Future<List<ScanResult>> call() async {
    return _repository.getScanHistory();
  }
}
