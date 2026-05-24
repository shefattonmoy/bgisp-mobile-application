class HomeStats {
  final int mapCount;
  final int metadataCount;
  final int dataCount;

  HomeStats({
    required this.mapCount,
    required this.metadataCount,
    required this.dataCount,
  });

  factory HomeStats.fromJson(Map<String, dynamic> json) {
    return HomeStats(
      mapCount: json['total_maps'] ?? 0,
      metadataCount: json['metadata_count'] ?? 0,
      dataCount: json['total_individual_records'] ?? 0,
    );
  }

  factory HomeStats.initial() {
    return HomeStats(
      mapCount: 0,
      metadataCount: 0,
      dataCount: 0,
    );
  }
}