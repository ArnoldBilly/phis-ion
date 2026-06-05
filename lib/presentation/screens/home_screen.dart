import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/history/history_bloc.dart';
import '../blocs/history/history_event_state.dart';
import '../widgets/scan_result_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../domain/entities/scan_result.dart';
import 'live_scanner_screen.dart';
import 'scan_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
    context.read<HistoryBloc>().add(const LoadHistoryEvent());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeContent(pulseAnim: _pulseAnim, onScanTap: () {
            setState(() => _currentIndex = 1);
          }),
          const LiveScannerScreen(),
          const ScanHistoryScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Animation<double> pulseAnim;
  final VoidCallback onScanTap;

  const _HomeContent({required this.pulseAnim, required this.onScanTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(child: _ScanButton(pulseAnim: pulseAnim, onTap: onScanTap)),
          SliverToBoxAdapter(child: _StatsRow()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text('Recent Scans',
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
          SliverToBoxAdapter(child: _RecentScans()),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PhisIon',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      )),
              const Text('Phishing Detector',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.shield_outlined,
                color: AppTheme.primary, size: 22),
          ),
        ],
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _ScanButton({required this.pulseAnim, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: pulseAnim.value,
            child: child,
          ),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withOpacity(0.15),
                  AppTheme.primaryDark.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppTheme.primary.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded,
                      color: AppTheme.bgPrimary, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Tap to Scan',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Point camera at URL or QR Code',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        int total = 0, dangerous = 0, safe = 0;
        if (state is HistoryLoaded) {
          final results = state.results.cast<ScanResult>();
          total = results.length;
          dangerous = results.where((r) => r.isDangerous).length;
          safe = results.where((r) => r.isSafe).length;
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Row(
            children: [
              Expanded(
                  child: _StatCard(
                      value: total.toString(),
                      label: 'Total Scans',
                      color: AppTheme.primary,
                      icon: Icons.search_rounded)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      value: dangerous.toString(),
                      label: 'Threats',
                      color: AppTheme.danger,
                      icon: Icons.dangerous_rounded)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      value: safe.toString(),
                      label: 'Safe',
                      color: AppTheme.safe,
                      icon: Icons.verified_rounded)),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _RecentScans extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoaded) {
          final recent = state.results.cast<ScanResult>().take(3).toList();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: recent
                  .map((r) => ScanResultCard(result: r))
                  .toList(),
            ),
          );
        }
        if (state is HistoryEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.radar_rounded,
                      color: AppTheme.textSecondary, size: 48),
                  SizedBox(height: 12),
                  Text('No scans yet',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
