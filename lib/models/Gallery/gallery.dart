import '../../constants/constant.dart';

class GalleryItem {
  final int id;
  final String? title;
  final String? shortDetails;
  final DateTime? createdAt;
  final String? image;

  GalleryItem({
    required this.id,
    this.title,
    this.shortDetails,
    this.createdAt,
    this.image,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id'] ?? 0,
      title: json['title'],
      shortDetails: json['short_details'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      image: json['image'],
    );
  }

  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    return '${AppConstants.myAPILink}$image';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'short_details': shortDetails,
      'created_at': createdAt?.toIso8601String(),
      'image': image,
    };
  }

  @override
  String toString() {
    return 'GalleryItem(id: $id, title: $title)';
  }
}
