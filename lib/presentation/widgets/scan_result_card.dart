import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/scan_result.dart';

class ScanResultCard extends StatelessWidget {
  final ScanResult result;
  final VoidCallback? onTap;

  const ScanResultCard({super.key, required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(result.status);
    final icon = result.isDangerous
        ? Icons.dangerous_rounded
        : result.isSuspicious
            ? Icons.warning_amber_rounded
            : Icons.verified_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.35),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              Container(
                width: double.infinity,
                color: statusColor.withOpacity(0.12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(icon, color: statusColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      result.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (result.fromCache)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flash_on,
                                color: AppTheme.primary, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              'cached',
                              style: TextStyle(
                                  color: AppTheme.primary, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // URL and details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _Chip(
                          icon: Icons.bug_report_outlined,
                          label: '${result.maliciousCount} malicious',
                          color: AppTheme.danger,
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          icon: Icons.warning_outlined,
                          label: '${result.suspiciousCount} suspicious',
                          color: AppTheme.warning,
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM HH:mm').format(result.analysisDate),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}
