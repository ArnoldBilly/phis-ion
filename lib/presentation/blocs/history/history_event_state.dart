import 'package:equatable/equatable.dart';

// ── Events ───────────────────────────────────────────────────────────────────

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadHistoryEvent extends HistoryEvent {
  const LoadHistoryEvent();
}

class ClearHistoryEvent extends HistoryEvent {
  const ClearHistoryEvent();
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<dynamic> results; // List<ScanResult>
  const HistoryLoaded(this.results);
  @override
  List<Object?> get props => [results];
}

class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);
  @override
  List<Object?> get props => [message];
}
