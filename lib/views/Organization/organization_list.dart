import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/Organization/organization_api.dart';
import '../../constants/constant.dart';
import '../../models/Organization/organization.dart';
import '../../providers/language_provider.dart';
import 'organization_detail.dart';

class OrganizationListPage extends StatefulWidget {
  const OrganizationListPage({super.key});

  @override
  State<OrganizationListPage> createState() => _OrganizationListPageState();
}

class _OrganizationListPageState extends State<OrganizationListPage> {
  final OrganizationApi _organizationApi = OrganizationApi();
  List<MemberOrganization> _organizations = [];
  List<MemberOrganization> _filteredOrganizations = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
    _searchController.addListener(_filterOrganizations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizations() async {
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
      final organizations = await _organizationApi.getOrganizations(lang: lang);
      if (mounted) {
        setState(() {
          _organizations = organizations;
          _filteredOrganizations = organizations;
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

  void _filterOrganizations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOrganizations = _organizations;
      } else {
        _filteredOrganizations = _organizations
            .where(
              (org) =>
                  org.orgName.toLowerCase().contains(query) ||
                  (org.orgShort?.toLowerCase().contains(query) ?? false) ||
                  (org.description?.toLowerCase().contains(query) ?? false),
            )
            .toList();
      }
    });
  }

  void _navigateToDetail(MemberOrganization org) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrganizationDetailPage(organization: org),
      ),
    );
  }

  void _openWebsite(String? url) {
    if (url != null && url.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Opening: $url')));
    } else {
      final t = Provider.of<LanguageProvider>(context, listen: false).t;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t['noWebsite'] ?? 'No website available')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<LanguageProvider>(context).t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t['organizationTitle'] ?? 'Organization'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: t['searchPlaceholder'] ?? 'Search organizations...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '${t['showing'] ?? 'Showing'} ${_filteredOrganizations.length} ${t['organizations'] ?? 'organizations'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(child: _buildContent(t)),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, String> t) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrganizations,
              child: Text(t['retry'] ?? 'Retry'),
            ),
          ],
        ),
      );
    }
    if (_filteredOrganizations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              t['noResults'] ?? 'No organizations found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOrganizations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredOrganizations.length,
        itemBuilder: (context, index) =>
            _buildOrganizationCard(_filteredOrganizations[index], t),
      ),
    );
  }

  Widget _buildOrganizationCard(MemberOrganization org, Map<String, String> t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(org),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  image: org.imagePath != null
                      ? DecorationImage(
                          image: NetworkImage(
                            '${AppConstants.myAPILink}${org.imagePath}',
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: org.imagePath == null
                    ? const Icon(
                        Icons.business,
                        color: AppConstants.primaryColor,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openWebsite(org.websiteUrl),
                      child: Text(
                        org.displayShortName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => _navigateToDetail(org),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(t['viewDetails'] ?? 'View Details'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
