import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'onnx_method_channel.dart';

abstract class OnnxPlatform extends PlatformInterface {
  /// Constructs a OnnxPlatform.
  OnnxPlatform() : super(token: _token);

  static final Object _token = Object();

  static OnnxPlatform _instance = MethodChannelOnnx();

  /// The default instance of [OnnxPlatform] to use.
  ///
  /// Defaults to [MethodChannelOnnx].
  static OnnxPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OnnxPlatform] when
  /// they register themselves.
  static set instance(OnnxPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Float32List> encodeImage(String assetPath, Uint8List imageBytes);
  Future<Float32List> encodeText(
      String assetPath, String tokenizerAssetPath, String text);
}
