import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/FocalPoint/focal_point_api.dart';
import '../../models/FocalPoint/focal_point.dart';
import '../../providers/language_provider.dart';

class FocalPointPage extends StatefulWidget {
  const FocalPointPage({super.key});

  @override
  State<FocalPointPage> createState() => _FocalPointPageState();
}

class _FocalPointPageState extends State<FocalPointPage> {
  final FocalPointApi _api = FocalPointApi();
  List<FocalPoint> _focalPoints = [];
  List<FocalPoint> _filteredPoints = [];
  bool _isLoading = true;
  String? _error;
  String _searchTerm = '';
  int _currentPage = 0;
  final int _rowsPerPage = 6; // 6 cards per page

  @override
  void initState() {
    super.initState();
    _loadFocalPoints();
  }

  Future<void> _loadFocalPoints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final langProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      final lang = langProvider.language == 'BN' ? 'bn' : 'en';
      final points = await _api.getFocalPoints(lang: lang);
      if (mounted) {
        setState(() {
          _focalPoints = points;
          _filteredPoints = points;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterPoints(String query) {
    setState(() {
      _searchTerm = query;
      if (query.isEmpty) {
        _filteredPoints = _focalPoints;
      } else {
        final q = query.toLowerCase();
        _filteredPoints = _focalPoints.where((p) {
          return (p.name?.toLowerCase().contains(q) ?? false) ||
              (p.nameBn?.toLowerCase().contains(q) ?? false) ||
              (p.organization?.toLowerCase().contains(q) ?? false) ||
              (p.designation?.toLowerCase().contains(q) ?? false) ||
              (p.designationBn?.toLowerCase().contains(q) ?? false) ||
              (p.phone?.contains(q) ?? false) ||
              (p.email?.toLowerCase().contains(q) ?? false);
        }).toList();
      }
      _currentPage = 0;
    });
  }

  void _showPointDetail(FocalPoint point) {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isBn = langProvider.language == 'BN';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF008080), Color(0xFF006666)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point.getDisplayName(isBn ? 'BN' : 'EN'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF008080),
                          width: 3,
                        ),
                        color: Colors.grey[100],
                        image: point.image != null && point.image!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(point.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: point.image == null || point.image!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Organization
                    if (point.organization != null &&
                        point.organization!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF008080).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          point.organization!,
                          style: const TextStyle(
                            color: Color(0xFF008080),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Details
                    _buildDetailRow(
                      Icons.badge,
                      'Designation',
                      point.getDisplayDesignation(isBn ? 'BN' : 'EN'),
                    ),
                    _buildDetailRow(Icons.phone, 'Phone', point.phone),
                    _buildDetailRow(Icons.email, 'Email', point.email),
                  ],
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFe9ecef))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6c757d),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated detail row with icon
  Widget _buildDetailRow(IconData icon, String label, String? value) {
    final displayValue = (value == null || value.isEmpty)
        ? 'Not available'
        : value;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF008080)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(
                color: Color(0xFF1e293b),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int get _totalPages => (_filteredPoints.length / _rowsPerPage).ceil();
  List<FocalPoint> get _currentPageData {
    final start = _currentPage * _rowsPerPage;
    return _filteredPoints.sublist(
      start,
      start + _rowsPerPage > _filteredPoints.length
          ? _filteredPoints.length
          : start + _rowsPerPage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<LanguageProvider>(context).t;

    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t['focalPersons'] ?? 'Focal Points'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF008080), Color(0xFF20b2aa)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_pin,
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
                        t['focalPersons'] ?? 'Focal Points',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1e293b),
                        ),
                      ),
                      Text(
                        '${_filteredPoints.length} persons',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '🔍 Search...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _filterPoints(''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF008080)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _filterPoints,
            ),
          ),
          const SizedBox(height: 12),
          // Cards Grid - 3 columns, 2 rows = 6 per page
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF008080)),
                  )
                : _error != null
                ? Center(
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
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFocalPoints,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredPoints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No persons found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600
                          ? 3
                          : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _currentPageData.length,
                    itemBuilder: (context, index) =>
                        _buildFocalPointCard(_currentPageData[index]),
                  ),
          ),
          // Pagination
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPageBtn(
                    Icons.first_page,
                    _currentPage > 0,
                    () => setState(() => _currentPage = 0),
                  ),
                  const SizedBox(width: 4),
                  _buildPageBtn(
                    Icons.chevron_left,
                    _currentPage > 0,
                    () => setState(() => _currentPage--),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Page ${_currentPage + 1} of $_totalPages',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildPageBtn(
                    Icons.chevron_right,
                    _currentPage < _totalPages - 1,
                    () => setState(() => _currentPage++),
                  ),
                  const SizedBox(width: 4),
                  _buildPageBtn(
                    Icons.last_page,
                    _currentPage < _totalPages - 1,
                    () => setState(() => _currentPage = _totalPages - 1),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFocalPointCard(FocalPoint point) {
    return GestureDetector(
      onTap: () => _showPointDetail(point),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF008080).withOpacity(0.3),
                  width: 3,
                ),
                image: point.image != null && point.image!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(point.imageUrl),
                        fit: BoxFit.cover,
                        onError: (e, s) {},
                      )
                    : null,
              ),
              child: point.image == null || point.image!.isEmpty
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 12),
            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                point.name ?? '—',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1e293b),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Organization
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                point.organization ?? '—',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            // View button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF008080).withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: const Text(
                'Tap to view',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF008080),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF008080) : Colors.grey[100],
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
}
