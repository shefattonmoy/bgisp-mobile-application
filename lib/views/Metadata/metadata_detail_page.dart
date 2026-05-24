import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/constant.dart';

class MetadataDetailPage extends StatefulWidget {
  final int metadataId;

  const MetadataDetailPage({
    super.key,
    required this.metadataId,
  });

  @override
  State<MetadataDetailPage> createState() => _MetadataDetailPageState();
}

class _MetadataDetailPageState extends State<MetadataDetailPage> {
  Map<String, dynamic>? _record;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMetadataDetail();
  }

  Future<void> _loadMetadataDetail() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final url = '${AppConstants.myAPILink}/api/get_metadata/${widget.metadataId}/';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _record = Map<String, dynamic>.from(data);
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        if (mounted) setState(() { _error = 'Metadata not found'; _isLoading = false; });
      } else {
        throw Exception('Failed to load');
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error loading metadata'; _isLoading = false; });
    }
  }

  String _formatValue(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Not available';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9fa),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_record?['title'] ?? 'Metadata Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF008080)))
          : _error != null
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(fontSize: 16, color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadMetadataDetail, child: const Text('Retry')),
                  ]),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF1a1a2e).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.description_outlined, color: Colors.white, size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _record?['title'] ?? 'Untitled',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            if (_record?['contributor'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _record!['contributor'],
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(children: [
                              Icon(Icons.info_outline, color: Color(0xFF008080), size: 20),
                              SizedBox(width: 8),
                              Text('Metadata Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1e293b))),
                            ]),
                            const SizedBox(height: 20),
                            _buildDetailRow('Title', _record?['title']),
                            _buildDetailRow('Contributor', _record?['contributor']),
                            _buildDetailRow('Data Type', _record?['data_type']),
                            _buildDetailRow('Vector Format', _record?['vector_format']),
                            _buildDetailRow('Raster Format', _record?['raster_format']),
                            _buildDetailRow('Number of Layers', _record?['layers_number']),
                            _buildDetailRow('Datum', _record?['datum']),
                            _buildDetailRow('Projection', _record?['projection']),
                            _buildDetailRow('Semi-Major/Minor Axis', _record?['semi_major_minor_axis']),
                            _buildDetailRow('Flattening Ratio', _record?['flattening_ratio']),
                            _buildDetailRow('Dimension', _record?['dimension']),
                            _buildDetailRow('Software Version', _record?['software_version']),
                            _buildDetailRow('Scale', _record?['scale']),
                            _buildDetailRow('Admin Levels', _record?['admin_levels']),
                            _buildDetailRow('Area Coverage', _record?['area_coverage']),
                            _buildDetailRow('Data Collection Method', _record?['data_collection_method']),
                            _buildDetailRow('Survey Year', _record?['survey_year']),
                            _buildDetailRow('Update Frequency', _record?['update_frequency']),
                            _buildDetailRow('Data Volume', _record?['data_volume']),
                            _buildDetailRow('Data Compatibility', _record?['data_compatibility']),
                            _buildDetailRow('Conflict of Interest', _record?['conflict_of_interest']),
                            _buildDetailRow('Purpose of Use', _record?['purpose_of_use']),
                            _buildDetailRow('Availability', _record?['availability']),
                            _buildDetailRow('Cost Per Unit', _record?['cost_per_unit']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    final displayValue = _formatValue(value);
    final isEven = label.length % 2 == 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFf8fafc) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFe2e8f0), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                color: displayValue == 'Not available' ? Colors.grey[400] : const Color(0xFF1e293b),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}