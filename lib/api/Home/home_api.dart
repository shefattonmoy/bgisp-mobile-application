import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';
import '../../models/home/home_stats.dart';
import '../../models/home/visitor_count.dart';

class HomeApi {
  Future<HomeStats> fetchHomeStats() async {
    try {
      final mapResponse = await http
          .get(
            Uri.parse('${AppConstants.myAPILink}/api/map_data/thematic-areas/'),
          )
          .timeout(const Duration(seconds: 15));

      final metadataResponse = await http
          .get(
            Uri.parse('${AppConstants.myAPILink}/api/metadata/thematic-areas/'),
          )
          .timeout(const Duration(seconds: 15));

      final dataResponse = await http
          .get(Uri.parse('${AppConstants.myAPILink}/api/data/thematic-areas/'))
          .timeout(const Duration(seconds: 15));

      int mapCount = 0;
      int metadataCount = 0;
      int dataCount = 0;

      if (mapResponse.statusCode == 200) {
        final mapData = jsonDecode(mapResponse.body);
        if (mapData['success'] == true) {
          final areas = mapData['thematic_areas'] as List?;
          if (areas != null) {
            for (final area in areas) {
              mapCount += (area['map_count'] ?? area['data_count'] ?? 0) as int;
            }
          }
          mapCount = mapData['total_maps'] ?? mapCount;
        }
      }

      if (metadataResponse.statusCode == 200) {
        final metadataData = jsonDecode(metadataResponse.body);
        if (metadataData['success'] == true) {
          final areas = metadataData['thematic_areas'] as List?;
          if (areas != null) {
            for (final area in areas) {
              metadataCount += (area['metadata_count'] ?? 0) as int;
            }
          }
          metadataCount = metadataData['total_metadata'] ?? metadataCount;
        }
      }

      if (dataResponse.statusCode == 200) {
        final dataResult = jsonDecode(dataResponse.body);
        if (dataResult['success'] == true) {
          final areas = dataResult['thematic_areas'] as List?;
          if (areas != null) {
            for (final area in areas) {
              dataCount += (area['data_count'] ?? 0) as int;
            }
          }
          dataCount = dataResult['total_data_records'] ?? dataCount;
        }
      }

      return HomeStats(
        mapCount: mapCount,
        metadataCount: metadataCount,
        dataCount: dataCount,
      );
    } catch (e) {
      return HomeStats(mapCount: 0, metadataCount: 0, dataCount: 0);
    }
  }

  Future<VisitorCount> fetchVisitorCount() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.myAPILink}/api/visitor-count/'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VisitorCount.fromJson(data);
      }
      return VisitorCount.initial();
    } catch (e) {
      return VisitorCount.initial();
    }
  }

  Future<int> fetchFocalPointsCount({String lang = 'en'}) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '${AppConstants.myAPILink}/api/get_focal_persons/?lang=$lang',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.length;
        } else if (data is Map && data.containsKey('count')) {
          return data['count'] as int;
        } else if (data is Map && data.containsKey('data')) {
          final focalData = data['data'];
          return focalData is List ? focalData.length : 0;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> trackVisitor() async {
    try {
      await http
          .post(
            Uri.parse('${AppConstants.myAPILink}/api/track-visit/'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      // Silent
    }
  }
}
