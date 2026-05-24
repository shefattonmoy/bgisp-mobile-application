import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';
import '../../models/ExecutiveCommittee/executive_committee.dart';

class ExecutiveCommitteeApi {
  final String baseUrl = AppConstants.myAPILink;

  Future<List<ExecutiveCommitteeMember>> getExecutiveCommittees({String lang = 'en'}) async {
    try {
      final url = '$baseUrl/api/get_executive_committees/?lang=$lang';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => ExecutiveCommitteeMember.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load executive committees');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}