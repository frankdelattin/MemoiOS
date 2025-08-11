import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:snapp_app/aggregates/cluster_images_aggregate.dart';
import 'package:snapp_app/presentations/pages/cluster_page.dart';
import 'package:snapp_app/services/image_service.dart';

class ClustersListPage extends StatelessWidget {
  final List<ClusterImagesAggregate> clusters;
  const ClustersListPage({super.key, required this.clusters});

  @override
  Widget build(BuildContext context) {
    final sortedClusters = List<ClusterImagesAggregate>.from(clusters)
      ..sort((a, b) {
        final isAUuid = _isUuid(a.cluster.name);
        final isBUuid = _isUuid(b.cluster.name);
        if (isAUuid && !isBUuid) return 1;
        if (!isAUuid && isBUuid) return -1;
        return a.cluster.name.compareTo(b.cluster.name);
      });

    final totalClusters = sortedClusters.length;
    final totalImages = sortedClusters.fold<int>(
        0, (sum, cluster) => sum + cluster.images.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clusters'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Total Clusters: $totalClusters, Total Images: $totalImages',
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
              itemCount: sortedClusters.length,
              itemBuilder: (context, index) {
                final clusterAggregate = sortedClusters[index];
                final imageId = clusterAggregate.images.first.imageId;
                final assetEntity = GetIt.I<ImageService>().getAssetEntity(imageId);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ClusterPage(cluster: clusterAggregate),
                      ),
                    );
                  },
                  child: GridTile(
                    footer: GridTileBar(
                      backgroundColor: Colors.black54,
                      title: Text(clusterAggregate.cluster.name),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FutureBuilder<AssetEntity?>(
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
                        ),
                        Positioned(
                          top: 8.0,
                          right: 8.0,
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            color: const Color.fromARGB(237, 74, 74, 74),
                            child: Text(
                              '${clusterAggregate.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isUuid(String name) {
    final uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegExp.hasMatch(name);
  }
}
