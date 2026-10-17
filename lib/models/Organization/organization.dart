class MemberOrganization {
  final int id;
  final String orgName;
  final String? orgShort;
  final String? description;
  final String? imagePath;
  final String? websiteUrl;
  final String? organizationsType;

  MemberOrganization({
    required this.id,
    required this.orgName,
    this.orgShort,
    this.description,
    this.imagePath,
    this.websiteUrl,
    this.organizationsType,
  });

  factory MemberOrganization.fromJson(Map<String, dynamic> json) {
    return MemberOrganization(
      id: json['id'] ?? 0,
      orgName: json['org_name'] ?? '',
      orgShort: json['org_short'] ?? json['short_name'],
      description: json['description'] ?? json['org_info'],
      imagePath: json['image_path'] ?? json['image'],
      websiteUrl: json['website_url'],
      organizationsType: json['organizations_type'],
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
      'organizations_type': organizationsType,
    };
  }

  String get displayShortName {
    if (orgShort != null && orgShort!.isNotEmpty) {
      return orgShort!;
    }
    return orgName.length >= 4
        ? orgName.substring(0, 4).toUpperCase()
        : orgName;
  }
}

class OrganizationType {
  final String name;
  final int count;

  OrganizationType({required this.name, required this.count});

  @override
  String toString() => 'OrganizationType(name: $name, count: $count)';
}
