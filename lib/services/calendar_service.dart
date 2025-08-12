import 'package:device_calendar/device_calendar.dart';

class CalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin;

  CalendarService({required DeviceCalendarPlugin deviceCalendarPlugin})
      : _deviceCalendarPlugin = deviceCalendarPlugin;

  Future<List<Event>> getCalendarEventsInRange(DateTime start, DateTime end) async {
    var hasPermissions = await _deviceCalendarPlugin.hasPermissions();
    if (hasPermissions.data != true) {
      await _deviceCalendarPlugin.requestPermissions();
    }

    var calendars = await _deviceCalendarPlugin.retrieveCalendars();

    var allEvents = <Event>[];

    for (var calendar in calendars.data ?? <Calendar>[]) {
      if (calendar.id == null) continue;

      var events = await _deviceCalendarPlugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(
          startDate: start,
          endDate: end,
        ),
      );

      if (events.hasErrors || events.data == null) continue;
      allEvents.addAll(events.data!);
    }

    return allEvents;
  }
}
