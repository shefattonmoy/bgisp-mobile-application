// lib/services/download_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel_plus/excel_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/constant.dart';

typedef ProgressCallback = void Function(String message, {double? fraction});

class DownloadService {
  DownloadService._();

  static const Map<String, Map<String, String>> _metadataLabels = {
    'EN': {
      'field': 'Field',
      'value': 'Value',
      'title': 'Title',
      'contributor': 'Contributor',
      'thematicArea': 'Thematic Area',
      'dataType': 'Data Type',
      'vectorFormat': 'Vector Format',
      'rasterFormat': 'Raster Format',
      'layersNumber': 'Number of Layers',
      'datum': 'Datum',
      'projection': 'Projection',
      'semiMajorMinorAxis': 'Semi-Major/Minor Axis',
      'flatteningRatio': 'Flattening Ratio',
      'dimension': 'Dimension',
      'softwareVersion': 'Software Version',
      'scale': 'Scale',
      'adminLevels': 'Admin Level',
      'areaCoverage': 'Area Coverage',
      'dataCollectionMethod': 'Data Collection Method',
      'surveyYear': 'Survey Year',
      'updateFrequency': 'Update Frequency',
      'dataVolume': 'Data Volume',
      'dataCompatibility': 'Data Compatibility',
      'conflictOfInterest': 'Conflict of Interest',
      'purposeOfUse': 'Purpose of Use',
      'availability': 'Availability',
      'costPerUnit': 'Cost Per Unit',
      'notAvailable': 'Not available',
    },
    'BN': {
      'field': 'ফিল্ড',
      'value': 'মান',
      'title': 'শিরোনাম',
      'contributor': 'অবদানকারী',
      'thematicArea': 'থিম্যাটিক এরিয়া',
      'dataType': 'ডেটা টাইপ',
      'vectorFormat': 'ভেক্টর ফরম্যাট',
      'rasterFormat': 'রাস্টার ফরম্যাট',
      'layersNumber': 'লেয়ার সংখ্যা',
      'datum': 'ডেটাম',
      'projection': 'প্রক্ষেপণ',
      'semiMajorMinorAxis': 'সেমি-মেজর/মাইনর অক্ষ',
      'flatteningRatio': 'সমতলকরণ অনুপাত',
      'dimension': 'মাত্রা',
      'softwareVersion': 'সফটওয়্যার সংস্করণ',
      'scale': 'স্কেল',
      'adminLevels': 'প্রশাসনিক স্তর',
      'areaCoverage': 'এলাকা কভারেজ',
      'dataCollectionMethod': 'ডেটা সংগ্রহের পদ্ধতি',
      'surveyYear': 'জরিপ বছর',
      'updateFrequency': 'হালনাগাদের ফ্রিকোয়েন্সি',
      'dataVolume': 'ডেটা ভলিউম',
      'dataCompatibility': 'ডেটা সামঞ্জস্যতা',
      'conflictOfInterest': 'স্বার্থের সংঘাত',
      'purposeOfUse': 'ব্যবহারের উদ্দেশ্য',
      'availability': 'প্রাপ্যতা',
      'costPerUnit': 'প্রতি ইউনিট খরচ',
      'notAvailable': 'উপলব্ধ নয়',
    },
  };

  /// Ordered list of (jsonKey, labelKey) — also used as column order for multi-export.
  static const List<MapEntry<String, String>> _metadataFieldOrder = [
    MapEntry('title', 'title'),
    MapEntry('contributor', 'contributor'),
    MapEntry('data_type', 'dataType'),
    MapEntry('vector_format', 'vectorFormat'),
    MapEntry('raster_format', 'rasterFormat'),
    MapEntry('layers_number', 'layersNumber'),
    MapEntry('datum', 'datum'),
    MapEntry('projection', 'projection'),
    MapEntry('semi_major_minor_axis', 'semiMajorMinorAxis'),
    MapEntry('flattening_ratio', 'flatteningRatio'),
    MapEntry('dimension', 'dimension'),
    MapEntry('software_version', 'softwareVersion'),
    MapEntry('scale', 'scale'),
    MapEntry('admin_levels', 'adminLevels'),
    MapEntry('area_coverage', 'areaCoverage'),
    MapEntry('data_collection_method', 'dataCollectionMethod'),
    MapEntry('survey_year', 'surveyYear'),
    MapEntry('update_frequency', 'updateFrequency'),
    MapEntry('data_volume', 'dataVolume'),
    MapEntry('data_compatibility', 'dataCompatibility'),
    MapEntry('conflict_of_interest', 'conflictOfInterest'),
    MapEntry('purpose_of_use', 'purposeOfUse'),
    MapEntry('availability', 'availability'),
    MapEntry('cost_per_unit', 'costPerUnit'),
  ];

  // ---------------------------------------------------------------------------
  // KEY NORMALIZATION
  // Accepts snake_case / camelCase / kebab-case JSON. Returns a map keyed
  // by snake_case (matching _metadataFieldOrder).
  // ---------------------------------------------------------------------------

  static Map<String, dynamic> _normalizeRecord(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    for (final entry in raw.entries) {
      final snake = _toSnakeCase(entry.key);
      out[snake] = entry.value;
    }
    return out;
  }

  static String _toSnakeCase(String input) {
    // Insert underscore before capitals, lowercase everything.
    final buf = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final ch = input[i];
      final code = ch.codeUnitAt(0);
      final isUpper = code >= 65 && code <= 90;
      if (isUpper && i > 0) {
        final prev = input.codeUnitAt(i - 1);
        final prevLower = prev >= 97 && prev <= 122;
        final prevDigit = prev >= 48 && prev <= 57;
        if (prevLower || prevDigit) buf.write('_');
      }
      buf.write(ch.toLowerCase());
    }
    return buf.toString().replaceAll('-', '_').replaceAll(RegExp(r'__+'), '_');
  }

  // ---------------------------------------------------------------------------
  // METADATA EXPORT — single record (two-column Field/Value sheet)
  // ---------------------------------------------------------------------------

  static Future<void> downloadMetadataExcel({
    required Map<String, dynamic> record,
    String language = 'EN',
    ProgressCallback? onProgress,
  }) async {
    onProgress?.call('Building workbook...', fraction: 0.1);

    final labels = _metadataLabels[language] ?? _metadataLabels['EN']!;
    final notAvailable = labels['notAvailable']!;
    final normalized = _normalizeRecord(record);

    final excel = Excel.createExcel();
    const sheetName = 'Metadata Details';
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];

    sheet.appendRow([
      TextCellValue(labels['field'] ?? 'Field'),
      TextCellValue(labels['value'] ?? 'Value'),
    ]);

    for (final entry in _metadataFieldOrder) {
      final jsonKey = entry.key;
      final labelKey = entry.value;
      final label = labels[labelKey] ?? labelKey;

      final raw = normalized[jsonKey];
      final valueText = (raw == null || raw.toString().trim().isEmpty)
          ? notAvailable
          : raw.toString();

      sheet.appendRow([TextCellValue(label), TextCellValue(valueText)]);
    }

    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 50);

    onProgress?.call('Saving file...', fraction: 0.8);

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to build Excel workbook.');
    }

    final rawTitle = (normalized['title']?.toString() ?? '').trim();
    final safeTitle = _sanitizeFileName(rawTitle.isEmpty ? 'record' : rawTitle);
    final fileName = '$safeTitle.xlsx';

    await _saveAndShare(
      Uint8List.fromList(bytes),
      fileName,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      shareText: rawTitle.isEmpty ? 'Metadata Details' : rawTitle,
    );

    onProgress?.call('Done.', fraction: 1.0);
  }

  // ---------------------------------------------------------------------------
  // METADATA EXPORT — multiple records (one row per record, wide table)
  // ---------------------------------------------------------------------------

  static Future<void> downloadMetadataExcelMulti({
    required List<Map<String, dynamic>> records,
    String language = 'EN',
    String fileName = 'metadata_export',
    ProgressCallback? onProgress,
  }) async {
    if (records.isEmpty) {
      throw Exception('No records to export.');
    }

    onProgress?.call('Preparing ${records.length} records...', fraction: 0.1);

    final labels = _metadataLabels[language] ?? _metadataLabels['EN']!;
    final notAvailable = labels['notAvailable']!;

    final excel = Excel.createExcel();
    const sheetName = 'Metadata';
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      excel.rename(defaultSheet, sheetName);
    }
    final sheet = excel[sheetName];

    // Header row.
    final header = _metadataFieldOrder
        .map((e) => TextCellValue(labels[e.value] ?? e.value))
        .toList();
    sheet.appendRow(header);

    // Data rows.
    int i = 0;
    for (final rec in records) {
      i++;
      final normalized = _normalizeRecord(rec);
      final row = _metadataFieldOrder.map((e) {
        final raw = normalized[e.key];
        final text = (raw == null || raw.toString().trim().isEmpty)
            ? notAvailable
            : raw.toString();
        return TextCellValue(text);
      }).toList();
      sheet.appendRow(row);

      if (i % 25 == 0) {
        onProgress?.call(
          'Writing $i / ${records.length}...',
          fraction: 0.1 + 0.6 * (i / records.length),
        );
      }
    }

    // Column widths.
    for (int c = 0; c < _metadataFieldOrder.length; c++) {
      int longest = (labels[_metadataFieldOrder[c].value] ?? '').length;
      for (final rec in records) {
        final n = _normalizeRecord(rec);
        final v = n[_metadataFieldOrder[c].key]?.toString() ?? '';
        if (v.length > longest) longest = v.length;
      }
      sheet.setColumnWidth(c, (longest + 2).clamp(12, 50).toDouble());
    }

    onProgress?.call('Saving file...', fraction: 0.85);

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to build Excel workbook.');
    }

    final safeName = fileName.endsWith('.xlsx') ? fileName : '$fileName.xlsx';

    await _saveAndShare(
      Uint8List.fromList(bytes),
      safeName,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      shareText: '${records.length} metadata records',
    );

    onProgress?.call('Done.', fraction: 1.0);
  }

  // ---------------------------------------------------------------------------
  // DATA DOWNLOAD (ZIP)
  // ---------------------------------------------------------------------------

  static Future<void> downloadDataZip({
    required List<int> ids,
    required String title,
    ProgressCallback? onProgress,
  }) async {
    if (ids.isEmpty) {
      throw Exception('No file ids provided.');
    }

    onProgress?.call(
      'Requesting archive (${ids.length} files)...',
      fraction: 0.05,
    );

    final uri = Uri.parse('${AppConstants.myAPILink}/api/data/download/');
    final bodyJson = jsonEncode({
      'ids': ids,
      'title': title.isEmpty ? 'download' : title,
    });

    final http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': '*/*',
            },
            body: bodyJson,
          )
          .timeout(const Duration(seconds: 300));
    } catch (e) {
      throw Exception('Network error while downloading: $e');
    }

    if (response.statusCode != 200) {
      String serverMsg = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] != null) {
          serverMsg = decoded['error'].toString();
        }
      } catch (_) {}
      throw Exception('Download failed (${response.statusCode}): $serverMsg');
    }

    onProgress?.call('Received archive, saving...', fraction: 0.75);

    final fileName =
        _filenameFromHeaders(response.headers['content-disposition']) ??
        '${_sanitizeFileName(title.isEmpty ? 'download' : title)}.zip';

    final mimeType =
        response.headers['content-type'] ?? 'application/octet-stream';

    await _saveAndShare(
      response.bodyBytes,
      fileName,
      mimeType: mimeType,
      shareText: title.isEmpty ? 'Data file' : title,
    );

    onProgress?.call('Done.', fraction: 1.0);
  }

  // ---------------------------------------------------------------------------
  // GEOCODE EXPORT
  // ---------------------------------------------------------------------------

  static Future<void> downloadGeocodeExcel({
    required String sheetName,
    required List<String> headers,
    required List<List<String>> rows,
    required Set<int> codeColumns,
    required String fileName,
    ProgressCallback? onProgress,
  }) async {
    onProgress?.call('Building workbook...', fraction: 0.1);

    final excel = Excel.createExcel();
    final safeSheet = _sanitizeSheetName(sheetName);

    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != safeSheet) {
      excel.rename(defaultSheet, safeSheet);
    }
    final sheet = excel[safeSheet];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (final row in rows) {
      final padded = List<String>.generate(
        headers.length,
        (i) => i < row.length ? row[i] : '',
      );
      sheet.appendRow(padded.map((v) => TextCellValue(v)).toList());
    }

    for (int c = 0; c < headers.length; c++) {
      int longest = headers[c].length;
      for (final row in rows) {
        if (c < row.length && row[c].length > longest) {
          longest = row[c].length;
        }
      }
      sheet.setColumnWidth(c, (longest + 2).clamp(12, 42).toDouble());
    }

    onProgress?.call('Saving file...', fraction: 0.85);

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Failed to build Excel workbook.');
    }

    final safeFileName = fileName.endsWith('.xlsx')
        ? fileName
        : '$fileName.xlsx';

    await _saveAndShare(
      Uint8List.fromList(bytes),
      safeFileName,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      shareText: sheetName,
    );

    onProgress?.call('Done.', fraction: 1.0);
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static Future<void> _saveAndShare(
    Uint8List bytes,
    String fileName, {
    required String mimeType,
    String? shareText,
  }) async {
    final dir = await getTemporaryDirectory();
    final safeName = _sanitizeFileName(fileName);
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([
      XFile(file.path, mimeType: mimeType, name: safeName),
    ], text: shareText);
  }

  static String _sanitizeFileName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? 'file' : cleaned;
  }

  static String _sanitizeSheetName(String name) {
    var cleaned = name.replaceAll(RegExp(r'[\\/?*\[\]:]'), ' ').trim();
    if (cleaned.isEmpty) cleaned = 'Geocode';
    return cleaned.length > 31 ? cleaned.substring(0, 31) : cleaned;
  }

  static String? _filenameFromHeaders(String? disposition) {
    if (disposition == null || disposition.isEmpty) return null;
    final match = RegExp(
      r"filename\*?=(?:UTF-8'')?([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition);
    if (match == null) return null;

    var raw = match.group(1)!.trim();
    if (raw.length >= 2 && raw.startsWith('"') && raw.endsWith('"')) {
      raw = raw.substring(1, raw.length - 1);
    }

    String decoded;
    try {
      decoded = Uri.decodeComponent(raw);
    } catch (_) {
      decoded = raw;
    }

    final cleaned = _sanitizeFileName(decoded);
    return cleaned.isEmpty ? null : cleaned;
  }
}
