import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void _download(web.Blob blob, String fileName) {
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}

bool saveTextFile({
  required String fileName,
  required String content,
  required String mimeType,
  required bool withBom,
}) {
  // BOM para o Excel abrir os acentos corretamente nos CSV.
  final text = withBom ? '﻿$content' : content;
  _download(
    web.Blob([text.toJS].toJS, web.BlobPropertyBag(type: mimeType)),
    fileName,
  );
  return true;
}

bool saveBytesFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) {
  _download(
    web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType)),
    fileName,
  );
  return true;
}
