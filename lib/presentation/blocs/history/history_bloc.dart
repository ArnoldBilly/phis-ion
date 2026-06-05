import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_scan_history_usecase.dart';
import '../../../domain/repositories/scan_repository.dart';
import 'history_event_state.dart';

/// BLoC responsible for managing scan history from Hive.
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetScanHistoryUseCase _getHistory;
  final ScanRepository _repository;

  HistoryBloc({
    required GetScanHistoryUseCase getScanHistoryUseCase,
    required ScanRepository repository,
  })  : _getHistory = getScanHistoryUseCase,
        _repository = repository,
        super(const HistoryLoading()) {
    on<LoadHistoryEvent>(_onLoad);
    on<ClearHistoryEvent>(_onClear);
  }

  Future<void> _onLoad(
      LoadHistoryEvent event, Emitter<HistoryState> emit) async {
    emit(const HistoryLoading());
    try {
      final results = await _getHistory();
      if (results.isEmpty) {
        emit(const HistoryEmpty());
      } else {
        emit(HistoryLoaded(results));
      }
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> _onClear(
      ClearHistoryEvent event, Emitter<HistoryState> emit) async {
    await _repository.clearHistory();
    emit(const HistoryEmpty());
  }
}
