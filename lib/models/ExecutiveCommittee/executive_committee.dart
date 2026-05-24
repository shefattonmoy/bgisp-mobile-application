import '../../constants/constant.dart';

class ExecutiveCommitteeMember {
  final int id;
  final String? designation;
  final String? designationBn;
  final String? committeeRole;
  final String? committeeRoleBn;
  final String? organization;
  final String? image;
  final DateTime? createdAt;

  ExecutiveCommitteeMember({
    required this.id,
    this.designation,
    this.designationBn,
    this.committeeRole,
    this.committeeRoleBn,
    this.organization,
    this.image,
    this.createdAt,
  });

  factory ExecutiveCommitteeMember.fromJson(Map<String, dynamic> json) {
    return ExecutiveCommitteeMember(
      id: json['id'] ?? 0,
      designation: json['designation'] ?? '',
      designationBn: json['designation_bn'],
      committeeRole: json['committee_role'] ?? '',
      committeeRoleBn: json['committee_role_bn'],
      organization: json['organization'] ?? '',
      image: json['image'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image!;
    }
    final cleanPath = image!.startsWith('/') ? image!.substring(1) : image!;
    final baseUrl = AppConstants.myAPILink.endsWith('/')
        ? AppConstants.myAPILink.substring(0, AppConstants.myAPILink.length - 1)
        : AppConstants.myAPILink;
    return '$baseUrl/$cleanPath';
  }

  String getDisplayDesignation(String lang) {
    if (lang == 'BN' && designationBn != null && designationBn!.isNotEmpty) {
      return designationBn!;
    }
    return designation ?? '';
  }

  String getDisplayRole(String lang) {
    if (lang == 'BN' && committeeRoleBn != null && committeeRoleBn!.isNotEmpty) {
      return committeeRoleBn!;
    }
    return committeeRole ?? '';
  }
}

class Meeting {
  final int id;
  final String title;
  final String description;
  final String date;

  Meeting({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });
}

class Notice {
  final int id;
  final String title;
  final String description;
  final String publishedDate;
  final bool hasAttachment;

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.publishedDate,
    this.hasAttachment = false,
  });
}
