import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hierarchy_provider.dart';
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
      Provider.of<HierarchyProvider>(context, listen: false).fetchHierarchy();
    });
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return AppTheme.primaryPurple;
      case 2:
        return AppTheme.primaryPink;
      case 3:
        return AppTheme.neonCyan;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hierarchyProvider = Provider.of<HierarchyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Hierarchy Tree'),
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

    return Padding(
      padding: EdgeInsets.only(left: node.level * 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
              ],
            ),
          ),
          if (hasChildren)
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
