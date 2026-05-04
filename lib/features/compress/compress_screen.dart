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
  int _customQuality = 50; // 1–100%, used when preset == custom

  // ETA tracking
  DateTime? _compressStartTime;
  String _etaText = '';

  final _ffmpeg = FFmpegService();

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  String _calcEta(double progress) {
    if (progress <= 0.01 || _compressStartTime == null) return '';
    final elapsed =
        DateTime.now().difference(_compressStartTime!).inMilliseconds;
    final totalEstimated = elapsed / progress;
    final remaining = (totalEstimated - elapsed).round();
    if (remaining <= 0) return '';
    final secs = (remaining / 1000).ceil();
    if (secs < 60) return '~${secs}s left';
    final mins = secs ~/ 60;
    final remSecs = secs % 60;
    return remSecs > 0 ? '~${mins}m ${remSecs}s left' : '~${mins}m left';
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
      _etaText = '';
      _compressStartTime = DateTime.now();
    });

    try {
      CompressResult result;

      if (widget.media.type == MediaType.video) {
        result = await _ffmpeg.compressVideo(
          inputPath: widget.media.path,
          preset: _selectedPreset,
          customQualityPercent: _customQuality,
          onProgress: (p) {
            if (mounted) {
              setState(() {
                _progress = p;
                _etaText = _calcEta(p);
              });
            }
          },
        );
      } else {
        result = await _ffmpeg.compressImage(
          inputPath: widget.media.path,
          preset: _selectedPreset,
          customQualityPercent: _customQuality,
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
            customQualityPercent:
                _selectedPreset == SocialPreset.custom ? _customQuality : null,
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
            child: preset == SocialPreset.custom
                ? _CustomPresetCard(
                    selected: _selectedPreset == SocialPreset.custom,
                    quality: _customQuality,
                    onTap: _compressing
                        ? null
                        : () => setState(
                            () => _selectedPreset = SocialPreset.custom),
                    onQualityChanged: _compressing
                        ? null
                        : (v) => setState(() => _customQuality = v),
                  )
                : _PresetCard(
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
    final label = _selectedPreset == SocialPreset.custom
        ? 'Optimize · Custom $_customQuality%'
        : 'Optimize · ${_selectedPreset.label}';
    return ElevatedButton(
      onPressed: _startCompress,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.zap, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final percent = (_progress * 100).toInt();
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
            Row(
              children: [
                if (_etaText.isNotEmpty) ...[
                  Text(
                    _etaText,
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                preset.icon,
                color: selected ? Colors.white : const Color(0xFF888888),
                size: 20,
              ),
            ),
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

/// Card for the Custom preset — shows a quality slider when selected.
class _CustomPresetCard extends StatelessWidget {
  final bool selected;
  final int quality; // 1–100
  final VoidCallback? onTap;
  final ValueChanged<int>? onQualityChanged;

  const _CustomPresetCard({
    required this.selected,
    required this.quality,
    this.onTap,
    this.onQualityChanged,
  });

  String _qualityLabel(int q) {
    if (q >= 80) return 'High quality · larger file';
    if (q >= 50) return 'Balanced quality & size';
    if (q >= 25) return 'Smaller file · some loss';
    return 'Maximum compression';
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row (same layout as _PresetCard)
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.settings2,
                    color: selected ? Colors.white : const Color(0xFF888888),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom',
                        style: TextStyle(
                          color:
                              selected ? Colors.white : const Color(0xFFCCCCCC),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        selected
                            ? _qualityLabel(quality)
                            : 'Set your own compression level',
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
            // Slider — only visible when selected
            if (selected) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Quality',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Text(
                      '$quality%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 3,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Color(0xFF2A2A2A),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white12,
                ),
                child: Slider(
                  value: quality.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 18, // steps of 5%
                  onChanged: onQualityChanged != null
                      ? (v) => onQualityChanged!(v.round())
                      : null,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Smaller',
                        style:
                            TextStyle(color: Color(0xFF555555), fontSize: 11)),
                    Text('Better quality',
                        style:
                            TextStyle(color: Color(0xFF555555), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
