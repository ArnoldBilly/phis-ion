import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../../core/constants/app_constants.dart';

class ProcessedImageData {
  final Uint8List bytes;
  final int width;
  final int height;

  const ProcessedImageData({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

/// FR-04: Manual image pre-processing pipeline
/// FR-05: Heavy computation runs via compute() in a separate Isolate
class ImageProcessor {
  ImageProcessor._();
  static final ImageProcessor instance = ImageProcessor._();

  /// Main entry point — runs pre-processing in a background Isolate (FR-05)
  Future<ProcessedImageData> preprocess(CameraImage cameraImage) async {
    return compute(_preprocessIsolate, cameraImage);
  }

  /// Top-level function (required for compute/Isolate)
  static ProcessedImageData _preprocessIsolate(CameraImage cameraImage) {
    // Step 1: Convert YUV420 / BGRA8888 → img.Image (RGB)
    img.Image? rgbImage = _convertCameraImage(cameraImage);
    if (rgbImage == null) {
      throw Exception('Unsupported camera image format');
    }

    // Step 2: Convert to Grayscale (FR-04 — Grayscale conversion)
    img.Image gray = img.grayscale(rgbImage);

    // Step 3: Gaussian Blur — noise reduction for screen captures (FR-04)
    img.Image blurred = img.gaussianBlur(gray, radius: 2);

    // Step 4: Resize to INPUT_SIZE × INPUT_SIZE (FR-04 — Resizing)
    final targetSize = AppConstants.inputSize;
    img.Image resized = img.copyResize(
      blurred,
      width: targetSize,
      height: targetSize,
      interpolation: img.Interpolation.linear,
    );

    // Step 5: Normalize pixels to [0, 1] (FR-04 — Normalization)
    // We encode the normalized values as float32 bytes
    final normalized = _normalize(resized);

    return ProcessedImageData(
      bytes: normalized,
      width: targetSize,
      height: targetSize,
    );
  }

  /// Convert CameraImage (YUV420, NV21, or BGRA8888) to an img.Image
  static img.Image? _convertCameraImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _yuv420ToImage(image);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        return _nv21ToImage(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _bgra8888ToImage(image);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// NV21 → RGB conversion
  static img.Image _nv21ToImage(CameraImage image) {
    final bytes = image.planes[0].bytes;
    final int width = image.width;
    final int height = image.height;
    final result = img.Image(width: width, height: height);

    final int yLength = width * height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = yLength + (y ~/ 2) * width + (x ~/ 2) * 2;

        // In NV21, the chroma bytes are interleaved as V, U, V, U...
        final int yVal = bytes[yIndex];
        final int vVal = bytes[uvIndex] - 128;
        final int uVal = bytes[uvIndex + 1] - 128;

        final int r = (yVal + 1.402 * vVal).clamp(0, 255).toInt();
        final int g = (yVal - 0.344136 * uVal - 0.714136 * vVal)
            .clamp(0, 255)
            .toInt();
        final int b = (yVal + 1.772 * uVal).clamp(0, 255).toInt();

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  /// YUV420 → RGB conversion
  static img.Image _yuv420ToImage(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final int width = image.width;
    final int height = image.height;
    final result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yPlane.bytesPerRow + x;
        final int uvIndex =
            (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uPlane.bytesPerPixel!;

        final int yVal = yPlane.bytes[yIndex];
        final int uVal = uPlane.bytes[uvIndex] - 128;
        final int vVal = vPlane.bytes[uvIndex] - 128;

        final int r = (yVal + 1.402 * vVal).clamp(0, 255).toInt();
        final int g = (yVal - 0.344136 * uVal - 0.714136 * vVal)
            .clamp(0, 255)
            .toInt();
        final int b = (yVal + 1.772 * uVal).clamp(0, 255).toInt();

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  /// BGRA8888 → RGB conversion
  static img.Image _bgra8888ToImage(CameraImage image) {
    final bytes = image.planes[0].bytes;
    final int width = image.width;
    final int height = image.height;
    final result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int index = (y * width + x) * 4;
        final int b = bytes[index];
        final int g = bytes[index + 1];
        final int r = bytes[index + 2];
        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  /// Normalize pixel values to [0, 1] and encode as Float32List bytes
  static Uint8List _normalize(img.Image image) {
    final floatList = Float32List(image.width * image.height);
    int idx = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        // Grayscale — all channels are equal, use red
        floatList[idx++] = pixel.r / 255.0;
      }
    }
    return floatList.buffer.asUint8List();
  }

}
