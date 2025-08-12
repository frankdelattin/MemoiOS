import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import 'package:snapp_app/services/nlp_tokenizer.dart';
import 'package:sp_ai_simple_bpe_tokenizer/utilities/sp_ai_simple_bpe_tokenizer.dart';

class OnnxRuntimeService {
  final _visualizeModelPath = 'assets/models/nlp_visualize_opset3.onnx';
  final _textualModelPath = 'assets/models/nlp_textual_opset3.onnx';
  final _textualTokenizerPath =
      'assets/models/tokenizers/nlp_textual_tokenizer.txt.gz';
  OrtSession? _visualizeSession;
  OrtSession? _textualSession;
  OrtSessionOptions? _sessionOptions;
  SimpleTokenizer? _textualTokenizer;
  // Modeli yükle
  Future<OrtSession> _loadModel(String modelPath) async {
    if (_sessionOptions == null) {
      _sessionOptions = OrtSessionOptions();
    }
    final rawModel = await rootBundle.load(modelPath);
    final bytes = rawModel.buffer.asUint8List();
    return OrtSession.fromBuffer(bytes, _sessionOptions!);
  }

  Future<void> loadVisualizeModel() async {
    _visualizeSession ??= await _loadModel(_visualizeModelPath);
  }

  Future<void> loadTextualModel() async {
    _textualSession ??= await _loadModel(_textualModelPath);
    var bpeBytes = await rootBundle.load(_textualTokenizerPath);
    _textualTokenizer ??= SimpleTokenizer(
      bpeBytes.buffer.asUint8List(),
    );
  }

  List<dynamic> prepareImage(ByteData imageByteData) {
    final inputImage = img.decodeImage(imageByteData.buffer.asUint8List())!;

    // Resize the image to 224x224
    final resizedImage = img.copyResize(inputImage,
        width: 224, height: 224, interpolation: img.Interpolation.linear);

    const batchSize = 1;
    const height = 224;
    const width = 224;
    const channels = 3;

    List<List<List<Float32List>>> output = List.generate(
      batchSize,
      (_) => List.generate(
        channels,
        (_) => List.generate(
          height,
          (_) => Float32List(width),
        ),
      ),
    );
    // Eksenleri yeniden düzenle
    for (int b = 0; b < batchSize; b++) {
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          final pixel = resizedImage.getPixel(w, h);
          output[b][0][h][w] = pixel.r / 255;
          output[b][1][h][w] = pixel.g / 255;
          output[b][2][h][w] = pixel.b / 255;
        }
      }
    }
    return output;
  }

  Future<List<double>> encodeImage(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes)!;

    // Resize ve normalizasyon
    var isWidthSmaller = image.width < image.height;

    // Resmi yeniden boyutlandır
    final resizedImage = img.copyResize(image,
        width: isWidthSmaller ? 224 : null,
        height: isWidthSmaller ? null : 224,
        interpolation: img.Interpolation.cubic,
        maintainAspect: true);

    //center crop
    final croppedImage = img.copyCrop(resizedImage,
        x: (resizedImage.width - 224) ~/ 2,
        y: (resizedImage.height - 224) ~/ 2,
        width: 224,
        height: 224);

    var pixels = croppedImage.getBytes();

    // Normalizasyon parametreleri
    const normMeanRGB = [0.48145466, 0.4578275, 0.40821073];
    const normStdRGB = [0.26862954, 0.26130258, 0.27577711];

    // Girdi tensörünü hazırlama
    final int pixelsCount = 224 * 224;
    final int offsetG = pixelsCount;
    final int offsetB = 2 * pixelsCount;
    final inputData = Float32List(3 * 224 * 224);
    for (int i = 0; i < pixelsCount; i++) {
      double r = (pixels[i * 3]) / 255.0;
      double g = (pixels[i * 3 + 1]) / 255.0;
      double b = (pixels[i * 3 + 2]) / 255.0;
      inputData[i] = (r - normMeanRGB[0]) / normStdRGB[0];
      inputData[offsetG + i] = (g - normMeanRGB[1]) / normStdRGB[1];
      inputData[offsetB + i] = (b - normMeanRGB[2]) / normStdRGB[2];
    }

    // ONNX Runtime session oluştur
    await loadVisualizeModel();

    try {
      // Girdiyi hazırla
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        inputData,
        [1, 3, 224, 224],
      );

      // Çıktıyı al
      var stopwatch = Stopwatch()..start();
      final outputs = _visualizeSession!.run(
        OrtRunOptions(),
        {_visualizeSession!.inputNames[0]: inputTensor},
      );
      stopwatch.stop();
      print("Visualize Model Time: ${stopwatch.elapsed}");

      // Sonuçları dönüştür
      final outputTensor = outputs[0] as OrtValueTensor;
      return outputTensor.value[0].cast<double>();
    } finally {
      // Release resources
    }
  }

  Future<List<double>> encodeText(String text) async {
    await loadTextualModel();

    // Token'ları hazırla
    final tokens = _textualTokenizer!.encode(text);
    final libraryTokens =
        await SPAiSimpleBpeTokenizer().encodeString("hello world");
    const maxLength = 77;
    final inputData = Int32List(maxLength);

    // Start ve end token'larını ekle
    inputData[0] = 49406;
    for (var i = 0; i < tokens.length && i < maxLength - 2; i++) {
      inputData[i + 1] = tokens[i];
    }
    inputData[tokens.length + 1] = 49407;

    try {
      // Girdi tensörünü oluştur
      final inputTensor = OrtValueTensor.createTensorWithDataList(
        inputData,
        [1, maxLength],
      );

      // Modeli çalıştır
      final stopwatch = Stopwatch()..start();
      final outputs = _textualSession!.run(
        OrtRunOptions(),
        {_textualSession!.inputNames[0]: inputTensor},
      );
      stopwatch.stop();
      print("Textual Model Time: ${stopwatch.elapsed}");

      // Çıktıyı işle
      final outputTensor = outputs[0] as OrtValueTensor;
      return outputTensor.value[0].cast<double>();
    } finally {
      // Kaynakları serbest bırak
    }
  }
}
