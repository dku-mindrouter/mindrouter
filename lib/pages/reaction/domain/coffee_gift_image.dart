import 'dart:typed_data';

class CoffeeGiftImage {
  const CoffeeGiftImage({
    required this.bytes,
    required this.fileExtension,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileExtension;
  final String contentType;
}
