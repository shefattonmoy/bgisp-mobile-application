import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';
import '../../models/SubCommittee/sub_committee.dart';

class SubCommitteeApi {
  SubCommitteeApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<SubCommitteeMember>> getSubCommitteeMembers({
    String lang = 'en',
  }) async {
    final uri = Uri.parse(
      '${AppConstants.myAPILink}/api/get_sub_committees/?lang=$lang',
    );

    final response = await _client.get(uri).timeout(_timeout);

    if (response.statusCode != 200) {
      throw SubCommitteeApiException(
        'Failed to load sub-committee members '
        '(HTTP ${response.statusCode})',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw SubCommitteeApiException(
        'Unexpected response shape: expected a list.',
        body: response.body,
      );
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SubCommitteeMember.fromJson)
        .toList();
  }

  /// GET /api/get_sub_committees/<id>/?lang=en|bn
  Future<SubCommitteeMember> getSubCommitteeMemberDetail(
    int id, {
    String lang = 'en',
  }) async {
    final uri = Uri.parse(
      '${AppConstants.myAPILink}/api/get_sub_committees/$id/?lang=$lang',
    );

    final response = await _client.get(uri).timeout(_timeout);

    if (response.statusCode == 404) {
      throw SubCommitteeApiException('Member not found', statusCode: 404);
    }
    if (response.statusCode != 200) {
      throw SubCommitteeApiException(
        'Failed to load member detail (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw SubCommitteeApiException(
        'Unexpected response shape: expected an object.',
        body: response.body,
      );
    }
    return SubCommitteeMember.fromJson(decoded);
  }

  void dispose() => _client.close();
}

class SubCommitteeApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  SubCommitteeApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() =>
      'SubCommitteeApiException($message'
      '${statusCode != null ? ', status=$statusCode' : ''})';
}
