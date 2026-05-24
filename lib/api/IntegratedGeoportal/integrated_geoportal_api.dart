import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ArcGISFeature {
  final Map<String, dynamic> attributes;
  final List<List<LatLng>> rings;

  ArcGISFeature({required this.attributes, required this.rings});

  factory ArcGISFeature.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final List<List<LatLng>> rings = [];
    
    if (geometry != null && geometry['rings'] != null) {
      final ringsData = geometry['rings'] as List<dynamic>;
      for (final ring in ringsData) {
        final points = (ring as List<dynamic>).map((coord) {
          return LatLng(coord[1] as double, coord[0] as double);
        }).toList();
        rings.add(points);
      }
    }
    
    return ArcGISFeature(
      attributes: Map<String, dynamic>.from(json['attributes'] ?? {}),
      rings: rings,
    );
  }
}

class ArcGISLayerInfo {
  final int id;
  final String name;
  final String? geometryType;

  ArcGISLayerInfo({required this.id, required this.name, this.geometryType});

  factory ArcGISLayerInfo.fromJson(Map<String, dynamic> json) {
    return ArcGISLayerInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      geometryType: json['geometryType'],
    );
  }
}

class ArcGISApi {
  final String baseUrl;

  ArcGISApi({required this.baseUrl});

  /// Get layer info from FeatureServer
  Future<ArcGISLayerInfo> getLayerInfo(String layerUrl) async {
    try {
      final url = '$layerUrl?f=json';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ArcGISLayerInfo.fromJson(data);
      }
      throw Exception('Failed to load layer info');
    } catch (e) {
      throw Exception('Error fetching layer info: $e');
    }
  }

  /// Query features from ArcGIS FeatureServer
  /// Returns all features or filtered by where clause
  Future<List<ArcGISFeature>> queryFeatures({
    required String layerUrl,
    String where = '1=1',
    List<String> outFields = const ['*'],
    bool returnGeometry = true,
    int maxRecords = 1000,
  }) async {
    try {
      final params = {
        'where': where,
        'outFields': outFields.join(','),
        'returnGeometry': returnGeometry.toString(),
        'f': 'json',
        'resultRecordCount': maxRecords.toString(),
      };
      
      final uri = Uri.parse('$layerUrl/query').replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null) {
          return (data['features'] as List)
              .map((f) => ArcGISFeature.fromJson(f))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error querying features: $e');
      return [];
    }
  }

  /// Get sidebar layers from your Django API
  Future<List<Map<String, dynamic>>> getSidebarLayers(String apiUrl) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/show-geoportal-sidebar-map/'),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      print('Error fetching sidebar layers: $e');
      return [];
    }
  }
}