import 'dart:typed_data';

bool saveTextFile({
  required String fileName,
  required String content,
  required String mimeType,
  required bool withBom,
}) =>
    false;

bool saveBytesFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) =>
    false;
