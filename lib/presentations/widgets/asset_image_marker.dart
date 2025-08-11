import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:snapp_app/aggregates/cluster_images_aggregate.dart';
import 'package:snapp_app/presentations/pages/cluster_page.dart';
import 'package:snapp_app/services/image_service.dart';

class AssetImageMarker extends StatelessWidget {
  final ClusterImagesAggregate clusterAggregate;

  const AssetImageMarker({super.key, required this.clusterAggregate});

  static const markerSize = 100;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClusterPage(cluster: clusterAggregate),
          ),
        );
      },
      child: FutureBuilder<AssetEntity?>(
        future: GetIt.I<ImageService>()
            .getAssetEntity(clusterAggregate.images.first.imageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Icon(Icons.error);
          }
          return Container(
            width: markerSize.toDouble(),
            height: markerSize.toDouble(),
            decoration: BoxDecoration(
              color: const Color.fromARGB(94, 0, 0, 0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(94, 0, 0, 0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  width: markerSize.toDouble(),
                  height: markerSize.toDouble(),
                  child: AssetEntityImage(
                    snapshot.data!,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(markerSize),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: -8.0,
                  right: -8.0,
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${clusterAggregate.images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
