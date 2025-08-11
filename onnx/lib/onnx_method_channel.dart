import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnx/preprocess.dart';
import 'package:path_provider/path_provider.dart';

import 'onnx_platform_interface.dart';

/// An implementation of [OnnxPlatform] that uses method channels.
class MethodChannelOnnx extends OnnxPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('onnx');

  @override
  Future<Float32List> encodeImage(
      String assetPath, Uint8List imageBytes) async {
    var modelPath = await getModelPath(assetPath);
    var preprocessedImage =
        await ImagePreprocess.preProcessImage(imageBytes, 224, 224);
    final Stopwatch stopwatch = Stopwatch()..start();
    final result = await run([modelPath, preprocessedImage]);
    stopwatch.stop();
    print(
        "Total elapsed for one ONNX encodeImage ${stopwatch.elapsedMilliseconds}ms");
    return result;
  }

  Future<Float32List> run(List<dynamic> vars) async {
    return await methodChannel.invokeMethod('encodeImage',
        <String, Object?>{"modelPath": vars[0], "bytes": vars[1]});
  }

  Future<String> getModelPath(String assetPath) async {
    if (assetPath.isEmpty) {
      throw Exception("Asset path is empty");
    }

    final directory = await getApplicationCacheDirectory();

    final file = File("${directory.path}/$assetPath");

    if (!file.existsSync()) {
      await copyModelToDirectory(assetPath, file);
    }

    if (file.existsSync()) {
      return file.path;
    }
    throw Exception("Model file not found");
  }

  Future<String> copyModelToDirectory(String assetPath, File file) async {
    final bytes = await rootBundle.load(assetPath);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file.path;
  }

  @override
  Future<Float32List> encodeText(
      String assetPath, String tokenizerAssetPath, String text) async {
    var modelPath = await getModelPath(assetPath);
    final result = await methodChannel.invokeMethod(
        'encodeText', <String, Object?>{
      "modelPath": modelPath,
      "tokenizerPath": tokenizerAssetPath,
      "text": text
    });
    return result;
  }
}
