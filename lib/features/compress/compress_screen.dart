import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/media_picker_service.dart';
import '../../core/services/ffmpeg_service.dart';
import '../../core/utils/toast_utils.dart';
import '../result/result_screen.dart';
import 'preset_model.dart';

class CompressScreen extends StatefulWidget {
  final PickedMedia media;

  const CompressScreen({super.key, required this.media});

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  SocialPreset _selectedPreset = SocialPreset.instagram;
  bool _compressing = false;
  double _progress = 0;
  String? _thumbPath;

  final _ffmpeg = FFmpegService();

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    if (widget.media.type != MediaType.video) return;
    try {
      final thumb = await VideoThumbnail.thumbnailFile(
        video: widget.media.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400,
        quality: 75,
      );
      if (mounted && thumb != null) {
        setState(() => _thumbPath = thumb);
      }
    } catch (_) {
      // Thumbnail generation failed — preview will show placeholder icon
    }
  }

  Future<void> _startCompress() async {
    setState(() {
      _compressing = true;
      _progress = 0;
    });

    try {
      CompressResult result;

      if (widget.media.type == MediaType.video) {
        result = await _ffmpeg.compressVideo(
          inputPath: widget.media.path,
          preset: _selectedPreset,
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
        );
      } else {
        result = await _ffmpeg.compressImage(
          inputPath: widget.media.path,
          preset: _selectedPreset,
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => ResultScreen(
            result: result,
            mediaType: widget.media.type,
            preset: _selectedPreset,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _compressing = false);
        showTopToast(context, 'Compression failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildPreview(),
                    const SizedBox(height: 32),
                    _buildPresetSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _compressing ? null : () => Navigator.pop(context),
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
            color: Colors.white,
          ),
          const Expanded(
            child: Text(
              'Choose Preset',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // balance
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreviewContent(),
          // File info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.media.type == MediaType.video
                        ? LucideIcons.video
                        : LucideIcons.image,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.media.path.split('/').last,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    widget.media.formattedSize,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewContent() {
    if (widget.media.type == MediaType.image) {
      return Image.file(
        File(widget.media.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _PlaceholderIcon(LucideIcons.image),
      );
    }

    if (_thumbPath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_thumbPath!), fit: BoxFit.cover),
          const Center(
            child: Icon(LucideIcons.play, color: Colors.white70, size: 40),
          ),
        ],
      );
    }

    return const _PlaceholderIcon(LucideIcons.video);
  }

  Widget _buildPresetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optimize for',
          style: TextStyle(
            color: Color(0xFF888888),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ...SocialPreset.values.map(
          (preset) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PresetCard(
              preset: preset,
              selected: _selectedPreset == preset,
              onTap: _compressing
                  ? null
                  : () => setState(() => _selectedPreset = preset),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: _compressing ? _buildProgressBar() : _buildOptimizeButton(),
    );
  }

  Widget _buildOptimizeButton() {
    return ElevatedButton(
      onPressed: _startCompress,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.zap, size: 18),
          const SizedBox(width: 8),
          Text('Optimize · ${_selectedPreset.label}'),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Compressing...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            backgroundColor: const Color(0xFF1A1A1A),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _PresetCard extends StatelessWidget {
  final SocialPreset preset;
  final bool selected;
  final VoidCallback? onTap;

  const _PresetCard({
    required this.preset,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.white : const Color(0xFF1E1E1E),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(preset.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFCCCCCC),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preset.description,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                LucideIcons.circleCheck,
                color: Colors.white,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  final IconData icon;
  const _PlaceholderIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(icon, color: const Color(0xFF333333), size: 48),
    );
  }
}
