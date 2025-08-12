import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:snapp_app/blocs/nlp_search/nlp_search_bloc.dart';
import 'package:snapp_app/blocs/nlp_search/nlp_search_event.dart';

class NlpPromptsWidget extends StatelessWidget {
  NlpPromptsWidget({super.key});

  final NeumorphicStyle style = NeumorphicStyle(
    color: Colors.white,
    depth: 5,
    intensity: 10,
    shape: NeumorphicShape.flat,
    lightSource: LightSource.topLeft,
    boxShape: NeumorphicBoxShape.roundRect(
      BorderRadius.circular(15.0),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          fillOverscroll: false,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _promptButton('Coffee moments', context),
              _promptButton('Cooking at home', context),
              _promptButton('Birthday Photos', context),
              _promptButton('Fantastic View', context),
              _promptButton('Adorable Pet', context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _promptButton(String prompt, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: NeumorphicButton(
            style: style,
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Text('"$prompt"', textAlign: TextAlign.center),
            ),
            onPressed: () =>
                context.read<NlpSearchBloc>().add(NlpSearch(query: prompt)),
          ),
        ),
      ],
    );
  }
}
