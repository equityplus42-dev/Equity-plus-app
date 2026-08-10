import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/admin_languages_provider.dart';
import '../../providers/admin_videos_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final langProvider = Provider.of<AdminLanguagesProvider>(context, listen: false);
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

  void _showUploadVideoDialog() {
    final langProvider = Provider.of<AdminLanguagesProvider>(context, listen: false);
    if (langProvider.languages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create at least one language folder first.')),
      );
      return;
    }

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final urlController = TextEditingController();
    final thumbController = TextEditingController();
    String dialogLanguageId = _selectedLanguageId ?? langProvider.languages.first.id;

    bool isUploadingFile = false;
    String? selectedFileName;
    int uploadedVideoDuration = 0;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                  value: dialogLanguageId,
                  dropdownColor: AppTheme.cardBg,
                  style: GoogleFonts.outfit(color: AppTheme.lightText),
                  decoration: const InputDecoration(
                    labelText: 'Select Language Folder',
                    prefixIcon: Icon(Icons.folder_outlined, color: AppTheme.primaryPurple),
                  ),
                  items: langProvider.languages.map((l) {
                    return DropdownMenuItem<String>(
                      value: l.id,
                      child: Text('${l.name} (${l.code})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() {
                        dialogLanguageId = val;
                      });
                    }
                  },
                ),
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
                // Device File Picker Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isUploadingFile
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                            if (video != null) {
                              setDialogState(() {
                                isUploadingFile = true;
                                selectedFileName = video.name;
                              });

                              try {
                                final token = StorageService().getToken();
                                final uri = Uri.parse('${ApiConstants.baseUrl}/upload-pipeline/media');
                                final request = http.MultipartRequest('POST', uri);
                                if (token != null) {
                                  request.headers['Authorization'] = 'Bearer $token';
                                }
                                final bytes = await video.readAsBytes();
                                request.files.add(http.MultipartFile.fromBytes(
                                  'file',
                                  bytes,
                                  filename: video.name,
                                ));

                                final streamedResponse = await request.send();
                                final response = await http.Response.fromStream(streamedResponse);

                                if (response.statusCode == 200 || response.statusCode == 201) {
                                  final data = jsonDecode(response.body);
                                  final uploadedUrl = data['data']?['url'] ?? data['url'];
                                  final int dur = (data['data']?['duration'] ?? data['duration'] ?? 0) as int;
                                  if (uploadedUrl != null) {
                                    urlController.text = uploadedUrl;
                                    uploadedVideoDuration = dur;
                                    if (titleController.text.trim().isEmpty) {
                                      titleController.text = video.name.replaceAll(RegExp(r'\.[^.]+$'), '');
                                    }
                                  }
                                }
                              } catch (e) {
                                debugPrint('Error uploading video file: $e');
                              } finally {
                                setDialogState(() {
                                  isUploadingFile = false;
                                });
                              }
                            }
                          },
                    icon: isUploadingFile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonGreen),
                          )
                        : const Icon(Icons.video_collection_outlined, color: AppTheme.neonGreen),
                    label: Text(
                      isUploadingFile
                          ? 'Uploading video from device...'
                          : (selectedFileName != null ? 'Selected: $selectedFileName' : 'Select Video from Device'),
                      style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cardBg,
                      side: const BorderSide(color: AppTheme.neonGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: urlController,
                  style: GoogleFonts.outfit(color: AppTheme.lightText),
                  decoration: const InputDecoration(
                    labelText: 'Video URL (Auto-filled or manual)',
                    prefixIcon: Icon(Icons.video_library, color: AppTheme.neonCyan),
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
              onPressed: () async {
                final title = titleController.text.trim();
                final url = urlController.text.trim();

                if (title.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title and Video URL are required')),
                  );
                  return;
                }

                final videoProvider = Provider.of<AdminVideosProvider>(context, listen: false);
                final success = await videoProvider.createVideo(
                  title: title,
                  description: descController.text.trim(),
                  videoUrl: url,
                  thumbnailUrl: thumbController.text.trim(),
                  languageId: dialogLanguageId,
                  duration: uploadedVideoDuration > 0 ? uploadedVideoDuration : null,
                );

                if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                if (success && mounted) {
                  setState(() {
                    _selectedLanguageId = dialogLanguageId;
                  });
                  Provider.of<AdminLanguagesProvider>(context, listen: false).fetchLanguages();
                  Provider.of<AdminVideosProvider>(context, listen: false).fetchVideos(languageId: dialogLanguageId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video uploaded successfully! 🎥'),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'FOLDERS:',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.softGrey,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
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

                const SizedBox(height: 12),
                const Divider(color: Colors.white10),

                // Video List Body
                Expanded(
                  child: videoProvider.isLoading
                  ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
                  : videoProvider.videos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.video_library_outlined, size: 70, color: AppTheme.softGrey),
                              const SizedBox(height: 16),
                              Text(
                                'No Videos in this Language Folder',
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
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: videoProvider.videos.length,
                          itemBuilder: (context, index) {
                            final video = videoProvider.videos[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: AppTheme.glassCardDecoration(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryPurple.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.play_circle_fill, color: AppTheme.primaryPurple, size: 30),
                                    ),
                                    title: Text(
                                      video.title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.lightText,
                                      ),
                                    ),
                                    subtitle: Text(
                                      video.description ?? 'No description provided',
                                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.arrow_upward, size: 20, color: AppTheme.neonCyan),
                                          tooltip: 'Move Up',
                                          onPressed: index > 0
                                              ? () async {
                                                  final list = List<AdminVideoModel>.from(videoProvider.videos);
                                                  final item = list.removeAt(index);
                                                  list.insert(index - 1, item);
                                                  final orders = list
                                                      .asMap()
                                                      .entries
                                                      .map((e) => {'id': e.value.id, 'orderIndex': e.key})
                                                      .toList();
                                                  await videoProvider.reorderVideos(orders, languageId: _selectedLanguageId);
                                                }
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.arrow_downward, size: 20, color: AppTheme.neonCyan),
                                          tooltip: 'Move Down',
                                          onPressed: index < videoProvider.videos.length - 1
                                              ? () async {
                                                  final list = List<AdminVideoModel>.from(videoProvider.videos);
                                                  final item = list.removeAt(index);
                                                  list.insert(index + 1, item);
                                                  final orders = list
                                                      .asMap()
                                                      .entries
                                                      .map((e) => {'id': e.value.id, 'orderIndex': e.key})
                                                      .toList();
                                                  await videoProvider.reorderVideos(orders, languageId: _selectedLanguageId);
                                                }
                                              : null,
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: video.isAssignedToSnapshot ? AppTheme.softGrey : Colors.redAccent,
                                          ),
                                          tooltip: video.isAssignedToSnapshot
                                              ? 'Assigned to Paid Users — Deletion Disabled'
                                              : 'Delete Video',
                                          onPressed: video.isAssignedToSnapshot
                                              ? null
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
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (video.isAssignedToSnapshot) ...[
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 6),
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
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppTheme.neonCyan.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                video.languageName,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.neonCyan,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                video.videoUrl,
                                                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.softGrey),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
            ],
          ),
        ),
        const AdminVideoAssignmentsScreen(),
      ],
    ),
  );
  }
}
