import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class LanguageSelectionModal extends StatefulWidget {
  final List<Map<String, dynamic>> languages;
  final Function(String selectedLanguageId) onLanguageSelected;

  const LanguageSelectionModal({
    super.key,
    required this.languages,
    required this.onLanguageSelected,
  });

  static Future<String?> show({
    required BuildContext context,
    required List<Map<String, dynamic>> languages,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LanguageSelectionModal(
        languages: languages,
        onLanguageSelected: (id) {
          Navigator.of(ctx).pop(id);
        },
      ),
    );
  }

  @override
  State<LanguageSelectionModal> createState() => _LanguageSelectionModalState();
}

class _LanguageSelectionModalState extends State<LanguageSelectionModal> {
  String? _selectedLanguageId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.languages.isNotEmpty) {
      // Pre-select default language or first language
      final defaultLang = widget.languages.firstWhere(
        (l) => l['isDefault'] == true,
        orElse: () => widget.languages.first,
      );
      _selectedLanguageId = defaultLang['id'] as String?;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing without choosing a language
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF16152A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.language_rounded, color: AppTheme.neonCyan, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Learning Language',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose your preferred language for video courses',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.softGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 16),

              // Available Languages List
              if (widget.languages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No language folders available. Please contact support.',
                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Column(
                      children: widget.languages.map((lang) {
                        final id = lang['id'] as String;
                        final name = lang['name'] as String? ?? 'Unknown';
                        final code = lang['code'] as String? ?? '';
                        final isSelected = _selectedLanguageId == id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedLanguageId = id;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryPurple.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppTheme.neonCyan : Colors.white10,
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isSelected ? AppTheme.neonCyan : Colors.white38,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.white : Colors.white70,
                                      ),
                                    ),
                                  ),
                                  if (code.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        code.toUpperCase(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.softGrey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_selectedLanguageId == null || _isSubmitting)
                      ? null
                      : () {
                          setState(() {
                            _isSubmitting = true;
                          });
                          widget.onLanguageSelected(_selectedLanguageId!);
                        },
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'Saving Language...' : 'Confirm Language Choice',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
