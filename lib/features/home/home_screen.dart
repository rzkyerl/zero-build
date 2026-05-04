import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/media_picker_service.dart';
import '../../core/utils/toast_utils.dart';
import '../compress/compress_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _pickerService = MediaPickerService();
  bool _picking = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Permission ────────────────────────────────────────────────────────────

  Future<bool> _requestPermission(MediaType type) async {
    // image_picker handles its own permission dialog on modern Android,
    // but we pre-check so we can show a friendly message if denied.
    final perm =
        type == MediaType.image ? Permission.photos : Permission.videos;

    var status = await perm.status;

    // Already granted or limited (partial access on Android 14+)
    if (status.isGranted || status.isLimited) return true;

    // Permanently denied → guide user to settings
    if (status.isPermanentlyDenied) {
      if (mounted) _showSettingsDialog(type);
      return false;
    }

    // Request
    status = await perm.request();

    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      if (mounted) _showSettingsDialog(type);
      return false;
    }

    // Denied — let image_picker try anyway (some devices grant via picker UI)
    return true;
  }

  void _showSettingsDialog(MediaType type) {
    final label = type == MediaType.image ? 'Photos' : 'Videos';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Permission Required',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Zero needs access to your $label.\n\n'
          'Go to Settings → Apps → Zero → Permissions and enable it.',
          style: const TextStyle(
            color: Color(0xFF888888),
            height: 1.5,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pick flow ─────────────────────────────────────────────────────────────

  Future<void> _pick(MediaType type) async {
    if (_picking) return;

    final canProceed = await _requestPermission(type);
    if (!canProceed || !mounted) return;

    setState(() => _picking = true);
    try {
      final media = type == MediaType.image
          ? await _pickerService.pickImage()
          : await _pickerService.pickVideo();

      if (media == null || !mounted) return;

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => CompressScreen(media: media),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      if (mounted) showTopToast(context, 'Could not open gallery: $e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              _buildHeader(),
              const Spacer(),
              _buildPickArea(),
              const Spacer(),
              _buildMediaButtons(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ZERO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => const SettingsScreen(),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
                  transitionDuration: const Duration(milliseconds: 200),
                ),
              ),
              icon: const Icon(LucideIcons.settings, size: 20),
              color: const Color(0xFF555555),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Compress.\nStay sharp.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Optimize photos & videos for social media.\nOffline. No account needed.',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPickArea() {
    return Center(
      child: ScaleTransition(
        scale: _pulseAnim,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF222222), width: 1.5),
            color: const Color(0xFF111111),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.plus,
                size: 44,
                color: _picking
                    ? const Color(0xFF444444)
                    : const Color(0xFF555555),
              ),
              const SizedBox(height: 8),
              Text(
                _picking ? 'Opening...' : 'Select Media',
                style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButtons() {
    return Column(
      children: [
        _MediaButton(
          label: 'Photo',
          icon: LucideIcons.image,
          onTap: _picking ? null : () => _pick(MediaType.image),
        ),
        const SizedBox(height: 12),
        _MediaButton(
          label: 'Video',
          icon: LucideIcons.video,
          onTap: _picking ? null : () => _pick(MediaType.video),
          outlined: true,
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _MediaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool outlined;

  const _MediaButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF333333)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}
