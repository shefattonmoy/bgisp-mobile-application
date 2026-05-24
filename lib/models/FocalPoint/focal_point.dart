import '../../constants/constant.dart';

class FocalPoint {
  final int id;
  final String? name;
  final String? nameBn;
  final String? organization;
  final String? designation;
  final String? designationBn;
  final String? phone;
  final String? email;
  final String? image;

  FocalPoint({
    required this.id,
    this.name,
    this.nameBn,
    this.organization,
    this.designation,
    this.designationBn,
    this.phone,
    this.email,
    this.image,
  });

  factory FocalPoint.fromJson(Map<String, dynamic> json) {
    return FocalPoint(
      id: json['id'] ?? 0,
      name: json['name'],
      nameBn: json['name_bn'],
      organization: json['organization'],
      designation: json['designation'],
      designationBn: json['designation_bn'],
      phone: json['phone'],
      email: json['email'],
      image: json['image'],
    );
  }

  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http')) return image!;
    return '${AppConstants.myAPILink}$image';
  }

  String getDisplayName(String lang) {
    if (lang == 'BN' && nameBn != null && nameBn!.isNotEmpty) return nameBn!;
    return name ?? '';
  }

  String getDisplayDesignation(String lang) {
    if (lang == 'BN' && designationBn != null && designationBn!.isNotEmpty) return designationBn!;
    return designation ?? '';
  }
}