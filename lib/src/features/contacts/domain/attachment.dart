import 'package:equatable/equatable.dart';
import 'package:imovio/src/utils/format.dart';

/// Ficheiro anexado a um contacto (CC, contratos, comprovativos...).
class Attachment extends Equatable {
  const Attachment({
    required this.name,
    required this.url,
    required this.path,
    this.size,
    this.contentType,
    this.uploadedAt,
  });

  final String name;
  final String url;

  /// Caminho no Firebase Storage, para poder apagar o ficheiro.
  final String path;
  final int? size;
  final String? contentType;
  final int? uploadedAt;

  bool get isImage => contentType?.startsWith('image/') ?? false;
  bool get isPdf => contentType == 'application/pdf' ||
      name.toLowerCase().endsWith('.pdf');

  String get sizeLabel {
    final s = size;
    if (s == null) return '';
    if (s < 1024) return '$s B';
    if (s < 1024 * 1024) return '${(s / 1024).toStringAsFixed(0)} KB';
    return '${(s / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  factory Attachment.fromMap(Map<String, dynamic> m) => Attachment(
        name: m['name']?.toString() ?? 'ficheiro',
        url: m['url']?.toString() ?? '',
        path: m['path']?.toString() ?? '',
        size: parseInt(m['size']),
        contentType: m['contentType']?.toString(),
        uploadedAt: parseMillis(m['uploadedAt']),
      );

  static List<Attachment> listFrom(Object? value) => value is List
      ? value.whereType<Map<String, dynamic>>().map(Attachment.fromMap).toList()
      : const [];

  Map<String, dynamic> toMap() => {
        'name': name,
        'url': url,
        'path': path,
        'size': size,
        'contentType': contentType,
        'uploadedAt': uploadedAt,
      };

  @override
  List<Object?> get props => [name, url, path, size, contentType, uploadedAt];
}
