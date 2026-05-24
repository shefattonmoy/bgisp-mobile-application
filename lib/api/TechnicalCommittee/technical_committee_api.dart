import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';
import '../../models/TechnicalCommittee/technical_committee.dart';

class TechnicalCommitteeApi {
  final String baseUrl = AppConstants.myAPILink;

  Future<List<TechnicalCommitteeMember>> getTechnicalCommittees({String lang = 'en'}) async {
    try {
      final url = '$baseUrl/api/get_technical_committees/?lang=$lang';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => TechnicalCommitteeMember.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load technical committees');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}