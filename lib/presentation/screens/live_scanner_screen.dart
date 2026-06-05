import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/ocr_service.dart';
import '../blocs/detection/detection_bloc.dart';
import '../blocs/detection/detection_event_state.dart';
import '../widgets/camera_overlay_painter.dart';
import 'detection_result_screen.dart';
import '../../domain/entities/scan_result.dart';

class LiveScannerScreen extends StatefulWidget {
  const LiveScannerScreen({super.key});

  @override
  State<LiveScannerScreen> createState() => _LiveScannerScreenState();
}

class _LiveScannerScreenState extends State<LiveScannerScreen>
    with SingleTickerProviderStateMixin {
  // ── Camera ──────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _isProcessing = false;
  DateTime _lastProcessed = DateTime(2000);

  // ── OCR ─────────────────────────────────────────────────────────────────
  List<Rect> _boundingBoxes = [];
  Size _imageSize = Size.zero;
  String _detectedUrl = '';
  String _scanMode = AppConstants.modeQr;

  // ── Scan animation ───────────────────────────────────────────────────────
  late AnimationController _scanAnimController;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_scanAnimController);
    _initCamera();
  }

  // ── FR-01: Camera lifecycle with proper dispose ──────────────────────────
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      // FR-01: Start camera image stream
      await _cameraController!.startImageStream(_onCameraFrame);
      setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  // ── FR-05: Throttled frame processing to maintain 60 FPS ────────────────
  void _onCameraFrame(CameraImage image) {
    final now = DateTime.now();
    final elapsed = now.difference(_lastProcessed).inMilliseconds;
    if (_isProcessing || elapsed < AppConstants.processingThrottleMs) return;

    _isProcessing = true;
    _lastProcessed = now;
    _processFrame(image);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (!mounted) {
      _isProcessing = false;
      return;
    }

    try {
      final rotation = _getRotation(_cameras.first.sensorOrientation);
      final previewSize = Size(
        _cameraController!.value.previewSize!.height,
        _cameraController!.value.previewSize!.width,
      );

      OcrScanResult result;
      if (_scanMode == AppConstants.modeQr) {
        // FR-02: QR Code scanning
        result = await OcrService.instance.scanQrCode(image, rotation, previewSize);
      } else {
        // FR-02: Text OCR scanning
        result = await OcrService.instance.recognizeText(image, rotation, previewSize);
      }

      if (!mounted) {
        _isProcessing = false;
        return;
      }

      setState(() {
        _boundingBoxes = result.boundingBoxes;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _detectedUrl = result.detectedUrls.isNotEmpty
            ? result.detectedUrls.first
            : '';
      });

      // Auto-trigger analysis when URL detected
      if (result.hasUrls && mounted) {
        final url = result.detectedUrls.first;
        // ignore: use_build_context_synchronously
        context.read<DetectionBloc>().add(AnalyzeUrlEvent(url));
      }
    } catch (_) {
    } finally {
      _isProcessing = false;
    }
  }

  InputImageRotation _getRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  // ── FR-01: Proper dispose to prevent memory leak ─────────────────────────
  @override
  void dispose() {
    _scanAnimController.dispose();
    OcrService.instance.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocListener<DetectionBloc, DetectionState>(
        listener: (context, state) {
          if (state is DetectionSuccess) {
            _navigateToResult(state.result as ScanResult);
          } else if (state is DetectionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.danger,
              ),
            );
          }
        },
        child: Stack(
          children: [
            // Camera preview
            if (_cameraReady && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text('Initializing camera...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),

            // FR-03: Bounding box overlay
            if (_cameraReady)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _scanAnim,
                  builder: (_, __) => CustomPaint(
                    painter: _boundingBoxes.isNotEmpty
                        ? CameraOverlayPainter(
                            boundingBoxes: _boundingBoxes,
                            imageSize: _imageSize,
                          )
                        : ScannerFramePainter(
                            isScanning: true,
                            animValue: _scanAnim.value,
                          ),
                  ),
                ),
              ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'PhisIon Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _ModeToggle(
                        currentMode: _scanMode,
                        onChanged: (mode) =>
                            setState(() => _scanMode = mode),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom URL indicator
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomIndicator(
                detectedUrl: _detectedUrl,
                scanMode: _scanMode,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToResult(ScanResult result) async {
    // Pause processing while viewing result
    _isProcessing = true;
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DetectionResultScreen(result: result)),
    );
    // Reset and resume
    context.read<DetectionBloc>().add(const ResetDetectionEvent());
    setState(() {
      _boundingBoxes = [];
      _detectedUrl = '';
    });
    _isProcessing = false;
  }
}

class _ModeToggle extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onChanged;

  const _ModeToggle(
      {required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
              label: 'QR',
              icon: Icons.qr_code_rounded,
              isActive: currentMode == AppConstants.modeQr,
              onTap: () => onChanged(AppConstants.modeQr)),
          _ToggleBtn(
              label: 'OCR',
              icon: Icons.text_fields_rounded,
              isActive: currentMode == AppConstants.modeText,
              onTap: () => onChanged(AppConstants.modeText)),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleBtn(
      {required this.label,
      required this.icon,
      required this.isActive,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: isActive ? AppTheme.bgPrimary : Colors.white70),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  color: isActive ? AppTheme.bgPrimary : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

class _BottomIndicator extends StatelessWidget {
  final String detectedUrl;
  final String scanMode;

  const _BottomIndicator(
      {required this.detectedUrl, required this.scanMode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DetectionBloc, DetectionState>(
      builder: (context, state) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: detectedUrl.isNotEmpty
                    ? AppTheme.primary.withOpacity(0.6)
                    : Colors.white12,
              ),
            ),
            child: state is DetectionLoading
                ? Row(
                    children: [
                      const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AppTheme.primary, strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Analyzing: ${state.url}',
                          style: const TextStyle(
                              color: AppTheme.primary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        detectedUrl.isNotEmpty
                            ? Icons.link_rounded
                            : Icons.search_rounded,
                        color: detectedUrl.isNotEmpty
                            ? AppTheme.primary
                            : Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          detectedUrl.isNotEmpty
                              ? detectedUrl
                              : 'Point at a $scanMode to detect phishing',
                          style: TextStyle(
                            color: detectedUrl.isNotEmpty
                                ? Colors.white
                                : Colors.white38,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
