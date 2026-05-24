class MetadataRecord {
  final int id;
  final String? title;
  final String? contributor;
  final String? dataType;
  final String? vectorFormat;
  final String? rasterFormat;
  final String? layersNumber;
  final String? datum;
  final String? projection;
  final String? semiMajorMinorAxis;
  final String? flatteningRatio;
  final String? dimension;
  final String? softwareVersion;
  final String? scale;
  final String? adminLevels;
  final String? areaCoverage;
  final String? dataCollectionMethod;
  final String? surveyYear;
  final String? updateFrequency;
  final String? dataVolume;
  final String? dataCompatibility;
  final String? conflictOfInterest;
  final String? purposeOfUse;
  final String? availability;
  final String? costPerUnit;
  final int? organizationId;
  final String? organizationName;
  final int? thematicAreaId;
  final String? thematicAreaName;
  final DateTime? createdAt;

  MetadataRecord({
    required this.id,
    this.title,
    this.contributor,
    this.dataType,
    this.vectorFormat,
    this.rasterFormat,
    this.layersNumber,
    this.datum,
    this.projection,
    this.semiMajorMinorAxis,
    this.flatteningRatio,
    this.dimension,
    this.softwareVersion,
    this.scale,
    this.adminLevels,
    this.areaCoverage,
    this.dataCollectionMethod,
    this.surveyYear,
    this.updateFrequency,
    this.dataVolume,
    this.dataCompatibility,
    this.conflictOfInterest,
    this.purposeOfUse,
    this.availability,
    this.costPerUnit,
    this.organizationId,
    this.organizationName,
    this.thematicAreaId,
    this.thematicAreaName,
    this.createdAt,
  });

  factory MetadataRecord.fromJson(Map<String, dynamic> json) {
    return MetadataRecord(
      id: json['id'] ?? 0,
      title: json['title'],
      contributor: json['contributor'],
      dataType: json['data_type'],
      vectorFormat: json['vector_format'],
      rasterFormat: json['raster_format'],
      layersNumber: json['layers_number'],
      datum: json['datum'],
      projection: json['projection'],
      semiMajorMinorAxis: json['semi_major_minor_axis'],
      flatteningRatio: json['flattening_ratio'],
      dimension: json['dimension'],
      softwareVersion: json['software_version'],
      scale: json['scale'],
      adminLevels: json['admin_levels'],
      areaCoverage: json['area_coverage'],
      dataCollectionMethod: json['data_collection_method'],
      surveyYear: json['survey_year'],
      updateFrequency: json['update_frequency'],
      dataVolume: json['data_volume'],
      dataCompatibility: json['data_compatibility'],
      conflictOfInterest: json['conflict_of_interest'],
      purposeOfUse: json['purpose_of_use'],
      availability: json['availability'],
      costPerUnit: json['cost_per_unit'],
      organizationId: json['organization_id'],
      organizationName: json['organization_name'],
      thematicAreaId: json['thematic_area_id'],
      thematicAreaName: json['thematic_area_name'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}