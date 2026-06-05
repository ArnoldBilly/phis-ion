import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class OcrScanResult {
  final List<String> detectedUrls;
  final List<Rect> boundingBoxes;
  final String rawText;

  const OcrScanResult({
    required this.detectedUrls,
    required this.boundingBoxes,
    required this.rawText,
  });

  bool get hasUrls => detectedUrls.isNotEmpty;
}

class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  final BarcodeScanner _barcodeScanner = BarcodeScanner(formats: [
    BarcodeFormat.qrCode,
    BarcodeFormat.dataMatrix,
  ]);

  static final RegExp _urlPattern = RegExp(
    r'(https?://[^\s]+|www\.[^\s]+\.[a-z]{2,})',
    caseSensitive: false,
  );

  bool _isDisposed = false;

  Future<OcrScanResult> recognizeText(CameraImage cameraImage,
      InputImageRotation rotation, Size previewSize) async {
    if (_isDisposed) return const OcrScanResult(
        detectedUrls: [], boundingBoxes: [], rawText: '');

    final inputImage = _buildInputImage(cameraImage, rotation);
    if (inputImage == null) {
      return const OcrScanResult(
          detectedUrls: [], boundingBoxes: [], rawText: '');
    }

    try {
      final recognized = await _textRecognizer.processImage(inputImage);
      final urls = <String>[];
      final boxes = <Rect>[];

      for (final block in recognized.blocks) {
        final matches = _urlPattern.allMatches(block.text);
        if (matches.isNotEmpty) {
          for (final m in matches) {
            urls.add(m.group(0)!);
          }
          boxes.add(block.boundingBox);
        }
      }

      return OcrScanResult(
        detectedUrls: urls,
        boundingBoxes: boxes,
        rawText: recognized.text,
      );
    } catch (_) {
      return const OcrScanResult(
          detectedUrls: [], boundingBoxes: [], rawText: '');
    }
  }

  Future<OcrScanResult> scanQrCode(CameraImage cameraImage,
      InputImageRotation rotation, Size previewSize) async {
    if (_isDisposed) return const OcrScanResult(
        detectedUrls: [], boundingBoxes: [], rawText: '');

    final inputImage = _buildInputImage(cameraImage, rotation);
    if (inputImage == null) {
      return const OcrScanResult(
          detectedUrls: [], boundingBoxes: [], rawText: '');
    }

    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);
      final urls = <String>[];
      final boxes = <Rect>[];

      for (final barcode in barcodes) {
        final raw = barcode.rawValue ?? '';
        if (raw.isNotEmpty) {
          urls.add(raw);
        }
        boxes.add(barcode.boundingBox);
      }

      return OcrScanResult(
        detectedUrls: urls,
        boundingBoxes: boxes,
        rawText: urls.join('\n'),
      );
    } catch (_) {
      return const OcrScanResult(
          detectedUrls: [], boundingBoxes: [], rawText: '');
    }
  }

  InputImage? _buildInputImage(
      CameraImage image, InputImageRotation rotation) {
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    if (!_isDisposed) {
      _textRecognizer.close();
      _barcodeScanner.close();
      _isDisposed = true;
    }
  }
}
