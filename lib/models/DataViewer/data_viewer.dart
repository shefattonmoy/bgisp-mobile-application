class DataRecord {
  final int id;
  final String? contributor;
  final String? title;
  final String? dataType;
  final String? shortDescription;
  final String? dataStorageUrl;
  final String? fileName;
  final String? filePath;
  final int? organizationId;
  final String? organizationName;
  final int? thematicAreaId;
  final String? thematicAreaName;
  final DateTime? createdAt;
  final int? totalRecords;
  final List<DataRecord>? records;

  DataRecord({
    required this.id,
    this.contributor,
    this.title,
    this.dataType,
    this.shortDescription,
    this.dataStorageUrl,
    this.fileName,
    this.filePath,
    this.organizationId,
    this.organizationName,
    this.thematicAreaId,
    this.thematicAreaName,
    this.createdAt,
    this.totalRecords,
    this.records,
  });

  factory DataRecord.fromJson(Map<String, dynamic> json) {
    return DataRecord(
      id: json['id'] ?? 0,
      contributor: json['contributor'],
      title: json['title'],
      dataType: json['data_type'],
      shortDescription: json['short_description'],
      dataStorageUrl: json['data_storage_url'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      organizationId: json['organization_id'],
      organizationName: json['organization_name'],
      thematicAreaId: json['thematic_area_id'],
      thematicAreaName: json['thematic_area_name'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      totalRecords: json['total_records'],
      records: json['records'] != null
          ? (json['records'] as List).map((r) => DataRecord.fromJson(r)).toList()
          : null,
    );
  }
}

class ThematicAreaData {
  final int thematicAreaId;
  final String thematicAreaName;
  final String? thematicAreaNameBn;
  final int dataCount;
  final int organizationCount;
  final List<DataRecord>? sampleData;

  ThematicAreaData({
    required this.thematicAreaId,
    required this.thematicAreaName,
    this.thematicAreaNameBn,
    required this.dataCount,
    required this.organizationCount,
    this.sampleData,
  });

  factory ThematicAreaData.fromJson(Map<String, dynamic> json) {
    return ThematicAreaData(
      thematicAreaId: json['thematic_area_id'] ?? 0,
      thematicAreaName: json['thematic_area_name'] ?? '',
      thematicAreaNameBn: json['thematic_area_name_bn'],
      dataCount: json['data_count'] ?? 0,
      organizationCount: json['organization_count'] ?? 0,
      sampleData: json['sample_data'] != null
          ? (json['sample_data'] as List).map((r) => DataRecord.fromJson(r)).toList()
          : null,
    );
  }
}