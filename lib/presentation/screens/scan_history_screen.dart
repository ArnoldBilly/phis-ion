import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_event_state.dart';
import '../widgets/scan_result_card.dart';
import '../../domain/entities/scan_result.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const LoadHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildFilterChips(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scan History',
                  style: Theme.of(context).textTheme.displayMedium),
              const Text('All your previous scans',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
          const Spacer(),
          BlocBuilder<HistoryBloc, HistoryState>(
            builder: (context, state) {
              if (state is! HistoryLoaded) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => _showClearDialog(context),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.textSecondary),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'All'),
      ('dangerous', 'Dangerous'),
      ('suspicious', 'Suspicious'),
      ('safe', 'Safe'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters
              .map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: f.$2,
                      isSelected: _filter == f.$1,
                      onTap: () => setState(() => _filter = f.$1),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (state is HistoryEmpty) {
          return _EmptyHistory();
        }
        if (state is HistoryLoaded) {
          var results = state.results.cast<ScanResult>();
          if (_filter != 'all') {
            results = results.where((r) => r.status == _filter).toList();
          }
          if (results.isEmpty) return _EmptyHistory(filtered: true);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: results.length,
            itemBuilder: (_, i) => ScanResultCard(result: results[i]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Clear History',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will delete all local scan records.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<HistoryBloc>().add(const ClearHistoryEvent());
              Navigator.pop(context);
            },
            child: const Text('Clear',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.primary : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.bgPrimary : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final bool filtered;
  const _EmptyHistory({this.filtered = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filtered ? Icons.filter_list_off_rounded : Icons.history_rounded,
            color: AppTheme.textSecondary,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            filtered ? 'No results for this filter' : 'No scan history yet',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (!filtered)
            const Text('Start scanning to see results here',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
