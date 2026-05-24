import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/constant.dart';
import '../../models/DataViewer/data_viewer.dart';
import 'data_detail_page.dart';

class DataViewerPage extends StatefulWidget {
  final String? organizationId;
  final String? thematicAreaId;
  final String? thematicAreaName;

  const DataViewerPage({
    super.key,
    this.organizationId,
    this.thematicAreaId,
    this.thematicAreaName,
  });

  @override
  State<DataViewerPage> createState() => _DataViewerPageState();
}

class _DataViewerPageState extends State<DataViewerPage> {
  List<Map<String, dynamic>> _thematicAreas = [];
  List<DataRecord> _data = [];
  List<DataRecord> _filteredData = [];
  int? _selectedThematicId;
  String _selectedThematicName = '';
  bool _isLoadingAreas = true;
  bool _isLoadingData = false;
  String? _error;
  String _searchTerm = '';
  int _currentPage = 0;
  final int _rowsPerPage = 12;

  @override
  void initState() {
    super.initState();
    if (widget.thematicAreaId != null) {
      _selectedThematicId = int.tryParse(widget.thematicAreaId!);
      _selectedThematicName = widget.thematicAreaName ?? '';
    }
    _loadThematicAreas();
  }

  Future<void> _loadThematicAreas() async {
    try {
      const url = '${AppConstants.myAPILink}/api/data/thematic-areas/';
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
            if (_selectedThematicId != null) _loadData();
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
    });
    _loadData();
  }

  void _goBackToThematicAreas() {
    setState(() {
      _selectedThematicId = null;
      _selectedThematicName = '';
      _data = [];
      _filteredData = [];
    });
  }

  Future<void> _loadData() async {
    if (_selectedThematicId == null) return;
    setState(() => _isLoadingData = true);
    try {
      final apiUrl =
          '${AppConstants.myAPILink}/api/data/thematic-area/$_selectedThematicId/';
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final List<dynamic> dataList = result['data'] ?? [];
          final list = dataList
              .map(
                (item) => DataRecord.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
          if (mounted) {
            setState(() {
              _data = list;
              _filteredData = list;
              _isLoadingData = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingData = false;
        });
      }
    }
  }

  void _applySearch() {
    setState(() {
      _filteredData = _data.where((item) {
        if (_searchTerm.isNotEmpty &&
            !'${item.contributor} ${item.title} ${item.dataType}'
                .toLowerCase()
                .contains(_searchTerm.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();
      _currentPage = 0;
    });
  }

  int get _totalPages => (_filteredData.length / _rowsPerPage).ceil();
  List<DataRecord> get _currentPageData {
    final start = _currentPage * _rowsPerPage;
    return _filteredData.sublist(
      start,
      start + _rowsPerPage > _filteredData.length
          ? _filteredData.length
          : start + _rowsPerPage,
    );
  }

  Color _getColor(String name) {
    const c = {
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
    return c[name] ?? const Color(0xFF64748b);
  }

  IconData _getIcon(String name) {
    const i = {
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
    return i[name] ?? Icons.folder;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 768;
    return Scaffold(
      backgroundColor: const Color(0xFFeef2f7),
      appBar: AppBar(
        leading: _selectedThematicId != null && widget.thematicAreaId == null
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
          _selectedThematicName.isNotEmpty
              ? _selectedThematicName
              : 'Data Viewer',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoadingAreas
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFe67e22)),
            )
          : _selectedThematicId == null
          ? _buildThematicAreasView(isWide)
          : _buildRecordsPanel(),
    );
  }

  Widget _buildThematicAreasView(bool isWide) {
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
                    Icon(Icons.storage, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Data Viewer',
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
                            '${area['data_count']} records',
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

  Widget _buildRecordsPanel() {
    final color = _getColor(_selectedThematicName);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 30)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.08), Colors.white],
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
                            '${_filteredData.length} records',
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
                      ),
                      child: Text(
                        '${_filteredData.length}',
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
                    hintText: '🔍 Search...',
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: color, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    isDense: true,
                    suffixIcon: _searchTerm.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              setState(() => _searchTerm = '');
                              _applySearch();
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) {
                    setState(() => _searchTerm = v);
                    _applySearch();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingData
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFe67e22)),
                  )
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _filteredData.isEmpty
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
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentPageData.length,
                    itemBuilder: (context, index) =>
                        _buildDataRecordCard(_currentPageData[index]),
                  ),
          ),
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
                    'Prev',
                    _currentPage > 0,
                    () => setState(() => _currentPage--),
                    color,
                  ),
                  const SizedBox(width: 4),
                  ...List.generate(_totalPages.clamp(0, 5), (i) {
                    final p = _getPageNum(i);
                    if (p <= _totalPages && p > 0) {
                      return _buildPageNumBtn(p, color);
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(width: 4),
                  _buildPageBtn(
                    'Next',
                    _currentPage < _totalPages - 1,
                    () => setState(() => _currentPage++),
                    color,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataRecordCard(DataRecord item) {
    final color = _getColor(_selectedThematicName);
    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DataDetailPage(dataRecord: item),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insert_drive_file,
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
                      item.title ?? 'Untitled',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1a1a2e),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.contributor != null)
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 12,
                            color: color.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.contributor!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
              const SizedBox(width: 8),
              Column(
                children: [
                  if (item.dataType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.dataType!,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.arrow_circle_right,
                    size: 22,
                    color: color.withOpacity(0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    String text,
    bool enabled,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey[400],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumBtn(int page, Color color) {
    final isActive = _currentPage + 1 == page;
    return GestureDetector(
      onTap: () => setState(() => _currentPage = page - 1),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isActive ? color : Colors.grey[200]!),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
