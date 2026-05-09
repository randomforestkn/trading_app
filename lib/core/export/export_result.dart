import 'export_format.dart';

class ExportResult {
  const ExportResult({
    required this.filename,
    required this.mimeType,
    required this.content,
    required this.createdAt,
    required this.format,
    required this.includedSections,
  });

  final String filename;
  final String mimeType;
  final String content;
  final DateTime createdAt;
  final ExportFormat format;
  final List<String> includedSections;

  int get characterCount => content.length;
}
