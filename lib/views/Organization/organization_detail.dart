import 'package:flutter/material.dart';
import '../../constants/constant.dart';
import '../../models/Organization/organization.dart';
import 'widgets/organization_data_tab.dart';
import 'widgets/organization_metadata_tab.dart';
import 'widgets/organization_map_tab.dart';

class OrganizationDetailPage extends StatefulWidget {
  final MemberOrganization organization;

  const OrganizationDetailPage({super.key, required this.organization});

  @override
  State<OrganizationDetailPage> createState() => _OrganizationDetailPageState();
}

class _OrganizationDetailPageState extends State<OrganizationDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openWebsite() {
    final url = widget.organization.websiteUrl;
    if (url != null && url.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Opening: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final org = widget.organization;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Organization Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
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
                          size: 35,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org.orgName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (org.orgShort != null)
                        Text(
                          org.orgShort!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppConstants.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppConstants.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline), text: 'About'),
              Tab(icon: Icon(Icons.storage), text: 'Data'),
              Tab(icon: Icon(Icons.map), text: 'Map'),
              Tab(icon: Icon(Icons.description), text: 'Metadata'),
            ],
          ),

          // TabBarView wrapped in Expanded to fix unbounded height
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(org),
                OrganizationDataTab(organizationId: org.id),
                OrganizationMapTab(
                  organizationId: org.id,
                  organizationName: org.orgName,
                ),
                OrganizationMetadataTab(organizationId: org.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(MemberOrganization org) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (org.description != null) ...[
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              org.description!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (org.websiteUrl != null) ...[
            const Text(
              'Website',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _openWebsite,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.language,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        org.websiteUrl!,
                        style: const TextStyle(
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
