import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';
import '../../models/Geocode/geocode.dart';

class TimeSeriesApi {
  final String baseUrl = AppConstants.myAPILink;

  Future<List<Division>> getAllDivisions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_all_divisions/'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) => Division.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<District>> getAllDistricts({int? divisionId}) async {
    try {
      String url = '$baseUrl/api/get_all_districts/';
      if (divisionId != null) {
        url += '?division_id=$divisionId';
      }

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) => District.fromJson(item)).toList();
        }
      } else {
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get all upazilas (optionally filtered by district)
  Future<List<Upazila>> getAllUpazilas({int? districtId}) async {
    try {
      String url = '$baseUrl/api/get_all_upazilas/';
      if (districtId != null) {
        url += '?district_id=$districtId';
      }

      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) => Upazila.fromJson(item)).toList();
        }
      } else {
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}