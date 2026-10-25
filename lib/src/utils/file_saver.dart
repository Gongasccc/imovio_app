import 'package:imovio/src/utils/file_saver_stub.dart'
    if (dart.library.js_interop) 'package:imovio/src/utils/file_saver_web.dart'
    as impl;

/// Guarda um ficheiro de texto. Na web descarrega-o; no iOS devolve false
/// para o ecrã oferecer copiar o conteúdo.
bool saveTextFile({required String fileName, required String content}) =>
    impl.saveTextFile(fileName: fileName, content: content);
