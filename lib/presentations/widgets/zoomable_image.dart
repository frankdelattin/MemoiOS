import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class ZoomableImage extends StatefulWidget {
  final AssetEntity assetEntity;
  final Function(bool)? interactionEnded;

  const ZoomableImage({
    super.key,
    required this.assetEntity,
    this.interactionEnded,
  });

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  final _transformationController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _transformationController.addListener(() {
      if (_transformationController.value.isIdentity()) {
        widget.interactionEnded?.call(true);
      } else {}
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    final position = details.localPosition;
    final endMatrix = _transformationController.value.isIdentity()
        ? (Matrix4.identity()
          ..translate(-position.dx * 2, -position.dy * 2)
          ..scale(3.0))
        : Matrix4.identity();

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0);
    _animationController.addListener(() {
      _transformationController.value = _animation!.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key(widget.assetEntity.id),
      onDoubleTapDown: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        maxScale: 10,
        child: Image(
          image: AssetEntityImageProvider(
            widget.assetEntity,
            isOriginal: true,
          ),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
