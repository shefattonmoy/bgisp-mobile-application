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
  final TextEditingController _searchController = TextEditingController();

  // Full list fetched once.
  List<MemberOrganization> _allOrganizations = [];

  // Step 1 — type picker.
  List<OrganizationType> _types = [];
  bool _isLoadingTypes = true;
  String? _typesError;

  // Step 2 — org list for the selected type.
  OrganizationType? _selectedType;
  List<MemberOrganization> _organizationsOfType = [];
  List<MemberOrganization> _filteredOrganizations = [];

  @override
  void initState() {
    super.initState();
    _loadTypes();
    _searchController.addListener(_filterOrganizations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _currentLang() {
    final provider = Provider.of<LanguageProvider>(context, listen: false);
    return provider.language == 'BN' ? 'bn' : 'en';
  }

  Future<void> _loadTypes() async {
    setState(() {
      _isLoadingTypes = true;
      _typesError = null;
    });
    try {
      final organizations = await _organizationApi.getOrganizations(
        lang: _currentLang(),
      );
      final types = await _organizationApi.getOrganizationTypes(
        lang: _currentLang(),
        preloaded: organizations,
      );
      if (!mounted) return;
      setState(() {
        _allOrganizations = organizations;
        _types = types;
        _isLoadingTypes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _typesError = e.toString();
        _isLoadingTypes = false;
      });
    }
  }

  void _selectType(OrganizationType type) {
    final filtered = _allOrganizations
        .where((o) => _typeKeyOf(o) == type.name)
        .toList();
    setState(() {
      _selectedType = type;
      _organizationsOfType = filtered;
      _filteredOrganizations = filtered;
      _searchController.clear();
    });
  }

  void _backToTypes() {
    setState(() {
      _selectedType = null;
      _organizationsOfType = [];
      _filteredOrganizations = [];
      _searchController.clear();
    });
  }

  Future<void> _onRefresh() async {
    if (_selectedType == null) {
      await _loadTypes();
      return;
    }
    try {
      final organizations = await _organizationApi.getOrganizations(
        lang: _currentLang(),
      );
      if (!mounted) return;
      final filtered = organizations
          .where((o) => _typeKeyOf(o) == _selectedType!.name)
          .toList();
      setState(() {
        _allOrganizations = organizations;
        _organizationsOfType = filtered;
        _filteredOrganizations = filtered;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _typeKeyOf(MemberOrganization org) {
    final raw = org.organizationsType?.trim();
    return (raw == null || raw.isEmpty) ? 'Uncategorized' : raw;
  }

  void _filterOrganizations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOrganizations = _organizationsOfType;
      } else {
        _filteredOrganizations = _organizationsOfType
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
    final showingOrgs = _selectedType != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          showingOrgs
              ? _selectedType!.name
              : (t['organizationTitle'] ?? 'Organization'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        leading: showingOrgs
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToTypes,
              )
            : null,
      ),
      body: showingOrgs ? _buildOrgList(t) : _buildTypeList(t),
    );
  }

  // =================== STEP 1: TYPE PICKER ===================

  Widget _buildTypeList(Map<String, String> t) {
    if (_isLoadingTypes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_typesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _typesError!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTypes,
              child: Text(t['retry'] ?? 'Retry'),
            ),
          ],
        ),
      );
    }
    if (_types.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              t['noOrganizationTypes'] ?? 'No organization types found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final type = _types[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.primaryColor.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.category,
                  color: AppConstants.primaryColor,
                ),
              ),
              title: Text(
                type.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${type.count} ${t['organizations'] ?? 'organizations'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _selectType(type),
            ),
          );
        },
      ),
    );
  }

  // =================== STEP 2: ORG LIST ===================

  Widget _buildOrgList(Map<String, String> t) {
    return Column(
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
            '${t['showing'] ?? 'Showing'} ${_filteredOrganizations.length} '
            '${t['organizations'] ?? 'organizations'}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
        Expanded(child: _buildOrgContent(t)),
      ],
    );
  }

  Widget _buildOrgContent(Map<String, String> t) {
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
      onRefresh: _onRefresh,
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
