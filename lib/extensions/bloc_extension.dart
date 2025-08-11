import 'package:get_it/get_it.dart';
import 'package:snapp_app/background/work_manager_service.dart';
import 'package:snapp_app/blocs/nlp_search/nlp_search_bloc.dart';
import 'package:snapp_app/blocs/nlp_sync/nlp_sync_bloc.dart';
import 'package:snapp_app/blocs/permissions/permissions_bloc.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:snapp_app/services/vector_service.dart';

extension BlocExtension on GetIt {
  void registerBlocs() {
    _registerNlpSearchBloc();
    _registerNlpSyncBloc();
    _registerPermissionsBloc();
  }

  void _registerNlpSearchBloc() {
    registerFactory<NlpSearchBloc>(
      () => NlpSearchBloc(
        vectorService: this(),
      ),
    );
  }

  void _registerNlpSyncBloc() {
    registerSingletonAsync<NlpSyncBloc>(
      () async => NlpSyncBloc(
        workManagerService: this(),
        vectorService: this(),
        imageService: this(),
      ),
      dependsOn: [
        WorkManagerService,
        VectorService,
        ImageService,
      ],
    );
  }

  void _registerPermissionsBloc() {
    registerSingletonAsync<PermissionsBloc>(
      () async => PermissionsBloc(
        imageService: this(),
      ),
      dependsOn: [
        ImageService,
      ],
    );
  }
}
