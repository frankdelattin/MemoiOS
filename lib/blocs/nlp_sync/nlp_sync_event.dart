import 'package:equatable/equatable.dart';

abstract class NlpSyncEvent extends Equatable {}

class StopNlpSync extends NlpSyncEvent {
  List<Object?> get props => [];
}

class ResumeNlpSync extends NlpSyncEvent {
  List<Object?> get props => [];
}

class ObserveNlpStatus extends NlpSyncEvent {
  List<Object?> get props => [];
}

class NotifyNlpStatus extends NlpSyncEvent {
  final String status;

  NotifyNlpStatus({required this.status});

  List<Object?> get props => [status];
}

class StartNlpSync extends NlpSyncEvent {
  List<Object?> get props => [];
}