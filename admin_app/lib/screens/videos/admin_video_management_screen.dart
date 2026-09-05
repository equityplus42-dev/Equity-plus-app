import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:convert';
import '../../providers/admin_languages_provider.dart';
import '../../providers/admin_videos_provider.dart';
import '../../providers/admin_categories_provider.dart';
import '../../core/storage/storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import 'admin_video_assignments_screen.dart';

class AdminVideoManagementScreen extends StatefulWidget {
  const AdminVideoManagementScreen({super.key});

  @override
  State<AdminVideoManagementScreen> createState() => _AdminVideoManagementScreenState();
}

class _AdminVideoManagementScreenState extends State<AdminVideoManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedLanguageId;
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final langProvider = Provider.of<AdminLanguagesProvider>(context, listen: false);
      final catProvider = Provider.of<AdminCategoriesProvider>(context, listen: false);
      await catProvider.fetchCategories();
      await langProvider.fetchLanguages();
      if (langProvider.languages.isNotEmpty) {
        setState(() {
          _selectedLanguageId = langProvider.languages.first.id;
        });
        if (mounted) {
          Provider.of<AdminVideosProvider>(context, listen: false)
              .fetchVideos(languageId: _selectedLanguageId);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddLanguageDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            'Add Language Folder',
            style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.outfit(color: AppTheme.lightText),
                decoration: const InputDecoration(
                  labelText: 'Language Name (e.g. Tamil, Marathi)',
                  prefixIcon: Icon(Icons.language, color: AppTheme.primaryPurple),
                ),
                onChanged: (val) {
                  if (codeController.text.isEmpty && val.trim().length >= 2) {
                    setDialogState(() {
                      codeController.text = val.trim().substring(0, val.trim().length >= 3 ? 3 : 2).toLowerCase();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                style: GoogleFonts.outfit(color: AppTheme.lightText),
                decoration: const InputDecoration(
                  labelText: 'Language Code (e.g. ta, mr)',
                  prefixIcon: Icon(Icons.code, color: AppTheme.neonCyan),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isCreating ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isCreating
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      String code = codeController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Language name is required')),
                        );
                        return;
                      }

                      if (code.isEmpty) {
                        code = name.substring(0, name.length >= 3 ? 3 : name.length).toLowerCase();
                      }

                      setDialogState(() {
                        isCreating = true;
                      });

                      final langProvider = Provider.of<AdminLanguagesProvider>(context, listen: false);
                      final success = await langProvider.createLanguage(name, code);

                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                      if (success && mounted) {
                        final newLang = langProvider.languages.firstWhere(
                          (l) => l.name.toLowerCase() == name.toLowerCase(),
                          orElse: () => langProvider.languages.last,
                        );
                        setState(() {
                          _selectedLanguageId = newLang.id;
                        });
                        if (mounted) {
                          Provider.of<AdminVideosProvider>(context, listen: false)
                              .fetchVideos(languageId: newLang.id);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Language folder "$name" created successfully! 🎉'),
                            backgroundColor: AppTheme.neonGreen,
                          ),
                        );
                      } else if (mounted) {
                        final err = langProvider.errorMessage ?? 'Failed to create language folder';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $err'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              child: isCreating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Folder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageCategoriesDialog() {
    final catProvider = Provider.of<AdminCategoriesProvider>(context, listen: false);
    catProvider.fetchCategories();

    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            'Manage Video Categories',
            style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADD NEW CATEGORY',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonCyan,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.outfit(color: AppTheme.lightText),
                    decoration: const InputDecoration(
                      labelText: 'Category Name (e.g. Leadership)',
                      prefixIcon: Icon(Icons.category, color: AppTheme.neonCyan),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    style: GoogleFonts.outfit(color: AppTheme.lightText),
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: Icon(Icons.description, color: AppTheme.softGrey),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isCreating
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Category name is required')),
                                );
                                return;
                              }
                              setDialogState(() { isCreating = true; });
                              final success = await catProvider.createCategory(name, descController.text.trim());
                              setDialogState(() { isCreating = false; });
                              if (success) {
                                nameController.clear();
                                descController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Category "$name" created! 🎉'), backgroundColor: AppTheme.neonGreen),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(catProvider.errorMessage ?? 'Error creating category'), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: isCreating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Add Category'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  Text(
                    'EXISTING CATEGORIES (${catProvider.categories.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.softGrey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  catProvider.categories.isEmpty
                      ? const Text('No categories added yet.', style: TextStyle(color: AppTheme.softGrey))
                      : Column(
                          children: catProvider.categories.map((cat) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: AppTheme.glassCardDecoration(),
                              child: Row(
                                children: [
                                  const Icon(Icons.folder_special_outlined, size: 18, color: AppTheme.neonCyan),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cat.name,
                                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.lightText),
                                        ),
                                        Text(
                                          '${cat.videoCount} videos',
                                          style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.softGrey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppTheme.cardBg,
                                          title: Text('Delete Category "${cat.name}"?'),
                                          content: const Text('Videos under this category will fallback to default category.'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await catProvider.deleteCategory(cat.id);
                                        setDialogState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadVideoDialog() {
    final langProvider = Provider.of<AdminLanguagesProvider>(context, listen: false);
    final catProvider = Provider.of<AdminCategoriesProvider>(context, listen: false);
    if (langProvider.languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create at least one language folder first.')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final thumbController = TextEditingController();
    String dialogLanguageId = _selectedLanguageId ?? langProvider.languages.first.id;
    String? dialogCategoryId = catProvider.categories.isNotEmpty ? catProvider.categories.first.id : null;
    String? dialogCategoryName = catProvider.categories.isNotEmpty ? catProvider.categories.first.name : 'Time Management';

    bool isUploadingFile = false;
    String? selectedFileName;
    String? uploadedCloudinaryUrl;
    String? uploadedR2ObjectKey;
    int uploadedVideoDuration = 0;
    int elapsedSeconds = 0;
    int uploadedBytes = 0;
    int totalBytes = 0;
    double uploadProgress = 0.0;
    Timer? uploadTimer;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (sbContext, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: Text(
            'Upload Video to Language Folder',
            style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: langProvider.languages.any((l) => l.id == dialogLanguageId)
                      ? dialogLanguageId
                      : (langProvider.languages.isNotEmpty ? langProvider.languages.first.id : null),
                  dropdownColor: AppTheme.cardBg,
                  style: GoogleFonts.outfit(color: AppTheme.lightText),
                  decoration: const InputDecoration(
                    labelText: 'Select Language Folder',
                    prefixIcon: Icon(Icons.folder_outlined, color: AppTheme.primaryPurple),
                  ),
                  items: () {
                    final Map<String, dynamic> uniqueLangs = {};
                    for (final l in langProvider.languages) {
                      uniqueLangs[l.id] = l;
                    }
                    return uniqueLangs.values.map((l) {
                      return DropdownMenuItem<String>(
                        value: l.id,
                        child: Text('${l.name} (${l.code})'),
                      );
                    }).toList();
                  }(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        dialogLanguageId = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Category Dropdown Selection
                DropdownButtonFormField<String>(
                  value: catProvider.categories.any((c) => c.id == dialogCategoryId)
                      ? dialogCategoryId
                      : (catProvider.categories.isNotEmpty ? catProvider.categories.first.id : null),
                  dropdownColor: AppTheme.cardBg,
                  style: GoogleFonts.outfit(color: AppTheme.lightText),
                  decoration: const InputDecoration(
                    labelText: 'Select Category (e.g. Time Management)',
                    prefixIcon: Icon(Icons.category_outlined, color: AppTheme.neonGreen),
                  ),
                  items: catProvider.categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final selectedCat = catProvider.categories.firstWhere((c) => c.id == val);
                      setDialogState(() {
                        dialogCategoryId = val;
                        dialogCategoryName = selectedCat.name;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: 'CLOUDFLARE_R2',
                  isExpanded: true,
                  dropdownColor: AppTheme.cardBg,
                  style: GoogleFonts.outfit(color: AppTheme.lightText, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Cloud Storage & Streaming Provider',
                    prefixIcon: Icon(Icons.cloud_queue_rounded, color: AppTheme.neonCyan),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'CLOUDFLARE_R2',
                      child: Text('⚡ Cloudflare R2 Bucket (Direct High Speed)', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: null,
                ),
                const SizedBox(height: 14),
                // Device File Picker Dropzone Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isUploadingFile
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                            if (video != null) {
                              elapsedSeconds = 0;
                              uploadedBytes = 0;
                              totalBytes = 0;
                              uploadProgress = 0.0;
                              setDialogState(() {
                                isUploadingFile = true;
                                selectedFileName = video.name;
                              });

                              // Start live elapsed timer
                              uploadTimer?.cancel();
                              uploadTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                                setDialogState(() {
                                  elapsedSeconds++;
                                });
                              });

                              try {
                                final token = StorageService().getToken();
                                final totalLength = await video.length();
                                setDialogState(() {
                                  totalBytes = totalLength;
                                });

                                final ext = video.name.toLowerCase().split('.').last;
                                final mimeType = const {
                                  'mp4': 'video/mp4',
                                  'mov': 'video/quicktime',
                                  'avi': 'video/x-msvideo',
                                  'mkv': 'video/x-matroska',
                                  'webm': 'video/webm',
                                  'flv': 'video/x-flv',
                                  'wmv': 'video/x-ms-wmv',
                                  'm4v': 'video/mp4',
                                  '3gp': 'video/3gpp',
                                  'mpeg': 'video/mpeg',
                                  'mpg': 'video/mpeg',
                                }[ext] ?? 'video/mp4';

                                // ── Direct Presigned PUT to Cloudflare R2 Storage (Supports 30MB-40MB+ high speed) ──
                                try {
                                  final presignedUri = Uri.parse('${ApiConstants.baseUrl}/upload-pipeline/presigned-url');
                                  final presignedRes = await http.post(
                                    presignedUri,
                                    headers: {
                                      'Content-Type': 'application/json',
                                      if (token != null) 'Authorization': 'Bearer $token',
                                    },
                                    body: jsonEncode({
                                      'folder': 'videos',
                                      'filename': video.name,
                                      'mimeType': mimeType,
                                    }),
                                  );

                                  if (presignedRes.statusCode == 200 || presignedRes.statusCode == 201) {
                                    final pData = jsonDecode(presignedRes.body);
                                    final uploadUrl = pData['data']?['uploadUrl'];
                                    final r2Key = pData['data']?['r2ObjectKey'];
                                    final publicUrl = pData['data']?['publicUrl'];

                                    if (uploadUrl != null && r2Key != null) {
                                      final videoBytes = await video.readAsBytes();
                                      setDialogState(() {
                                        uploadedBytes = totalLength;
                                        uploadProgress = 1.0;
                                      });

                                      final putResponse = await http.put(
                                        Uri.parse(uploadUrl),
                                        headers: {'Content-Type': mimeType},
                                        body: videoBytes,
                                      );

                                      if (putResponse.statusCode == 200 || putResponse.statusCode == 201 || putResponse.statusCode == 204) {
                                        int dur = 0;
                                        if (publicUrl != null && publicUrl.toString().isNotEmpty) {
                                          try {
                                            final probe = VideoPlayerController.networkUrl(Uri.parse(publicUrl.toString()));
                                            await probe.initialize();
                                            dur = probe.value.duration.inSeconds;
                                            await probe.dispose();
                                          } catch (e) {
                                            debugPrint('Duration probe info: $e');
                                          }
                                        }

                                        setDialogState(() {
                                          uploadedCloudinaryUrl = publicUrl;
                                          uploadedR2ObjectKey = r2Key;
                                          uploadedVideoDuration = dur;
                                          if (titleController.text.trim().isEmpty) {
                                            titleController.text = video.name.replaceAll(RegExp(r'\.[^.]+$'), '');
                                          }
                                        });
                                      } else {
                                        if (dialogCtx.mounted) {
                                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                            SnackBar(content: Text('Cloudflare R2 upload failed (${putResponse.statusCode})'), backgroundColor: Colors.redAccent),
                                          );
                                        }
                                      }
                                    }
                                  } else {
                                    if (dialogCtx.mounted) {
                                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                        SnackBar(content: Text('Could not get R2 upload presigned URL (${presignedRes.statusCode})'), backgroundColor: Colors.redAccent),
                                      );
                                    }
                                  }
                                } catch (r2Err) {
                                  debugPrint('Cloudflare R2 upload error: $r2Err');
                                  if (dialogCtx.mounted) {
                                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                      SnackBar(content: Text('Cloudflare R2 upload error: $r2Err'), backgroundColor: Colors.redAccent),
                                    );
                                  }
                                }
                              } catch (e) {
                                debugPrint('Error uploading video file: $e');
                                if (dialogCtx.mounted) {
                                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString().replaceAll('Exception: ', '')),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              } finally {
                                uploadTimer?.cancel();
                                uploadTimer = null;
                                setDialogState(() {
                                  isUploadingFile = false;
                                });
                              }
                            }
                          },
                    icon: isUploadingFile
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonCyan),
                          )
                        : Icon(
                            uploadedCloudinaryUrl != null ? Icons.check_circle : Icons.cloud_upload,
                            color: uploadedCloudinaryUrl != null ? AppTheme.neonGreen : AppTheme.primaryPurple,
                          ),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUploadingFile
                              ? (uploadProgress >= 0.99
                                  ? '⚡ Processing & Securing on Cloudflare R2... Please wait'
                                  : 'Uploading (${(uploadedBytes / 1024 / 1024).toStringAsFixed(1)} MB / ${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB — ${(uploadProgress * 100).toStringAsFixed(0)}%)...')
                              : (uploadedCloudinaryUrl != null
                                  ? '✓ File Uploaded (${uploadedVideoDuration >= 60 ? "${uploadedVideoDuration ~/ 60}m ${uploadedVideoDuration % 60}s" : "${uploadedVideoDuration}s"} duration)'
                                  : (selectedFileName != null ? 'Selected: $selectedFileName' : 'Select / Drag Video File')),
                          style: GoogleFonts.outfit(
                            color: uploadedCloudinaryUrl != null ? AppTheme.neonGreen : AppTheme.lightText,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (isUploadingFile) ...[  
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: uploadProgress > 0 ? uploadProgress : null,
                            backgroundColor: Colors.white12,
                            color: AppTheme.neonCyan,
                            minHeight: 4,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            () {
                              final mins = elapsedSeconds ~/ 60;
                              final secs = elapsedSeconds % 60;
                              final elapsed = mins > 0
                                  ? '${mins}m ${secs.toString().padLeft(2, '0')}s elapsed'
                                  : '${secs}s elapsed';
                              if (uploadProgress >= 0.99) {
                                return '⏱ $elapsed — Direct Cloudflare R2 bucket security check';
                              }
                              return '⏱ $elapsed — high-speed Cloudflare R2 upload active';
                            }(),
                            style: GoogleFonts.outfit(
                              color: AppTheme.neonCyan,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cardBg,
                      side: BorderSide(
                        color: uploadedCloudinaryUrl != null ? AppTheme.neonGreen : AppTheme.primaryPurple,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                  ),
                ),
                if (uploadedCloudinaryUrl != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.verified, size: 14, color: AppTheme.neonGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Cloudflare R2 Bucket (vridhinetwork) ready',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.neonGreen, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  style: GoogleFonts.outfit(color: AppTheme.lightText),
                  decoration: const InputDecoration(
                    labelText: 'Video Title',
                    prefixIcon: Icon(Icons.title, color: AppTheme.primaryPink),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: GoogleFonts.outfit(color: AppTheme.lightText),
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: Icon(Icons.description, color: AppTheme.softGrey),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: thumbController,
                  style: GoogleFonts.outfit(color: AppTheme.lightText),
                  decoration: const InputDecoration(
                    labelText: 'Thumbnail Image URL (Optional)',
                    prefixIcon: Icon(Icons.image, color: AppTheme.neonGreen),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploadingFile
                  ? null
                  : () async {
                      final title = titleController.text.trim();

                      if (uploadedCloudinaryUrl == null || uploadedCloudinaryUrl!.isEmpty) {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a video file and wait for file upload to complete first.'),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                        return;
                      }

                      if (title.isEmpty) {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          const SnackBar(content: Text('Please enter a video title')),
                        );
                        return;
                      }

                      final videoProvider = Provider.of<AdminVideosProvider>(dialogCtx, listen: false);
                      final success = await videoProvider.createVideo(
                        title: title,
                        description: descController.text.trim(),
                        videoUrl: uploadedCloudinaryUrl!,
                        thumbnailUrl: thumbController.text.trim(),
                        languageId: dialogLanguageId,
                        categoryId: dialogCategoryId,
                        categoryName: dialogCategoryName,
                        duration: uploadedVideoDuration > 0 ? uploadedVideoDuration : null,
                        r2ObjectKey: uploadedR2ObjectKey,
                      );

                      final langProv = Provider.of<AdminLanguagesProvider>(dialogCtx, listen: false);
                      final vidProv = Provider.of<AdminVideosProvider>(dialogCtx, listen: false);

                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                      if (success) {
                        if (mounted) {
                          setState(() {
                            _selectedLanguageId = dialogLanguageId;
                          });
                        }
                        langProv.fetchLanguages();
                        vidProv.fetchVideos(languageId: dialogLanguageId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Video uploaded successfully! 🎥'),
                              backgroundColor: AppTheme.neonGreen,
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Upload Video'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<AdminLanguagesProvider>(context);
    final videoProvider = Provider.of<AdminVideosProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multilingual Video Hub'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: AppTheme.softGrey,
          tabs: const [
            Tab(icon: Icon(Icons.video_library), text: 'VIDEOS'),
            Tab(icon: Icon(Icons.assignment_ind), text: 'ASSIGNMENTS'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined, color: AppTheme.neonGreen),
            tooltip: 'Manage Video Categories',
            onPressed: _showManageCategoriesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Add Language Folder',
            onPressed: _showAddLanguageDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadVideoDialog,
        backgroundColor: AppTheme.primaryPurple,
        icon: const Icon(Icons.video_call, color: Colors.white),
        label: Text('Upload Video', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Container(
            decoration: AppTheme.bgGradient,
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Folder Section Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Text(
                          'FOLDERS',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.softGrey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: langProvider.languages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == langProvider.languages.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Row(
                                      children: [
                                        const Icon(Icons.add, size: 16, color: AppTheme.neonCyan),
                                        const SizedBox(width: 4),
                                        Text('+ New Language', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.neonCyan)),
                                      ],
                                    ),
                                    selected: false,
                                    backgroundColor: AppTheme.cardBg,
                                    onSelected: (_) => _showAddLanguageDialog(),
                                  ),
                                );
                              }

                              final lang = langProvider.languages[index];
                              final isSelected = lang.id == _selectedLanguageId;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text('${lang.name} (${lang.videoCount})'),
                                  selected: isSelected,
                                  selectedColor: AppTheme.primaryPurple,
                                  backgroundColor: AppTheme.cardBg,
                                  labelStyle: GoogleFonts.outfit(
                                    color: isSelected ? Colors.white : AppTheme.lightText,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedLanguageId = lang.id;
                                      });
                                      videoProvider.fetchVideos(languageId: lang.id);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Category Filter Row
                Consumer<AdminCategoriesProvider>(
                  builder: (context, catProv, child) {
                    if (catProv.categories.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Text(
                              'CATEGORIES',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.softGrey,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: ChoiceChip(
                                      selected: _selectedCategoryFilter == null,
                                      label: Text('All', style: GoogleFonts.outfit(fontSize: 11)),
                                      selectedColor: AppTheme.neonCyan.withOpacity(0.3),
                                      backgroundColor: AppTheme.cardBg,
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedCategoryFilter = null;
                                        });
                                      },
                                    ),
                                  ),
                                  ...catProv.categories.map((c) {
                                    final isSelected = _selectedCategoryFilter == c.name;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6.0),
                                      child: ChoiceChip(
                                        selected: isSelected,
                                        label: Text(c.name, style: GoogleFonts.outfit(fontSize: 11)),
                                        selectedColor: AppTheme.neonCyan.withOpacity(0.3),
                                        backgroundColor: AppTheme.cardBg,
                                        onSelected: (selected) {
                                          setState(() {
                                            _selectedCategoryFilter = selected ? c.name : null;
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white10),

                // Video List Body
                Expanded(
                  child: _buildVideoListBody(videoProvider),
                ),
              ],
            ),
          ),
          const AdminVideoAssignmentsScreen(),
        ],
      ),
    );
  }

  Widget _buildVideoListBody(AdminVideosProvider videoProvider) {
    if (videoProvider.isLoading) {
      return const Center(child: SpinKitRing(color: AppTheme.primaryPurple));
    }

    final displayVideos = _selectedCategoryFilter == null
        ? videoProvider.videos
        : videoProvider.videos.where((v) => v.categoryName == _selectedCategoryFilter).toList();

    if (displayVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, size: 70, color: AppTheme.softGrey),
            const SizedBox(height: 16),
            Text(
              'No Videos Found',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Upload Video" below to add content.',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayVideos.length,
      itemBuilder: (context, index) {
        final video = displayVideos[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showAdminVideoPreviewDialog(context, video),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.play_circle_fill, color: AppTheme.primaryPurple, size: 28),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.neonCyan.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                video.categoryName.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.neonCyan,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPurple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                video.languageName,
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video.title,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    padding: const EdgeInsets.all(3),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    onPressed: video.isAssignedToSnapshot
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Deletion Protected: Video is part of active user snapshots.'),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                          }
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.cardBg,
                                title: const Text('Delete Video?'),
                                content: Text('Are you sure you want to delete "${video.title}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final langProv = Provider.of<AdminLanguagesProvider>(context, listen: false);
                              final success = await videoProvider.deleteVideo(video.id, languageId: _selectedLanguageId);
                              langProv.fetchLanguages();
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Video deleted successfully'),
                                    backgroundColor: AppTheme.neonCyan,
                                  ),
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
              if (video.isAssignedToSnapshot) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 12, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Used in User Snapshots — Deletion Protected',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                video.videoUrl,
                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdminVideoPreviewDialog(BuildContext context, AdminVideoModel video) {
    if (video.videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video URL is empty or unavailable')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => _AdminVideoPreviewModal(video: video),
    );
  }
}

class _AdminVideoPreviewModal extends StatefulWidget {
  final AdminVideoModel video;
  const _AdminVideoPreviewModal({required this.video});

  @override
  State<_AdminVideoPreviewModal> createState() => _AdminVideoPreviewModalState();
}

class _AdminVideoPreviewModalState extends State<_AdminVideoPreviewModal> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl.trim()));
      await _controller.initialize();
      _controller.setLooping(true);
      _controller.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Admin video preview error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCloudflare = widget.video.videoUrl.contains('r2.cloudflarestorage.com') ||
        widget.video.videoUrl.contains('.r2.dev');

    return AlertDialog(
      backgroundColor: const Color(0xFF0F0E17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.video.title,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Unable to load video preview',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : !_isInitialized
                        ? const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan))
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              AspectRatio(
                                aspectRatio: _controller.value.aspectRatio > 0
                                    ? _controller.value.aspectRatio
                                    : 16 / 9,
                                child: VideoPlayer(_controller),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                                  });
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: AnimatedOpacity(
                                      opacity: _controller.value.isPlaying ? 0.0 : 0.85,
                                      duration: const Duration(milliseconds: 200),
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.black54,
                                        child: Icon(
                                          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 36,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isCloudflare ? AppTheme.neonCyan : AppTheme.primaryPurple).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isCloudflare ? AppTheme.neonCyan : AppTheme.primaryPurple).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    isCloudflare ? '⚡ Cloudflare R2' : '☁️ Dedicated Cloudinary',
                    style: GoogleFonts.outfit(
                      color: isCloudflare ? AppTheme.neonCyan : AppTheme.primaryPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    int secs = widget.video.duration;
                    if (secs == 0 && _isInitialized && _controller.value.isInitialized) {
                      secs = _controller.value.duration.inSeconds;
                    }
                    final durStr = secs > 0
                        ? (secs >= 60 ? '${secs ~/ 60}m ${(secs % 60).toString().padLeft(2, '0')}s' : '${secs}s')
                        : 'Unknown duration';
                    return Text(
                      '$durStr duration',
                      style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 12),
                    );
                  },
                ),
              ],
            ),
            if (widget.video.description != null && widget.video.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.video.description!,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
