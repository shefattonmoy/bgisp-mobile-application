import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';
import '../../models/FocalPoint/focal_point.dart';

class FocalPointApi {
  final String baseUrl = AppConstants.myAPILink;

  Future<List<FocalPoint>> getFocalPoints({String lang = 'en'}) async {
    try {
      final url = '$baseUrl/api/get_focal_persons/?lang=$lang';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => FocalPoint.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load focal points');
      }
    } catch (e) {
      throw Exception('Error fetching focal points: $e');
    }
  }
}