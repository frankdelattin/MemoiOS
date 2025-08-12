import 'package:device_calendar/device_calendar.dart';
import 'package:get_it/get_it.dart';
import 'package:onnx/onnx.dart';
import 'package:workmanager/workmanager.dart';

extension PluginExtension on GetIt {
  void registerPlugins() {
    _registerOnnx();
    _registerDeviceCalendar();
    _registerWorkManager();
  }

  void registerPluginsForBackground() {
    _registerOnnx();
  }

  void _registerOnnx() {
    registerSingletonAsync<Onnx>(() async => Onnx());
  }

  void _registerDeviceCalendar() {
    registerSingletonAsync<DeviceCalendarPlugin>(
      () async => DeviceCalendarPlugin(),
    );
  }

  void _registerWorkManager() {
    registerSingletonAsync<Workmanager>(() async => Workmanager());
  }
}
