import 'package:equatable/equatable.dart';

class ScanResult extends Equatable {
  final String id;
  final String url;
  final String status; // 'dangerous' | 'safe' | 'suspicious' | 'unknown'
  final int maliciousCount;
  final int suspiciousCount;
  final DateTime analysisDate;
  final bool fromCache; // true if result came from MongoDB Atlas cache

  const ScanResult({
    required this.id,
    required this.url,
    required this.status,
    required this.maliciousCount,
    required this.suspiciousCount,
    required this.analysisDate,
    required this.fromCache,
  });

  bool get isDangerous => status == 'dangerous';
  bool get isSafe => status == 'safe';
  bool get isSuspicious => status == 'suspicious';

  ScanResult copyWith({
    String? id,
    String? url,
    String? status,
    int? maliciousCount,
    int? suspiciousCount,
    DateTime? analysisDate,
    bool? fromCache,
  }) {
    return ScanResult(
      id: id ?? this.id,
      url: url ?? this.url,
      status: status ?? this.status,
      maliciousCount: maliciousCount ?? this.maliciousCount,
      suspiciousCount: suspiciousCount ?? this.suspiciousCount,
      analysisDate: analysisDate ?? this.analysisDate,
      fromCache: fromCache ?? this.fromCache,
    );
  }

  @override
  List<Object?> get props => [
        id,
        url,
        status,
        maliciousCount,
        suspiciousCount,
        analysisDate,
        fromCache,
      ];
}
