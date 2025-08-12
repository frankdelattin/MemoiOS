import 'dart:typed_data';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:snapp_app/blocs/nlp_search/nlp_search_bloc.dart';
import 'package:snapp_app/blocs/nlp_search/nlp_search_event.dart';
import 'package:snapp_app/blocs/nlp_search/nlp_search_state.dart';
import 'package:snapp_app/presentations/constants/colors.dart';
import 'package:snapp_app/presentations/pages/image_page.dart';
import 'package:snapp_app/presentations/widgets/nlp_prompts_widget.dart';
import 'package:snapp_app/presentations/widgets/sync_status_widget.dart';
import 'package:snapp_app/services/debug_service.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:transparent_image/transparent_image.dart';

class NlpSearchPage extends StatelessWidget {
  static const imageWidth = 138.0;
  static const imageHeight = 200.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: CustomColors.backgroundColor,
      appBar: AppBar(
        title: Text('NLP Search'),
        centerTitle: true,
        backgroundColor: CustomColors.backgroundColor,
        actions: [
          IconButton(
            onPressed: runFlutterOnnx,
            icon: Icon(Icons.flutter_dash),
          ),
          IconButton(
            onPressed: runNativeOnnx,
            icon: Icon(Icons.cleaning_services),
          ),
          IconButton(
            onPressed: debug,
            icon: Icon(Icons.bug_report),
          ),
          IconButton(
            onPressed: periodicBackground,
            icon: Icon(Icons.timer),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 30.0,
            right: 30.0,
            top: 15,
            bottom: 100,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 0.0),
                child: SearchBar(),
              ),
              SyncStatusWidget(),
              Expanded(
                child: BlocBuilder<NlpSearchBloc, NlpSearchState>(
                  builder: (context, state) {
                    if (state is NlpSearchLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Colors.grey,
                          backgroundColor: CustomColors.backgroundColor,
                        ),
                      );
                    }
                    if (state is NlpSearchLoaded) {
                      return ImageGridView(
                          imageWidth: imageWidth, imageHeight: imageHeight);
                    }
                    return NlpPromptsWidget();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  const SearchBar({
    super.key,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  var _clearButtonVisible = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_clearButtonVisible,
      onPopInvokedWithResult: (didPop, result) {
        if (_clearButtonVisible) {
          _searchController.clear();
          setState(() {
            _clearButtonVisible = false;
          });
          _focusNode.requestFocus();
          context.read<NlpSearchBloc>().add(NlpSearch(query: ''));
        }
      },
      child: Neumorphic(
        style: NeumorphicStyle(
          color: CustomColors.backgroundColor,
          depth: -7,
          intensity: 40,
          boxShape: NeumorphicBoxShape.roundRect(
            BorderRadius.circular(15.0),
          ),
        ),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 30.0, right: 10, top: 5, bottom: 5),
          child: BlocConsumer<NlpSearchBloc, NlpSearchState>(
            listener: (context, state) {
              if (state is NlpSearchLoading) {
                _searchController.value = TextEditingValue(
                    text: state.query,
                    selection: TextSelection.fromPosition(
                      TextPosition(offset: state.query.length),
                    ));
                setState(() {
                  _clearButtonVisible = true;
                });
                _focusNode.unfocus();
              }
            },
            builder: (context, state) {
              return TextField(
                focusNode: _focusNode,
                cursorColor: Colors.grey,
                textAlignVertical: TextAlignVertical.center,
                controller: _searchController,
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  hintText: 'Search Anything...',
                  suffixIcon: _clearButtonVisible
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _clearButtonVisible = false;
                            });
                            _focusNode.requestFocus();
                            context
                                .read<NlpSearchBloc>()
                                .add(NlpSearch(query: ''));
                          },
                          constraints: BoxConstraints(
                            maxWidth: 10,
                            maxHeight: 10,
                          ),
                          icon: Icon(Icons.highlight_remove_outlined,
                              color: Colors.grey[500]))
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                  ),
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                onSubmitted: (value) =>
                    context.read<NlpSearchBloc>().add(NlpSearch(query: value)),
                onChanged: (value) {
                  if (value.isEmpty && _clearButtonVisible) {
                    setState(() {
                      _clearButtonVisible = false;
                    });
                  } else if (value.isNotEmpty && !_clearButtonVisible) {
                    setState(() {
                      _clearButtonVisible = true;
                    });
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class ImageGridView extends StatefulWidget {
  const ImageGridView({
    super.key,
    required this.imageWidth,
    required this.imageHeight,
  });

  final double imageWidth;
  final double imageHeight;

  @override
  State<ImageGridView> createState() => _ImageGridViewState();
}

class _ImageGridViewState extends State<ImageGridView> {
  var _columnCount = 4;
  final transparentImage = MemoryImage(kTransparentImage);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NlpSearchBloc, NlpSearchState>(
        builder: (context, state) {
      if (state is NlpSearchLoaded) {
        return Neumorphic(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          style: NeumorphicStyle(
            color: Colors.white,
            depth: 15,
            intensity: 60,
            boxShape: NeumorphicBoxShape.roundRect(
              BorderRadius.circular(30.0),
            ),
          ),
          child: GridView.builder(
            cacheExtent: 3000,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              childAspectRatio: widget.imageWidth / widget.imageHeight,
              crossAxisCount: _columnCount,
              crossAxisSpacing: 3.0,
              mainAxisSpacing: 3.0,
            ),
            itemCount: state.results.length,
            itemBuilder: (context, index) {
              final prediction = state.results[index];
              final assetEntity =
                  GetIt.I<ImageService>().getAssetEntity(prediction.imageId);
              return FutureBuilder<AssetEntity?>(
                  future: assetEntity,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var bytes = snapshot.data!.thumbnailDataWithOption(
                        ThumbnailOption(
                            size: ThumbnailSize(224, 224), quality: 80),
                      );
                      return FutureBuilder<Uint8List?>(
                          future: bytes,
                          builder: (context, bytesSnapshot) {
                            if (bytesSnapshot.hasData) {
                              return Hero(
                                tag: snapshot.data!.id,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      context.pushTransparentRoute(ImagePage(
                                          allImages: state.results,
                                          thumbnailBytes: bytesSnapshot.data!,
                                          index: index));
                                    },
                                    child: FadeInImage(
                                      key: Key(snapshot.data!.id),
                                      image: MemoryImage(bytesSnapshot.data!),
                                      placeholder: transparentImage,
                                      fit: BoxFit.cover,
                                      placeholderFilterQuality:
                                          FilterQuality.low,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          });
                    }
                    return const SizedBox.shrink();
                  });
            },
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}
