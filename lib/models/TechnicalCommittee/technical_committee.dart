import '../../constants/constant.dart';

class TechnicalCommitteeMember {
  final int id;
  final String? designation;
  final String? designationBn;
  final String? committeeRole;
  final String? committeeRoleBn;
  final String? organization;
  final String? image;
  final DateTime? createdAt;

  TechnicalCommitteeMember({
    required this.id,
    this.designation,
    this.designationBn,
    this.committeeRole,
    this.committeeRoleBn,
    this.organization,
    this.image,
    this.createdAt,
  });

  factory TechnicalCommitteeMember.fromJson(Map<String, dynamic> json) {
    return TechnicalCommitteeMember(
      id: json['id'] ?? 0,
      designation: json['designation'] ?? '',
      designationBn: json['designation_bn'],
      committeeRole: json['committee_role'] ?? '',
      committeeRoleBn: json['committee_role_bn'],
      organization: json['organization'] ?? '',
      image: json['image'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http://') || image!.startsWith('https://')) return image!;
    final cleanPath = image!.startsWith('/') ? image!.substring(1) : image!;
    final baseUrl = AppConstants.myAPILink.endsWith('/')
        ? AppConstants.myAPILink.substring(0, AppConstants.myAPILink.length - 1)
        : AppConstants.myAPILink;
    return '$baseUrl/$cleanPath';
  }
}

class TechMeeting {
  final int id;
  final String title;
  final String description;
  final String date;

  TechMeeting({required this.id, required this.title, required this.description, required this.date});
}

class TechNotice {
  final int id;
  final String title;
  final String description;
  final String publishedDate;
  final bool hasAttachment;

  TechNotice({required this.id, required this.title, required this.description, required this.publishedDate, this.hasAttachment = false});
}