import 'package:flutter/material.dart';

class TempPage extends StatelessWidget {
  const TempPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemCount: 5000,
        itemBuilder: (_, index) {
          return ListTile(
            title: Text(index.toString()),
          );
        },
      ),
    );
  }
}
