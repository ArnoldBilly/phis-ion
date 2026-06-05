import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/analyze_url_usecase.dart';
import 'detection_event_state.dart';

/// BLoC responsible for URL phishing analysis.
/// Triggered when a URL is extracted from OCR/QR scan.
class DetectionBloc extends Bloc<DetectionEvent, DetectionState> {
  final AnalyzeUrlUseCase _analyzeUrl;

  DetectionBloc({required AnalyzeUrlUseCase analyzeUrlUseCase})
      : _analyzeUrl = analyzeUrlUseCase,
        super(const DetectionInitial()) {
    on<AnalyzeUrlEvent>(_onAnalyzeUrl);
    on<ResetDetectionEvent>(_onReset);
  }

  Future<void> _onAnalyzeUrl(
      AnalyzeUrlEvent event, Emitter<DetectionState> emit) async {
    emit(DetectionLoading(event.url));
    try {
      final result = await _analyzeUrl(event.url);
      emit(DetectionSuccess(result));
    } catch (e) {
      emit(DetectionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void _onReset(ResetDetectionEvent event, Emitter<DetectionState> emit) {
    emit(const DetectionInitial());
  }
}
