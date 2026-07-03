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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminHierarchyProvider>(context, listen: false).fetchGlobalHierarchy();
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
      default:
        return AppTheme.neonGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hierarchy = Provider.of<AdminHierarchyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Referral Map'),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: hierarchy.isLoading
            ? const Center(child: SpinKitFoldingCube(color: AppTheme.primaryPurple))
            : hierarchy.globalTree.isEmpty
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
                : RefreshIndicator(
                    onRefresh: () => hierarchy.fetchGlobalHierarchy(),
                    color: AppTheme.primaryPurple,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20.0),
                      itemCount: hierarchy.globalTree.length,
                      itemBuilder: (context, index) {
                        return _buildTreeNodeCard(hierarchy.globalTree[index]);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildTreeNodeCard(HierarchyNodeModel node) {
    final bool hasChildren = node.children.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: node.level * 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.glassCardDecoration().copyWith(
              border: Border.all(
                color: _getLevelColor(node.level).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _getLevelColor(node.level).withValues(alpha: 0.15),
                  backgroundImage: node.avatarUrl != null ? NetworkImage(node.avatarUrl!) : null,
                  child: node.avatarUrl == null
                      ? Text(
                          node.name.isNotEmpty ? node.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: _getLevelColor(node.level),
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
                        node.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightText,
                        ),
                      ),
                      Text(
                        node.email,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppTheme.softGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(node.level).withValues(alpha: 0.1),
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
          if (hasChildren)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                children: node.children.map((child) => _buildTreeNodeCard(child)).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
