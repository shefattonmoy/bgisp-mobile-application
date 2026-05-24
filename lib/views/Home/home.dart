import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/Home/home_api.dart';
import '../../constants/constant.dart';
import '../../models/home/home_stats.dart';
import '../../models/home/visitor_count.dart';
import '../../providers/language_provider.dart';
import '../Home/widgets/statistic_card.dart';
import 'widgets/image_slider.dart';
import 'widgets/mission_vision_section.dart';
import 'widgets/news_events_section.dart';
import 'widgets/partners_section.dart';
import 'widgets/home_footer.dart';
import '../Organization/organization_list.dart';
import '../ExecutiveCommittee/executive_committee_page.dart';
import '../TechnicalCommittee/technical_committee_page.dart';
import '../IntegratedGeoportal/integrated_geoportal_page.dart';
import '../TimeSeriesAnalysis/time_series_analysis_page.dart';
import '../FocalPoint/focal_point_page.dart';
import '../Gallery/gallery_page.dart';
import '../../views/DataViewer/data_viewer.dart';
import '../../views/Metadata/metadata_viewer.dart';
import '../../views/About/about_page.dart';
import '../../views/Contact/contact_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeApi _homeApi = HomeApi();
  HomeStats _homeStats = HomeStats.initial();
  VisitorCount _visitorCount = VisitorCount.initial();
  int _focalPointsCount = 0;
  bool _isLoading = true;
  String _selectedDrawerItem = 'Home';
  String _expandedSection = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final statsFuture = _homeApi.fetchHomeStats();
      final visitorFuture = _homeApi.fetchVisitorCount();
      final focalPointsFuture = _homeApi.fetchFocalPointsCount();

      _homeApi.trackVisitor();

      final results = await Future.wait([
        statsFuture,
        visitorFuture,
        focalPointsFuture,
      ]);

      if (mounted) {
        setState(() {
          _homeStats = results[0] as HomeStats;
          _visitorCount = results[1] as VisitorCount;
          _focalPointsCount = results[2] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _homeStats = HomeStats.initial();
          _visitorCount = VisitorCount.initial();
          _focalPointsCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final t = langProvider.t;

    return Scaffold(
      drawer: _buildNavigationDrawer(t),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppConstants.primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 1,
              title: _buildCompactHeader(),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: () => _handleLanguageToggle(),
                    icon: const Icon(Icons.translate, size: 14),
                    label: Text(
                      langProvider.language == 'EN' ? 'বাংলা' : 'English',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      minimumSize: const Size(60, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: ImageSlider()),
            SliverToBoxAdapter(child: _buildAboutSection(t)),
            SliverToBoxAdapter(child: _buildObjectiveAndStatisticsSection(t)),
            const SliverToBoxAdapter(child: MissionVisionSection()),
            SliverToBoxAdapter(child: NewsEventsSection()),
            const SliverToBoxAdapter(child: PartnersSection()),
            SliverToBoxAdapter(child: HomeFooter(visitorCount: _visitorCount)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scrollToTop(),
        backgroundColor: AppConstants.primaryColor,
        mini: true,
        child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
      ),
    );
  }

  Widget _buildNavigationDrawer(Map<String, String> t) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryColor,
                    AppConstants.primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/bgisp_logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.public,
                          color: Colors.blue,
                          size: 44,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bangladesh GIS Platform',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t['geospatialDataInfrastructure'] ??
                        'Geospatial Data Infrastructure',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    Icons.home,
                    t['home'] ?? 'Home',
                    'Home',
                    () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    Icons.people,
                    t['organization'] ?? 'Organization',
                    'Organization',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrganizationListPage(),
                        ),
                      );
                    },
                  ),
                  _buildExpandableDrawerItem(
                    Icons.account_balance,
                    t['committees'] ?? 'Committees',
                    'Committees',
                    [
                      _buildSubDrawerItem(
                        t['executiveCommittee'] ?? 'Executive Committee',
                        'executive',
                        Icons.group,
                        () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ExecutiveCommitteePage(),
                                ),
                              );
                            }
                          });
                        },
                      ),
                      _buildSubDrawerItem(
                        t['technicalCommittee'] ?? 'Technical Committee',
                        'technical',
                        Icons.engineering,
                        () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TechnicalCommitteePage(),
                                ),
                              );
                            }
                          });
                        },
                      ),
                      _buildSubDrawerItem(
                        t['subCommittees'] ?? 'Sub Committees',
                        'sub',
                        Icons.workspaces,
                        () {},
                      ),
                    ],
                  ),
                  _buildExpandableDrawerItem(
                    Icons.build,
                    t['tools'] ?? 'Tools',
                    'Tools',
                    [
                      _buildSubDrawerItem(
                        t['integratedGeoportal'] ?? 'Integrated Geoportal',
                        'geoportal',
                        Icons.map,
                        () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const GeoportalMapPage(),
                                ),
                              );
                            }
                          });
                        },
                      ),
                      _buildSubDrawerItem(
                        t['timeSeriesAnalysis'] ?? 'Time Series Analysis',
                        'timeseries',
                        Icons.timeline,
                        () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TimeSeriesAnalysisPage(),
                                ),
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  _buildExpandableDrawerItem(
                    Icons.miscellaneous_services,
                    t['others'] ?? 'Others',
                    'Others',
                    [
                      _buildSubDrawerItem(
                        t['focalPersons'] ?? 'Focal Persons',
                        'focal',
                        Icons.person_pin,
                        () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FocalPointPage(),
                                ),
                              );
                            }
                          });
                        },
                      ),
                      _buildSubDrawerItem(
                        t['gallery'] ?? 'Gallery',
                        'gallery',
                        Icons.photo_library,
                        () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GalleryPage(),
                                ),
                              );
                            }
                          });
                        },
                      ),
                      _buildSubDrawerItem(
                        t['dataViewer'] ?? 'Data Viewer',
                        'dataViewer',
                        Icons.storage,
                        () {
                          setState(() => _selectedDrawerItem = 'dataViewer');
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DataViewerPage(),
                                ),
                              );
                            }
                          });
                        },
                      ),
                      _buildSubDrawerItem(
                        t['metadata'] ?? 'Metadata',
                        'metadata',
                        Icons.description,
                        () {
                          setState(() => _selectedDrawerItem = 'metadata');
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MetadataViewerPage(),
                                ),
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    Icons.info_outline,
                    t['about'] ?? 'About',
                    'About',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    Icons.contact_mail,
                    t['contactUs'] ?? 'Contact',
                    'Contact',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  Text(
                    '© ${DateTime.now().year} BGISP',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t['version'] ?? 'Version 1.0.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    String itemKey,
    VoidCallback onTap,
  ) {
    final bool isSelected = _selectedDrawerItem == itemKey;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppConstants.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? AppConstants.primaryColor : Colors.grey[700],
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppConstants.primaryColor : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          onTap: () {
            setState(() => _selectedDrawerItem = itemKey);
            onTap();
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildExpandableDrawerItem(
    IconData icon,
    String title,
    String sectionKey,
    List<Widget> children,
  ) {
    final bool hasSelectedChild = _selectedDrawerItem.startsWith(
      sectionKey.toLowerCase(),
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: hasSelectedChild
            ? AppConstants.primaryColor.withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(
              icon,
              color: hasSelectedChild
                  ? AppConstants.primaryColor
                  : Colors.grey[700],
              size: 22,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: hasSelectedChild
                    ? AppConstants.primaryColor
                    : Colors.grey[800],
                fontWeight: hasSelectedChild
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            childrenPadding: const EdgeInsets.only(
              left: 48,
              right: 8,
              bottom: 4,
            ),
            shape: const Border(),
            collapsedShape: const Border(),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: AppConstants.primaryColor,
            collapsedIconColor: Colors.grey[600],
            onExpansionChanged: (expanded) {
              setState(() => _expandedSection = expanded ? sectionKey : '');
            },
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildSubDrawerItem(
    String title,
    String itemKey,
    IconData icon,
    VoidCallback onTap,
  ) {
    final bool isSelected = _selectedDrawerItem == itemKey;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? AppConstants.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? AppConstants.primaryColor : Colors.grey[500],
            size: 18,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppConstants.primaryColor : Colors.grey[600],
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          onTap: () {
            setState(() => _selectedDrawerItem = itemKey);
            onTap();
          },
          dense: true,
          contentPadding: const EdgeInsets.only(left: 8, right: 12),
          visualDensity: VisualDensity.compact,
          minLeadingWidth: 24,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return const Text(
      'BGISP',
      style: TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAboutSection(Map<String, String> t) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF008080), Color(0xFF70d3d3)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF008080).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t['aboutBgisp'] ?? 'About BGISP',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 50,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF008080), Color(0xFF70d3d3)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          _buildAboutText(t['aboutBgispDesc1'] ?? ''),
          _buildAboutText(t['aboutBgispDesc2'] ?? ''),
          _buildAboutText(t['aboutBgispDesc3'] ?? ''),
          _buildAboutText(t['aboutBgispDesc4'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildAboutText(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppConstants.primaryColor.withOpacity(0.2),
            width: 3,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, height: 1.8, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildObjectiveAndStatisticsSection(Map<String, String> t) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey[200]!, Colors.blue[50]!]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 992) {
            return Column(
              children: [
                _buildObjectiveContent(t),
                const SizedBox(height: 30),
                _buildStatisticsGrid(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildObjectiveContent(t)),
              const SizedBox(width: 30),
              Expanded(child: _buildStatisticsGrid()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildObjectiveContent(Map<String, String> t) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF008080), Color(0xFF70d3d3)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF008080).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.gps_fixed,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t['objective'] ?? 'Our Objective',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2c3e50),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 50,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF008080), Color(0xFF70d3d3)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            t['objectiveText'] ?? '',
            style: TextStyle(
              fontSize: 16,
              height: 1.8,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final statistics = [
      StatisticCard(
        value: _isLoading ? '...' : _homeStats.mapCount.toString(),
        label: 'Map',
        icon: Icons.map,
        color: AppConstants.primaryColor,
        gradient: LinearGradient(colors: [Colors.teal[50]!, Colors.teal[100]!]),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GeoportalMapPage()),
          );
        },
      ),
      StatisticCard(
        value: _isLoading ? '...' : _focalPointsCount.toString(),
        label: 'Focal Points',
        icon: Icons.person_pin,
        color: AppConstants.secondaryColor,
        gradient: LinearGradient(
          colors: [Colors.indigo[50]!, Colors.indigo[100]!],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FocalPointPage()),
          );
        },
      ),
      StatisticCard(
        value: _isLoading ? '...' : _homeStats.metadataCount.toString(),
        label: 'Metadata',
        icon: Icons.description,
        color: AppConstants.accentColor,
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.orange[100]!],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MetadataViewerPage()),
          );
        },
      ),
      StatisticCard(
        value: _isLoading ? '...' : _homeStats.dataCount.toString(),
        label: 'Data',
        icon: Icons.storage,
        color: AppConstants.dangerColor,
        gradient: LinearGradient(colors: [Colors.red[50]!, Colors.red[100]!]),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DataViewerPage()),
          );
        },
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.0,
      ),
      itemCount: statistics.length,
      itemBuilder: (context, index) => statistics[index],
    );
  }

  void _handleLanguageToggle() {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    languageProvider.toggleLanguage();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}
