import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../constants/constant.dart';
import '../../services/download_service.dart';

const LatLng _bdCenter = LatLng(23.9836, 90.5837);
const double _bdZoom = 6.5;
const int _maxFeatureExport = 20000;

const List<Map<String, String>> _adminLevels = [
  {'value': '1', 'label': 'Division'},
  {'value': '2', 'label': 'District'},
  {'value': '3', 'label': 'City Corporations'},
  {'value': '4', 'label': 'Upazila'},
  {'value': '5', 'label': 'Municipality'},
  {'value': '6', 'label': 'Union'},
  {'value': '7', 'label': 'Mauza'},
  {'value': '8', 'label': 'Village'},
];

const Map<String, String> _levelToLayerId = {
  '1': 'division',
  '2': 'district',
  '3': 'city_corporation',
  '4': 'upazila',
  '5': 'municipality',
  '6': 'union',
  '7': 'mauza',
  '8': 'village',
};

const Map<String, Color> _highlightFill = {
  'division': Color(0x1F3B82F6),
  'district': Color(0x2410B981),
  'cityCorporation': Color(0x26F59E0B),
  'upazila': Color(0x21EF4444),
  'municipality': Color(0x24A855F7),
  'union': Color(0x2614B8A6),
  'mauza': Color(0x29F97316),
  'village': Color(0x2EEC4899),
};
const Map<String, Color> _highlightLine = {
  'division': Color(0xE62563EB),
  'district': Color(0xE6059069),
  'cityCorporation': Color(0xE6D97706),
  'upazila': Color(0xE6B91C1C),
  'municipality': Color(0xE67E22CE),
  'union': Color(0xE60F766E),
  'mauza': Color(0xE6C2410C),
  'village': Color(0xE69D174D),
};

const List<Map<String, String>> _basemaps = [
  {
    'key': 'topo',
    'label': 'Topo Map',
    'url':
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
  },
  {
    'key': 'osm',
    'label': 'Street Map',
    'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  },
  {
    'key': 'satellite',
    'label': 'Satellite',
    'url':
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  },
];

class _ExcelColumn {
  final String header;
  final List<String> keys;
  final List<String> geoKeys;
  final int? suffixLength;
  final int minLevel;
  final bool isCode;

  const _ExcelColumn({
    required this.header,
    required this.keys,
    this.geoKeys = const [],
    this.suffixLength,
    required this.minLevel,
    this.isCode = false,
  });
}

const List<_ExcelColumn> _excelColumns = [
  _ExcelColumn(
    header: 'Division Name',
    keys: ['division_name', 'division_name_en', 'div_name', 'div_name_en'],
    minLevel: 1,
  ),
  _ExcelColumn(
    header: 'Division Code',
    keys: ['division_code', 'div_code'],
    geoKeys: ['division_geo_code', 'div_geo_code'],
    suffixLength: 2,
    minLevel: 1,
    isCode: true,
  ),
  _ExcelColumn(
    header: 'District Name',
    keys: ['district_name', 'district_name_en', 'dist_name', 'dist_name_en'],
    minLevel: 2,
  ),
  _ExcelColumn(
    header: 'District Code',
    keys: ['district_code', 'dist_code'],
    geoKeys: ['district_geo_code', 'dist_geo_code'],
    suffixLength: 2,
    minLevel: 2,
    isCode: true,
  ),
  _ExcelColumn(
    header: 'City Corporation Name',
    keys: [
      'city_name',
      'city_name_en',
      'city_corporation_name',
      'city_corporation_name_en',
      'citycorp_name',
    ],
    minLevel: 3,
  ),
  _ExcelColumn(
    header: 'City Corporation Code',
    keys: ['city_code', 'city_corporation_code', 'citycorp_code'],
    geoKeys: ['city_geo_code', 'city_corporation_geo_code'],
    suffixLength: 2,
    minLevel: 3,
    isCode: true,
  ),
  _ExcelColumn(
    header: 'Upazila/Thana Name',
    keys: [
      'upazila_thana_name',
      'upazila_thana_name_en',
      'upazila_name',
      'upazila_name_en',
      'thana_name',
    ],
    minLevel: 4,
  ),
  _ExcelColumn(
    header: 'Upazila/Thana Code',
    keys: ['upazila_thana_code', 'upazila_code', 'thana_code'],
    geoKeys: ['upazila_thana_geo_code', 'upazila_geo_code', 'thana_geo_code'],
    suffixLength: 2,
    minLevel: 4,
    isCode: true,
  ),
  _ExcelColumn(
    header: 'Municipality Name',
    keys: [
      'municipality_name',
      'municipality_name_en',
      'pourashava_name',
      'pourashava_name_en',
    ],
    minLevel: 5,
  ),
  _ExcelColumn(
    header: 'Municipality Code',
    keys: ['municipality_code', 'pourashava_code'],
    geoKeys: ['municipality_geo_code', 'pourashava_geo_code'],
    suffixLength: 2,
    minLevel: 5,
    isCode: true,
  ),
  _ExcelColumn(
    header: 'Union/Ward Name',
    keys: [
      'union_ward_name',
      'union_ward_name_en',
      'union_name',
      'union_name_en',
      'ward_name',
    ],
    minLevel: 6,
  ),
  _ExcelColumn(
    header: 'Union/Ward Code',
    keys: ['union_ward_code', 'union_code', 'ward_code', 'uni_code'],
    geoKeys: [
      'union_ward_geo_code',
      'union_geo_code',
      'ward_geo_code',
      'uni_geo_code',
    ],
    suffixLength: 3,
    minLevel: 6,
    isCode: true,
  ),
  _ExcelColumn(
    header: 'Mauza Name',
    keys: [
      'mauza_name',
      'mauza_name_en',
      'mouza_name',
      'mouza_name_en',
      'muz_name',
    ],
    minLevel: 7,
  ),
  _ExcelColumn(
    header: 'Mauza Code',
    keys: ['mauza_code', 'mouza_code', 'muz_code'],
    geoKeys: ['mauza_geo_code', 'mouza_geo_code', 'muz_geo_code'],
    suffixLength: 3,
    minLevel: 7,
    isCode: true,
  ),
  _ExcelColumn(
    header: 'Village Name',
    keys: ['village_name', 'village_name_en', 'vilg_name', 'vilg_name_en'],
    minLevel: 8,
  ),
  _ExcelColumn(
    header: 'Village Code',
    keys: ['village_code', 'vilg_code'],
    geoKeys: ['village_geo_code', 'vilg_geo_code'],
    suffixLength: 3,
    minLevel: 8,
    isCode: true,
  ),
];

String _layerIdForLevel(String levelValue) =>
    _levelToLayerId[levelValue] ?? levelValue;

String _escapeSql(String value) => value.replaceAll("'", "''");

String _clean(dynamic v) {
  if (v == null) return '';
  return v.toString().trim();
}

String _attr(Map<String, dynamic> attrs, List<String> keys) {
  if (keys.isEmpty) return '';
  final lower = <String, dynamic>{};
  attrs.forEach((k, v) => lower[k.toLowerCase()] = v);
  for (final key in keys) {
    if (attrs.containsKey(key)) {
      final v = attrs[key];
      return v == null ? '' : v.toString();
    }
    final lk = key.toLowerCase();
    if (lower.containsKey(lk)) {
      final v = lower[lk];
      return v == null ? '' : v.toString();
    }
  }
  return '';
}

bool _isOtherArea(Map<String, dynamic>? option) {
  if (option == null) return false;
  final flag = option['is_other_area'] == true || option['isOtherArea'] == true;
  final value = _clean(option['value'] ?? option['code'] ?? option['geo_code']);
  final name = _clean(option['name'] ?? option['label']).toLowerCase();
  return flag ||
      (value == '00') ||
      (value.isNotEmpty &&
          value.length >= 2 &&
          value.endsWith('00') &&
          name.contains('other'));
}

class GeocodeDownloadPage extends StatefulWidget {
  const GeocodeDownloadPage({super.key});

  @override
  State<GeocodeDownloadPage> createState() => _GeocodeDownloadPageState();
}

class _GeocodeDownloadPageState extends State<GeocodeDownloadPage> {
  final MapController _mapController = MapController();

  String _levelValue = '1';
  bool _layerConfigLoaded = false;
  Map<String, String> _layerUrls = {};
  Map<String, String> _layerTitles = {};

  List<Map<String, dynamic>> _divisions = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _cityCorporations = [];
  List<Map<String, dynamic>> _upazilas = [];
  List<Map<String, dynamic>> _municipalities = [];
  List<Map<String, dynamic>> _unions = [];
  List<Map<String, dynamic>> _mauzas = [];
  List<Map<String, dynamic>> _villages = [];

  Map<String, dynamic>? _selDivision;
  Map<String, dynamic>? _selDistrict;
  Map<String, dynamic>? _selCityCorp;
  Map<String, dynamic>? _selUpazila;
  Map<String, dynamic>? _selMunicipality;
  Map<String, dynamic>? _selUnion;
  Map<String, dynamic>? _selMauza;
  Map<String, dynamic>? _selVillage;

  bool _loadingUpazila = false;
  bool _downloadLoading = false;
  bool _mapLoading = false;
  int _featureCount = 0;
  String? _error;

  String _basemapKey = 'topo';
  bool _basemapMenuOpen = false;
  bool _filterPanelOpen = true;
  bool _showCoords = false;
  LatLng? _cursorLatLng;

  List<List<LatLng>> _highlightPolygons = [];
  String _symbolKeyForHighlight = 'division';

  int get _levelNumber => int.tryParse(_levelValue) ?? 1;

  bool get _showDivision => _levelNumber >= 1;
  bool get _showDistrict => _levelNumber >= 2;
  bool get _showCity => _levelNumber >= 3;
  bool get _showUpazila => _levelNumber >= 4;
  bool get _showMunicipality => _levelNumber >= 5;
  bool get _showUnion => _levelNumber >= 6;
  bool get _showMauza => _levelNumber >= 7;
  bool get _showVillage => _levelNumber == 8;

  String get _layerUrl {
    final id = _layerIdForLevel(_levelValue);
    return _layerUrls[id] ?? _layerUrls[_levelValue] ?? '';
  }

  String get _layerTitle {
    final id = _layerIdForLevel(_levelValue);
    return _layerTitles[id] ??
        _layerTitles[_levelValue] ??
        '${id.replaceAll('_', ' ')} Boundary';
  }

  String get _levelLabel {
    for (final row in _adminLevels) {
      if (row['value'] == _levelValue) return row['label']!;
    }
    return 'Division';
  }

  // ── Dedupe helper (by stable key) ────────────────────────────────────────

  List<Map<String, dynamic>> _dedupe(
    List<Map<String, dynamic>> list,
    String keyField,
  ) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final m in list) {
      final k = _clean(m[keyField]);
      if (k.isEmpty) {
        out.add(m); // keep entries with empty key but don't dedupe on them
        continue;
      }
      if (seen.add(k)) out.add(m);
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _fetchLayerConfig();
    _fetchDivisions();
  }

  Uri _api(String path, [Map<String, String>? q]) {
    final base = '${AppConstants.myAPILink}$path';
    return q == null || q.isEmpty
        ? Uri.parse(base)
        : Uri.parse(base).replace(queryParameters: q);
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, [
    Map<String, String>? q,
  ]) async {
    final resp = await http
        .get(_api(path, q), headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} on $path');
    }
    final decoded = jsonDecode(resp.body);
    if (decoded is List) {
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return const [];
  }

  Future<void> _fetchLayerConfig() async {
    setState(() => _layerConfigLoaded = false);
    try {
      final resp = await http
          .get(
            _api('/api/admin-boundary-layers/'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      final data = jsonDecode(resp.body);

      final urls = <String, String>{};
      final titles = <String, String>{};

      void apply(String layerId, String url, String title) {
        if (layerId.isEmpty || url.isEmpty) return;
        urls[layerId] = url;
        titles[layerId] = title.isEmpty
            ? '${layerId.replaceAll('_', ' ')} Boundary'
            : title;
        _levelToLayerId.forEach((level, mapped) {
          if (mapped == layerId) {
            urls[level] = url;
            titles[level] = titles[layerId]!;
          }
        });
      }

      if (data is Map) {
        final layerUrls = data['layer_urls'];
        final layerTitles = data['layer_titles'];
        if (layerUrls is Map) {
          layerUrls.forEach((k, v) {
            final title = (layerTitles is Map)
                ? (layerTitles[k] ?? '').toString()
                : '';
            apply(k.toString(), v.toString(), title);
          });
        }
        final rows = data['layers'];
        if (rows is List) {
          for (final r in rows) {
            if (r is Map) {
              apply(
                _clean(r['layer_id']),
                _clean(r['layer_url']),
                _clean(r['layer_display_name']),
              );
            }
          }
        }
      } else if (data is List) {
        for (final r in data) {
          if (r is Map) {
            apply(
              _clean(r['layer_id']),
              _clean(r['layer_url']),
              _clean(r['layer_display_name']),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _layerUrls = urls;
        _layerTitles = titles;
        _layerConfigLoaded = true;
        if (urls.isEmpty) {
          _error = 'No map layer URL found from tbl_admin_boundary_map_layer.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _layerConfigLoaded = true;
        _layerUrls = {};
        _layerTitles = {};
        _error = 'Failed to load map layer URLs from database.';
      });
    }
  }

  Future<void> _fetchDivisions({String search = ''}) async {
    try {
      final data = await _getList('/api/get_divisions_geocode_filter/', {
        'search': search,
      });
      if (!mounted) return;
      setState(() {
        _divisions = _dedupe(
          data
              .map(
                (item) => <String, dynamic>{
                  'id': item['division_id'],
                  'value': _clean(item['division_code']),
                  'label':
                      '${_clean(item['division_name'])} (${_clean(item['division_geo_code'])})',
                  'name': _clean(item['division_name']),
                  'geo_code': _clean(item['division_geo_code']),
                },
              )
              .toList(),
          'geo_code',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load divisions.');
    }
  }

  Future<void> _fetchDistricts(String divisionGeo, {String search = ''}) async {
    try {
      final data = await _getList('/api/get_districts_geocode_filter/', {
        'division_geo_code': divisionGeo,
        'search': search,
      });
      if (!mounted) return;
      setState(() {
        _districts = _dedupe(
          data
              .map(
                (item) => <String, dynamic>{
                  'id': item['district_id'],
                  'value': _clean(item['district_code']),
                  'label':
                      '${_clean(item['district_name'])} (${_clean(item['district_code'])})',
                  'name': _clean(item['district_name']),
                  'geo_code': _clean(item['district_geo_code']),
                  'division_geo_code': divisionGeo,
                },
              )
              .toList(),
          'geo_code',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load districts.');
    }
  }

  Future<void> _fetchCityCorporations(
    String districtGeo, {
    String search = '',
  }) async {
    try {
      final data = await _getList('/api/get_citycorporations_geocode_filter/', {
        'district_geo_code': districtGeo,
        'search': search,
        'include_other_area': 'true',
      });
      if (!mounted) return;
      setState(() {
        _cityCorporations = _dedupe(
          data.map((item) {
            final geo = _clean(
              item['city_geo_code'] ?? item['city_corporation_geo_code'],
            );
            final isOther = item['is_other_area'] == true;
            return <String, dynamic>{
              'id': item['city_id'] ?? item['city_corporation_id'],
              'value': _clean(
                item['city_code'] ?? item['city_corporation_code'],
              ),
              'label':
                  '${_clean(item['city_name'] ?? item['city_corporation_name'])} ($geo)',
              'name': _clean(
                item['city_name'] ?? item['city_corporation_name'],
              ),
              'geo_code': geo,
              'is_other_area': isOther,
              'district_geo_code': districtGeo,
            };
          }).toList(),
          'geo_code',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load city corporations.');
    }
  }

  Future<void> _fetchUpazilas(String districtGeo, {String search = ''}) async {
    try {
      final data = await _getList('/api/get_upazilas_geocode_filter/', {
        'district_geo_code': districtGeo,
        'search': search,
      });
      if (!mounted) return;
      setState(() {
        _upazilas = _dedupe(
          data
              .map(
                (item) => <String, dynamic>{
                  'id': item['upazila_id'],
                  'value': _clean(item['upazila_code']),
                  'label':
                      '${_clean(item['upazila_name'])} (${_clean(item['upazila_code'])})',
                  'name': _clean(item['upazila_name']),
                  'geo_code': _clean(item['upazila_geo_code']),
                  'district_geo_code': districtGeo,
                  'is_city_corporation': item['is_city_corporation'],
                },
              )
              .toList(),
          'geo_code',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load upazilas.');
    }
  }

  Future<void> _fetchUpazilasByCity(
    String cityGeo,
    String districtGeo, {
    String search = '',
  }) async {
    final isOther =
        cityGeo == '00' || (cityGeo.length == 6 && cityGeo.endsWith('00'));
    final params = <String, String>{'search': search};
    if (isOther) {
      params['district_geo_code'] = districtGeo.isNotEmpty
          ? districtGeo
          : cityGeo.substring(0, 4);
      params['city_geo_code'] = cityGeo;
      params['other_area'] = 'city_corporation';
    } else {
      params['city_geo_code'] = cityGeo;
    }
    try {
      final data = await _getList('/api/get_upazilas_geocode_filter/', params);
      if (!mounted) return;
      setState(() {
        _upazilas = _dedupe(
          data
              .map(
                (item) => <String, dynamic>{
                  'id': item['upazila_id'],
                  'value': _clean(item['upazila_code']),
                  'label':
                      '${_clean(item['upazila_name'])} (${_clean(item['upazila_code'])})',
                  'name': _clean(item['upazila_name']),
                  'geo_code': _clean(item['upazila_geo_code']),
                  'district_geo_code': districtGeo,
                  'is_city_corporation': item['is_city_corporation'],
                },
              )
              .toList(),
          'geo_code',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load upazilas.');
    }
  }

  Future<void> _fetchMunicipalities(
    String upazilaGeo, {
    String search = '',
  }) async {
    try {
      final data = await _getList('/api/get_municipalities_geocode_filter/', {
        'upazila_geo_code': upazilaGeo,
        'search': search,
        'include_other_area': 'true',
      });
      if (!mounted) return;
      setState(() {
        _municipalities = _dedupe(
          data.map((item) {
            final geo = _clean(item['municipality_geo_code']);
            return <String, dynamic>{
              'id': item['municipality_id'],
              'value': _clean(item['municipality_code']),
              'label':
                  '${_clean(item['municipality_name'])} (${_clean(item['municipality_code'])})',
              'name': _clean(item['municipality_name']),
              'geo_code': geo,
              'is_other_area': item['is_other_area'] == true,
              'upazila_geo_code': upazilaGeo,
            };
          }).toList(),
          'geo_code',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load municipalities.');
    }
  }

  Future<void> _fetchUnions(String upazilaGeo, {String search = ''}) async {
    try {
      final data = await _getList('/api/get_unions_geocode_filter/', {
        'upazila_geo_code': upazilaGeo,
        'search': search,
      });
      if (!mounted) return;
      setState(() {
        _unions = _dedupe(
          data
              .map(
                (item) => <String, dynamic>{
                  'id': item['union_id'],
                  'value': _clean(item['union_code'] ?? item['uni_code']),
                  'label':
                      '${_clean(item['union_name'] ?? item['uni_name'])} (${_clean(item['union_code'] ?? item['uni_code'])})',
                  'name': _clean(item['union_name'] ?? item['uni_name']),
                  'geo_code': _clean(
                    item['union_geo_code'] ?? item['uni_geo_code'],
                  ),
                  'upazila_geo_code': upazilaGeo,
                  'is_municipality': item['is_municipality'],
                },
              )
              .toList(),
          'geo_code',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load unions.');
    }
  }

  Future<void> _fetchUnionsByMunicipality(
    String municipalityGeo,
    String upazilaGeo, {
    String search = '',
  }) async {
    final isOther =
        municipalityGeo == '00' ||
        (municipalityGeo.length == 10 && municipalityGeo.endsWith('00'));
    final params = <String, String>{'search': search};
    if (isOther) {
      params['upazila_geo_code'] = upazilaGeo.isNotEmpty
          ? upazilaGeo
          : municipalityGeo.substring(0, 8);
      params['municipality_geo_code'] = municipalityGeo;
      params['other_area'] = 'municipality';
    } else {
      params['municipality_geo_code'] = municipalityGeo;
    }
    try {
      final data = await _getList('/api/get_unions_geocode_filter/', params);
      if (!mounted) return;
      setState(() {
        _unions = _dedupe(
          data
              .map(
                (item) => <String, dynamic>{
                  'id': item['union_id'],
                  'value': _clean(item['union_code'] ?? item['uni_code']),
                  'label':
                      '${_clean(item['union_name'] ?? item['uni_name'])} (${_clean(item['union_code'] ?? item['uni_code'])})',
                  'name': _clean(item['union_name'] ?? item['uni_name']),
                  'geo_code': _clean(
                    item['union_geo_code'] ?? item['uni_geo_code'],
                  ),
                  'upazila_geo_code': upazilaGeo,
                },
              )
              .toList(),
          'geo_code',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load unions.');
    }
  }

  Future<void> _fetchMauzas(String unionGeo, {String search = ''}) async {
    try {
      final data = await _getList('/api/get_mauzas_geocode_filter/', {
        'union_geo_code': unionGeo,
        'search': search,
      });
      if (!mounted) return;
      setState(() {
        _mauzas = _dedupe(
          data
              .map(
                (item) => <String, dynamic>{
                  'id': item['mauza_id'] ?? item['muz_id'],
                  'value': _clean(item['mauza_code'] ?? item['muz_code']),
                  'label':
                      '${_clean(item['mauza_name'] ?? item['muz_name'])} (${_clean(item['mauza_code'] ?? item['muz_code'])})',
                  'name': _clean(item['mauza_name'] ?? item['muz_name']),
                  'geo_code': _clean(
                    item['mauza_geo_code'] ?? item['muz_geo_code'],
                  ),
                  'union_geo_code': unionGeo,
                },
              )
              .toList(),
          'geo_code',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load mauzas.');
    }
  }

  Future<void> _fetchVillages(String mauzaGeo, {String search = ''}) async {
    try {
      final data = await _getList('/api/get_villages_geocode_filter/', {
        'mauza_geo_code': mauzaGeo,
        'search': search,
      });
      if (!mounted) return;
      setState(() {
        _villages = _dedupe(
          data
              .map(
                (item) => <String, dynamic>{
                  'id': item['village_id'] ?? item['vilg_id'],
                  'value': _clean(item['village_code'] ?? item['vilg_code']),
                  'label':
                      '${_clean(item['village_name'] ?? item['vilg_name'])} (${_clean(item['village_code'] ?? item['vilg_code'])})',
                  'name': _clean(item['village_name'] ?? item['vilg_name']),
                  'geo_code': _clean(
                    item['village_geo_code'] ?? item['vilg_geo_code'],
                  ),
                  'mauza_geo_code': mauzaGeo,
                },
              )
              .toList(),
          'geo_code',
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load villages.');
    }
  }

  void _clearBelow(int fromLevel) {
    if (fromLevel <= 1) {
      _selDivision = null;
    }
    if (fromLevel <= 2) {
      _selDistrict = null;
      _districts = [];
    }
    if (fromLevel <= 3) {
      _selCityCorp = null;
      _cityCorporations = [];
    }
    if (fromLevel <= 4) {
      _selUpazila = null;
      _upazilas = [];
    }
    if (fromLevel <= 5) {
      _selMunicipality = null;
      _municipalities = [];
    }
    if (fromLevel <= 6) {
      _selUnion = null;
      _unions = [];
    }
    if (fromLevel <= 7) {
      _selMauza = null;
      _mauzas = [];
    }
    if (fromLevel <= 8) {
      _selVillage = null;
      _villages = [];
    }
  }

  Future<void> _onLevelChanged(String? value) async {
    if (value == null || value == _levelValue) return;
    setState(() {
      _levelValue = value;
      _clearBelow(1);
      _featureCount = 0;
      _highlightPolygons = [];
      _error = null;
    });
    await _fetchDivisions();
  }

  Future<void> _onDivisionChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selDivision = option;
      _clearBelow(2);
      _highlightPolygons = [];
      _featureCount = 0;
    });
    if (option == null) {
      _mapController.move(_bdCenter, _bdZoom);
      return;
    }
    final geo = _clean(option['geo_code']);
    if (geo.isNotEmpty) {
      await _fetchDistricts(geo);
      await _applyFilter('division_geo_code', geo, 'division');
    }
  }

  Future<void> _onDistrictChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selDistrict = option;
      _clearBelow(3);
      _highlightPolygons = [];
      _featureCount = 0;
    });
    if (option == null) {
      if (_selDivision != null) {
        await _applyFilter(
          'division_geo_code',
          _clean(_selDivision!['geo_code']),
          'division',
        );
      }
      return;
    }
    final geo = _clean(option['geo_code']);
    if (geo.isNotEmpty) {
      await Future.wait([_fetchCityCorporations(geo), _fetchUpazilas(geo)]);
      await _applyFilter('district_geo_code', geo, 'district');
    }
  }

  Future<void> _onCityCorpChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selCityCorp = option;
      _clearBelow(4);
      _highlightPolygons = [];
      _featureCount = 0;
    });
    if (option == null) {
      if (_selDistrict != null) {
        await _applyFilter(
          'district_geo_code',
          _clean(_selDistrict!['geo_code']),
          'district',
        );
      }
      return;
    }
    final geo = _clean(option['geo_code']);
    final parentDistrict = _clean(
      _selDistrict?['geo_code'] ?? option['district_geo_code'],
    );
    if (geo.isEmpty) return;

    setState(() => _loadingUpazila = true);
    await _fetchUpazilasByCity(geo, parentDistrict);
    if (mounted) setState(() => _loadingUpazila = false);

    if (_isOtherArea(option)) {
      if (parentDistrict.isNotEmpty) {
        await _applyFilter('district_geo_code', parentDistrict, 'district');
      }
    } else {
      await _applyFilter('city_geo_code', geo, 'cityCorporation');
    }
  }

  Future<void> _onUpazilaChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selUpazila = option;
      _clearBelow(5);
      _highlightPolygons = [];
      _featureCount = 0;
    });
    if (option == null) {
      if (_selCityCorp != null && !_isOtherArea(_selCityCorp)) {
        await _applyFilter(
          'city_geo_code',
          _clean(_selCityCorp!['geo_code']),
          'cityCorporation',
        );
      } else if (_selDistrict != null) {
        await _applyFilter(
          'district_geo_code',
          _clean(_selDistrict!['geo_code']),
          'district',
        );
      }
      return;
    }
    final geo = _clean(option['geo_code']);
    if (geo.isEmpty) return;
    await Future.wait([_fetchMunicipalities(geo), _fetchUnions(geo)]);
    await _applyFilter('upazila_thana_geo_code', geo, 'upazila');
  }

  Future<void> _onMunicipalityChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selMunicipality = option;
      _clearBelow(6);
      _highlightPolygons = [];
      _featureCount = 0;
    });
    if (option == null) {
      if (_selUpazila != null) {
        await _applyFilter(
          'upazila_thana_geo_code',
          _clean(_selUpazila!['geo_code']),
          'upazila',
        );
      }
      return;
    }
    final geo = _clean(option['geo_code']);
    final parentUpazila = _clean(
      _selUpazila?['geo_code'] ?? option['upazila_geo_code'],
    );
    if (geo.isEmpty) return;
    await _fetchUnionsByMunicipality(geo, parentUpazila);
    if (_isOtherArea(option)) {
      if (parentUpazila.isNotEmpty) {
        await _applyFilter('upazila_thana_geo_code', parentUpazila, 'upazila');
      }
    } else {
      await _applyFilter('municipality_geo_code', geo, 'municipality');
    }
  }

  Future<void> _onUnionChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selUnion = option;
      _clearBelow(7);
      _highlightPolygons = [];
      _featureCount = 0;
    });
    if (option == null) {
      if (_selMunicipality != null && !_isOtherArea(_selMunicipality)) {
        await _applyFilter(
          'municipality_geo_code',
          _clean(_selMunicipality!['geo_code']),
          'municipality',
        );
      } else if (_selUpazila != null) {
        await _applyFilter(
          'upazila_thana_geo_code',
          _clean(_selUpazila!['geo_code']),
          'upazila',
        );
      }
      return;
    }
    final geo = _clean(option['geo_code']);
    if (geo.isEmpty) return;
    await _fetchMauzas(geo);
    await _applyFilter('union_ward_geo_code', geo, 'union');
  }

  Future<void> _onMauzaChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selMauza = option;
      _clearBelow(8);
      _highlightPolygons = [];
      _featureCount = 0;
    });
    if (option == null) {
      if (_selUnion != null) {
        await _applyFilter(
          'union_ward_geo_code',
          _clean(_selUnion!['geo_code']),
          'union',
        );
      }
      return;
    }
    final geo = _clean(option['geo_code']);
    if (geo.isEmpty) return;
    await _fetchVillages(geo);
    await _applyFilter('mauza_geo_code', geo, 'mauza');
  }

  Future<void> _onVillageChanged(Map<String, dynamic>? option) async {
    setState(() {
      _selVillage = option;
      _highlightPolygons = [];
      _featureCount = 0;
    });
    if (option == null) {
      if (_selMauza != null) {
        await _applyFilter(
          'mauza_geo_code',
          _clean(_selMauza!['geo_code']),
          'mauza',
        );
      }
      return;
    }
    final geo = _clean(option['geo_code']);
    if (geo.isEmpty) return;
    await _applyFilter('village_geo_code', geo, 'village');
  }

  (String, String) get _currentWhere {
    if (_selVillage != null && _clean(_selVillage!['geo_code']).isNotEmpty) {
      return (
        "village_geo_code = '${_escapeSql(_clean(_selVillage!['geo_code']))}'",
        'village',
      );
    }
    if (_selMauza != null && _clean(_selMauza!['geo_code']).isNotEmpty) {
      return (
        "mauza_geo_code = '${_escapeSql(_clean(_selMauza!['geo_code']))}'",
        'mauza',
      );
    }
    if (_selUnion != null && _clean(_selUnion!['geo_code']).isNotEmpty) {
      return (
        "union_ward_geo_code = '${_escapeSql(_clean(_selUnion!['geo_code']))}'",
        'union',
      );
    }
    if (_selMunicipality != null &&
        !_isOtherArea(_selMunicipality) &&
        _clean(_selMunicipality!['geo_code']).isNotEmpty) {
      return (
        "municipality_geo_code = '${_escapeSql(_clean(_selMunicipality!['geo_code']))}'",
        'municipality',
      );
    }
    if (_selUpazila != null && _clean(_selUpazila!['geo_code']).isNotEmpty) {
      return (
        "upazila_thana_geo_code = '${_escapeSql(_clean(_selUpazila!['geo_code']))}'",
        'upazila',
      );
    }
    if (_selCityCorp != null &&
        !_isOtherArea(_selCityCorp) &&
        _clean(_selCityCorp!['geo_code']).isNotEmpty) {
      return (
        "city_geo_code = '${_escapeSql(_clean(_selCityCorp!['geo_code']))}'",
        'cityCorporation',
      );
    }
    if (_selDistrict != null && _clean(_selDistrict!['geo_code']).isNotEmpty) {
      return (
        "district_geo_code = '${_escapeSql(_clean(_selDistrict!['geo_code']))}'",
        'district',
      );
    }
    if (_selDivision != null && _clean(_selDivision!['geo_code']).isNotEmpty) {
      return (
        "division_geo_code = '${_escapeSql(_clean(_selDivision!['geo_code']))}'",
        'division',
      );
    }
    return ('1=1', _layerIdForLevel(_levelValue));
  }

  Future<void> _applyFilter(String field, String code, String symbolKey) async {
    await _refreshHighlight(field, code, symbolKey);
  }

  Uri _arcgisQueryUrl(String layerUrl) {
    final base = layerUrl.endsWith('/query') ? layerUrl : '$layerUrl/query';
    return Uri.parse(base);
  }

  Future<Map<String, dynamic>> _arcgisPost(
    String layerUrl,
    Map<String, String> body,
  ) async {
    final resp = await http
        .post(
          _arcgisQueryUrl(layerUrl),
          headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        )
        .timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw Exception('ArcGIS HTTP ${resp.statusCode}');
    }
    final decoded = jsonDecode(resp.body);
    if (decoded is! Map) {
      throw Exception('ArcGIS returned non-object.');
    }
    if (decoded['error'] != null) {
      final err = decoded['error'];
      final msg = err is Map ? (err['message'] ?? 'ArcGIS error') : err;
      throw Exception('ArcGIS: $msg');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<List<Map<String, dynamic>>> _queryFeatureAttributes(
    String layerUrl,
    String where,
  ) async {
    final attrs = <Map<String, dynamic>>[];

    final idResp = await _arcgisPost(layerUrl, {
      'f': 'json',
      'where': where,
      'returnIdsOnly': 'true',
    });
    final ids = (idResp['objectIds'] as List?)?.cast<num>() ?? const [];

    if (ids.isEmpty) return attrs;

    const chunkSize = 1000;
    for (int i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(
        i,
        (i + chunkSize > ids.length) ? ids.length : i + chunkSize,
      );
      final resp = await _arcgisPost(layerUrl, {
        'f': 'json',
        'objectIds': chunk.join(','),
        'outFields': '*',
        'returnGeometry': 'false',
      });
      final features = (resp['features'] as List?) ?? const [];
      for (final f in features) {
        if (f is Map && f['attributes'] is Map) {
          attrs.add(Map<String, dynamic>.from(f['attributes'] as Map));
        }
      }
      if (attrs.length > _maxFeatureExport + 1) {
        throw Exception(
          'Too many features (over $_maxFeatureExport). Please filter further before downloading.',
        );
      }
    }
    return attrs;
  }

  Future<List<List<LatLng>>> _queryFeaturePolygons(
    String layerUrl,
    String where,
  ) async {
    final resp = await _arcgisPost(layerUrl, {
      'f': 'json',
      'where': where,
      'outFields': 'OBJECTID',
      'returnGeometry': 'true',
      'outSR': '4326',
      'resultRecordCount': '500',
    });
    final features = (resp['features'] as List?) ?? const [];
    final polygons = <List<LatLng>>[];
    for (final f in features) {
      if (f is! Map) continue;
      final geom = f['geometry'];
      if (geom is! Map) continue;
      for (final ring in (geom['rings'] as List?) ?? const []) {
        final path = <LatLng>[];
        for (final pt in ring as List) {
          if (pt is List && pt.length >= 2) {
            final x = (pt[0] as num).toDouble();
            final y = (pt[1] as num).toDouble();
            path.add(LatLng(y, x));
          }
        }
        if (path.length >= 3) polygons.add(path);
      }
    }
    return polygons;
  }

  Future<void> _refreshHighlight(
    String field,
    String code,
    String symbolKey,
  ) async {
    final url = _layerUrl;
    if (url.isEmpty) return;
    final where = "$field = '${_escapeSql(code)}'";
    setState(() {
      _mapLoading = true;
      _error = null;
    });
    try {
      final countResp = await _arcgisPost(url, {
        'f': 'json',
        'where': where,
        'returnCountOnly': 'true',
      });
      final count = (countResp['count'] as num?)?.toInt() ?? 0;

      final polygons = await _queryFeaturePolygons(url, where);

      if (!mounted) return;
      setState(() {
        _featureCount = count;
        _highlightPolygons = polygons;
        _mapLoading = false;
        _symbolKeyForHighlight = symbolKey;
      });

      if (polygons.isNotEmpty) {
        double minLat = polygons.first.first.latitude;
        double maxLat = polygons.first.first.latitude;
        double minLon = polygons.first.first.longitude;
        double maxLon = polygons.first.first.longitude;
        for (final ring in polygons) {
          for (final pt in ring) {
            if (pt.latitude < minLat) minLat = pt.latitude;
            if (pt.latitude > maxLat) maxLat = pt.latitude;
            if (pt.longitude < minLon) minLon = pt.longitude;
            if (pt.longitude > maxLon) maxLon = pt.longitude;
          }
        }
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds(
              LatLng(minLat, minLon),
              LatLng(maxLat, maxLon),
            ),
            padding: const EdgeInsets.all(60),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mapLoading = false;
        _error = 'Failed to load boundary on map: $e';
      });
    }
  }

  Future<void> _resetAll() async {
    setState(() {
      // Data
      _selDivision = null;
      _selDistrict = null;
      _selCityCorp = null;
      _selUpazila = null;
      _selMunicipality = null;
      _selUnion = null;
      _selMauza = null;
      _selVillage = null;
      _districts = [];
      _cityCorporations = [];
      _upazilas = [];
      _municipalities = [];
      _unions = [];
      _mauzas = [];
      _villages = [];
      _highlightPolygons = [];
      _featureCount = 0;
      _error = null;

      // UI — restore the floating panel to its open state
      _filterPanelOpen = true;
      _basemapMenuOpen = false;
      _showCoords = false;
      _cursorLatLng = null;
    });
    _mapController.move(_bdCenter, _bdZoom);
    await _fetchDivisions();
  }

  Future<void> _fullExtent() async {
    _mapController.move(_bdCenter, _bdZoom);
  }

  Future<void> _downloadExcel() async {
    final url = _layerUrl;
    if (url.isEmpty) {
      setState(() => _error = 'No layer URL configured for this level.');
      return;
    }
    setState(() {
      _downloadLoading = true;
      _error = null;
    });

    try {
      final (where, _) = _currentWhere;
      final attrs = await _queryFeatureAttributes(url, where);

      if (attrs.isEmpty) {
        throw Exception('No features found for the current filter.');
      }
      if (attrs.length > _maxFeatureExport) {
        throw Exception(
          'Too many features (${attrs.length}). Please filter further before downloading.',
        );
      }

      final exportLevel = _levelNumber;
      final columns = _excelColumns
          .where((c) => c.minLevel <= exportLevel)
          .toList();

      final headers = <String>['Serial No', ...columns.map((c) => c.header)];
      final rows = <List<String>>[];

      for (int i = 0; i < attrs.length; i++) {
        final a = attrs[i];
        final row = <String>['${i + 1}'];
        for (final col in columns) {
          var value = _attr(a, col.keys);
          if (col.isCode &&
              value.isEmpty &&
              col.geoKeys.isNotEmpty &&
              col.suffixLength != null) {
            final geo = _attr(a, col.geoKeys);
            if (geo.isNotEmpty && geo.length >= col.suffixLength!) {
              value = geo.substring(geo.length - col.suffixLength!);
            }
          }
          row.add(value);
        }
        rows.add(row);
      }

      final codeColumns = <int>{};
      for (int i = 0; i < columns.length; i++) {
        if (columns[i].isCode) {
          codeColumns.add(i + 1);
        }
      }

      final fileName = _buildFileName();

      await DownloadService.downloadGeocodeExcel(
        sheetName: _levelLabel,
        headers: headers,
        rows: rows,
        codeColumns: codeColumns,
        fileName: fileName,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _downloadLoading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _downloadLoading = false);
  }

  String _buildFileName() {
    final layerId = _layerIdForLevel(_levelValue);
    final code = _clean(_selVillage?['geo_code']).isNotEmpty
        ? _clean(_selVillage!['geo_code'])
        : _clean(_selMauza?['geo_code']).isNotEmpty
        ? _clean(_selMauza!['geo_code'])
        : _clean(_selUnion?['geo_code']).isNotEmpty
        ? _clean(_selUnion!['geo_code'])
        : (_selMunicipality != null &&
              !_isOtherArea(_selMunicipality) &&
              _clean(_selMunicipality!['geo_code']).isNotEmpty)
        ? _clean(_selMunicipality!['geo_code'])
        : _clean(_selUpazila?['geo_code']).isNotEmpty
        ? _clean(_selUpazila!['geo_code'])
        : (_selCityCorp != null &&
              !_isOtherArea(_selCityCorp) &&
              _clean(_selCityCorp!['geo_code']).isNotEmpty)
        ? _clean(_selCityCorp!['geo_code'])
        : _clean(_selDistrict?['geo_code']).isNotEmpty
        ? _clean(_selDistrict!['geo_code'])
        : _clean(_selDivision?['geo_code']).isNotEmpty
        ? _clean(_selDivision!['geo_code'])
        : 'all';
    final safeCode = code.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'geocode_${layerId}_${safeCode}_$stamp.xlsx';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(child: _buildMapPanel()),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          Positioned(
            top: 76,
            right: 16,
            child: _buildFloatingFilterPanel(context),
          ),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE60F172A), Color(0x000F172A)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.map, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Geocode Download',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Bangladesh Administrative Boundary',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _layerConfigLoaded
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_layerConfigLoaded
                                    ? const Color(0xFF22C55E)
                                    : const Color(0xFFF59E0B))
                                .withOpacity(0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _layerConfigLoaded ? 'Layers ready' : 'Loading layers…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating filter panel (AnimatedSize + ClipRRect = no overflow) ────────

  Widget _buildFloatingFilterPanel(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height - 120;
    final panelWidth = MediaQuery.of(context).size.width < 600 ? 270.0 : 300.0;
    const collapsedWidth = 48.0;

    return Material(
      elevation: 14,
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      child: Container(
        width: _filterPanelOpen ? panelWidth : collapsedWidth,
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPanelHeader(),
                if (_filterPanelOpen)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                      child: _buildPanelBody(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: _filterPanelOpen
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ClipRect(
                child: Row(
                  children: [
                    _headerIconButton(
                      icon: Icons.close,
                      tooltip: 'Hide filters',
                      onTap: () => setState(() => _filterPanelOpen = false),
                    ),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Text(
                        'Boundary Filters',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_featureCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: _headerIconButton(
                icon: Icons.tune,
                tooltip: 'Show filters',
                onTap: () => setState(() => _filterPanelOpen = true),
              ),
            ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    );
  }

  Widget _buildPanelBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _levelDropdown(),
        const SizedBox(height: 6),
        if (_showDivision)
          _filterDropdown(
            label: 'Division',
            icon: Icons.public,
            value: _selDivision,
            options: _divisions,
            onChanged: _onDivisionChanged,
          ),
        if (_showDistrict)
          _filterDropdown(
            label: 'District',
            icon: Icons.map,
            value: _selDistrict,
            options: _districts,
            enabled: _selDivision != null,
            placeholder: _selDivision != null
                ? 'Select District…'
                : 'Select division first',
            onChanged: _onDistrictChanged,
          ),
        if (_showCity)
          _filterDropdown(
            label: 'City Corporation',
            icon: Icons.location_city,
            value: _selCityCorp,
            options: _cityCorporations,
            enabled: _selDistrict != null,
            placeholder: _selDistrict != null
                ? 'Select City Corporation…'
                : 'Select district first',
            onChanged: _onCityCorpChanged,
          ),
        if (_showUpazila)
          _filterDropdown(
            label: 'Upazila',
            icon: Icons.apartment,
            value: _selUpazila,
            options: _upazilas,
            enabled: _selDistrict != null,
            loading: _loadingUpazila,
            placeholder: _selDistrict != null
                ? 'Select Upazila…'
                : 'Select district first',
            onChanged: _onUpazilaChanged,
          ),
        if (_showMunicipality)
          _filterDropdown(
            label: 'Municipality',
            icon: Icons.home_work,
            value: _selMunicipality,
            options: _municipalities,
            enabled: _selUpazila != null,
            placeholder: _selUpazila != null
                ? 'Select Municipality…'
                : 'Select upazila first',
            onChanged: _onMunicipalityChanged,
          ),
        if (_showUnion)
          _filterDropdown(
            label: 'Union',
            icon: Icons.layers,
            value: _selUnion,
            options: _unions,
            enabled: _selUpazila != null,
            placeholder: _selUpazila != null
                ? 'Select Union…'
                : 'Select upazila first',
            onChanged: _onUnionChanged,
          ),
        if (_showMauza)
          _filterDropdown(
            label: 'Mauza',
            icon: Icons.terrain,
            value: _selMauza,
            options: _mauzas,
            enabled: _selUnion != null,
            placeholder: _selUnion != null
                ? 'Select Mauza…'
                : 'Select union first',
            onChanged: _onMauzaChanged,
          ),
        if (_showVillage)
          _filterDropdown(
            label: 'Village',
            icon: Icons.home_work_outlined,
            value: _selVillage,
            options: _villages,
            enabled: _selMauza != null,
            placeholder: _selMauza != null
                ? 'Select Village…'
                : 'Select mauza first',
            onChanged: _onVillageChanged,
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetAll,
                icon: const Icon(Icons.restart_alt, size: 13),
                label: const Text('Reset', style: TextStyle(fontSize: 10.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  minimumSize: const Size(0, 32),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    (_downloadLoading ||
                        !_layerConfigLoaded ||
                        _featureCount == 0)
                    ? null
                    : _downloadExcel,
                icon: _downloadLoading
                    ? const SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_download, size: 13),
                label: const Text('Excel', style: TextStyle(fontSize: 10.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: const Color(0xFFFCA5A5)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFDC2626),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Level selector ────────────────────────────────────────────────────────

  Widget _levelDropdown() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0x292563EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.apartment, size: 10, color: Color(0xFF2563EB)),
              SizedBox(width: 3),
              Expanded(
                child: Text(
                  'ADMINISTRATIVE LEVEL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              value: _levelValue,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0x292563EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0x292563EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                ),
              ),
              items: _adminLevels
                  .map(
                    (row) => DropdownMenuItem<String>(
                      value: row['value'],
                      child: Text(
                        row['label']!,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _onLevelChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter card (stable-string-key DropdownButton) ───────────────────────

  Widget _filterDropdown({
    required String label,
    required IconData icon,
    required Map<String, dynamic>? value,
    required List<Map<String, dynamic>> options,
    required void Function(Map<String, dynamic>?) onChanged,
    bool enabled = true,
    bool loading = false,
    String? placeholder,
  }) {
    // Stable string key for a map option.
    String keyOf(Map<String, dynamic> m) {
      final v = _clean(m['value']);
      if (v.isNotEmpty) return 'v:$v';
      final g = _clean(m['geo_code']);
      if (g.isNotEmpty) return 'g:$g';
      return 'i:${m['id']}';
    }

    // Build deduped key -> option map (first occurrence wins).
    final seenKeys = <String>{};
    final itemKeys = <String>[];
    final keyToOption = <String, Map<String, dynamic>>{};
    for (final opt in options) {
      final k = keyOf(opt);
      if (seenKeys.add(k)) {
        itemKeys.add(k);
        keyToOption[k] = opt;
      }
    }

    // Resolve current value to a key that definitely exists in items.
    String? currentKey;
    if (value != null) {
      final k = keyOf(value);
      if (keyToOption.containsKey(k)) currentKey = k;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: value != null
              ? const Color(0x0F2563EB)
              : const Color(0xFFFBFDFF),
          border: Border.all(
            color: value != null
                ? const Color(0x382563EB)
                : const Color(0x331E293B),
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: value != null
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    icon,
                    size: 8.5,
                    color: value != null
                        ? Colors.white
                        : const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: value != null
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF64748B),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 9,
                    height: 9,
                    child: CircularProgressIndicator(strokeWidth: 1.3),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentKey,
                  isExpanded: true,
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0F172A),
                  ),
                  hint: Text(
                    placeholder ?? 'Select…',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  items: itemKeys
                      .map(
                        (k) => DropdownMenuItem<String>(
                          value: k,
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              (keyToOption[k]!['label'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: enabled && !loading
                      ? (k) {
                          if (k == null) {
                            onChanged(null);
                          } else {
                            onChanged(keyToOption[k]);
                          }
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Map panel with professional UI ────────────────────────────────────────

  Widget _buildMapPanel() {
    final fill =
        _highlightFill[_symbolKeyForHighlight] ?? _highlightFill['division']!;
    final line =
        _highlightLine[_symbolKeyForHighlight] ?? _highlightLine['division']!;

    final tileUrl = _basemaps.firstWhere(
      (b) => b['key'] == _basemapKey,
      orElse: () => _basemaps.first,
    )['url']!;

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _bdCenter,
              initialZoom: _bdZoom,
              minZoom: 4,
              maxZoom: 18,
              onPositionChanged: (camera, hasGesture) {
                if (_showCoords) {
                  setState(() => _cursorLatLng = camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.example.bgisp',
                retinaMode: MediaQuery.of(context).devicePixelRatio > 1.5,
              ),
              if (_highlightPolygons.isNotEmpty)
                PolygonLayer(
                  polygons: _highlightPolygons
                      .map(
                        (ring) => Polygon(
                          points: ring,
                          color: fill,
                          borderColor: line,
                          borderStrokeWidth: 1.8,
                        ),
                      )
                      .toList(),
                ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution(
                    'Esri, OpenStreetMap contributors',
                    prependCopyright: true,
                  ),
                ],
              ),
            ],
          ),
        ),

        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC0F172A), Color(0x000F172A)],
                ),
              ),
            ),
          ),
        ),

        Positioned(left: 16, bottom: 90, child: _zoomControls()),

        Positioned(left: 16, bottom: 16, child: _basemapSwitcher()),

        if (_basemapMenuOpen)
          Positioned(left: 16, bottom: 70, child: _basemapMenu()),

        Positioned(
          right: 16,
          bottom: 90,
          child: _mapButton(
            icon: Icons.fullscreen,
            tooltip: 'Full extent',
            onTap: _fullExtent,
          ),
        ),

        Positioned(right: 16, bottom: 16, child: _featureInfoPill(line)),

        if (_showCoords && _cursorLatLng != null)
          Positioned(top: 76, left: 16, child: _coordsPill(_cursorLatLng!)),

        Positioned(
          top: 76,
          left: 16,
          child: _mapButton(
            icon: _showCoords ? Icons.my_location : Icons.location_searching,
            tooltip: _showCoords ? 'Hide coordinates' : 'Show coordinates',
            active: _showCoords,
            onTap: () => setState(() => _showCoords = !_showCoords),
          ),
        ),

        if (_mapLoading)
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Color(0x330F172A),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Zoom controls ─────────────────────────────────────────────────────────

  Widget _zoomControls() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _zoomButton(
            icon: Icons.add,
            tooltip: 'Zoom in',
            onTap: () {
              final z = _mapController.camera.zoom + 1;
              _mapController.move(_mapController.camera.center, z);
            },
          ),
          Container(height: 1, width: 34, color: const Color(0xFFE2E8F0)),
          _zoomButton(
            icon: Icons.remove,
            tooltip: 'Zoom out',
            onTap: () {
              final z = _mapController.camera.zoom - 1;
              _mapController.move(_mapController.camera.center, z);
            },
          ),
        ],
      ),
    );
  }

  Widget _zoomButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 18, color: const Color(0xFF334155)),
        ),
      ),
    );
  }

  // ── Basemap switcher ──────────────────────────────────────────────────────

  Widget _basemapSwitcher() {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: InkWell(
        onTap: () => setState(() => _basemapMenuOpen = !_basemapMenuOpen),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.layers, size: 16, color: Color(0xFF334155)),
              const SizedBox(width: 6),
              Text(
                _basemaps.firstWhere(
                  (b) => b['key'] == _basemapKey,
                  orElse: () => _basemaps.first,
                )['label']!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _basemapMenuOpen ? Icons.expand_more : Icons.expand_less,
                size: 14,
                color: const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _basemapMenu() {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _basemaps
              .map(
                (b) => InkWell(
                  onTap: () {
                    setState(() {
                      _basemapKey = b['key']!;
                      _basemapMenuOpen = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    color: _basemapKey == b['key']
                        ? const Color(0xFFEFF6FF)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          Icons.layers,
                          size: 14,
                          color: _basemapKey == b['key']
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          b['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _basemapKey == b['key']
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // ── Feature info pill ─────────────────────────────────────────────────────

  Widget _featureInfoPill(Color line) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: line, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              _levelLabel,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 12, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 8),
            Text(
              '${_featureCount.toString()} features',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Coordinates pill ──────────────────────────────────────────────────────

  Widget _coordsPill(LatLng ll) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.my_location, size: 12, color: Color(0xFF2563EB)),
            const SizedBox(width: 6),
            Text(
              '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Circular map button ───────────────────────────────────────────────────

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? const Color(0xFF2563EB) : Colors.white,
        shape: const CircleBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(
              icon,
              size: 18,
              color: active ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
