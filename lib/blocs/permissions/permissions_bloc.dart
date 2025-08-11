import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:snapp_app/blocs/permissions/permissions_event.dart';
import 'package:snapp_app/blocs/permissions/permissions_state.dart';
import 'package:snapp_app/services/image_service.dart';

class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  final ImageService _imageService;

  PermissionsBloc({required ImageService imageService})
      : _imageService = imageService,
        super(InitialPermissionsState()) {
    on<AcquirePermissions>(_onAcquirePermissions);
    on<CheckPermissions>(_onCheckPermissions);
  }

  void _onAcquirePermissions(
      AcquirePermissions event, Emitter<PermissionsState> emit) async {
    PermissionState permissionState = await _imageService.requestPermission();

    if (permissionState.isAuth || permissionState.hasAccess) {
      emit(PermissionsAcquired());
    } else {
      emit(PermissionsRequired());
    }
  }

  void _onCheckPermissions(
      CheckPermissions event, Emitter<PermissionsState> emit) async {
    PermissionState permissionState = await _imageService.getPermissionState();
    var granted = await Permission.contacts.request().isGranted;

    if (permissionState.isAuth || permissionState.hasAccess || granted) {
      emit(PermissionsAcquired());
    } else {
      emit(PermissionsRequired());
    }
  }
}
