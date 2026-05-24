import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/constant.dart';
import '../../models/Metadata/metadata.dart';
import 'metadata_detail_page.dart';

class MetadataViewerPage extends StatefulWidget {
  const MetadataViewerPage({super.key});

  @override
  State<MetadataViewerPage> createState() => _MetadataViewerPageState();
}

class _MetadataViewerPageState extends State<MetadataViewerPage> {
  List<Map<String, dynamic>> _thematicAreas = [];
  List<MetadataRecord> _metadataRecords = [];
  int? _selectedThematicId;
  String _selectedThematicName = '';
  bool _isLoadingAreas = true;
  bool _isLoadingMetadata = false;
  String _searchTerm = '';
  int _currentPage = 0;
  final int _rowsPerPage = 6;
  bool _showSidebar = true;

  @override
  void initState() {
    super.initState();
    _loadThematicAreas();
  }

  Future<void> _loadThematicAreas() async {
    try {
      const url = '${AppConstants.myAPILink}/api/metadata/thematic-areas/';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final areas = List<Map<String, dynamic>>.from(
            data['thematic_areas'] ?? [],
          );
          if (mounted) {
            setState(() {
              _thematicAreas = areas;
              _isLoadingAreas = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAreas = false);
    }
  }

  void _selectThematicArea(int id, String name) {
    setState(() {
      _selectedThematicId = id;
      _selectedThematicName = name;
      _currentPage = 0;
      _searchTerm = '';
      _showSidebar = false;
    });
    _loadMetadata(id);
  }

  Future<void> _loadMetadata(int thematicId) async {
    setState(() => _isLoadingMetadata = true);
    try {
      final url =
          '${AppConstants.myAPILink}/api/metadata/thematic-area/$thematicId/';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _metadataRecords = (data['metadata'] as List)
                  .map((m) => MetadataRecord.fromJson(m))
                  .toList();
              _isLoadingMetadata = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMetadata = false);
    }
  }

  void _goBackToThematicAreas() {
    setState(() {
      _selectedThematicId = null;
      _selectedThematicName = '';
      _metadataRecords = [];
      _showSidebar = true;
    });
  }

  List<MetadataRecord> get _filteredRecords {
    if (_searchTerm.isEmpty) return _metadataRecords;
    return _metadataRecords
        .where(
          (item) =>
              '${item.title} ${item.contributor} ${item.dataType} ${item.organizationName}'
                  .toLowerCase()
                  .contains(_searchTerm.toLowerCase()),
        )
        .toList();
  }

  int get _totalPages => (_filteredRecords.length / _rowsPerPage).ceil();
  List<MetadataRecord> get _currentPageData {
    final start = _currentPage * _rowsPerPage;
    final filtered = _filteredRecords;
    return filtered.sublist(
      start,
      start + _rowsPerPage > filtered.length
          ? filtered.length
          : start + _rowsPerPage,
    );
  }

  Color _getColor(String name) {
    const colors = {
      'Education': Color(0xFF6366f1),
      'Nutrition': Color(0xFFf59e0b),
      'Finance': Color(0xFF10b981),
      'Health': Color(0xFFef4444),
      'Agriculture': Color(0xFF84cc16),
      'Transport': Color(0xFF3b82f6),
      'Technology': Color(0xFF8b5cf6),
      'Society': Color(0xFFec4899),
      'Local Government': Color(0xFF14b8a6),
      'Environment': Color(0xFF22c55e),
      'Economy': Color(0xFF06b6d4),
      'Business': Color(0xFFf43f5e),
    };
    return colors[name] ?? const Color(0xFF64748b);
  }

  IconData _getIcon(String name) {
    const icons = {
      'Education': Icons.school,
      'Nutrition': Icons.restaurant,
      'Finance': Icons.attach_money,
      'Health': Icons.favorite,
      'Agriculture': Icons.agriculture,
      'Transport': Icons.directions_car,
      'Technology': Icons.computer,
      'Society': Icons.volunteer_activism,
      'Local Government': Icons.account_balance,
      'Environment': Icons.eco,
      'Economy': Icons.trending_up,
      'Business': Icons.store,
    };
    return icons[name] ?? Icons.folder;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;
    return Scaffold(
      backgroundColor: const Color(0xFFeef2f7),
      appBar: AppBar(
        leading: _selectedThematicId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToThematicAreas,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
        title: Text(
          _selectedThematicId != null ? _selectedThematicName : 'Metadata',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoadingAreas
          ? const Center(child: CircularProgressIndicator())
          : _selectedThematicId == null
          ? _buildThematicAreasFullScreen(isWide)
          : isWide
          ? _buildWideLayout()
          : _showSidebar
          ? _buildThematicAreasFullScreen(false)
          : _buildRecordsOnly(),
    );
  }

  Widget _buildThematicAreasFullScreen(bool isWide) {
    return Container(
      margin: isWide ? const EdgeInsets.all(20) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: isWide ? BorderRadius.circular(28) : null,
        boxShadow: isWide
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
              ),
              borderRadius: isWide
                  ? const BorderRadius.vertical(top: Radius.circular(28))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.layers, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Metadata',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${_thematicAreas.length} categories (Thematic Areas)',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _thematicAreas.length,
              itemBuilder: (context, index) {
                final area = _thematicAreas[index];
                final color = _getColor(area['thematic_area_name'] ?? '');
                return _buildThematicCard(area, color, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThematicCard(Map<String, dynamic> area, Color color, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _selectThematicArea(
            area['thematic_area_id'],
            area['thematic_area_name'] ?? '',
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _getIcon(area['thematic_area_name'] ?? ''),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area['thematic_area_name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1e293b),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${area['metadata_count']} records',
                            style: const TextStyle(
                              color: Color(0xFFe67e22),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${area['organization_count']} orgs',
                            style: const TextStyle(
                              color: Color(0xFF64748b),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF94a3b8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 320, child: _buildThematicAreasFullScreen(true)),
        Expanded(child: _buildRecordsPanel()),
      ],
    );
  }

  Widget _buildRecordsOnly() {
    return _buildRecordsPanel();
  }

  Widget _buildRecordsPanel() {
    final color = _getColor(_selectedThematicName);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.08), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(color: color.withOpacity(0.15)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIcon(_selectedThematicName),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedThematicName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1a1a2e),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_filteredRecords.length} records',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFe67e22), Color(0xFFf59e0b)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFe67e22).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${_filteredRecords.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: InputDecoration(
                    hintText: '🔍 Search metadata...',
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: color.withOpacity(0.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: color.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: color.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _searchTerm.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() {
                              _searchTerm = '';
                              _currentPage = 0;
                            }),
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() {
                    _searchTerm = v;
                    _currentPage = 0;
                  }),
                ),
              ],
            ),
          ),
          // Records Grid
          Expanded(
            child: _isLoadingMetadata
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No records found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600
                          ? 2
                          : 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: _currentPageData.length,
                    itemBuilder: (context, index) =>
                        _buildRecordCard(_currentPageData[index]),
                  ),
          ),
          // Pagination
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: color.withOpacity(0.2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageBtn(
                    Icons.chevron_left,
                    'Prev',
                    _currentPage > 0,
                    () => setState(() => _currentPage--),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(_totalPages.clamp(0, 5), (i) {
                    final page = _getPageNum(i);
                    if (page <= _totalPages && page > 0) {
                      return _buildPageNumBtn(page);
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(width: 8),
                  _buildPageBtn(
                    Icons.chevron_right,
                    'Next',
                    _currentPage < _totalPages - 1,
                    () => setState(() => _currentPage++),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int _getPageNum(int i) {
    if (_totalPages <= 5) return i + 1;
    if (_currentPage + 1 <= 3) return i + 1;
    if (_currentPage + 1 >= _totalPages - 2) return _totalPages - 4 + i;
    return _currentPage - 1 + i;
  }

  Widget _buildPageBtn(
    IconData icon,
    String text,
    bool enabled,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFFe2e8f0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon == Icons.chevron_left)
              Icon(
                icon,
                size: 14,
                color: enabled ? Colors.black87 : Colors.grey[400],
              ),
            Text(
              text,
              style: TextStyle(
                color: enabled ? Colors.black87 : Colors.grey[400],
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (icon == Icons.chevron_right)
              Icon(
                icon,
                size: 14,
                color: enabled ? Colors.black87 : Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageNumBtn(int page) {
    final isActive = _currentPage + 1 == page;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = page - 1),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFe67e22) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isActive ? const Color(0xFFe67e22) : const Color(0xFFe2e8f0),
          ),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard(MetadataRecord item) {
    final color = _getColor(_selectedThematicName);
    final gradientColors = [color, color.withOpacity(0.6)];
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title ?? 'Untitled Metadata',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1a1a2e),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          if (item.contributor != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: color.withOpacity(0.7),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    item.contributor!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    if (item.dataType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.15),
                              color.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.dataType!,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_circle_right,
                      size: 24,
                      color: color.withOpacity(0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Clickable overlay - Navigate to metadata details
          Material(
            color: Colors.transparent,
            child: InkWell(
              // In the InkWell onTap, change to:
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MetadataDetailPage(metadataId: item.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              splashColor: color.withOpacity(0.15),
              highlightColor: color.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }
}
