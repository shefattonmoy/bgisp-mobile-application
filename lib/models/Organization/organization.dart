class MemberOrganization {
  final int id;
  final String orgName;
  final String? orgShort;
  final String? description;
  final String? imagePath;
  final String? websiteUrl;

  MemberOrganization({
    required this.id,
    required this.orgName,
    this.orgShort,
    this.description,
    this.imagePath,
    this.websiteUrl,
  });

  factory MemberOrganization.fromJson(Map<String, dynamic> json) {
    return MemberOrganization(
      id: json['id'] ?? 0,
      orgName: json['org_name'] ?? '',
      orgShort: json['org_short'] ?? json['short_name'],
      description: json['description'],
      imagePath: json['image_path'],
      websiteUrl: json['website_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'org_name': orgName,
      'org_short': orgShort,
      'description': description,
      'image_path': imagePath,
      'website_url': websiteUrl,
    };
  }

  String get displayShortName {
    if (orgShort != null && orgShort!.isNotEmpty) {
      return orgShort!;
    }
    return orgName.length >= 4 ? orgName.substring(0, 4).toUpperCase() : orgName;
  }
}