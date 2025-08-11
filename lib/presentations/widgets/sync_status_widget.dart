import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get_it/get_it.dart';
import 'package:snapp_app/blocs/nlp_sync/nlp_sync_bloc.dart';
import 'package:snapp_app/blocs/nlp_sync/nlp_sync_state.dart';
import 'package:snapp_app/presentations/constants/colors.dart';
import 'package:snapp_app/presentations/pages/request_permissions_page.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NlpSyncBloc, NlpSyncState>(
      buildWhen: (previous, current) => current is! NlpSyncRequirePermission,
      builder: (context, state) {
        if (state is NlpSyncWorking) {
          var visible = true;
          if (state.isCompleted) {
            //visible = false;
          }

          return Visibility(
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            visible: visible,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      onPressed: () => popupWindow(context),
                      icon: NeumorphicIcon(
                        Icons.info_outline,
                        style: NeumorphicStyle(
                          depth: 5,
                          color: Colors.lightGreen,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: state.syncRatio,
                        backgroundColor: Colors.grey,
                        color: Colors.lightGreen,
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
                if (state.failed > 0)
                  Text("Failed Images Count: ${state.failed}",
                      style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
      listener: (BuildContext context, NlpSyncState state) {
        if (state is NlpSyncRequirePermission) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RequestPermissionsPage()),
          );
        }
      },
    );
  }

  Future<dynamic> popupWindow(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        child: BlocProvider.value(
          value: GetIt.I.get<NlpSyncBloc>(),
          child:
              BlocBuilder<NlpSyncBloc, NlpSyncState>(builder: (context, state) {
            if (state is NlpSyncWorking) {
              return Container(
                decoration: BoxDecoration(
                  color: CustomColors.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NeumorphicIcon(Icons.sync,
                          size: 50,
                          style: NeumorphicStyle(
                            depth: 5,
                            color: Colors.lightGreen,
                          )),
                      Text(
                        "${state.synced} / ${state.total}",
                        style: TextStyle(
                          color: Colors.green,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              color: Colors.black,
                            ),
                            children: const <TextSpan>[
                              TextSpan(
                                text: 'We are currently syncing your photos.\n',
                              ),
                              TextSpan(text: 'This may take a while.'),
                              TextSpan(
                                text: '\n\nYou can close the app',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    ' since it will continue to sync in the background.',
                              ),
                              TextSpan(
                                text:
                                    '\n\nSync will continue when your phone is connected to a charger.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: NeumorphicButton(
                          style: NeumorphicStyle(
                            shape: NeumorphicShape.convex,
                            depth: 2,
                            intensity: 10,
                            color: Colors.grey[200],
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("Okay"),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }
            Navigator.of(context).pop();
            return const SizedBox.shrink();
          }),
        ),
      ),
    );
  }
}
