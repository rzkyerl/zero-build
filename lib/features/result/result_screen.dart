import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/ffmpeg_service.dart';
import '../../core/services/media_picker_service.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/toast_utils.dart';
import '../compress/preset_model.dart';

class ResultScreen extends StatefulWidget {
  final CompressResult result;
  final MediaType mediaType;
  final SocialPreset preset;

  const ResultScreen({
    super.key,
    required this.result,
    required this.mediaType,
    required this.preset,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _saving = false;
  String? _savedPath;

  // Video player
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _videoPlaying = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();

    if (widget.mediaType == MediaType.video) {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    _videoController = VideoPlayerController.file(
      File(widget.result.outputPath),
    );
    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      if (mounted) setState(() => _videoInitialized = true);
    } catch (_) {
      // Video init failed — will show fallback
    }
  }

  void _togglePlay() {
    if (_videoController == null || !_videoInitialized) return;
    setState(() {
      if (_videoPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _videoPlaying = !_videoPlaying;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ext = widget.mediaType == MediaType.video ? 'mp4' : 'jpg';
      await FileUtils.saveToGallery(widget.result.outputPath, ext);
      if (mounted) {
        setState(() {
          _savedPath = 'saved';
          _saving = false;
        });
        _showSnack('Saved to Gallery ✓');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack('Save failed: $e');
      }
    }
  }

  Future<void> _share() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.result.outputPath)],
        text: 'Compressed with Zero',
      );
    } catch (e) {
      _showSnack('Share failed: $e');
    }
  }

  void _showSnack(String msg) => showTopToast(context, msg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildSuccessBadge(),
                        const SizedBox(height: 28),
                        _buildPreviewCard(),
                        const SizedBox(height: 24),
                        _buildSizeComparison(),
                        const SizedBox(height: 16),
                        _buildPresetBadge(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomActions(),
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
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(LucideIcons.x, size: 20),
            color: const Color(0xFF666666),
          ),
          const Expanded(
            child: Text(
              'Result',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF4ADE80),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Optimization complete',
            style: TextStyle(
              color: Color(0xFF4ADE80),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview card (image or video player) ──────────────────────────────────

  Widget _buildPreviewCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 260,
        width: double.infinity,
        color: const Color(0xFF111111),
        child: widget.mediaType == MediaType.image
            ? _buildImagePreview()
            : _buildVideoPreview(),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Image.file(
      File(widget.result.outputPath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(LucideIcons.image, color: Color(0xFF333333), size: 48),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_videoInitialized || _videoController == null) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF444444),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
          // Play/pause overlay
          AnimatedOpacity(
            opacity: _videoPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              color: Colors.black38,
              child: Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    LucideIcons.play,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          // Duration badge
          Positioned(
            bottom: 12,
            right: 12,
            child: ValueListenableBuilder(
              valueListenable: _videoController!,
              builder: (_, value, __) {
                final dur = value.duration;
                final pos = value.position;
                final remaining = dur - pos;
                final secs = remaining.inSeconds;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          // Progress bar at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder(
              valueListenable: _videoController!,
              builder: (_, value, __) {
                final progress = value.duration.inMilliseconds > 0
                    ? value.position.inMilliseconds /
                        value.duration.inMilliseconds
                    : 0.0;
                return LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 2,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Size comparison ────────────────────────────────────────────────────────

  Widget _buildSizeComparison() {
    final reduction = widget.result.reductionPercent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E1E1E)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SizeBlock(
                  label: 'Before',
                  value: widget.result.formattedOriginal,
                  dimmed: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const Icon(LucideIcons.arrowRight,
                        color: Color(0xFF333333), size: 18),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2818),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF1A4A2E)),
                      ),
                      child: Text(
                        '-${reduction.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _SizeBlock(
                  label: 'After',
                  value: widget.result.formattedCompressed,
                  dimmed: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (100 - reduction) / 100,
              backgroundColor: const Color(0xFF1A1A1A),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reduced by ${reduction.toStringAsFixed(1)}%',
            style: const TextStyle(color: Color(0xFF444444), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.preset.emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 6),
        Text(
          widget.preset.label,
          style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 13,
              fontWeight: FontWeight.w500),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('·', style: TextStyle(color: Color(0xFF333333))),
        ),
        Icon(
          widget.mediaType == MediaType.video
              ? LucideIcons.video
              : LucideIcons.image,
          color: const Color(0xFF555555),
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          widget.mediaType == MediaType.video ? 'Video' : 'Photo',
          style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Icon(
                      _savedPath != null
                          ? LucideIcons.circleCheck
                          : LucideIcons.download,
                      size: 18,
                    ),
              label: Text(_saving
                  ? 'Saving...'
                  : _savedPath != null
                      ? 'Saved!'
                      : 'Save to Gallery'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _share,
              icon: const Icon(LucideIcons.share2, size: 18),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF333333)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool dimmed;

  const _SizeBlock(
      {required this.label, required this.value, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF555555),
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: dimmed ? const Color(0xFF444444) : Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
