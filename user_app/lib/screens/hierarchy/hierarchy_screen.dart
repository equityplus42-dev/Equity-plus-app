import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hierarchy_provider.dart';
import '../../models/hierarchy_model.dart';
import '../../core/theme/app_theme.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'canvas_tree_view.dart';

class HierarchyScreen extends StatefulWidget {
  const HierarchyScreen({super.key});

  @override
  State<HierarchyScreen> createState() => _HierarchyScreenState();
}

class _HierarchyScreenState extends State<HierarchyScreen> {
  final Set<String> _expandedNodeIds = {};
  bool _isTreeView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HierarchyProvider>(context, listen: false).fetchHierarchy();
    });
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
        return AppTheme.neonGreen;
      default:
        return Colors.white;
    }
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
                _buildDetailRow('Email Address', node.email.isNotEmpty ? node.email : 'N/A'),
                if (node.level == 0) ...[
                  _buildDetailRow('WhatsApp No.', node.whatsApp.isNotEmpty ? node.whatsApp : 'N/A'),
                  _buildDetailRow('State', node.state.isNotEmpty ? node.state : 'N/A'),
                  _buildDetailRow('District', node.district.isNotEmpty ? node.district : 'N/A'),
                  _buildDetailRow('PAN Number', node.panNumber.isNotEmpty ? node.panNumber : 'N/A'),
                  _buildDetailRow('Aadhar Number', node.aadharNumber.isNotEmpty ? node.aadharNumber : 'N/A'),
                ],
                _buildDetailRow('Points Balance', '${node.points} PTS'),
                _buildDetailRow('Hierarchy Level', node.level == 0 ? 'YOU (Root)' : 'Level ${node.level}'),
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

  @override
  Widget build(BuildContext context) {
    final hierarchyProvider = Provider.of<HierarchyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Hierarchy Tree'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_in_picture_alt_outlined),
            tooltip: 'Dock to PiP',
            onPressed: () {
              Navigator.pop(context, 'dock');
            },
          ),
          if (!hierarchyProvider.isLoading && hierarchyProvider.hierarchyTree.isNotEmpty)
            IconButton(
              icon: Icon(_isTreeView ? Icons.list : Icons.bubble_chart_outlined),
              tooltip: _isTreeView ? 'List View' : 'Tree Canvas',
              onPressed: () {
                setState(() {
                  _isTreeView = !_isTreeView;
                });
              },
            ),
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: hierarchyProvider.isLoading
            ? const Center(
                child: SpinKitFoldingCube(
                  color: AppTheme.primaryPurple,
                  size: 50.0,
                ),
              )
            : hierarchyProvider.hierarchyTree.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_tree_outlined, size: 80, color: AppTheme.softGrey),
                        const SizedBox(height: 16),
                        Text(
                          'No Hierarchy Data',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Text(
                            'Your referral network tree will build out here once signups occur.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: AppTheme.softGrey),
                          ),
                        ),
                      ],
                    ),
                  )
                : _isTreeView
                    ? CanvasTreeView(
                        tree: hierarchyProvider.hierarchyTree,
                        onNodeTap: _showUserDetailsDialog,
                      )
                    : RefreshIndicator(
                        onRefresh: () => hierarchyProvider.fetchHierarchy(),
                        color: AppTheme.primaryPurple,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20.0),
                          itemCount: hierarchyProvider.hierarchyTree.length,
                          itemBuilder: (context, index) {
                            final rootNode = hierarchyProvider.hierarchyTree[index];
                            return _buildNodeCard(rootNode);
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildNodeCard(HierarchyNodeModel node) {
    final bool hasChildren = node.children.isNotEmpty;
    final bool isExpanded = _expandedNodeIds.contains(node.id);

    return Padding(
      padding: EdgeInsets.only(left: node.level * 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: hasChildren
                ? () {
                    setState(() {
                      if (isExpanded) {
                        _expandedNodeIds.remove(node.id);
                      } else {
                        _expandedNodeIds.add(node.id);
                      }
                    });
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.glassCardDecoration().copyWith(
                border: Border.all(
                  color: _getLevelColor(node.level).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Level Indicator Dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getLevelColor(node.level),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getLevelColor(node.level).withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        )
                      ]
                    ),
                  ),
                  const SizedBox(width: 14),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.lightText,
                          ),
                        ),
                        Text(
                          node.email,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.softGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tier Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getLevelColor(node.level).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      node.level == 0 ? 'YOU' : 'L${node.level}',
                      style: TextStyle(
                        color: _getLevelColor(node.level),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: AppTheme.softGrey, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showUserDetailsDialog(node),
                  ),
                  if (hasChildren) ...[
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: AppTheme.softGrey,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasChildren && isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: node.children.map((child) => _buildNodeCard(child)).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
