import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../constants/constant.dart';
import '../../../api/Organization/organization_api.dart';
import 'package:bgisp/models/ThematicArea/thematic_area.dart';
import '../../../providers/language_provider.dart';

class OrganizationDataTab extends StatefulWidget {
  final int organizationId;
  const OrganizationDataTab({super.key, required this.organizationId});

  @override
  State<OrganizationDataTab> createState() => _OrganizationDataTabState();
}

class _OrganizationDataTabState extends State<OrganizationDataTab> {
  final OrganizationApi _api = OrganizationApi();
  List<ThematicArea> _thematicAreas = [];
  bool _isLoading = true;

  int? _selectedThematicId;
  String _selectedThematicName = '';
  List<Map<String, dynamic>> _dataRecords = [];
  bool _isLoadingData = false;
  String _searchTerm = '';
  int _currentPage = 0;
  final int _rowsPerPage = 6;
  int? _downloadingId;

  @override
  void initState() {
    super.initState();
    _loadThematicAreas();
  }

  Future<void> _loadThematicAreas() async {
    setState(() => _isLoading = true);
    try {
      final areas = await _api.getThematicAreasWithData(widget.organizationId);
      if (mounted) {
        setState(() {
          _thematicAreas = areas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDataRecords(int thematicId, String thematicName) async {
    setState(() {
      _isLoadingData = true;
      _selectedThematicId = thematicId;
      _selectedThematicName = thematicName;
      _currentPage = 0;
      _searchTerm = '';
    });
    try {
      final url =
          '${AppConstants.myAPILink}/api/get_member_organizations/${widget.organizationId}/thematic-areas/$thematicId/data/';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true && result['data'] != null) {
          final List<Map<String, dynamic>> flatRecords = [];
          for (final group in result['data']) {
            final records = group['records'] as List<dynamic>?;
            if (records != null) {
              for (final record in records) {
                flatRecords.add(
                  Map<String, dynamic>.from({
                    ...record,
                    'contributor': group['contributor'],
                    'title': record['title'] ?? group['title'],
                    'data_type': group['data_type'],
                    'organization_name':
                        record['organization_name'] ??
                        group['organization_name'],
                  }),
                );
              }
            }
          }
          if (mounted) {
            setState(() {
              _dataRecords = flatRecords;
              _isLoadingData = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _goBackToThematicAreas() {
    setState(() {
      _selectedThematicId = null;
      _selectedThematicName = '';
      _dataRecords = [];
    });
  }

  Future<void> _downloadFile(Map<String, dynamic> record) async {
    setState(() => _downloadingId = record['id']);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading: ${record['title'] ?? 'file'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download failed'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _downloadingId = null);
    }
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_searchTerm.isEmpty) return _dataRecords;
    final q = _searchTerm.toLowerCase();
    return _dataRecords
        .where(
          (r) =>
              '${r['title']} ${r['organization_name']} ${r['data_type']} ${r['file_name']}'
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
  }

  int get _totalPages => (_filteredRecords.length / _rowsPerPage).ceil();

  List<Map<String, dynamic>> get _currentPageData {
    final start = _currentPage * _rowsPerPage;
    final end = start + _rowsPerPage;
    return _filteredRecords.sublist(
      start,
      end > _filteredRecords.length ? _filteredRecords.length : end,
    );
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

  Color _getTypeBadgeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'raster':
        return const Color(0xFF1d4ed8);
      case 'tabular':
        return const Color(0xFF15803d);
      case 'document':
        return const Color(0xFFa16207);
      case 'shape':
        return const Color(0xFFc2410c);
      case 'image':
        return const Color(0xFF7e22ce);
      default:
        return const Color(0xFF475569);
    }
  }

  Color _getTypeBadgeBg(String? type) {
    switch (type?.toLowerCase()) {
      case 'raster':
        return const Color(0xFFdbeafe);
      case 'tabular':
        return const Color(0xFFdcfce7);
      case 'document':
        return const Color(0xFFfef9c3);
      case 'shape':
        return const Color(0xFFffedd5);
      case 'image':
        return const Color(0xFFf3e8ff);
      default:
        return const Color(0xFFf1f5f9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBangla = langProvider.language == 'BN';

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF667eea),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading data categories...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_selectedThematicId != null) return _buildRecordsView();

    if (_thematicAreas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Data Available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'No data records yet.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: _thematicAreas.length,
      itemBuilder: (context, index) {
        final area = _thematicAreas[index];
        final hasData = area.dataCount > 0;
        final displayName = isBangla && area.nameBn != null
            ? area.nameBn!
            : area.name;
        return _buildCircularCard(
          icon: _getIcon(area.name),
          title: displayName,
          count: area.dataCount,
          hasData: hasData,
          onTap: hasData ? () => _loadDataRecords(area.id, area.name) : null,
        );
      },
    );
  }

  Widget _buildRecordsView() {
    final color = _getColor(_selectedThematicName);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: color.withOpacity(0.05),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: _goBackToThematicAreas,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _selectedThematicName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Text(
                '${_filteredRecords.length} records',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 20,
              ),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() {
                        _searchTerm = '';
                        _currentPage = 0;
                      }),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              isDense: true,
            ),
            onChanged: (v) => setState(() {
              _searchTerm = v;
              _currentPage = 0;
            }),
          ),
        ),
        Expanded(
          child: _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : _filteredRecords.isEmpty
              ? const Center(child: Text('No records found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _currentPageData.length,
                  itemBuilder: (context, index) =>
                      _buildFullWidthCard(_currentPageData[index], color),
                ),
        ),
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageBtn(
                  Icons.chevron_left,
                  _currentPage > 0,
                  () => setState(() => _currentPage--),
                  color,
                ),
                const SizedBox(width: 14),
                Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(width: 14),
                _buildPageBtn(
                  Icons.chevron_right,
                  _currentPage < _totalPages - 1,
                  () => setState(() => _currentPage++),
                  color,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFullWidthCard(Map<String, dynamic> record, Color color) {
    final tc = _getTypeBadgeColor(record['data_type']);
    final tb = _getTypeBadgeBg(record['data_type']);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.insert_drive_file,
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
                    record['title'] ?? 'Untitled',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1e293b),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (record['organization_name'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 13,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              record['organization_name'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      if (record['data_type'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: tb,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            record['data_type'],
                            style: TextStyle(
                              fontSize: 10,
                              color: tc,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (record['file_name'] != null)
                        Flexible(
                          child: Text(
                            record['file_name'].toString().split('/').last,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
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
            _downloadingId == record['id']
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF008080),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.download_rounded,
                      color: Color(0xFF008080),
                      size: 26,
                    ),
                    tooltip: 'Download',
                    onPressed: () => _downloadFile(record),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageBtn(
    IconData icon,
    bool enabled,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: enabled ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildCircularCard({
    required IconData icon,
    required String title,
    required int count,
    required bool hasData,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Outer Ring
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: hasData
                    ? const [Color(0xFF667eea), Color(0xFF764ba2)]
                    : const [Color(0xFFbdc3c7), Color(0xFF95a5a6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: hasData
                      ? const Color(0xFF667eea).withOpacity(0.25)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: hasData ? 20 : 12,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasData ? Colors.white : const Color(0xFFf5f5f5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: hasData
                            ? const [Color(0xFF667eea), Color(0xFF764ba2)]
                            : const [Color(0xFFbdc3c7), Color(0xFF95a5a6)],
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: hasData
                              ? const [Color(0xFFf093fb), Color(0xFFf5576c)]
                              : const [Color(0xFFbdc3c7), Color(0xFF95a5a6)],
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Title
          SizedBox(
            width: 90,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: hasData
                    ? const Color(0xFF2c3e50)
                    : const Color(0xFF95a5a6),
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 1),
          // Records label
          Text(
            count == 1 ? 'Record' : 'Records',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: hasData
                  ? const Color(0xFF7f8c8d)
                  : const Color(0xFFbdc3c7),
            ),
          ),
        ],
      ),
    );
  }
}
