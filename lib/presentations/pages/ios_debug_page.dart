import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:snapp_app/services/onnx_runtime_service.dart';
import 'package:snapp_app/services/vector_service.dart';

class IOSDebugPage extends StatelessWidget {
  const IOSDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IOS Debug'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              var onnxService = OnnxRuntimeService();

              var textualResult = await onnxService.encodeText("hello world");
              print("Textual Result: $textualResult");
              print("done");
            },
            child: const Text('Run Onnx Visual Model Once'),
          ),
          ElevatedButton(
            onPressed: () async {
              var vectorService = GetIt.I<VectorService>();
              vectorService.getSimilarPhotos("hello world");
              print("done");
            },
            child: const Text('Run Native Once'),
          )
        ],
      ),
    );
  }
}
