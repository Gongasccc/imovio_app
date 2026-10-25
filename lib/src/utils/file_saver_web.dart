import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool saveTextFile({required String fileName, required String content}) {
  // BOM para o Excel abrir os acentos corretamente.
  final blob = web.Blob(
    ['﻿$content'.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return true;
}
