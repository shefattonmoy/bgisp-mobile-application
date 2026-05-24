import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../api/TimeSeriesAnalysis/time_series_analysis_api.dart';
import '../../models/Geocode/geocode.dart';
import '../../providers/language_provider.dart';

class TimeSeriesAnalysisPage extends StatefulWidget {
  const TimeSeriesAnalysisPage({super.key});

  @override
  State<TimeSeriesAnalysisPage> createState() => _TimeSeriesAnalysisPageState();
}

class _TimeSeriesAnalysisPageState extends State<TimeSeriesAnalysisPage> {
  final TimeSeriesApi _api = TimeSeriesApi();

  // Data
  final List<FilterRow> _rows = [FilterRow(id: 0)];
  String _selectedChartView = 'line';

  // Census data (static fallback)
  final Map<String, Map<String, double>> _censusData = {
    '2001': {
      'total_population': 124.4,
      'total_male': 64.1,
      'total_female': 60.3,
      'total_hizra': 0.12,
      'total_household': 26.8,
      'density': 843.0,
    },
    '2011': {
      'total_population': 144.0,
      'total_male': 72.1,
      'total_female': 71.9,
      'total_hizra': 0.25,
      'total_household': 32.1,
      'density': 976.0,
    },
    '2022': {
      'total_population': 165.2,
      'total_male': 81.7,
      'total_female': 83.5,
      'total_hizra': 0.45,
      'total_household': 37.8,
      'density': 1119.0,
    },
  };

  final Map<String, Map<String, double>> _divisionData = {
    'Dhaka': {'2001': 29.2, '2011': 36.4, '2022': 44.2},
    'Chittagong': {'2001': 24.3, '2011': 28.4, '2022': 33.2},
    'Rajshahi': {'2001': 16.4, '2011': 18.5, '2022': 20.4},
    'Khulna': {'2001': 14.7, '2011': 15.7, '2022': 17.4},
    'Barisal': {'2001': 8.2, '2011': 8.3, '2022': 9.1},
    'Sylhet': {'2001': 7.9, '2011': 9.9, '2022': 11.0},
    'Rangpur': {'2001': 13.9, '2011': 15.8, '2022': 17.6},
    'Mymensingh': {'2001': 9.9, '2011': 11.4, '2022': 12.2},
  };

  final List<Color> _seriesColors = [
    const Color(0xFF8884d8),
    const Color(0xFF82ca9d),
    const Color(0xFFFF8042),
    const Color(0xFF0088FE),
  ];

  final List<Color> _pieColors = [
    const Color(0xFF0088FE),
    const Color(0xFF00C49F),
    const Color(0xFFFFBB28),
    const Color(0xFFFF8042),
    const Color(0xFF8884d8),
    const Color(0xFF82ca9d),
    const Color(0xFFFF6B6B),
    const Color(0xFF4ECDC4),
  ];

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
        title: Text(t['timeSeriesAnalysis'] ?? 'Time Series Analysis'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(t),
            const SizedBox(height: 20),

            // Filter rows
            ...List.generate(_rows.length, (index) => _buildFilterRow(index)),

            const SizedBox(height: 20),

            // Chart
            _buildChartSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, String> t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t['timeSeriesAnalysis'] ?? 'Time Series Analysis',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1e293b),
          ),
        ),
        if (_rows.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Comparing ${_rows.length} census year series on the same chart',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterRow(int index) {
    final row = _rows[index];
    final isPrimary = index == 0;
    final canAddRow = _rows.length < 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: !isPrimary
            ? const Border(left: BorderSide(color: Color(0xFF8884d8), width: 4))
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isPrimary)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF8884d8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Comparison $index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Census Year
              SizedBox(
                width: 160,
                child: _buildDropdown(
                  label: 'Census Year',
                  icon: Icons.calendar_today,
                  value: row.selectedCensusYear,
                  items: _getAvailableCensusYears(row.id)
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      row.selectedCensusYear = val;
                    });
                  },
                ),
              ),

              // Admin Boundary
              SizedBox(
                width: 160,
                child: _buildDropdown(
                  label: 'Admin Boundary',
                  icon: Icons.filter_alt,
                  value: row.selectedBoundary,
                  items: ['division', 'district', 'upazila']
                      .map(
                        (b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.capitalize()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      row.selectedBoundary = val;
                      row.selectedLocation = null;
                      row.currentBoundaryType = null;
                      // Reset dependent data
                      row.divisions = [];
                      row.districts = [];
                      row.upazilas = [];
                      row.selectedDivisionId = null;
                      row.selectedDistrictId = null;
                      row.selectedUpazilaId = null;
                    });
                    _loadLocations(row);
                  },
                ),
              ),

              // Location
              SizedBox(
                width: 160,
                child: _buildDropdown(
                  label: row.selectedBoundary?.capitalize() ?? 'Location',
                  icon: Icons.location_on,
                  value: row.selectedLocation,
                  items: _getLocationOptions(row)
                      .map(
                        (loc) => DropdownMenuItem(value: loc, child: Text(loc)),
                      )
                      .toList(),
                  onChanged:
                      row.selectedBoundary != null && !row.isLoadingLocations
                      ? (val) {
                          setState(() {
                            row.selectedLocation = val;

                            // Store IDs for potential API calls
                            if (row.selectedBoundary == 'division') {
                              row.selectedDivisionId = row.getDivisionIdByName(
                                val ?? '',
                              );
                            } else if (row.selectedBoundary == 'district') {
                              row.selectedDistrictId = row.getDistrictIdByName(
                                val ?? '',
                              );
                            } else if (row.selectedBoundary == 'upazila') {
                              row.selectedUpazilaId = row.getUpazilaIdByName(
                                val ?? '',
                              );
                            }
                          });
                        }
                      : null,
                  hint: row.isLoadingLocations
                      ? 'Loading...'
                      : 'Select ${row.selectedBoundary?.capitalize() ?? "admin first"}...',
                ),
              ),

              // Population Indicator
              SizedBox(
                width: 180,
                child: _buildDropdown(
                  label: 'Population Indicator',
                  icon: Icons.bar_chart,
                  value: row.selectedPopulation,
                  items:
                      [
                            'total_household',
                            'total_population',
                            'total_male',
                            'total_female',
                            'total_hizra',
                          ]
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p.replaceAll('_', ' ').capitalize()),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    setState(() {
                      row.selectedPopulation = val;
                    });
                  },
                ),
              ),

              // Chart View
              if (isPrimary)
                SizedBox(
                  width: 160,
                  child: _buildDropdown(
                    label: 'Chart View',
                    icon: Icons.show_chart,
                    value: _selectedChartView,
                    items: ['line', 'bar', 'area', 'pie']
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.capitalize()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedChartView = val!;
                      });
                    },
                  ),
                ),

              // Year Button
              if (isPrimary)
                SizedBox(
                  width: 140,
                  child: ElevatedButton.icon(
                    onPressed: canAddRow ? _addRow : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Year'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              // Remove button (comparison rows only)
              if (!isPrimary)
                SizedBox(
                  width: 120,
                  child: OutlinedButton.icon(
                    onPressed: () => _removeRow(row.id),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?)? onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint ?? 'Select...',
                style: const TextStyle(fontSize: 13),
              ),
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              dropdownColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    final allSeries = _buildAllSeries();
    final hasSelection = _rows.any(
      (r) =>
          r.selectedCensusYear != null &&
          r.selectedPopulation != null &&
          r.selectedBoundary != null,
    );

    if (!hasSelection) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Chart will be displayed here once you select the filters above',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (allSeries.isEmpty) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Please complete your filter selections to view the chart',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: SizedBox(height: 450, child: _renderChart(allSeries)),
    );
  }

  Widget _renderChart(List<Map<String, dynamic>> allSeries) {
    if (_selectedChartView == 'pie') {
      final firstSeriesData = allSeries[0]['data'];
      if (firstSeriesData is! List || firstSeriesData.isEmpty) {
        return const SizedBox();
      }

      final pieData = firstSeriesData.cast<Map<String, dynamic>>();
      final sections = <PieChartSectionData>[];

      for (int i = 0; i < pieData.length; i++) {
        final item = pieData[i];
        final value = (item['value'] as num?)?.toDouble() ?? 0;
        final name = item['name']?.toString() ?? '';
        final year = item['year']?.toString() ?? '';
        final displayName = name.isNotEmpty ? name : year;

        sections.add(
          PieChartSectionData(
            color: _pieColors[i % _pieColors.length],
            value: value,
            title: '$displayName\n${_formatYAxis(value)}',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }

      return PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      );
    }

    // Line, Bar, Area charts
    final mergedData = _mergeSeriesForChart(allSeries);

    if (mergedData.isEmpty) return const SizedBox();

    final keyField = mergedData[0].containsKey('year') ? 'year' : 'name';
    final seriesLabels = allSeries.map((s) => s['label'].toString()).toList();

    if (_selectedChartView == 'bar') {
      final barGroups = <BarChartGroupData>[];

      for (int i = 0; i < mergedData.length; i++) {
        final rods = <BarChartRodData>[];
        for (int j = 0; j < seriesLabels.length; j++) {
          final value = mergedData[i][seriesLabels[j]];
          final doubleValue = value is num ? value.toDouble() : 0.0;
          rods.add(
            BarChartRodData(
              toY: doubleValue,
              color: _seriesColors[j % _seriesColors.length],
              width: 16,
            ),
          );
        }
        barGroups.add(BarChartGroupData(x: i, barRods: rods));
      }

      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(mergedData, seriesLabels),
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < mergedData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        mergedData[index][keyField].toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatYAxis(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      );
    }

    // Line or Area chart
    final lineBars = <LineChartBarData>[];

    for (int j = 0; j < seriesLabels.length; j++) {
      final label = seriesLabels[j];
      final spots = <FlSpot>[];

      for (int i = 0; i < mergedData.length; i++) {
        final value = mergedData[i][label];
        final doubleValue = value is num ? value.toDouble() : 0.0;
        spots.add(FlSpot(i.toDouble(), doubleValue));
      }

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _seriesColors[j % _seriesColors.length],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: _selectedChartView == 'area',
            color: _seriesColors[j % _seriesColors.length].withOpacity(0.2),
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineBarsData: lineBars,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < mergedData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      mergedData[index][keyField].toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatYAxis(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // Helper methods
  List<String> _getAvailableCensusYears(int rowId) {
    final usedYears = _rows
        .where((r) => r.id != rowId && r.selectedCensusYear != null)
        .map((r) => r.selectedCensusYear!)
        .toSet();
    return [
      '2001',
      '2011',
      '2022',
    ].where((y) => !usedYears.contains(y)).toList();
  }

  List<String> _getLocationOptions(FilterRow row) {
    if (row.currentBoundaryType == 'division') return row.divisionNames;
    if (row.currentBoundaryType == 'district') return row.districtNames;
    if (row.currentBoundaryType == 'upazila') return row.upazilaNames;
    return [];
  }

  Future<void> _loadLocations(FilterRow row) async {
    if (row.selectedBoundary == null) return;

    setState(() => row.isLoadingLocations = true);

    try {
      if (row.selectedBoundary == 'division') {
        final data = await _api.getAllDivisions();
        if (mounted) {
          setState(() {
            row.divisions = data;
            row.currentBoundaryType = 'division';
            row.isLoadingLocations = false;
          });
        }
      } else if (row.selectedBoundary == 'district') {
        final data = await _api.getAllDistricts();
        if (mounted) {
          setState(() {
            row.districts = data;
            row.currentBoundaryType = 'district';
            row.isLoadingLocations = false;
          });
        }
      } else if (row.selectedBoundary == 'upazila') {
        // Load all upazilas
        final data = await _api.getAllUpazilas();
        if (mounted) {
          setState(() {
            row.upazilas = data;
            row.currentBoundaryType = 'upazila';
            row.isLoadingLocations = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          row.isLoadingLocations = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildAllSeries() {
    final series = <Map<String, dynamic>>[];

    for (final r in _rows) {
      if (r.selectedCensusYear != null &&
          r.selectedPopulation != null &&
          r.selectedBoundary != null) {
        final label =
            '${r.selectedCensusYear}${r.selectedLocation != null ? ' - ${r.selectedLocation}' : ''}';
        final data = _generateSeriesData(r);
        if (data.isNotEmpty) {
          series.add({'label': label, 'data': data});
        }
      }
    }

    return series;
  }

  List<Map<String, dynamic>> _generateSeriesData(FilterRow row) {
    if (row.selectedCensusYear == null ||
        row.selectedPopulation == null ||
        row.selectedBoundary == null) {
      return [];
    }

    final metric = row.selectedPopulation!;
    final censusYears = ['2001', '2011', '2022'];

    if (row.selectedBoundary == 'division' && row.selectedLocation != null) {
      // Show specific division data across years
      final divName = row.selectedLocation!;
      final vals = _divisionData[divName];
      if (vals != null) {
        final result = <Map<String, dynamic>>[];
        for (final year in censusYears) {
          result.add({
            'year': year,
            'value': _getPopulationValue(vals[year] ?? 0, metric),
          });
        }
        return result;
      }
      // Fallback for divisions not in static data
      return _generateFallbackData(metric, censusYears);
    } else if (row.selectedBoundary == 'division' &&
        row.selectedLocation == null) {
      // Show all divisions for selected year
      final year = row.selectedCensusYear!;
      final result = <Map<String, dynamic>>[];
      for (final entry in _divisionData.entries) {
        result.add({
          'name': entry.key,
          'value': _getPopulationValue(entry.value[year] ?? 0, metric),
        });
      }
      return result;
    } else if (row.selectedBoundary == 'district' &&
        row.selectedLocation != null) {
      // District specific data (using fallback for now)
      return _generateFallbackData(metric, censusYears);
    } else if (row.selectedBoundary == 'upazila' &&
        row.selectedLocation != null) {
      // Upazila specific data (using fallback for now)
      return _generateFallbackData(metric, censusYears);
    } else {
      // Default: show national data across years
      final result = <Map<String, dynamic>>[];
      for (final year in censusYears) {
        final baseValue =
            _censusData[year]?[metric] ??
            _censusData[year]?['total_population'] ??
            0;
        result.add({
          'year': year,
          'value': _getPopulationValue(baseValue, metric),
        });
      }
      return result;
    }
  }

  List<Map<String, dynamic>> _generateFallbackData(
    String metric,
    List<String> years,
  ) {
    final result = <Map<String, dynamic>>[];
    for (final year in years) {
      final baseValue =
          _censusData[year]?[metric] ??
          _censusData[year]?['total_population'] ??
          0;
      result.add({
        'year': year,
        'value': _getPopulationValue(baseValue, metric),
      });
    }
    return result;
  }

  double _getPopulationValue(double baseValue, String metric) {
    switch (metric) {
      case 'total_male':
        return baseValue * 0.505;
      case 'total_female':
        return baseValue * 0.495;
      case 'total_hizra':
        return baseValue * 0.002;
      case 'total_household':
        return baseValue * 0.23;
      default:
        return baseValue;
    }
  }

  List<Map<String, dynamic>> _mergeSeriesForChart(
    List<Map<String, dynamic>> seriesArr,
  ) {
    if (seriesArr.isEmpty) return [];

    final firstData = seriesArr[0]['data'];
    if (firstData is! List || firstData.isEmpty) return [];

    final firstItem = firstData[0];
    if (firstItem is! Map) return [];

    final usesYear = (firstItem).containsKey('year');
    final keyField = usesYear ? 'year' : 'name';

    final allKeys = <String>{};
    for (final s in seriesArr) {
      final dataList = s['data'];
      if (dataList is List) {
        for (final d in dataList) {
          if (d is Map) {
            final key = d[keyField]?.toString();
            if (key != null) {
              allKeys.add(key);
            }
          }
        }
      }
    }

    final result = <Map<String, dynamic>>[];
    for (final key in allKeys) {
      final entry = <String, dynamic>{keyField: key};
      for (final s in seriesArr) {
        final label = s['label'].toString();
        final dataList = s['data'] as List;
        Map<String, dynamic>? found;
        for (final d in dataList) {
          if (d is Map && d[keyField]?.toString() == key) {
            found = Map<String, dynamic>.from(d);
            break;
          }
        }
        entry[label] = found != null ? found['value'] : null;
      }
      result.add(entry);
    }

    return result;
  }

  double _getMaxY(List<Map<String, dynamic>> data, List<String> labels) {
    double max = 0;
    for (final entry in data) {
      for (final label in labels) {
        final val = entry[label];
        if (val is num && val > max) max = val.toDouble();
      }
    }
    return max * 1.1;
  }

  String _formatYAxis(dynamic value) {
    double numValue;
    if (value is num) {
      numValue = value.toDouble();
    } else {
      return value.toString();
    }

    if (numValue >= 1000000) {
      return '${(numValue / 1000000).toStringAsFixed(1)}M';
    }
    if (numValue >= 1000) return '${(numValue / 1000).toStringAsFixed(1)}K';
    return numValue.toStringAsFixed(1);
  }

  void _addRow() {
    if (_rows.length < 3) {
      setState(() {
        _rows.add(FilterRow(id: DateTime.now().millisecondsSinceEpoch));
      });
    }
  }

  void _removeRow(int id) {
    setState(() {
      _rows.removeWhere((r) => r.id == id);
    });
  }
}

class FilterRow {
  final int id;
  String? selectedCensusYear;
  String? selectedBoundary;
  String? selectedLocation;
  String? selectedPopulation;
  String? currentBoundaryType;

  // Store both the display name and ID for lookups
  List<Division> divisions = [];
  List<District> districts = [];
  List<Upazila> upazilas = [];

  // Store IDs for API calls
  int? selectedDivisionId;
  int? selectedDistrictId;
  int? selectedUpazilaId;

  bool isLoadingLocations;

  FilterRow({
    required this.id,
    this.selectedCensusYear,
    this.selectedBoundary,
    this.selectedLocation,
    this.selectedPopulation,
    this.currentBoundaryType,
    this.selectedDivisionId,
    this.selectedDistrictId,
    this.selectedUpazilaId,
    this.isLoadingLocations = false,
  });

  // Get display names for dropdown
  List<String> get divisionNames =>
      divisions.map((d) => d.displayName).toList();
  List<String> get districtNames =>
      districts.map((d) => d.displayName).toList();
  List<String> get upazilaNames => upazilas.map((u) => u.displayName).toList();

  // Find IDs by name
  int? getDivisionIdByName(String name) {
    try {
      return divisions.firstWhere((d) => d.displayName == name).id;
    } catch (e) {
      return null;
    }
  }

  int? getDistrictIdByName(String name) {
    try {
      return districts.firstWhere((d) => d.displayName == name).id;
    } catch (e) {
      return null;
    }
  }

  int? getUpazilaIdByName(String name) {
    try {
      return upazilas.firstWhere((u) => u.displayName == name).id;
    } catch (e) {
      return null;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
