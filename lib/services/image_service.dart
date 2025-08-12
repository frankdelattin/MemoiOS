import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:photo_manager/photo_manager.dart';
import 'package:snapp_app/data/image_metadata.dart';

class ImageService {
  CustomFilter createFilter(
      int lastModifiedDate, List<String> excludedImageIds) {
    var sqlExcludedImages = '';
    if (excludedImageIds.isNotEmpty) {
      for (var excludedImageId in excludedImageIds) {
        sqlExcludedImages +=
            ' AND ${CustomColumns.base.id} != "$excludedImageId"';
      }
    }
    return CustomFilter.sql(
      where: """
          ${CustomColumns.base.modifiedDate} >= ${ColumnUtils.instance.convertDateTimeToSql(DateTime.fromMillisecondsSinceEpoch(lastModifiedDate * 1000))} AND 
          ${CustomColumns.base.mediaType} == 1 AND 
          ${CustomColumns.base.width} > 224 AND 
          ${CustomColumns.base.height} > 224
          $sqlExcludedImages          
          """,
      orderBy: [
        OrderByItem.asc(CustomColumns.base.modifiedDate),
      ],
    );
  }

  CustomFilter createFilterForTotalCount(int? maxModifiedDate) {
    return CustomFilter.sql(
      where: """
          ${maxModifiedDate != null ? '${CustomColumns.base.modifiedDate} <= $maxModifiedDate AND' : ''}
          ${CustomColumns.base.mediaType} == 1 AND 
          ${CustomColumns.base.width} > 224 AND 
          ${CustomColumns.base.height} > 224
          """,
    );
  }

  CustomFilter createFilterForListIn(Set<String>? imageIds) {
    return CustomFilter.sql(
      where: """
          ${CustomColumns.base.id} IN (${imageIds?.join(',')}) AND
          ${CustomColumns.base.mediaType} == 1 AND 
          ${CustomColumns.base.width} > 224 AND 
          ${CustomColumns.base.height} > 224
          """,
    );
  }

  Future<PermissionState> getPermissionState() async {
    return await PhotoManager.getPermissionState(
        requestOption: PermissionRequestOption(
            androidPermission: AndroidPermission(
                type: RequestType.image, mediaLocation: false)));
  }

  Future<PermissionState> requestPermission() async {
    return await PhotoManager.requestPermissionExtend(
        requestOption: PermissionRequestOption(
      androidPermission:
          AndroidPermission(type: RequestType.image, mediaLocation: false),
    ));
  }

  Future<List<AssetEntity>> getImagesByIds(
      {required Set<String> imageIds, int limit = 10}) async {
    final List<AssetEntity> assets = await PhotoManager.getAssetListRange(
      type: RequestType.image,
      start: 0,
      end: limit,
      filterOption: createFilterForListIn(imageIds),
    );
    return assets;
  }

  Future ignorePermissions() async {
    await PhotoManager.setIgnorePermissionCheck(true);
  }

  Future<List<AssetEntity>> getImages(
      {int lastModifiedDate = -1,
      int limit = 10,
      List<String> excludedImageIds = const []}) async {
    return await _getImages(lastModifiedDate, excludedImageIds, limit);
  }

  Future<List<AssetEntity>> _getImages(
      int lastModifiedDate, List<String> excludedImageIds, int limit) async {
    final List<AssetEntity> assets = await PhotoManager.getAssetListRange(
      type: RequestType.image,
      start: 0,
      end: limit,
      filterOption: createFilter(lastModifiedDate, excludedImageIds),
    );
    return assets;
  }

  Future<Uint8List> getImage(AssetEntity asset) async {
    final bytes = await asset.thumbnailDataWithOption(
      ThumbnailOption(
        size: ThumbnailSize(224, 224),
      ),
    );
    return bytes!;
  }

  Future<AssetEntity?> getAssetEntity(String id) async {
    return await AssetEntity.fromId(id);
  }

  Future<Uint8List> getImageById(String id) async {
    var assetEntity = await AssetEntity.fromId(id);

    if (assetEntity == null) return Uint8List(0);
    return await getImage(assetEntity);
  }

  Future<int> getAllImagesCount({int? maxModifiedDate}) async {
    return await PhotoManager.getAssetCount(
        type: RequestType.image,
        filterOption: createFilterForTotalCount(maxModifiedDate));
  }

  Future<List<AssetEntity>> getAllImageAssetEntities() async {
    int imagesCount = await getAllImagesCount();
    return await getImages(limit: imagesCount);
  }

  Future<ImageMetadata> getMetadata(AssetEntity asset) async {
    var latLon = await asset.latlngAsync();

    return ImageMetadata(
      latitude: latLon.latitude ?? 0,
      longitude: latLon.longitude ?? 0,
      dateTime: asset.createDateTime,
      id: asset.id,
    );
  }

  Future<Uint8List> preProcessImage(
      Uint8List imageBytes, int width, int height) async {
    // Dosyayı oku
    final image = img.decodeImage(imageBytes);

    if (image != null) {
      if (image.width == width && image.height == height) {
        return imageBytes;
      }
      var isWidthSmaller = image.width < image.height;

      // Resmi yeniden boyutlandır
      final resizedImage = img.copyResize(image,
          width: isWidthSmaller ? width : null,
          height: isWidthSmaller ? null : height,
          interpolation: img.Interpolation.cubic,
          maintainAspect: true);
      //center crop
      final croppedImage = img.copyCrop(resizedImage,
          x: (resizedImage.width - width) ~/ 2,
          y: (resizedImage.height - height) ~/ 2,
          width: width,
          height: height);
      return img.encodeJpg(croppedImage);
    } else {
      print("Resim decode edilemedi.");
      throw Exception("Resim decode edilemedi.");
    }
  }
}
