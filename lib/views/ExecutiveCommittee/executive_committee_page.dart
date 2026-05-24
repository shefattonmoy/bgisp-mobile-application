import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/ExecutiveCommittee/executive_committee_api.dart';
import '../../models/ExecutiveCommittee/executive_committee.dart';
import '../../providers/language_provider.dart';

class ExecutiveCommitteePage extends StatefulWidget {
  const ExecutiveCommitteePage({super.key});

  @override
  State<ExecutiveCommitteePage> createState() => _ExecutiveCommitteePageState();
}

class _ExecutiveCommitteePageState extends State<ExecutiveCommitteePage>
    with SingleTickerProviderStateMixin {
  final ExecutiveCommitteeApi _api = ExecutiveCommitteeApi();
  late TabController _tabController;

  List<ExecutiveCommitteeMember> _members = [];
  List<ExecutiveCommitteeMember> _filteredMembers = [];
  bool _isLoading = true;
  String? _error;
  String _memberSearchTerm = '';
  String _meetingSearchTerm = '';
  String _noticeSearchTerm = '';
  int _currentPage = 0;
  final int _rowsPerPage = 6;

  // Hardcoded meetings data
  final List<Meeting> _allMeetings = [
    Meeting(
      id: 1,
      title: 'Q1 Executive Strategy Meeting',
      description:
          'Quarterly executive strategy session to review organizational goals, budget allocations, and key performance indicators.',
      date: '2024-01-10',
    ),
    Meeting(
      id: 2,
      title: 'Annual General Assembly',
      description:
          'Annual general assembly meeting with all executive committee members and stakeholders.',
      date: '2024-02-15',
    ),
    Meeting(
      id: 3,
      title: 'Policy Review Board Meeting',
      description:
          'Comprehensive review of organizational policies and procedures.',
      date: '2024-03-05',
    ),
    Meeting(
      id: 4,
      title: 'Stakeholder Engagement Forum',
      description: 'Forum to engage with key stakeholders and partners.',
      date: '2024-04-12',
    ),
    Meeting(
      id: 5,
      title: 'Executive Leadership Summit',
      description:
          'Leadership summit focusing on organizational development and succession planning.',
      date: '2024-05-20',
    ),
  ];

  // Hardcoded notices data
  final List<Notice> _allNotices = [
    Notice(
      id: 1,
      title: 'Executive Committee Election Notice',
      description:
          'Notice for election of Executive Committee members for the term 2024-2026.',
      publishedDate: '2024-01-05',
      hasAttachment: true,
    ),
    Notice(
      id: 2,
      title: 'Budget Approval Meeting Announcement',
      description:
          'The annual budget approval meeting will be held on February 20th, 2024.',
      publishedDate: '2024-01-25',
      hasAttachment: true,
    ),
    Notice(
      id: 3,
      title: 'Policy Amendment Notification',
      description:
          'Notice of proposed amendments to the organizational bylaws and governance policies.',
      publishedDate: '2024-02-10',
      hasAttachment: true,
    ),
    Notice(
      id: 4,
      title: 'Annual Report Publication',
      description:
          'The Executive Committee announces the publication of the Annual Report for 2023-2024.',
      publishedDate: '2024-03-01',
      hasAttachment: true,
    ),
    Notice(
      id: 5,
      title: 'Special General Meeting Notice',
      description:
          'A Special General Meeting is scheduled for April 5th, 2024.',
      publishedDate: '2024-03-20',
    ),
  ];

  // Filtered lists
  List<Meeting> get _filteredMeetings {
    if (_meetingSearchTerm.isEmpty) return _allMeetings;
    final q = _meetingSearchTerm.toLowerCase();
    return _allMeetings
        .where(
          (m) =>
              m.title.toLowerCase().contains(q) ||
              m.description.toLowerCase().contains(q) ||
              m.date.contains(q),
        )
        .toList();
  }

  List<Notice> get _filteredNotices {
    if (_noticeSearchTerm.isEmpty) return _allNotices;
    final q = _noticeSearchTerm.toLowerCase();
    return _allNotices
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.description.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMembers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
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
      final members = await _api.getExecutiveCommittees(lang: lang);
      if (mounted) {
        setState(() {
          _members = members;
          _filteredMembers = members;
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

  void _filterMembers(String query) {
    setState(() {
      _memberSearchTerm = query;
      _filteredMembers = query.isEmpty
          ? _members
          : _members
                .where(
                  (m) =>
                      (m.organization?.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ??
                          false) ||
                      (m.committeeRole?.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ??
                          false) ||
                      (m.designation?.toLowerCase().contains(
                            query.toLowerCase(),
                          ) ??
                          false),
                )
                .toList();
      _currentPage = 0;
    });
  }

  int get _totalPages => (_filteredMembers.length / _rowsPerPage).ceil();
  List<ExecutiveCommitteeMember> get _currentPageData {
    final start = _currentPage * _rowsPerPage;
    return _filteredMembers.sublist(
      start,
      start + _rowsPerPage > _filteredMembers.length
          ? _filteredMembers.length
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
        title: Text(t['executiveCommittee'] ?? 'Executive Committee'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF008080),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF008080),
          tabs: const [
            Tab(text: 'Members', icon: Icon(Icons.people, size: 20)),
            Tab(text: 'Meetings', icon: Icon(Icons.event, size: 20)),
            Tab(text: 'Notices', icon: Icon(Icons.description, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMembersTab(), _buildMeetingsTab(), _buildNoticesTab()],
      ),
    );
  }

  // Members Tab
  Widget _buildMembersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: '🔍 Search members...',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _memberSearchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _filterMembers(''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _filterMembers,
          ),
        ),
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_filteredMembers.length} members',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              if (_memberSearchTerm.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '• Search: "$_memberSearchTerm"',
                  style: const TextStyle(
                    color: Color(0xFF008080),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Cards Grid
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
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMembers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _filteredMembers.isEmpty
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
                      Text(
                        _memberSearchTerm.isNotEmpty
                            ? 'No members match your search'
                            : 'No members found',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
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
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _currentPageData.length,
                  itemBuilder: (context, index) =>
                      _buildMemberCard(_currentPageData[index]),
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
    );
  }

  Widget _buildMemberCard(ExecutiveCommitteeMember member) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image with error handling
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF008080).withOpacity(0.1),
            ),
            child: ClipOval(
              child: member.image != null && member.image!.isNotEmpty
                  ? Image.network(
                      member.imageUrl,
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.business,
                          color: Color(0xFF008080),
                          size: 30,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF008080),
                          ),
                        );
                      },
                    )
                  : const Icon(
                      Icons.business,
                      color: Color(0xFF008080),
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            member.organization ?? '—',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF1e293b),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFe67e22).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              member.committeeRole ?? '—',
              style: const TextStyle(
                color: Color(0xFFe67e22),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            member.designation ?? '—',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Meetings Tab
  Widget _buildMeetingsTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: '🔍 Search meetings...',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _meetingSearchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _meetingSearchTerm = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (v) => setState(() => _meetingSearchTerm = v),
          ),
        ),
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_filteredMeetings.length} meetings',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              if (_meetingSearchTerm.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '• Search: "$_meetingSearchTerm"',
                  style: const TextStyle(
                    color: Color(0xFF008080),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Meetings list
        Expanded(
          child: _filteredMeetings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _meetingSearchTerm.isNotEmpty
                            ? 'No meetings match your search'
                            : 'No meetings found',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredMeetings.length,
                  itemBuilder: (context, index) {
                    final meeting = _filteredMeetings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF008080).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.event,
                                color: Color(0xFF008080),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    meeting.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Color(0xFF1e293b),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    meeting.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Color(0xFF008080),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        meeting.date,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF008080),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Notices Tab
  Widget _buildNoticesTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: '🔍 Search notices...',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _noticeSearchTerm.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _noticeSearchTerm = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (v) => setState(() => _noticeSearchTerm = v),
          ),
        ),
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${_filteredNotices.length} notices',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              if (_noticeSearchTerm.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '• Search: "$_noticeSearchTerm"',
                  style: const TextStyle(
                    color: Color(0xFF008080),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Notices grid
        Expanded(
          child: _filteredNotices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 60,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _noticeSearchTerm.isNotEmpty
                            ? 'No notices match your search'
                            : 'No notices found',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600
                        ? 3
                        : 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _filteredNotices.length,
                  itemBuilder: (context, index) {
                    final notice = _filteredNotices[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.description,
                                  color: Color(0xFF008080),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notice.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF1e293b),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Text(
                                notice.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Color(0xFF008080),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notice.publishedDate,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF008080),
                                  ),
                                ),
                                const Spacer(),
                                if (notice.hasAttachment)
                                  const Icon(
                                    Icons.attach_file,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
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
