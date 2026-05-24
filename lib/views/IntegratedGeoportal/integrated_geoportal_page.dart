import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import '../../constants/constant.dart';

class GeoportalMapPage extends StatefulWidget {
  const GeoportalMapPage({super.key});

  @override
  State<GeoportalMapPage> createState() => _GeoportalMapPageState();
}

class _GeoportalMapPageState extends State<GeoportalMapPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) async {
            if (mounted) setState(() => _isLoading = false);
            // Inject layer data after page loads
            await _injectLayerData();
          },
          onWebResourceError: (error) {
            if (mounted && error.errorCode != 0 && error.errorCode != 102) {
              setState(() {
                _error = error.description;
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://ims.cegisbd.com:8092/map_view_mobile_app'),
      );
  }

  Future<void> _injectLayerData() async {
    try {
      // Fetch both APIs in parallel
      final results = await Future.wait([
        _fetchApi('${AppConstants.myAPILink}/api/show-geoportal-sidebar-map/'),
        _fetchApi('${AppConstants.myAPILink}/api/layers/'),
      ]);

      final sidebarLayers = results[0] ?? [];
      final adminLayers = results[1] ?? [];

      // Remove duplicates from sidebar layers
      final seen = <String>{};
      final uniqueSidebar = sidebarLayers.where((item) {
        final id = item['layer_id']?.toString() ?? '';
        if (seen.contains(id)) return false;
        seen.add(id);
        return true;
      }).toList();

      // Transform admin layers
      final transformedAdmin = adminLayers.map((layer) {
        String fieldName = 'name';
        String fieldCode = 'code';
        final layerId = layer['layer_id']?.toString().toLowerCase() ?? '';

        if (layerId.contains('district')) {
          fieldName = 'district_name';
          fieldCode = 'district_code';
        } else if (layerId.contains('upazil')) {
          fieldName = 'upazila_name';
          fieldCode = 'upazila_code';
        } else if (layerId.contains('union')) {
          fieldName = 'union_name';
          fieldCode = 'union_code';
        } else if (layerId.contains('mouza') || layerId.contains('mauza')) {
          fieldName = 'mauza_name';
          fieldCode = 'mauza_code';
        }

        return {
          'layer_id': layer['layer_id'] ?? '',
          'name': layer['name'] ?? layer['layer_id'] ?? 'Unknown',
          'url': layer['url'] ?? '',
          'fieldName': fieldName,
          'fieldCode': fieldCode,
        };
      }).toList();

      // Inject JavaScript to set up the map with layers
      final jsCode =
          '''
        (function() {
          // Store layer data
          window.SIDEBAR_LAYERS = ${jsonEncode(uniqueSidebar)};
          window.ADMIN_LAYERS = ${jsonEncode(transformedAdmin)};
          
          // Initialize map if ArcGIS is loaded
          if (typeof require !== 'undefined') {
            initMapWithLayers();
          } else {
            // Wait for ArcGIS to load
            var checkInterval = setInterval(function() {
              if (typeof require !== 'undefined') {
                clearInterval(checkInterval);
                initMapWithLayers();
              }
            }, 100);
          }
          
          function initMapWithLayers() {
            require([
              "esri/Map",
              "esri/views/MapView",
              "esri/layers/FeatureLayer",
              "esri/widgets/Legend",
              "esri/widgets/Search",
              "esri/widgets/Expand"
            ], function(Map, MapView, FeatureLayer, Legend, Search, Expand) {
              
              // Only initialize if map doesn't exist
              if (window._mapInitialized) return;
              window._mapInitialized = true;
              
              var map = new Map({
                basemap: "topo-vector"
              });
              
              var view = new MapView({
                container: "viewDiv",
                map: map,
                center: [90.3563, 23.6850],
                zoom: 6,
                ui: { components: ["zoom"] }
              });
              
              // Legend
              var legend = new Legend({
                view: view,
                container: "legendContainer"
              });
              window._legend = legend;
              
              // Search widget
              var searchWidget = new Search({
                view: view,
                allPlaceholder: "Search locations...",
                includeDefaultSources: true
              });
              
              var searchExpand = new Expand({
                view: view,
                content: searchWidget,
                expandTooltip: "Search",
                expanded: false
              });
              view.ui.add(searchExpand, { position: "top-right", index: 0 });
              
              // Store references
              window._map = map;
              window._view = view;
              window._currentLayer = null;
              window._layerObjects = {};
              window._activeAdminLayerId = 'division';
              window._activeBasemapName = 'Topographic';
              
              // Refresh legend helper
              window._refreshLegend = function() {
                if (window._legend) {
                  window._legend.view = view;
                  setTimeout(function() { window._legend.refresh(); }, 300);
                }
              };
              
              // Update indicator
              window._updateIndicator = function() {
                var layerName = window._currentLayer ? window._currentLayer.title : 'Division';
                var el = document.getElementById('layerIndicator');
                if (el) el.innerText = 'Active: ' + layerName + ' | ' + window._activeBasemapName;
              };
              
              // Build basemap menu
              var basemaps = [
                { id: "topo-vector", name: "Topographic" },
                { id: "streets-vector", name: "Streets" },
                { id: "satellite", name: "Satellite" },
                { id: "hybrid", name: "Hybrid" },
                { id: "dark-gray-vector", name: "Dark Gray" },
                { id: "gray-vector", name: "Light Gray" },
                { id: "osm", name: "OpenStreetMap" }
              ];
              
              var bmHtml = '<div class="dropdown-header">Base Maps</div>';
              basemaps.forEach(function(bm) {
                bmHtml += '<div class="dropdown-item" onclick="window._changeBasemap(\\'' + bm.id + '\\', \\'' + bm.name + '\\')">' + bm.name + '</div>';
              });
              document.getElementById('basemapDropdown').innerHTML = bmHtml;
              
              window._changeBasemap = function(id, name) {
                map.basemap = id;
                window._activeBasemapName = name;
                window._updateIndicator();
                document.getElementById('basemapDropdown').classList.remove('show');
              };
              
              // Build admin layers menu
              var adminLayers = [{
                id: "division",
                name: "Division",
                url: "https://www.arcgisbd.com/server/rest/services/BBS009/geo_division_boundary_aam/FeatureServer",
                fieldName: "division_name",
                fieldCode: "division_code"
              }];
              
              if (window.ADMIN_LAYERS && window.ADMIN_LAYERS.length) {
                window.ADMIN_LAYERS.forEach(function(l) {
                  if (l.layer_id !== 'division') {
                    adminLayers.push(l);
                  }
                });
              }
              
              window._adminLayers = adminLayers;
              
              function buildAdminMenu() {
                var html = '<div class="dropdown-header">Admin Layers (' + adminLayers.length + ')</div>';
                adminLayers.forEach(function(layer) {
                  var activeClass = (layer.id === window._activeAdminLayerId) ? ' active' : '';
                  html += '<div class="dropdown-item' + activeClass + '" onclick="window._loadAdminLayer(\\'' + layer.id + '\\', \\'' + layer.url.replace(/'/g, "\\\\'") + '\\', \\'' + layer.fieldName + '\\', \\'' + layer.fieldCode + '\\', \\'' + layer.name.replace(/'/g, "\\\\'") + '\\')">' + layer.name + '</div>';
                });
                document.getElementById('layerDropdown').innerHTML = html;
              }
              
              window._loadAdminLayer = function(layerId, url, fieldName, fieldCode, name) {
                if (window._currentLayer) {
                  map.remove(window._currentLayer);
                }
                
                var popupTemplate = {
                  title: name,
                  content: [{
                    type: "fields",
                    fieldInfos: [
                      { fieldName: fieldName, label: name + " Name" },
                      { fieldName: fieldCode, label: name + " Code" }
                    ]
                  }]
                };
                
                var fl = new FeatureLayer({
                  url: url,
                  title: name,
                  outFields: ["*"],
                  visible: true,
                  popupTemplate: popupTemplate
                });
                
                map.add(fl);
                window._currentLayer = fl;
                window._activeAdminLayerId = layerId;
                window._updateIndicator();
                window._refreshLegend();
                buildAdminMenu();
                document.getElementById('layerDropdown').classList.remove('show');
              };
              
              buildAdminMenu();
              
              // Build data layers menu
              function buildDataMenu() {
                var html = '<div class="dropdown-header">Data Layers (' + window.SIDEBAR_LAYERS.length + ')</div>';
                if (!window.SIDEBAR_LAYERS.length) {
                  html += '<div style="padding:10px 16px;color:#666;font-size:12px;">No data layers available</div>';
                } else {
                  window.SIDEBAR_LAYERS.forEach(function(layer) {
                    var checked = window._layerObjects[layer.layer_id] ? ' checked' : '';
                    html += '<label class="layer-toggle"><input type="checkbox"' + checked + ' onchange="window._toggleDataLayer(\\'' + layer.layer_id + '\\', \\'' + (layer.url || '').replace(/'/g, "\\\\'") + '\\', \\'' + (layer.name || layer.layer_id).replace(/'/g, "\\\\'") + '\\', this.checked)">' + (layer.name || layer.layer_id) + '</label>';
                  });
                }
                document.getElementById('dataLayerDropdown').innerHTML = html;
                
                // Update badge
                var count = Object.keys(window._layerObjects).length;
                var btn = document.getElementById('btnDataLayers');
                if (count > 0) {
                  btn.setAttribute('data-count', count);
                  btn.classList.add('badge');
                } else {
                  btn.removeAttribute('data-count');
                  btn.classList.remove('badge');
                }
              }
              
              window._toggleDataLayer = function(layerId, url, name, show) {
                if (show) {
                  if (window._layerObjects[layerId]) {
                    window._layerObjects[layerId].visible = true;
                  } else {
                    var fl = new FeatureLayer({
                      url: url,
                      title: name || layerId,
                      outFields: ["*"],
                      visible: true,
                      popupTemplate: {
                        title: name || layerId,
                        content: [{ type: "fields", fieldInfos: [{ fieldName: "*", label: "Information" }] }]
                      }
                    });
                    map.add(fl);
                    window._layerObjects[layerId] = fl;
                  }
                } else {
                  if (window._layerObjects[layerId]) {
                    map.remove(window._layerObjects[layerId]);
                    delete window._layerObjects[layerId];
                  }
                }
                window._refreshLegend();
                buildDataMenu();
              };
              
              buildDataMenu();
              
              // Toggle functions
              window._toggleLegend = function() {
                var container = document.getElementById('legendContainer');
                var btn = document.getElementById('btnLegend');
                container.classList.toggle('hidden');
                btn.classList.toggle('active');
              };
              
              window._toggleDropdown = function(id) {
                var dropdown = document.getElementById(id);
                var isShowing = dropdown.classList.contains('show');
                document.querySelectorAll('.dropdown').forEach(function(d) { d.classList.remove('show'); });
                if (!isShowing) dropdown.classList.add('show');
              };
              
              window._fullExtent = function() {
                view.goTo({ center: [90.3563, 23.6850], zoom: 6 }, { duration: 1500, easing: "ease-in-out" });
              };
              
              // Close dropdowns on map click
              view.on("click", function() {
                document.querySelectorAll('.dropdown').forEach(function(d) { d.classList.remove('show'); });
              });
              
              // Load default layer
              view.when(function() {
                document.getElementById('loader').style.display = 'none';
                window._loadAdminLayer('division', 'https://www.arcgisbd.com/server/rest/services/BBS009/geo_division_boundary_aam/FeatureServer', 'division_name', 'division_code', 'Division');
              });
              
              console.log('✅ Map initialized with ' + adminLayers.length + ' admin layers and ' + window.SIDEBAR_LAYERS.length + ' data layers');
            });
          }
        })();
      ''';

      await _controller?.runJavaScript(jsCode);
    } catch (e) {
      print('Error injecting layer data: $e');
    }
  }

  Future<List<dynamic>?> _fetchApi(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        print('⚠️ API returned ${response.statusCode}: $url');
        return [];
      }
    } catch (e) {
      print('⚠️ API error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Integrated Geoportal',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                        });
                        _initWebView();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_controller != null)
            WebViewWidget(controller: _controller!),

          if (_isLoading)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF1353A3)),
                    SizedBox(height: 12),
                    Text(
                      'Loading Map...',
                      style: TextStyle(
                        color: Color(0xFF1353A3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
