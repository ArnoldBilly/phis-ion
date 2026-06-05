import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_service.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_event_state.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _backendReachable = false;
  bool _checkingBackend = true;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    setState(() => _checkingBackend = true);
    final ok = await ApiService.instance.isBackendReachable();
    if (mounted) setState(() {
      _backendReachable = ok;
      _checkingBackend = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: AppTheme.bgPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _Section(
            title: 'Backend Status',
            children: [
              _StatusRow(
                label: 'FastAPI Backend',
                sublabel: AppConstants.apiBaseUrl,
                isLoading: _checkingBackend,
                isOnline: _backendReachable,
                onRefresh: _checkBackend,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'AI Parameters',
            children: [
              _InfoRow(
                icon: Icons.tune_rounded,
                label: 'Confidence Threshold',
                value: '${(AppConstants.confidenceThreshold * 100).toStringAsFixed(0)}%',
              ),
              _InfoRow(
                icon: Icons.photo_size_select_large_rounded,
                label: 'Input Size',
                value: '${AppConstants.inputSize} × ${AppConstants.inputSize}px',
              ),
              _InfoRow(
                icon: Icons.blur_on_rounded,
                label: 'Gaussian Sigma',
                value: '${AppConstants.gaussianSigma}',
              ),
              _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Processing Throttle',
                value: '${AppConstants.processingThrottleMs}ms',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Local Data',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppTheme.danger, size: 18),
                ),
                title: const Text('Clear Scan History',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                subtitle: const Text('Remove all local records',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary),
                onTap: () {
                  context.read<HistoryBloc>().add(const ClearHistoryEvent());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('History cleared'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'About',
            children: [
              _InfoRow(
                icon: Icons.info_outline_rounded,
                label: 'Version',
                value: AppConstants.appVersion,
              ),
              _InfoRow(
                icon: Icons.architecture_rounded,
                label: 'Architecture',
                value: 'SOLID + BLoC',
              ),
              _InfoRow(
                icon: Icons.memory_rounded,
                label: 'Inference',
                value: 'Google ML Kit (On-device)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isLoading;
  final bool isOnline;
  final VoidCallback onRefresh;

  const _StatusRow({
    required this.label,
    required this.sublabel,
    required this.isLoading,
    required this.isOnline,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (isOnline ? AppTheme.safe : AppTheme.danger).withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: AppTheme.primary, strokeWidth: 2)))
            : Icon(
                isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                color: isOnline ? AppTheme.safe : AppTheme.danger,
                size: 18,
              ),
      ),
      title: Text(label,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      subtitle: Text(sublabel,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: IconButton(
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded,
            color: AppTheme.textSecondary, size: 18),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
      trailing: Text(value,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13)),
    );
  }
}
