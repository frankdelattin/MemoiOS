enum ImageVectorStatus {
  success(0),
  error(1);

  final int value;

  const ImageVectorStatus(this.value);

  static ImageVectorStatus? fromValue(int? value) {
    if (value == null) {
      return null;
    }
    return ImageVectorStatus.values.firstWhere((e) => e.value == value);
  }
}
