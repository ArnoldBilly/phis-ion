import 'dart:convert';
import '../../domain/entities/scan_result.dart';

/// Hive-compatible data model for [ScanResult].
/// Stored as JSON string in Hive to avoid build_runner code generation.
class ScanResultModel {
  final String id;
  final String url;
  final String status;
  final int maliciousCount;
  final int suspiciousCount;
  final DateTime analysisDate;
  final bool fromCache;

  const ScanResultModel({
    required this.id,
    required this.url,
    required this.status,
    required this.maliciousCount,
    required this.suspiciousCount,
    required this.analysisDate,
    required this.fromCache,
  });

  // ── Mapping ──────────────────────────────────────────────────────

  factory ScanResultModel.fromEntity(ScanResult entity) {
    return ScanResultModel(
      id: entity.id,
      url: entity.url,
      status: entity.status,
      maliciousCount: entity.maliciousCount,
      suspiciousCount: entity.suspiciousCount,
      analysisDate: entity.analysisDate,
      fromCache: entity.fromCache,
    );
  }

  ScanResult toEntity() {
    return ScanResult(
      id: id,
      url: url,
      status: status,
      maliciousCount: maliciousCount,
      suspiciousCount: suspiciousCount,
      analysisDate: analysisDate,
      fromCache: fromCache,
    );
  }

  factory ScanResultModel.fromJson(Map<String, dynamic> json) {
    return ScanResultModel(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      maliciousCount: json['malicious_count'] as int? ?? 0,
      suspiciousCount: json['suspicious_count'] as int? ?? 0,
      analysisDate: DateTime.tryParse(json['analysis_date'] as String? ?? '') ??
          DateTime.now(),
      fromCache: json['from_cache'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'status': status,
      'malicious_count': maliciousCount,
      'suspicious_count': suspiciousCount,
      'analysis_date': analysisDate.toIso8601String(),
      'from_cache': fromCache,
    };
  }

  /// Serialize to JSON string for Hive storage
  String toHiveString() => jsonEncode(toJson());

  /// Deserialize from Hive JSON string
  static ScanResultModel fromHiveString(String raw) {
    return ScanResultModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
