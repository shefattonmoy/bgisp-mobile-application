import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/SubCommittee/sub_committee_api.dart';
import '../../models/SubCommittee/sub_committee.dart';
import '../../providers/language_provider.dart';

class SubCommitteePage extends StatefulWidget {
  const SubCommitteePage({super.key});

  @override
  State<SubCommitteePage> createState() => _SubCommitteePageState();
}

class _SubCommitteePageState extends State<SubCommitteePage> {
  final SubCommitteeApi _api = SubCommitteeApi();

  bool _isLoading = true;
  String? _error;
  List<SubCommitteeMember> _members = [];
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false).language;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final members = await _api.getSubCommitteeMembers(
        lang: lang.toLowerCase(),
      );
      if (mounted) {
        setState(() {
          _members = members;
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

  List<SubCommitteeMember> get _filtered {
    if (_searchTerm.isEmpty) return _members;
    final q = _searchTerm.toLowerCase();
    return _members
        .where(
          (m) =>
              '${m.displayName} ${m.displayDesignation} '
                      '${m.displayRole} ${m.organization ?? ''}'
                  .toLowerCase()
                  .contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isBangla = langProvider.language == 'BN';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBangla ? 'সাব কমিটি' : 'Sub Committee'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(isBangla)),
    );
  }

  Widget _buildBody(bool isBangla) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _load,
            ),
          ),
        ],
      );
    }

    if (_members.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No sub-committee members',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Members will appear here once added.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }

    final filtered = _filtered;

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: isBangla ? 'খুঁজুন...' : 'Search members...',
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
                      onPressed: () => setState(() => _searchTerm = ''),
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
            onChanged: (v) => setState(() => _searchTerm = v),
          ),
        ),

        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isBangla
                  ? '${filtered.length} জন সদস্য'
                  : '${filtered.length} member${filtered.length == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ),

        // Members grid / list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    isBangla ? 'কোনো ফলাফল নেই' : 'No results',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 900
                        ? 4
                        : constraints.maxWidth >= 600
                        ? 3
                        : 2;

                    return GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _buildMemberCard(filtered[index], isBangla),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(SubCommitteeMember member, bool isBangla) {
    final accent = const Color(0xFF667eea);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo / avatar
          Expanded(
            flex: 5,
            child: Container(
              color: accent.withOpacity(0.08),
              child: Center(child: _buildAvatar(member, accent)),
            ),
          ),

          // Info
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBangla ? member.displayNameBn : member.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0f172a),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isBangla
                        ? member.displayDesignationBn
                        : member.displayDesignation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (member.displayRole.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isBangla ? member.displayRoleBn : member.displayRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (member.organization != null &&
                      member.organization!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 11,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            member.organization!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(SubCommitteeMember member, Color accent) {
    final imageUrl = _resolveImageUrl(member.imagePath);

    if (imageUrl != null) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(member, accent),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: 80,
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }

    return _initialsAvatar(member, accent);
  }

  Widget _initialsAvatar(SubCommitteeMember member, Color accent) {
    final name = member.displayName;
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0].toUpperCase())
              .join();

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [accent, accent.withOpacity(0.6)]),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
      ),
    );
  }

  String? _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) {
      // Django returns /storage/... — prepend host.
      return '$_host$path';
    }
    return '$_host/storage/$path';
  }

  String get _host {
    // Reuse the host from AppConstants.myAPILink.
    final uri = Uri.tryParse(
      Provider.of<LanguageProvider>(context, listen: false).toString(),
    );
    // Fallback: hardcode from AppConstants — we only need origin.
    final base = _apiBase;
    final u = Uri.tryParse(base);
    if (u == null) return base;
    return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
  }

  String get _apiBase {
    final uri = Uri.tryParse(uriString);
    return uriString;
  }
}
