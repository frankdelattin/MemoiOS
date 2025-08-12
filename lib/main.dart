import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapp_app/presentations/pages/splash_screen_page.dart';
import 'package:snapp_app/startup.dart';

Future main() async {
  await Startup.configure();
  runApp(const MyApp());
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snapp App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 3, 23, 241)),
        useMaterial3: true,
      ),
      home: const SplashScreenPage(),
    );
  }
}
