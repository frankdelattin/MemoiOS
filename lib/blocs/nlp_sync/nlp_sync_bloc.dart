import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:snapp_app/background/work_manager_service.dart';
import 'package:snapp_app/blocs/nlp_sync/nlp_sync_event.dart';
import 'package:snapp_app/blocs/nlp_sync/nlp_sync_state.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:snapp_app/services/vector_service.dart';

class NlpSyncBloc extends Bloc<NlpSyncEvent, NlpSyncState> {
  final WorkManagerService _workManagerService;
  final VectorService _vectorService;
  final ImageService _imageService;

  NlpSyncBloc({
    required WorkManagerService workManagerService,
    required VectorService vectorService,
    required ImageService imageService,
  })  : _workManagerService = workManagerService,
        _vectorService = vectorService,
        _imageService = imageService,
        super(NlpSyncInitial()) {
    on<StartNlpSync>(_onStartNlpSync);
    on<ObserveNlpStatus>(_onObserveNlpStatus);
    on<NotifyNlpStatus>(_onNotifyNlpStatus);
    on<StopNlpSync>(_onStopNlpSync);
    on<ResumeNlpSync>(_onResumeNlpSync);
    this.add(ObserveNlpStatus());
  }

  void _onStartNlpSync(StartNlpSync event, Emitter<NlpSyncState> emit) async {
    PermissionState permissionState = await PhotoManager.getPermissionState(
      requestOption: PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.image,
          mediaLocation: false,
        ),
      ),
    );

    if (permissionState.isAuth || permissionState.hasAccess) {
      _workManagerService.initialize().then(
            (_) => this.add(ObserveNlpStatus()),
          );
    } else {
      emit(NlpSyncRequirePermission());
    }
  }

  void _onNotifyNlpStatus(
      NotifyNlpStatus event, Emitter<NlpSyncState> emit) async {
    if (event.status == "STOPPED") {
      emit(NlpSyncStopped());
    }
    if (["STARTED", "RUNNING", "CLEANED"].contains(event.status)) {
      int totalCount = await _imageService.getAllImagesCount();
      int syncedCount = await _vectorService.retrieveSyncedCount();
      int failedCount = _vectorService.retrieveFailedCount();
      print("failedCount: $failedCount");
      emit(NlpSyncWorking(
          total: totalCount, synced: syncedCount, failed: failedCount));
    }
  }

  void _onObserveNlpStatus(ObserveNlpStatus event, Emitter<NlpSyncState> emit) {
    this.add(NotifyNlpStatus(status: "STARTED"));

    _workManagerService.observeService((status) {
      this.add(NotifyNlpStatus(status: status));
    });
  }

  void _onStopNlpSync(StopNlpSync event, Emitter<NlpSyncState> emit) {
    this.add(NotifyNlpStatus(status: "STOPPED"));
  }

  void _onResumeNlpSync(ResumeNlpSync event, Emitter<NlpSyncState> emit) {
    this.add(NotifyNlpStatus(status: "STARTED"));
  }
}
