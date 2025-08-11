import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get_it/get_it.dart';
import 'package:snapp_app/background_startup.dart';
import 'package:snapp_app/services/vector_service.dart';

class OnChargeBackgroundService {
  final service = FlutterBackgroundService();

  void initializeService() async {
    if (!Platform.isAndroid) {
      return;
    }

    print("initialized background service");

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        autoStartOnBoot: true,
        initialNotificationTitle: "Memojo",
        initialNotificationContent: "AI is analysing your photos",
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
    service.invoke("start");
  }

  void startService() {
    service.startService();
  }

  void stopService() {
    service.invoke("stop");
  }

  void observeService(void Function(dynamic status) fn) {
    service.on("stopped").listen((_) => fn("stopped"));
    service.on("started").listen((_) => fn("started"));
    service.on("running").listen((_) async {
      if (await service.isRunning()) {
        fn("running");
      } else {
        fn("stopped");
      }
    });
  }

  static bool onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static Future onStart(ServiceInstance service) async {
    await BackgroundStartup.configure();

    service.on("stop").listen((event) {
      service.stopSelf();
      print("background process is now stopped");
    });

    print("Started");
    aiProcess(shortDuration, service);
  }

  static const Duration shortDuration = Duration(milliseconds: 100);
  static const Duration longDuration = Duration(seconds: 30);

  static void aiProcess(Duration nextProcessAfter, ServiceInstance service) {
    var battery = Battery();

    Timer.periodic(nextProcessAfter, (timer) async {
      var batterState = await battery.batteryState;
      var isInBatterySaveMode = await battery.isInBatterySaveMode;
      timer.cancel();

      if (!isProcessable(batterState, isInBatterySaveMode)) {
        aiProcess(longDuration, service);
        return;
      }

      GetIt.I<VectorService>().procesNextImages().then((value) {
        print("ai process completed");
        service.invoke("running");
        aiProcess(value ? shortDuration : longDuration, service);
      }, onError: (error) {
        print("ai process error: $error");
        aiProcess(shortDuration, service);
      });
    });
  }

  static bool isProcessable(
      BatteryState batterState, bool isInBatterySaveMode) {
    return (batterState != BatteryState.discharging &&
            batterState != BatteryState.unknown) &&
        !isInBatterySaveMode;
  }
}
