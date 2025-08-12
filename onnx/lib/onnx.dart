import 'dart:typed_data';

import 'onnx_platform_interface.dart';

class Onnx {
  Future<Float32List> encodeImage(String assetPath, Uint8List imageBytes) {
    return OnnxPlatform.instance.encodeImage(assetPath, imageBytes);
  }

  Future<Float32List> encodeText(
      String assetPath, String tokenizerAssetPath, String text) {
    return OnnxPlatform.instance
        .encodeText(assetPath, tokenizerAssetPath, text);
  }
}
