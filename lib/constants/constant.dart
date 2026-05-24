import 'dart:ui';

class AppConstants {
  static const String myAPILink = 'https://ims.cegisbd.com:8091';
  static const String appName = 'Bangladesh GIS Platform';
  static const String appShortName = 'BGISP';

  static const Color primaryColor = Color(0xFF008080);
  static const Color secondaryColor = Color(0xFF2c3e50);
  static const Color accentColor = Color(0xFFe67e22);
  static const Color dangerColor = Color(0xFFe74c3c);
}

class ApiEndpoints {
  static const String thematicAreas = '/api/map_data/thematic-areas/';
  static const String metadata = '/api/get_metadata/';
  static const String dataView = '/api/data/view/';
  static const String trackVisit = '/api/track-visit/';
  static const String visitorCount = '/api/visitor-count/';
}
