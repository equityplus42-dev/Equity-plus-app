import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/admin_products_provider.dart';
import '../../core/theme/app_theme.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProductsProvider>(context, listen: false).fetchProducts();
    });
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          'Create Product / Course Package',
          style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: GoogleFonts.outfit(color: AppTheme.lightText),
              decoration: const InputDecoration(
                labelText: 'Product Name (e.g. Master Trader Pro)',
                prefixIcon: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryPurple),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              style: GoogleFonts.outfit(color: AppTheme.lightText),
              decoration: const InputDecoration(
                labelText: 'Product Code (e.g. PROD_TRADER)',
                prefixIcon: Icon(Icons.qr_code, color: AppTheme.neonCyan),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              style: GoogleFonts.outfit(color: AppTheme.lightText),
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                prefixIcon: Icon(Icons.description, color: AppTheme.softGrey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              if (name.isEmpty || code.isEmpty) return;

              final provider = Provider.of<AdminProductsProvider>(context, listen: false);
              final success = await provider.createProduct(
                name: name,
                code: code,
                description: descController.text.trim(),
              );

              if (dialogCtx.mounted) Navigator.pop(dialogCtx);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Product "$name" created successfully! 📦'),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              }
            },
            child: const Text('Create Product'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prodProvider = Provider.of<AdminProductsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Layer Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Add Product',
            onPressed: _showAddProductDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: AppTheme.primaryPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('New Product', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: prodProvider.isLoading
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : prodProvider.products.isEmpty
                ? Center(
                    child: Text(
                      'No products created yet',
                      style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: prodProvider.products.length,
                    itemBuilder: (context, index) {
                      final prod = prodProvider.products[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: AppTheme.glassCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    prod.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.lightText,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: prod.status == 'AVAILABLE'
                                        ? AppTheme.neonGreen.withOpacity(0.15)
                                        : AppTheme.softGrey.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    prod.status,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: prod.status == 'AVAILABLE' ? AppTheme.neonGreen : AppTheme.softGrey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Code: ${prod.code}  •  ${prod.videoCount} Videos', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.neonCyan)),
                            if (prod.description != null && prod.description!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(prod.description!, style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                            ],
                            if (prod.status != 'ARCHIVED') ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.archive_outlined, size: 16, color: AppTheme.softGrey),
                                  label: Text('Archive', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey)),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppTheme.cardBg,
                                        title: const Text('Archive Product?'),
                                        content: Text('Archive "${prod.name}"?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                            child: const Text('Archive'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      prodProvider.archiveProduct(prod.id);
                                    }
                                  },
                                ),
                              )
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
