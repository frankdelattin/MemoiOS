import 'package:equatable/equatable.dart';

abstract class PermissionsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitialPermissionsState extends PermissionsState {}

class PermissionsRequired extends PermissionsState {}

class PermissionsAcquired extends PermissionsState {}