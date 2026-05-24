import 'dart:convert';
import 'dart:io';
import '../../models/ThematicArea/thematic_area.dart';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';
import '../../models/Organization/organization.dart';

class OrganizationApi {
  final String baseUrl = AppConstants.myAPILink;

  Future<List<MemberOrganization>> getOrganizations({
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/get_member_organizations/?lang=$lang',
      );

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((json) => MemberOrganization.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load organizations: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Server not reachable. Please try again later.');
    } catch (e) {
      throw Exception('Error fetching organizations: $e');
    }
  }

  Future<MemberOrganization> getOrganizationDetail(
    int id, {
    String lang = 'en',
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/get_member_organizations/$id/?lang=$lang',
      );

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return MemberOrganization.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Organization not found');
      } else {
        throw Exception(
          'Failed to load organization details: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on HttpException {
      throw Exception('Server not reachable. Please try again later.');
    } catch (e) {
      throw Exception('Error fetching organization details: $e');
    }
  }

  Future<List<ThematicArea>> getThematicAreasWithData(
    int organizationId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/get_member_organizations/$organizationId/thematic-areas-data/',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['thematic_areas'] != null) {
          return (data['thematic_areas'] as List)
              .map((json) => ThematicArea.fromJson(json))
              .toList();
        }
      }
      return [];
    } on SocketException {
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<ThematicArea>> getThematicAreasWithMetadata(
    int organizationId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/api/get_member_organizations/$organizationId/thematic-areas-metadata/',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['thematic_areas'] != null) {
          return (data['thematic_areas'] as List)
              .map((json) => ThematicArea.fromJson(json))
              .toList();
        }
      }
      return [];
    } on SocketException {
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get data records for a specific organization and thematic area
  Future<List<Map<String, dynamic>>> getDataByOrgAndThematicArea(
    int organizationId,
    int thematicAreaId,
  ) async {
    try {
      final url =
          '$baseUrl/api/get_member_organizations/$organizationId/thematic-areas/$thematicAreaId/data/';
      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get metadata records for a specific organization and thematic area
  Future<List<Map<String, dynamic>>> getMetadataByOrgAndThematicArea(
    int organizationId,
    int thematicAreaId,
  ) async {
    try {
      final url =
          '$baseUrl/api/get_member_organizations/$organizationId/thematic-area/$thematicAreaId/metadata/';
      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['metadata'] != null) {
          return List<Map<String, dynamic>>.from(data['metadata']);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
