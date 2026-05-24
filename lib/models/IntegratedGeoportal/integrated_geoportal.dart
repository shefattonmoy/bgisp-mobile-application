class GeoportalMapLayer {
  final int id;
  final String? categoryId;
  final String? mainCategory;
  final String? subCategory;
  final String? categoryDisplayName;
  final String? categoryUrl;
  final String? tableName;
  final bool isGeoCodeLayer;
  final int? sortingOrder;
  final int? organizationId;
  final int? thematicAreaId;
  final DateTime? createdAt;

  GeoportalMapLayer({
    required this.id,
    this.categoryId,
    this.mainCategory,
    this.subCategory,
    this.categoryDisplayName,
    this.categoryUrl,
    this.tableName,
    this.isGeoCodeLayer = false,
    this.sortingOrder,
    this.organizationId,
    this.thematicAreaId,
    this.createdAt,
  });

  factory GeoportalMapLayer.fromJson(Map<String, dynamic> json) {
    return GeoportalMapLayer(
      id: json['id'] ?? 0,
      categoryId: json['category_id'],
      mainCategory: json['main_category'],
      subCategory: json['sub_category'],
      categoryDisplayName: json['category_display_name'],
      categoryUrl: json['category_url'],
      tableName: json['table_name'],
      isGeoCodeLayer: json['is_geo_code_layer'] ?? false,
      sortingOrder: json['sorting_order'],
      organizationId: json['organization_id'],
      thematicAreaId: json['thematic_area_id'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}

class GeoportalMapContent {
  final List<String> mainCategories;
  final Map<String, dynamic> layersByMainCategory;

  GeoportalMapContent({
    required this.mainCategories,
    required this.layersByMainCategory,
  });

  factory GeoportalMapContent.fromJson(Map<String, dynamic> json) {
    return GeoportalMapContent(
      mainCategories: List<String>.from(json['main_categories'] ?? []),
      layersByMainCategory: json['layers_by_main_category'] ?? {},
    );
  }
}