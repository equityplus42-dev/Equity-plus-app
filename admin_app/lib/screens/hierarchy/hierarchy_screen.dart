import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_hierarchy_provider.dart';
import '../../models/hierarchy_model.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class HierarchyScreen extends StatefulWidget {
  const HierarchyScreen({super.key});

  @override
  State<HierarchyScreen> createState() => _HierarchyScreenState();
}

class _HierarchyScreenState extends State<HierarchyScreen> {
  HierarchyNodeModel? _currentRootNode;
  final List<HierarchyNodeModel> _history = [];
  bool _isNavigatingForward = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminHierarchyProvider>(context, listen: false).fetchGlobalHierarchy();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return AppTheme.primaryPurple;
      case 1:
        return AppTheme.primaryPink;
      case 2:
        return AppTheme.neonCyan;
      case 3:
      default:
        return AppTheme.neonGreen;
    }
  }

  HierarchyNodeModel? _findNodeById(HierarchyNodeModel node, String id) {
    if (node.id == id) return node;
    for (final child in node.children) {
      final res = _findNodeById(child, id);
      if (res != null) return res;
    }
    return null;
  }

  List<HierarchyNodeModel> _findNodes(HierarchyNodeModel node, String query) {
    final List<HierarchyNodeModel> results = [];
    final q = query.toLowerCase();
    
    if (node.name.toLowerCase().contains(q) ||
        node.email.toLowerCase().contains(q) ||
        node.referralCode.toLowerCase().contains(q) ||
        node.phoneNumber.toLowerCase().contains(q) ||
        node.panNumber.toLowerCase().contains(q) ||
        node.aadharNumber.toLowerCase().contains(q)) {
      results.add(node);
    }
    
    for (final child in node.children) {
      results.addAll(_findNodes(child, query));
    }
    
    return results;
  }

  bool _buildHistoryPath(HierarchyNodeModel current, String targetId, List<HierarchyNodeModel> path) {
    if (current.id == targetId) {
      return true;
    }
    
    for (final child in current.children) {
      path.add(current);
      if (_buildHistoryPath(child, targetId, path)) {
        return true;
      }
      path.removeLast();
    }
    
    return false;
  }

  void _showUserDetailsDialog(HierarchyNodeModel node) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Partner Profile',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightText,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.softGrey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.borderGrey),
                const SizedBox(height: 16),
                _buildDetailRow('Full Name', node.name),
                _buildDetailRow('Exclusive ID', node.referralCode.isNotEmpty ? node.referralCode : 'N/A'),
                _buildDetailRow('Mobile Number', node.phoneNumber.isNotEmpty ? node.phoneNumber : 'N/A'),
                _buildDetailRow('WhatsApp No.', node.whatsApp.isNotEmpty ? node.whatsApp : 'N/A'),
                _buildDetailRow('State', node.state.isNotEmpty ? node.state : 'N/A'),
                _buildDetailRow('District', node.district.isNotEmpty ? node.district : 'N/A'),
                _buildDetailRow('Email Address', node.email.isNotEmpty ? node.email : 'N/A'),
                _buildDetailRow('PAN Number', node.panNumber.isNotEmpty ? node.panNumber : 'N/A'),
                _buildDetailRow('Aadhar Number', node.aadharNumber.isNotEmpty ? node.aadharNumber : 'N/A'),
                _buildDetailRow('Points Balance', '${node.points} PTS'),
                _buildDetailRow('Hierarchy Level', node.level == 0 ? 'ROOT (Admin)' : 'Level ${node.level}'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.softGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(HierarchyNodeModel globalRoot) {
    final List<Widget> items = [];

    // Root button
    items.add(
      GestureDetector(
        onTap: () {
          if (_currentRootNode?.id != globalRoot.id) {
            setState(() {
              _isNavigatingForward = false;
              _history.clear();
              _currentRootNode = globalRoot;
            });
          }
        },
        child: Text(
          'ROOT',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _currentRootNode?.id == globalRoot.id
                ? AppTheme.primaryPurple
                : AppTheme.softGrey,
          ),
        ),
      ),
    );

    // History buttons
    for (int i = 0; i < _history.length; i++) {
      final node = _history[i];
      items.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0),
        child: Icon(Icons.chevron_right, size: 16, color: AppTheme.softGrey),
      ));
      
      items.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _isNavigatingForward = false;
              _currentRootNode = node;
              _history.removeRange(i, _history.length);
            });
          },
          child: Text(
            node.name,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.softGrey,
            ),
          ),
        ),
      );
    }

    // Current node name (not clickable)
    if (_currentRootNode != null && _currentRootNode!.id != globalRoot.id) {
      items.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0),
        child: Icon(Icons.chevron_right, size: 16, color: AppTheme.softGrey),
      ));
      items.add(
        Text(
          _currentRootNode!.name,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryPurple,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: AppTheme.glassCardDecoration(),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items,
        ),
      ),
    );
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final double dx = _isNavigatingForward ? 1.0 : -1.0;
    final begin = Offset(dx, 0.0);
    const end = Offset.zero;

    final slideAnimation = Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  Widget _buildFocusCard(HierarchyNodeModel node) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration().copyWith(
        gradient: LinearGradient(
          colors: [
            _getLevelColor(node.level).withOpacity(0.2),
            AppTheme.cardBg.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _getLevelColor(node.level).withOpacity(0.6),
          width: 2.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _getLevelColor(node.level).withOpacity(0.25),
            backgroundImage: node.avatarUrl != null ? NetworkImage(node.avatarUrl!) : null,
            child: node.avatarUrl == null
                ? Text(
                    node.name.isNotEmpty ? node.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: _getLevelColor(node.level),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        node.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getLevelColor(node.level).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        node.level == 0 ? 'ROOT' : 'L${node.level}',
                        style: TextStyle(
                          color: _getLevelColor(node.level),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  node.email,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.softGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (node.referralCode.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Exclusive ID: ${node.referralCode}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.lightText, size: 24),
            onPressed: () => _showUserDetailsDialog(node),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(HierarchyNodeModel child) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isNavigatingForward = true;
          if (_currentRootNode != null) {
            _history.add(_currentRootNode!);
          }
          _currentRootNode = child;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.glassCardDecoration(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _getLevelColor(child.level).withOpacity(0.15),
              backgroundImage: child.avatarUrl != null ? NetworkImage(child.avatarUrl!) : null,
              child: child.avatarUrl == null
                  ? Text(
                      child.name.isNotEmpty ? child.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: _getLevelColor(child.level),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    child.email,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.softGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getLevelColor(child.level).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                child.level == 0 ? 'ROOT' : 'L${child.level}',
                style: TextStyle(
                  color: _getLevelColor(child.level),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.info_outline, color: AppTheme.softGrey, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showUserDetailsDialog(child),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_right,
              color: AppTheme.softGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<HierarchyNodeModel> results, HierarchyNodeModel globalRoot) {
    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final node = results[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _isNavigatingForward = true;
              final List<HierarchyNodeModel> path = [];
              _buildHistoryPath(globalRoot, node.id, path);
              _history.clear();
              _history.addAll(path);
              _currentRootNode = node;
              _searchQuery = "";
              _searchController.clear();
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassCardDecoration(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getLevelColor(node.level).withOpacity(0.15),
                  backgroundImage: node.avatarUrl != null ? NetworkImage(node.avatarUrl!) : null,
                  child: node.avatarUrl == null
                      ? Text(
                          node.name.isNotEmpty ? node.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: _getLevelColor(node.level),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        node.email,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.softGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(node.level).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    node.level == 0 ? 'ROOT' : 'L${node.level}',
                    style: TextStyle(
                      color: _getLevelColor(node.level),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hierarchy = Provider.of<AdminHierarchyProvider>(context);
    final globalTree = hierarchy.globalTree;

    // Sync root selection on data load / refresh
    if (globalTree.isNotEmpty) {
      if (_currentRootNode == null) {
        _currentRootNode = globalTree.first;
      } else {
        final synced = _findNodeById(globalTree.first, _currentRootNode!.id);
        if (synced != null) {
          _currentRootNode = synced;
        } else {
          _currentRootNode = globalTree.first;
          _history.clear();
        }
      }
    }

    // Filter results if search is active
    final List<HierarchyNodeModel> searchResults = (_searchQuery.isNotEmpty && globalTree.isNotEmpty)
        ? _findNodes(globalTree.first, _searchQuery)
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Referral Map'),
        leading: _history.isNotEmpty && _searchQuery.isEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _isNavigatingForward = false;
                    _currentRootNode = _history.removeLast();
                  });
                },
              )
            : null,
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: hierarchy.isLoading
            ? const Center(child: SpinKitFoldingCube(color: AppTheme.primaryPurple))
            : globalTree.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_tree_outlined, size: 80, color: AppTheme.softGrey),
                        const SizedBox(height: 16),
                        Text(
                          'No Tree Nodes',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Container(
                          decoration: AppTheme.glassCardDecoration(),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                            style: GoogleFonts.outfit(color: AppTheme.lightText),
                            decoration: InputDecoration(
                              hintText: 'Search partner by Name, Email, ID, PAN, Mobile...',
                              hintStyle: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 14),
                              prefixIcon: const Icon(Icons.search, color: AppTheme.softGrey),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: AppTheme.softGrey),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = "";
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),

                      // If searching, show search results
                      if (_searchQuery.isNotEmpty)
                        Expanded(
                          child: searchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    'No matching partners found',
                                    style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 16),
                                  ),
                                )
                              : _buildSearchResults(searchResults, globalTree.first),
                        )
                      else ...[
                        // Breadcrumbs path
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: _buildBreadcrumbs(globalTree.first),
                        ),

                        // Drill-down content with transition animation
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => hierarchy.fetchGlobalHierarchy(),
                            color: AppTheme.primaryPurple,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: _buildTransition,
                                child: _currentRootNode == null
                                    ? const SizedBox()
                                    : Column(
                                        key: ValueKey<String>(_currentRootNode!.id),
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Prominent Focus Card
                                          _buildFocusCard(_currentRootNode!),
                                          const SizedBox(height: 24),

                                          // Children section title
                                          Text(
                                            'DIRECT REFERRALS (${_currentRootNode!.children.length})',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.softGrey,
                                              letterSpacing: 2.0,
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Children list
                                          if (_currentRootNode!.children.isEmpty)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 40.0),
                                              child: Center(
                                                child: Column(
                                                  children: [
                                                    const Icon(Icons.people_outline, size: 48, color: AppTheme.softGrey),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'No direct referrals under this partner',
                                                      style: GoogleFonts.outfit(
                                                        color: AppTheme.softGrey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                          else
                                            ListView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: _currentRootNode!.children.length,
                                              itemBuilder: (context, idx) {
                                                return _buildChildCard(_currentRootNode!.children[idx]);
                                              },
                                            ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}
