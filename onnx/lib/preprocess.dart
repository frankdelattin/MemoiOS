import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImagePreprocess {
  static Future<Uint8List> preProcessImage(
      Uint8List imageBytes, int width, int height) async {
    var stopwatch = Stopwatch()..start();
    var totalStopWatch = Stopwatch()..start();
    // Dosyayı oku
    final image = img.decodeImage(imageBytes);
    stopwatch.stop();
    print("Image decoding elapsed ${stopwatch.elapsedMilliseconds}ms");
    stopwatch = Stopwatch()..start();

    if (image != null) {
      if (image.width == width && image.height == height) {
        return imageBytes;
      }
      var isWidthSmaller = image.width < image.height;

      // Resmi yeniden boyutlandır
      final resizedImage = img.copyResize(image,
          width: isWidthSmaller ? width : null,
          height: isWidthSmaller ? null : height,
          interpolation: img.Interpolation.cubic,
          maintainAspect: true);
      print(
          "Image resizing elapsed ${(stopwatch..stop()).elapsedMilliseconds}ms");
      stopwatch = Stopwatch()..start();
      //center crop
      final croppedImage = img.copyCrop(resizedImage,
          x: (resizedImage.width - width) ~/ 2,
          y: (resizedImage.height - height) ~/ 2,
          width: width,
          height: height);
      print(
          "Image cropping elapsed ${(stopwatch..stop()).elapsedMilliseconds}ms");
      stopwatch = Stopwatch()..start();
      var result = img.encodeJpg(croppedImage);
      print(
          "Image encoding elapsed ${(stopwatch..stop()).elapsedMilliseconds}ms");

      totalStopWatch.stop();
      print(
          "Total elapsed for preprocess ${totalStopWatch.elapsedMilliseconds}ms");
      return result;
    } else {
      throw Exception("Image decode failed.");
    }
  }
}
