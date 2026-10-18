// lib/screens/Organization/organization_metadata_tab.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../api/Organization/organization_api.dart';
import '../../../constants/constant.dart';
import '../../../models/Metadata/metadata.dart';
import '../../../models/ThematicArea/thematic_area.dart';
import '../../../providers/language_provider.dart';
import '../../../services/download_service.dart';
import '../../Metadata/metadata_detail_page.dart';

class OrganizationMetadataTab extends StatefulWidget {
  final int organizationId;
  const OrganizationMetadataTab({super.key, required this.organizationId});

  @override
  State<OrganizationMetadataTab> createState() =>
      _OrganizationMetadataTabState();
}

class _OrganizationMetadataTabState extends State<OrganizationMetadataTab> {
  final OrganizationApi _api = OrganizationApi();
  List<ThematicArea> _thematicAreas = [];
  bool _isLoading = true;

  int? _selectedThematicId;
  String _selectedThematicName = '';
  List<MetadataRecord> _metadataRecords = [];

  // ─────────────────────────────────────────────────────────────────────
  // Option A: keep the raw JSON maps the list endpoint already returned
  // so Excel export needs NO second network request.
  // ─────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _metadataRawById = [];

  bool _isLoadingData = false;
  String _searchTerm = '';
  int _currentPage = 0;
  final int _rowsPerPage = 6;

  // Per-card download spinner.
  int? _downloadingId;

  // Selection (visual only — no bulk action button).
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  // Progress overlay for the per-card Excel export.
  bool _busy = false;
  String _busyMessage = '';
  double? _busyFraction;

  @override
  void initState() {
    super.initState();
    _loadThematicAreas();
  }

  Future<void> _loadThematicAreas() async {
    setState(() => _isLoading = true);
    try {
      final areas = await _api.getThematicAreasWithMetadata(
        widget.organizationId,
      );
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

  Future<void> _loadMetadataForThematic(int thematicId) async {
    setState(() {
      _isLoadingData = true;
      _selectedThematicId = thematicId;
      _currentPage = 0;
      _searchTerm = '';
      _selectionMode = false;
      _selectedIds.clear();
      _metadataRawById = [];
    });

    try {
      final url =
          '${AppConstants.myAPILink}/api/get_member_organizations/${widget.organizationId}/thematic-area/$thematicId/metadata/';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final rawList = (data['metadata'] as List)
              .map((m) => Map<String, dynamic>.from(m as Map))
              .toList();

          if (mounted) {
            setState(() {
              // Parse for the UI.
              _metadataRecords = rawList
                  .map((m) => MetadataRecord.fromJson(m))
                  .toList();
              // Keep raw JSON for export — keyed by id for fast lookup.
              _metadataRawById = rawList;
              _isLoadingData = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingData = false);
        }
      } else {
        if (mounted) setState(() => _isLoadingData = false);
      }
    } catch (e) {
      // ignore: avoid_print
      print('!! [metadata] load failed: $e');
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _goBackToThematicAreas() {
    setState(() {
      _selectedThematicId = null;
      _selectedThematicName = '';
      _metadataRecords = [];
      _metadataRawById = [];
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _viewMetadataDetail(MetadataRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MetadataDetailPage(metadataId: record.id),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // DOWNLOAD — Option A: no second network call.
  // ─────────────────────────────────────────────────────────────────────

  String get _language =>
      Provider.of<LanguageProvider>(context, listen: false).language;

  /// Look up the raw JSON map the list endpoint already returned.
  Map<String, dynamic>? _rawFor(MetadataRecord r) {
    for (final m in _metadataRawById) {
      if (m['id'] == r.id) return m;
    }
    return null;
  }

  /// Minimal fallback if the raw map is somehow missing.
  Map<String, dynamic> _summaryMap(MetadataRecord r) => {
    'title': r.title,
    'contributor': r.contributor,
    'data_type': r.dataType,
    'data_volume': r.dataVolume,
    'organization_name': r.organizationName,
  };

  Future<void> _downloadSingle(MetadataRecord record) async {
    setState(() {
      _downloadingId = record.id;
      _busy = true;
      _busyMessage = 'Preparing Excel export...';
      _busyFraction = null;
    });

    try {
      final detail = _rawFor(record) ?? _summaryMap(record);
      if (detail.isEmpty) {
        throw Exception('No metadata fields available to export.');
      }

      // ignore: avoid_print
      print(
        '>> [download] exporting id=${record.id} '
        'fields=${detail.length}',
      );

      await DownloadService.downloadMetadataExcel(
        record: detail,
        language: _language,
        onProgress: (msg, {fraction}) {
          if (!mounted) return;
          setState(() {
            _busyMessage = msg;
            _busyFraction = fraction;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel exported'),
            backgroundColor: Color(0xFF10b981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('!! [download] failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingId = null;
          _busy = false;
          _busyMessage = '';
          _busyFraction = null;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // SELECTION (visual only)
  // ─────────────────────────────────────────────────────────────────────

  void _toggleSelection(MetadataRecord record) {
    setState(() {
      if (!_selectionMode) _selectionMode = true;
      if (_selectedIds.contains(record.id)) {
        _selectedIds.remove(record.id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(record.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // FILTER / PAGING
  // ─────────────────────────────────────────────────────────────────────

  List<MetadataRecord> get _filteredRecords {
    if (_searchTerm.isEmpty) return _metadataRecords;
    final q = _searchTerm.toLowerCase();
    return _metadataRecords
        .where(
          (r) =>
              '${r.title} ${r.contributor} ${r.dataType} ${r.organizationName}'
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
  }

  int get _totalPages => (_filteredRecords.length / _rowsPerPage).ceil();

  List<MetadataRecord> get _currentPageData {
    final start = _currentPage * _rowsPerPage;
    final end = start + _rowsPerPage;
    return _filteredRecords.sublist(
      start,
      end > _filteredRecords.length ? _filteredRecords.length : end,
    );
  }

  IconData _getIconForThematicArea(String name) {
    const mapping = {
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
    return mapping[name] ?? Icons.folder;
  }

  Color _getColorForThematicArea(String name) {
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

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBangla = langProvider.language == 'BN';

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading metadata categories...'),
          ],
        ),
      );
    }

    final body = _selectedThematicId != null
        ? _buildRecordsView()
        : _buildThematicGrid(isBangla);

    return PopScope(
      canPop: _selectedThematicId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedThematicId != null) {
          if (_selectionMode) {
            _clearSelection();
          } else {
            _goBackToThematicAreas();
          }
        }
      },
      child: Stack(children: [body, if (_busy) _buildProgressOverlay()]),
    );
  }

  Widget _buildProgressOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.35),
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _busyMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (_busyFraction != null) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: _busyFraction),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThematicGrid(bool isBangla) {
    if (_thematicAreas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Metadata Available',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "This organization hasn't contributed any metadata records yet.",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
          childAspectRatio: 0.85,
        ),
        itemCount: _thematicAreas.length,
        itemBuilder: (context, index) {
          final area = _thematicAreas[index];
          final hasRecords = area.metadataCount > 0;
          final color = _getColorForThematicArea(area.name);
          final displayName = isBangla && area.nameBn != null
              ? area.nameBn!
              : area.name;

          return GestureDetector(
            onTap: hasRecords
                ? () {
                    _selectedThematicName = area.name;
                    _loadMetadataForThematic(area.id);
                  }
                : null,
            child: AnimatedOpacity(
              opacity: hasRecords ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.2),
                              color.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                            ),
                          ],
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _getIconForThematicArea(area.name),
                          color: color,
                          size: 28,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: hasRecords
                                ? LinearGradient(
                                    colors: [color, color.withOpacity(0.7)],
                                  )
                                : const LinearGradient(
                                    colors: [Colors.grey, Colors.grey],
                                  ),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              area.metadataCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasRecords ? Colors.grey[800] : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasRecords
                        ? '${area.metadataCount} ${area.metadataCount == 1 ? 'Record' : 'Records'}'
                        : 'No Records',
                    style: TextStyle(
                      fontSize: 10,
                      color: hasRecords ? color : Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordsView() {
    final color = _getColorForThematicArea(_selectedThematicName);

    return Column(
      children: [
        // Search row — no back arrow, no count pill.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search metadata...',
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

        // Records list
        Expanded(
          child: _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : _filteredRecords.isEmpty
              ? const Center(child: Text('No records found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _currentPageData.length,
                  itemBuilder: (context, index) =>
                      _buildRecordCard(_currentPageData[index], color),
                ),
        ),

        // Pagination
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

  Widget _buildRecordCard(MetadataRecord record, Color color) {
    final isSelected = _selectedIds.contains(record.id);
    final isDownloading = _downloadingId == record.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Card content
          Column(
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.25), color.withOpacity(0.06)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: Color(0xFFe67e22),
                      size: 28,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title ?? 'Untitled Metadata',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF0f172a),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    if (record.organizationName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.business,
                              size: 13,
                              color: Color(0xFF64748b),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                record.organizationName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748b),
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
                        if (record.dataType != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.dns,
                                size: 13,
                                color: Color(0xFF64748b),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                record.dataType!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748b),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(width: 12),
                        if (record.dataVolume != null)
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.sd_storage,
                                  size: 13,
                                  color: Color(0xFF64748b),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    record.dataVolume!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748b),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tap overlay (details / long-press selection)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_selectionMode) {
                    _toggleSelection(record);
                  } else {
                    _viewMetadataDetail(record);
                  }
                },
                onLongPress: () => _toggleSelection(record),
                splashColor: Colors.black26,
                highlightColor: Colors.black12,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, color: Colors.white, size: 28),
                      SizedBox(height: 8),
                      Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Selection checkbox (visual only)
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: () => _toggleSelection(record),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? color : Colors.grey[400]!,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.add,
                  size: 15,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),

          // Per-card download button
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: isDownloading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFe67e22),
                        ),
                      ),
                    )
                  : IconButton(
                      iconSize: 18,
                      tooltip: 'Download Excel',
                      icon: const Icon(
                        Icons.download,
                        color: Color(0xFFe67e22),
                      ),
                      onPressed: () => _downloadSingle(record),
                    ),
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
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFe67e22) : Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? Colors.white : Colors.grey[400],
        ),
      ),
    );
  }
}
