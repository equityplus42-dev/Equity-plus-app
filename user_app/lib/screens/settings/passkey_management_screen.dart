import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/passkey_service.dart';

class PasskeyManagementScreen extends StatefulWidget {
  const PasskeyManagementScreen({super.key});

  @override
  State<PasskeyManagementScreen> createState() => _PasskeyManagementScreenState();
}

class _PasskeyManagementScreenState extends State<PasskeyManagementScreen> {
  final PasskeyService _passkeyService = PasskeyService();

  bool _isLoading = true;
  bool _isRegistering = false;
  bool _isSupported = false;
  List<PasskeyCredentialModel> _passkeys = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final supported = await _passkeyService.isSupported();
    if (mounted) {
      setState(() {
        _isSupported = supported;
      });
    }
    await _loadPasskeys();
  }

  Future<void> _loadPasskeys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _passkeyService.listPasskeys();
      if (mounted) {
        setState(() {
          _passkeys = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _registerNewPasskey() async {
    if (!_isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Passkey creation requires an Android device (Android 9+ with screen lock) or a supported Web browser.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final nicknameController = TextEditingController();

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.fingerprint, color: AppTheme.neonGreen),
            const SizedBox(width: 10),
            Text(
              'Add Passkey',
              style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a recognizable name for this passkey (e.g. My Phone, Work Laptop).',
              style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nicknameController,
              autofocus: true,
              style: GoogleFonts.outfit(color: AppTheme.lightText),
              decoration: InputDecoration(
                labelText: 'Passkey Nickname',
                hintText: 'e.g. Primary Device',
                labelStyle: GoogleFonts.outfit(color: AppTheme.softGrey),
                hintStyle: GoogleFonts.outfit(color: AppTheme.softGrey.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryPurple),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: AppTheme.softGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldCreate != true) return;

    final nickname = nicknameController.text.trim().isNotEmpty
        ? nicknameController.text.trim()
        : 'Passkey';

    setState(() {
      _isRegistering = true;
    });

    try {
      final credential = await _passkeyService.registerPasskey(nickname: nickname);
      if (!mounted) return;

      if (credential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passkey "${credential.name}" added successfully!'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
        await _loadPasskeys();
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('Exception: ', '');
      if (!msg.toLowerCase().contains('cancel')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _renamePasskey(PasskeyCredentialModel passkey) async {
    final controller = TextEditingController(text: passkey.name);

    final shouldRename = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename Passkey',
          style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.outfit(color: AppTheme.lightText),
          decoration: InputDecoration(
            labelText: 'New Name',
            labelStyle: GoogleFonts.outfit(color: AppTheme.softGrey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryPurple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.softGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldRename != true) return;

    final newName = controller.text.trim();
    if (newName.isEmpty || newName == passkey.name) return;

    try {
      await _passkeyService.renamePasskey(passkey.id, newName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passkey renamed'), backgroundColor: AppTheme.neonGreen),
      );
      await _loadPasskeys();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _deletePasskey(PasskeyCredentialModel passkey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              'Delete Passkey?',
              style: GoogleFonts.outfit(color: AppTheme.lightText, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${passkey.name}"? You will no longer be able to use it to sign in on this device.',
          style: GoogleFonts.outfit(color: AppTheme.softGrey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.softGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _passkeyService.deletePasskey(passkey.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passkey deleted'), backgroundColor: Colors.orangeAccent),
      );
      await _loadPasskeys();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passkey Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isRegistering ? null : _loadPasskeys,
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.bgGradient,
        child: RefreshIndicator(
          onRefresh: _loadPasskeys,
          color: AppTheme.primaryPurple,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Security Header Banner
              _buildInfoBanner(),

              const SizedBox(height: 24),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'YOUR REGISTERED PASSKEYS',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.softGrey,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${_passkeys.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonGreen,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_isLoading || _isRegistering)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: SpinKitThreeBounce(
                      color: AppTheme.primaryPurple,
                      size: 30.0,
                    ),
                  ),
                )
              else if (_errorMessage != null)
                _buildErrorCard()
              else if (_passkeys.isEmpty)
                _buildEmptyState()
              else
                ..._passkeys.map(_buildPasskeyCard),

              const SizedBox(height: 24),

              // Register Button
              ElevatedButton.icon(
                onPressed: _isRegistering || _isLoading ? null : _registerNewPasskey,
                icon: const Icon(Icons.add_moderator_outlined, size: 22),
                label: Text(
                  'Add New Passkey',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryPurple.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: AppTheme.neonCyan,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passwordless & Phishing-Proof',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Passkeys let you sign in seamlessly using your device fingerprint, face scan, or screen lock. Cryptographic keys never leave your secure authenticator.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.softGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasskeyCard(PasskeyCredentialModel passkey) {
    final createdDateStr = DateFormat.yMMMd().format(passkey.createdAt.toLocal());
    final lastUsedStr = passkey.lastUsedAt != null
        ? DateFormat.yMMMd().add_jm().format(passkey.lastUsedAt!.toLocal())
        : 'Never used yet';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.neonGreen.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.fingerprint_rounded,
            color: AppTheme.neonGreen,
            size: 26,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                passkey.name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightText,
                ),
              ),
            ),
            if (passkey.backedUp)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Synced',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neonCyan,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Added: $createdDateStr',
                style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.softGrey),
              ),
              const SizedBox(height: 2),
              Text(
                'Last used: $lastUsedStr',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: passkey.lastUsedAt != null ? AppTheme.neonGreen : AppTheme.softGrey,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.softGrey),
          color: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'rename') {
              _renamePasskey(passkey);
            } else if (value == 'delete') {
              _deletePasskey(passkey);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, size: 18, color: AppTheme.neonCyan),
                  const SizedBox(width: 8),
                  Text('Rename', style: GoogleFonts.outfit(color: AppTheme.lightText)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text('Delete', style: GoogleFonts.outfit(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.key_outlined,
              size: 40,
              color: AppTheme.primaryPurple,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Passkeys Added',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have not registered any passkeys yet. Add your current device to enable 1-tap biometric logins.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.softGrey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            _errorMessage ?? 'An error occurred',
            style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _loadPasskeys,
            child: const Text('Try Again', style: TextStyle(color: AppTheme.primaryPurple)),
          ),
        ],
      ),
    );
  }
}
