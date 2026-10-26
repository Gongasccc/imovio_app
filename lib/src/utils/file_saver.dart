import 'dart:typed_data';

import 'package:imovio/src/utils/file_saver_stub.dart'
    if (dart.library.js_interop) 'package:imovio/src/utils/file_saver_web.dart'
    as impl;

/// Guarda um ficheiro de texto. Na web descarrega-o; no iOS devolve false
/// para o ecrã oferecer copiar o conteúdo.
bool saveTextFile({
  required String fileName,
  required String content,
  String mimeType = 'text/csv;charset=utf-8',
  bool withBom = true,
}) =>
    impl.saveTextFile(
      fileName: fileName,
      content: content,
      mimeType: mimeType,
      withBom: withBom,
    );

/// Guarda um ficheiro binário (ex.: Excel). Devolve false fora da web.
bool saveBytesFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) =>
    impl.saveBytesFile(fileName: fileName, bytes: bytes, mimeType: mimeType);
