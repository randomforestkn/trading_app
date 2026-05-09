enum ExportFormat {
  jsonBackup,
  journalCsv,
  paperTradesCsv,
  optionsPositionsCsv,
  optionsTradesCsv,
  performanceReport,
}

extension ExportFormatLabel on ExportFormat {
  String get label {
    return switch (this) {
      ExportFormat.jsonBackup => 'JSON backup',
      ExportFormat.journalCsv => 'Journal CSV',
      ExportFormat.paperTradesCsv => 'Paper trades CSV',
      ExportFormat.optionsPositionsCsv => 'Options positions CSV',
      ExportFormat.optionsTradesCsv => 'Options trades CSV',
      ExportFormat.performanceReport => 'Performance report',
    };
  }

  String get extension {
    return switch (this) {
      ExportFormat.jsonBackup => 'json',
      ExportFormat.journalCsv => 'csv',
      ExportFormat.paperTradesCsv => 'csv',
      ExportFormat.optionsPositionsCsv => 'csv',
      ExportFormat.optionsTradesCsv => 'csv',
      ExportFormat.performanceReport => 'md',
    };
  }

  String get mimeType {
    return switch (this) {
      ExportFormat.jsonBackup => 'application/json',
      ExportFormat.journalCsv => 'text/csv',
      ExportFormat.paperTradesCsv => 'text/csv',
      ExportFormat.optionsPositionsCsv => 'text/csv',
      ExportFormat.optionsTradesCsv => 'text/csv',
      ExportFormat.performanceReport => 'text/markdown',
    };
  }
}
