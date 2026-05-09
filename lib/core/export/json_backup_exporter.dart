import 'dart:convert';

import 'export_bundle.dart';

class JsonBackupExporter {
  const JsonBackupExporter._();

  static String encode(ExportBundle bundle) {
    return const JsonEncoder.withIndent('  ').convert(bundle.toJson());
  }
}
