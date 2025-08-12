import 'dart:typed_data';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:snapp_app/data/nlp_image.dart';
import 'package:snapp_app/services/image_service.dart';
import 'package:transparent_image/transparent_image.dart';

class ImagePage extends StatefulWidget {
  final List<ImagePrediction> allImages;
  int index;
  final PreloadPageController controller;
  final Uint8List thumbnailBytes;
  ImagePage(
      {super.key,
      required this.allImages,
      required this.index,
      required this.thumbnailBytes})
      : controller = PreloadPageController(initialPage: index, keepPage: true);

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DismissiblePage(
      isFullScreen: true,
      onDismissed: () => Navigator.of(context).pop(),
      direction: DismissiblePageDismissDirection.down,
      child: PreloadPageView.builder(
        onPageChanged: (index) {
          setState(() {
            widget.index = index;
          });
        },
        key: Key('image_page_view'),
        controller: widget.controller,
        itemCount: widget.allImages.length,
        itemBuilder: (context, index) {
          final assetEntity = GetIt.I<ImageService>()
              .getAssetEntity(widget.allImages[index].imageId);
          return FutureBuilder<AssetEntity?>(
            future: assetEntity,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return PhotoView(
                  heroAttributes: index == widget.index
                      ? PhotoViewHeroAttributes(
                          tag: widget.allImages[index].imageId,
                        )
                      : null,
                  imageProvider: AssetEntityImageProvider(
                    snapshot.data!,
                    isOriginal: false,
                    thumbnailSize: ThumbnailSize(
                      MediaQuery.of(context).size.width.toInt(),
                      MediaQuery.of(context).size.height.toInt(),
                    ),
                  ),
                  loadingBuilder: (context, event) => Center(
                    child: Image(
                      image: MemoryImage(kTransparentImage),
                    ),
                  ),
                );
              }
              return Container();
            },
          );
        },
      ),
    );
  }
}
