import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/hierarchy_model.dart';
import '../../core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CanvasTreeView extends StatefulWidget {
  final List<HierarchyNodeModel> tree;
  final Function(HierarchyNodeModel) onNodeTap;

  const CanvasTreeView({
    super.key,
    required this.tree,
    required this.onNodeTap,
  });

  @override
  State<CanvasTreeView> createState() => _CanvasTreeViewState();
}

class _CanvasTreeViewState extends State<CanvasTreeView> {
  final TransformationController _transformationController = TransformationController();
  final Map<String, Offset> _positions = {};
  double _totalWidth = 0;
  double _totalHeight = 0;

  @override
  void initState() {
    super.initState();
    _calculateLayout();
    // Center the initial view slightly after frame layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_totalWidth > 0) {
        final screenWidth = MediaQuery.of(context).size.width;
        final xTranslation = (screenWidth - _totalWidth) / 2;
        _transformationController.value = Matrix4.translationValues(xTranslation, 20.0, 0.0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CanvasTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateLayout();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _calculateLayout() {
    _positions.clear();
    if (widget.tree.isEmpty) return;

    double computedWidth = 0;
    for (var root in widget.tree) {
      computedWidth += _calculateTreeWidth(root);
    }
    
    // Add extra padding on the sides
    _totalWidth = max(computedWidth, 800.0);

    double startLeft = (_totalWidth - computedWidth) / 2;
    for (var root in widget.tree) {
      _computeNodePositions(root, startLeft, 60.0);
      startLeft += _calculateTreeWidth(root);
    }

    double maxDepth = 0;
    for (var root in widget.tree) {
      maxDepth = max(maxDepth, _calculateMaxDepth(root, 1));
    }
    _totalHeight = maxDepth * 160.0 + 120.0;
  }

  double _calculateTreeWidth(HierarchyNodeModel node) {
    if (node.children.isEmpty) {
      return 140.0; // card width (110) + spacing (30)
    }
    double total = 0;
    for (var child in node.children) {
      total += _calculateTreeWidth(child);
    }
    return total;
  }

  double _calculateMaxDepth(HierarchyNodeModel node, int currentDepth) {
    if (node.children.isEmpty) {
      return currentDepth.toDouble();
    }
    double maxD = currentDepth.toDouble();
    for (var child in node.children) {
      maxD = max(maxD, _calculateMaxDepth(child, currentDepth + 1));
    }
    return maxD;
  }

  void _computeNodePositions(HierarchyNodeModel node, double left, double y) {
    double w = _calculateTreeWidth(node);
    double centerX = left + w / 2;
    _positions[node.id] = Offset(centerX, y);

    double currentLeft = left;
    for (var child in node.children) {
      _computeNodePositions(child, currentLeft, y + 160.0);
      currentLeft += _calculateTreeWidth(child);
    }
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

  void _zoom(double factor) {
    final double currentScale = _transformationController.value.getMaxScaleOnAxis();
    final double targetScale = currentScale * factor;
    if (targetScale < 0.1 || targetScale > 3.0) return;

    setState(() {
      _transformationController.value = _transformationController.value.clone()..scale(factor);
    });
  }

  void _resetView() {
    setState(() {
      if (_totalWidth > 0) {
        final screenWidth = MediaQuery.of(context).size.width;
        final xTranslation = (screenWidth - _totalWidth) / 2;
        _transformationController.value = Matrix4.translationValues(xTranslation, 20.0, 0.0);
      } else {
        _transformationController.value = Matrix4.identity();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tree.isEmpty) {
      return const SizedBox();
    }

    return Stack(
      children: [
        // Interactive Canvas
        InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(1000.0),
          minScale: 0.1,
          maxScale: 3.0,
          child: SizedBox(
            width: _totalWidth,
            height: _totalHeight,
            child: Stack(
              children: [
                // Paint Lines between nodes
                CustomPaint(
                  size: Size(_totalWidth, _totalHeight),
                  painter: _TreeLinePainter(
                    positions: _positions,
                    tree: widget.tree,
                    levelColor: _getLevelColor,
                  ),
                ),
                // Render Node cards
                ..._positions.entries.map((entry) {
                  final nodeId = entry.key;
                  final position = entry.value;
                  final node = _findNodeInTree(widget.tree, nodeId);
                  if (node == null) return const SizedBox();

                  return Positioned(
                    left: position.dx - 55, // Center the 110px card
                    top: position.dy - 40,  // Center the 80px card
                    child: _buildNodeCard(node),
                  );
                }),
              ],
            ),
          ),
        ),

        // Zoom Controls Overlay
        Positioned(
          bottom: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(
                icon: Icons.add,
                onPressed: () => _zoom(1.2),
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                icon: Icons.remove,
                onPressed: () => _zoom(0.8),
              ),
              const SizedBox(height: 8),
              _buildControlButton(
                icon: Icons.center_focus_strong_outlined,
                onPressed: _resetView,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.lightText),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildNodeCard(HierarchyNodeModel node) {
    final themeColor = _getLevelColor(node.level);

    return GestureDetector(
      onTap: () => widget.onNodeTap(node),
      child: Container(
        width: 110,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardBg.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeColor.withOpacity(0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: themeColor.withOpacity(0.2),
              child: Text(
                node.name.isNotEmpty ? node.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              node.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightText,
              ),
            ),
            Text(
              node.level == 0 ? 'YOU' : 'Level ${node.level}',
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: AppTheme.softGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  HierarchyNodeModel? _findNodeInTree(List<HierarchyNodeModel> tree, String id) {
    for (var node in tree) {
      if (node.id == id) return node;
      final childResult = _findNodeInTree(node.children, id);
      if (childResult != null) return childResult;
    }
    return null;
  }
}

class _TreeLinePainter extends CustomPainter {
  final Map<String, Offset> positions;
  final List<HierarchyNodeModel> tree;
  final Color Function(int) levelColor;

  _TreeLinePainter({
    required this.positions,
    required this.tree,
    required this.levelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    void drawNodeConnections(HierarchyNodeModel node) {
      final parentPos = positions[node.id];
      if (parentPos == null) return;

      for (var child in node.children) {
        final childPos = positions[child.id];
        if (childPos != null) {
          paint.color = levelColor(child.level).withOpacity(0.5);

          // Draw bezier curve from bottom of parent to top of child
          final startY = parentPos.dy + 40; // parent bottom
          final endY = childPos.dy - 40;   // child top

          final path = Path()
            ..moveTo(parentPos.dx, startY)
            ..cubicTo(
              parentPos.dx,
              startY + 50,
              childPos.dx,
              endY - 50,
              childPos.dx,
              endY,
            );

          canvas.drawPath(path, paint);
          drawNodeConnections(child);
        }
      }
    }

    for (var root in tree) {
      drawNodeConnections(root);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeLinePainter oldDelegate) {
    return oldDelegate.positions != positions || oldDelegate.tree != tree;
  }
}
