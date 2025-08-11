import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:snapp_app/aggregates/cluster_images_aggregate.dart';
import 'package:snapp_app/services/image_service.dart';

class ClusterPage extends StatelessWidget {
  final ClusterImagesAggregate cluster;
  const ClusterPage({super.key, required this.cluster});

  @override
  Widget build(BuildContext context) {
    final totalImages = cluster.images.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${cluster.cluster.name}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total Images: $totalImages',
              style: const TextStyle(fontSize: 12.0),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: cluster.images.length,
              itemBuilder: (context, index) {
                final imageId = cluster.images[index].imageId;
                final assetEntity = GetIt.I<ImageService>().getAssetEntity(imageId);
                return FutureBuilder<AssetEntity?>(
                  future: assetEntity,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return AssetEntityImage(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        thumbnailSize: const ThumbnailSize.square(200),
                        thumbnailFormat: ThumbnailFormat.jpeg,
                        isOriginal: false,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
