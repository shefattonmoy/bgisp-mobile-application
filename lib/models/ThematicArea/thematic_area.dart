class ThematicArea {
  final int id;
  final String name;
  final String? nameBn;
  final bool isActive;
  final String? comments;
  final int? sortingOrder;
  final int dataCount;
  final int metadataCount;
  final int organizationCount;

  ThematicArea({
    required this.id,
    required this.name,
    this.nameBn,
    this.isActive = true,
    this.comments,
    this.sortingOrder,
    this.dataCount = 0,
    this.metadataCount = 0,
    this.organizationCount = 0,
  });

  factory ThematicArea.fromJson(Map<String, dynamic> json) {
    return ThematicArea(
      id: json['thematic_area_id'] ?? json['id'] ?? 0,
      name: json['thematic_area_name'] ?? '',
      nameBn: json['thematic_area_name_bn'],
      isActive: json['is_active'] ?? true,
      comments: json['comments'],
      sortingOrder: json['sorting_order'],
      dataCount: json['data_count'] ?? 0,
      metadataCount: json['metadata_count'] ?? 0,
      organizationCount: json['organization_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thematic_area_id': id,
      'thematic_area_name': name,
      'thematic_area_name_bn': nameBn,
      'is_active': isActive,
      'comments': comments,
      'sorting_order': sortingOrder,
      'data_count': dataCount,
      'metadata_count': metadataCount,
      'organization_count': organizationCount,
    };
  }

  @override
  String toString() {
    return 'ThematicArea(id: $id, name: $name, dataCount: $dataCount, metadataCount: $metadataCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThematicArea && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}