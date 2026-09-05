// dart:ui removed — no longer needed after removing locked video blur cards
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../providers/user_video_provider.dart';
import '../../widgets/language_selection_modal.dart';
import 'video_player_screen.dart';
import '../../core/theme/app_theme.dart';

class UserVideoLibraryScreen extends StatefulWidget {
  const UserVideoLibraryScreen({super.key});

  @override
  State<UserVideoLibraryScreen> createState() => _UserVideoLibraryScreenState();
}

class _UserVideoLibraryScreenState extends State<UserVideoLibraryScreen> {
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadVideos();
    });
  }

  Future<void> _loadVideos() async {
    final provider = Provider.of<UserVideoProvider>(context, listen: false);
    await provider.fetchUserVideos();

    if (!mounted) return;

    // Check if user has no assigned language folder yet (e.g. legacy/old users)
    if (provider.needsLanguageSelection) {
      final selectedLangId = await LanguageSelectionModal.show(
        context: context,
        languages: provider.availableLanguages,
      );
      if (selectedLangId != null && mounted) {
        final success = await provider.selectLanguage(selectedLangId);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to save language selection'),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.of(context).pop();
          return;
        }
      } else if (mounted) {
        Navigator.of(context).pop();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = Provider.of<UserVideoProvider>(context);

    // Group videos by category name in English
    final Map<String, List<dynamic>> groupedVideos = {};
    for (final v in videoProvider.unlockedVideos) {
      final cat = v.categoryName.trim().isNotEmpty
          ? v.categoryName.trim()
          : 'Time Management';
      if (!groupedVideos.containsKey(cat)) {
        groupedVideos[cat] = [];
      }
      groupedVideos[cat]!.add(v);
    }

    final categoriesList = groupedVideos.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Learning Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppTheme.neonCyan),
            tooltip: 'Watch History & Progress',
            onPressed: () {
              Navigator.pushNamed(context, '/watch-history');
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: videoProvider.isLoading
            ? const Center(child: SpinKitRing(color: AppTheme.primaryPurple))
            : RefreshIndicator(
                onRefresh: () => videoProvider.fetchUserVideos(),
                color: AppTheme.primaryPurple,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Snapshot & Language Banner / Developer Test Banner
                      if (videoProvider.isTestUser) ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.glassCardDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonCyan.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.developer_mode, color: AppTheme.neonCyan, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'DEVELOPER TEST MODE ⚡',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.neonCyan,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'All Categories & Videos Unlocked',
                                          style: GoogleFonts.outfit(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.lightText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Snapshot restrictions are bypassed for your test account. You can view all uploaded videos across all language categories.',
                                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: AppTheme.glassCardDecoration(),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryPurple.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.language, color: AppTheme.primaryPurple, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ASSIGNED LANGUAGE & SNAPSHOT',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.softGrey,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      videoProvider.assignedLanguageName ?? 'English (Default)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.lightText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.swap_horiz, size: 16, color: AppTheme.neonCyan),
                                label: Text('Change', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.neonCyan, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/language-request');
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Category Filter Chips
                      if (categoriesList.isNotEmpty) ...[
                        Text(
                          'VIDEO CATEGORIES',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.softGrey,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  selected: _selectedCategoryFilter == null,
                                  label: Text(
                                    'All (${videoProvider.unlockedVideos.length})',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  selectedColor: AppTheme.primaryPurple,
                                  backgroundColor: AppTheme.cardBg,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedCategoryFilter = null;
                                    });
                                  },
                                ),
                              ),
                              ...categoriesList.map((catName) {
                                final isSelected = _selectedCategoryFilter == catName;
                                final count = groupedVideos[catName]?.length ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    selected: isSelected,
                                    label: Text(
                                      '$catName ($count)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isSelected ? Colors.white : AppTheme.lightText,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    selectedColor: AppTheme.primaryPurple,
                                    backgroundColor: AppTheme.cardBg,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategoryFilter = selected ? catName : null;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Empty Videos state
                      if (videoProvider.unlockedVideos.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Column(
                              children: [
                                const Icon(Icons.video_library_outlined, size: 50, color: AppTheme.softGrey),
                                const SizedBox(height: 12),
                                Text(
                                  'No Videos Available in Hub',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    color: AppTheme.lightText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        // Render Category Sections
                        for (final catName in categoriesList)
                          if (_selectedCategoryFilter == null || _selectedCategoryFilter == catName) ...[
                            _buildCategorySection(
                              context,
                              categoryName: catName,
                              videos: groupedVideos[catName] ?? [],
                              videoProvider: videoProvider,
                            ),
                            const SizedBox(height: 20),
                          ],
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String categoryName,
    required List<dynamic> videos,
    required UserVideoProvider videoProvider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.folder_special_outlined, color: AppTheme.neonCyan, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              categoryName.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.neonCyan,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderGrey.withOpacity(0.4)),
              ),
              child: Text(
                '${videos.length}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.softGrey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final v = videos[index];
            final progress = v.duration > 0
                ? (v.watchedSecs / v.duration).clamp(0.0, 1.0)
                : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: AppTheme.glassCardDecoration(),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(video: v),
                      ),
                    ).then((_) {
                      videoProvider.fetchUserVideos();
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: v.isCompleted
                                    ? AppTheme.neonGreen.withOpacity(0.15)
                                    : AppTheme.primaryPurple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                v.isCompleted ? Icons.check_circle : Icons.play_circle_fill,
                                color: v.isCompleted ? AppTheme.neonGreen : AppTheme.primaryPurple,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.lightText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    () {
                                      String fmt(int secs) {
                                        if (secs >= 60) {
                                          final m = secs ~/ 60;
                                          final s = secs % 60;
                                          return '${m}m ${s.toString().padLeft(2, '0')}s';
                                        }
                                        return '${secs}s';
                                      }
                                      final effTotal = v.duration > 0 ? v.duration : (v.watchedSecs > 0 ? v.watchedSecs : 0);
                                      if (v.watchedSecs > 0) {
                                        return 'Watched ${fmt(v.watchedSecs)} of ${fmt(effTotal)}';
                                      }
                                      return effTotal > 0 ? '${fmt(effTotal)} duration' : 'Video';
                                    }(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppTheme.softGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.softGrey),
                          ],
                        ),
                        if (v.watchedSecs > 0) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white10,
                              color: v.isCompleted ? AppTheme.neonGreen : AppTheme.primaryPurple,
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

