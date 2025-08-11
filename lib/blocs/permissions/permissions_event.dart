import 'package:equatable/equatable.dart';

abstract class PermissionsEvent extends Equatable {}

class AcquirePermissions extends PermissionsEvent {
  List<Object?> get props => [];
}

class CheckPermissions extends PermissionsEvent {
  List<Object?> get props => [];
}
