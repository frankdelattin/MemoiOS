import 'package:equatable/equatable.dart';

abstract class NlpSyncState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NlpSyncInitial extends NlpSyncState {}

class NlpSyncWorking extends NlpSyncState {
  final int total;
  final int synced;
  final int failed;

  bool get isCompleted => synced >= total;

  double get syncRatio => total > 0 ? synced / total : 0;

  NlpSyncWorking(
      {required this.total, required this.synced, required this.failed});

  @override
  List<Object?> get props => [total, synced, failed];
}

class NlpSyncStopped extends NlpSyncState {}

class NlpSyncRequirePermission extends NlpSyncState {}