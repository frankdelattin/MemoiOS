import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:snapp_app/background/background_service_initializer.dart';
import 'package:snapp_app/blocs/nlp_search/nlp_search_bloc.dart';
import 'package:snapp_app/blocs/nlp_sync/nlp_sync_bloc.dart';
import 'package:snapp_app/blocs/permissions/permissions_bloc.dart';
import 'package:snapp_app/blocs/permissions/permissions_event.dart';
import 'package:snapp_app/blocs/permissions/permissions_state.dart';
import 'package:snapp_app/presentations/pages/nlp_search_page.dart';
import 'package:snapp_app/presentations/pages/request_permissions_page.dart';

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
        value: GetIt.I<PermissionsBloc>()..add(CheckPermissions()),
        child: Builder(builder: (context) {
          return SplashListenerWidget();
        }));
  }
}

class SplashListenerWidget extends StatelessWidget {
  const SplashListenerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PermissionsBloc, PermissionsState>(
      listener: (context, state) {
        if (state is PermissionsRequired) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: GetIt.I<PermissionsBloc>(),
                child: RequestPermissionsPage(),
              ),
            ),
          );
        } else if (state is PermissionsAcquired) {
          BackgroundServiceInitializer.initializeAll();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (context) => GetIt.I<NlpSearchBloc>(),
                  ),
                  BlocProvider.value(
                    value: GetIt.I<NlpSyncBloc>(),
                  ),
                ],
                child: NlpSearchPage(),
              ),
            ),
          );
        }
      },
      listenWhen: (_, current) => context is! InitialPermissionsState,
      child: Scaffold(),
    );
  }
}
