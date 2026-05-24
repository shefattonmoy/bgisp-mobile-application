import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';
import '../../models/Gallery/gallery.dart';

class GalleryApi {
  final String baseUrl = AppConstants.myAPILink;

  Future<List<GalleryItem>> getGallery({String lang = 'en'}) async {
    try {
      final url = '$baseUrl/api/get_gallery/?lang=$lang';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => GalleryItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load gallery');
      }
    } catch (e) {
      throw Exception('Error fetching gallery: $e');
    }
  }
}