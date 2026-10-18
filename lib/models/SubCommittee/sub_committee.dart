// lib/models/SubCommittee/sub_committee.dart
class SubCommitteeMember {
  final int id;
  final String? name;
  final String? nameBn;
  final String? designation;
  final String? designationBn;
  final String? committeeRole;
  final String? committeeRoleBn;
  final String? organization;
  final String? imagePath;
  final String? email;
  final String? phone;
  final DateTime? createdAt;

  const SubCommitteeMember({
    required this.id,
    this.name,
    this.nameBn,
    this.designation,
    this.designationBn,
    this.committeeRole,
    this.committeeRoleBn,
    this.organization,
    this.imagePath,
    this.email,
    this.phone,
    this.createdAt,
  });

  factory SubCommitteeMember.fromJson(Map<String, dynamic> json) {
    return SubCommitteeMember(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString(),
      nameBn: json['name_bn']?.toString(),
      designation: json['designation']?.toString(),
      designationBn: json['designation_bn']?.toString(),
      committeeRole: json['committee_role']?.toString(),
      committeeRoleBn: json['committee_role_bn']?.toString(),
      organization: json['organization']?.toString(),
      imagePath: json['image']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_bn': nameBn,
    'designation': designation,
    'designation_bn': designationBn,
    'committee_role': committeeRole,
    'committee_role_bn': committeeRoleBn,
    'organization': organization,
    'image': imagePath,
    'email': email,
    'phone': phone,
    'created_at': createdAt?.toIso8601String(),
  };

  /// Display helpers that respect language.
  String get displayName => name ?? nameBn ?? '';
  String get displayNameBn => nameBn ?? name ?? '';
  String get displayDesignation => designation ?? designationBn ?? '';
  String get displayDesignationBn => designationBn ?? designation ?? '';
  String get displayRole => committeeRole ?? committeeRoleBn ?? '';
  String get displayRoleBn => committeeRoleBn ?? committeeRole ?? '';
}
