import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get_it/get_it.dart';
import 'package:snapp_app/background/background_service_initializer.dart';
import 'package:snapp_app/blocs/nlp_search/nlp_search_bloc.dart';
import 'package:snapp_app/blocs/nlp_sync/nlp_sync_bloc.dart';
import 'package:snapp_app/blocs/permissions/permissions_bloc.dart';
import 'package:snapp_app/blocs/permissions/permissions_event.dart';
import 'package:snapp_app/blocs/permissions/permissions_state.dart';
import 'package:snapp_app/presentations/constants/colors.dart';
import 'package:snapp_app/presentations/pages/nlp_search_page.dart';

class RequestPermissionsPage extends StatelessWidget {
  const RequestPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Text(
                  "To help you find all your photos with AI, we need access to your photos.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Don't worry it's just for you!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 20),
              NeumorphicIcon(
                Icons.shield,
                size: 100,
                style: NeumorphicStyle(
                    shape: NeumorphicShape.flat,
                    color: Colors.black,
                    depth: 3,
                    intensity: 10),
              ),
              SizedBox(height: 20),
              NeumorphicText(
                "We'll never use, see or share your photos. All photos are stored locally on your device.",
                style: NeumorphicStyle(
                  depth: 3,
                  color: Colors.black,
                ),
                textStyle: NeumorphicTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              NeumorphicText(
                'Tap "Allow" to start',
                style: NeumorphicStyle(
                  depth: 2,
                  color: Colors.black54,
                ),
                textStyle: NeumorphicTextStyle(
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              BlocListener<PermissionsBloc, PermissionsState>(
                child:NeumorphicButton(
                  onPressed: () {
                    context.read<PermissionsBloc>().add(AcquirePermissions());
                  },
                  style: NeumorphicStyle(
                    color: Colors.white,
                    depth: 5,
                    intensity: 10,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'Allow',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                listener: (context, state) {
                  if (state is PermissionsAcquired) {
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
