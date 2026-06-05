import 'package:equatable/equatable.dart';

// ── Events ───────────────────────────────────────────────────────────────────

abstract class DetectionEvent extends Equatable {
  const DetectionEvent();
  @override
  List<Object?> get props => [];
}

class AnalyzeUrlEvent extends DetectionEvent {
  final String url;
  const AnalyzeUrlEvent(this.url);
  @override
  List<Object?> get props => [url];
}

class ResetDetectionEvent extends DetectionEvent {
  const ResetDetectionEvent();
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class DetectionState extends Equatable {
  const DetectionState();
  @override
  List<Object?> get props => [];
}

class DetectionInitial extends DetectionState {
  const DetectionInitial();
}

class DetectionLoading extends DetectionState {
  final String url;
  const DetectionLoading(this.url);
  @override
  List<Object?> get props => [url];
}

class DetectionSuccess extends DetectionState {
  final dynamic result; // ScanResult entity
  const DetectionSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

class DetectionError extends DetectionState {
  final String message;
  const DetectionError(this.message);
  @override
  List<Object?> get props => [message];
}
