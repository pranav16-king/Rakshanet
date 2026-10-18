import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../theme/app_tokens.dart';

/// Lightweight reactive store for message/image reactions and likes.
/// Offline-first and persisted in SharedPreferences.
class ChatReactionStore {
  ChatReactionStore._();

  static final ValueNotifier<Map<String, bool>> likedNotifier =
      ValueNotifier<Map<String, bool>>({});

  /// Returns true if this message has been liked by the local user.
  static Future<bool> isLiked(String messageId) async {
    if (messageId.isEmpty) return false;
    if (likedNotifier.value.containsKey(messageId)) {
      return likedNotifier.value[messageId]!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool('chat_msg_liked_$messageId') ?? false;
      final map = Map<String, bool>.from(likedNotifier.value);
      map[messageId] = val;
      likedNotifier.value = map;
      return val;
    } catch (_) {
      return false;
    }
  }

  /// Toggles the like state and notifies all active listeners.
  static Future<bool> toggleLike(String messageId) async {
    if (messageId.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getBool('chat_msg_liked_$messageId') ?? false;
      final next = !current;
      await prefs.setBool('chat_msg_liked_$messageId', next);
      final map = Map<String, bool>.from(likedNotifier.value);
      map[messageId] = next;
      likedNotifier.value = map;
      return next;
    } catch (_) {
      return false;
    }
  }
}

/// Helper for saving offline emergency images to device public storage.
class ChatImageSaver {
  ChatImageSaver._();

  /// Saves the image file to device public Downloads or app external storage.
  static Future<File?> saveImageToDownloads(
    File sourceFile,
    String originalFileName,
  ) async {
    try {
      if (!await sourceFile.exists()) {
        return null;
      }

      Directory? targetDir;

      // 1. Preferred target on Android: Public Downloads folder / RakshaNet
      if (Platform.isAndroid) {
        final publicDownloadDir = Directory('/storage/emulated/0/Download/RakshaNet');
        try {
          if (!await publicDownloadDir.exists()) {
            await publicDownloadDir.create(recursive: true);
          }
          targetDir = publicDownloadDir;
        } catch (_) {
          final generalDownloadDir = Directory('/storage/emulated/0/Download');
          if (await generalDownloadDir.exists()) {
            targetDir = generalDownloadDir;
          }
        }
      }

      // 2. Cross-platform downloads directory fallback
      if (targetDir == null) {
        try {
          targetDir = await getDownloadsDirectory();
        } catch (_) {}
      }

      // 3. External storage directory fallback
      if (targetDir == null) {
        try {
          targetDir = await getExternalStorageDirectory();
        } catch (_) {}
      }

      // 4. Documents directory fallback
      targetDir ??= await getApplicationDocumentsDirectory();

      final sanitizedName = originalFileName.isNotEmpty
          ? originalFileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          : 'RakshaNet_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final destinationPath = '${targetDir.path}/$sanitizedName';
      final savedFile = await sourceFile.copy(destinationPath);
      return savedFile;
    } catch (e) {
      debugPrint('[ChatImageSaver] Error saving image to storage: $e');
      return null;
    }
  }
}

/// Fullscreen Interactive Image Viewer Route for RakshaNet Offline Mesh Images.
class ChatImageViewer extends StatefulWidget {
  final ChatMessage message;
  final MediaAttachment attachment;

  const ChatImageViewer({
    super.key,
    required this.message,
    required this.attachment,
  });

  /// Opens the full-screen image viewer with a smooth fade route transition.
  static Future<void> show(
    BuildContext context, {
    required ChatMessage message,
    required MediaAttachment attachment,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, _) => ChatImageViewer(
          message: message,
          attachment: attachment,
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<ChatImageViewer> createState() => _ChatImageViewerState();
}

class _ChatImageViewerState extends State<ChatImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  Size? _imageDimensions;
  bool _isLiked = false;
  bool _isSaving = false;
  late AnimationController _heartAnimController;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0.85,
      upperBound: 1.25,
    );
    _resolveImageDimensions();
    _loadInitialLikeState();
  }

  Future<void> _loadInitialLikeState() async {
    final liked = await ChatReactionStore.isLiked(widget.message.messageId);
    if (mounted) {
      setState(() {
        _isLiked = liked;
      });
    }
  }

  void _resolveImageDimensions() {
    final file = File(widget.attachment.localPath);
    if (!file.existsSync()) return;

    final image = FileImage(file);
    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          if (mounted) {
            setState(() {
              _imageDimensions = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              );
            });
          }
        },
        onError: (_, _) {},
      ),
    );
  }

  void _handleDoubleTap() {
    if (_transformController.value.isIdentity()) {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final x = -position.dx * (2.5 - 1);
      final y = -position.dy * (2.5 - 1);
      final zoomed = Matrix4.identity()
        ..translateByDouble(x, y, 0.0, 1.0)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
      _transformController.value = zoomed;
    } else {
      _transformController.value = Matrix4.identity();
    }
  }

  Future<void> _toggleLike() async {
    HapticFeedback.mediumImpact();
    _heartAnimController.forward().then((_) => _heartAnimController.reverse());
    final next = await ChatReactionStore.toggleLike(widget.message.messageId);
    if (!mounted) return;
    setState(() {
      _isLiked = next;
    });
  }

  Future<void> _downloadImage() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    final file = File(widget.attachment.localPath);
    final saved = await ChatImageSaver.saveImageToDownloads(
      file,
      widget.attachment.fileName,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0E8A94),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                saved != null
                    ? '✅ Photo saved to device Downloads'
                    : 'Unable to save photo to Downloads',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareImageDetails() async {
    HapticFeedback.selectionClick();
    final file = File(widget.attachment.localPath);
    final text = 'RakshaNet Emergency Image\n'
        'File: ${widget.attachment.fileName}\n'
        'Size: ${_formatBytes(widget.attachment.byteLength)}\n'
        'Sender: ${widget.message.senderName}\n'
        'Time: ${widget.message.formattedTime}\n'
        'Path: ${file.path}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0E8A94),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '📋 Photo details copied to clipboard',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  void dispose() {
    _transformController.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.attachment.localPath);
    final sizeFormatted = _formatBytes(widget.attachment.byteLength);

    return Scaffold(
      backgroundColor: const Color(0xFF070D18),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF070D18).withValues(alpha: 0.92),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          tooltip: 'Back to Chat',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.attachment.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.message.formattedTime} • $sizeFormatted',
              style: const TextStyle(
                color: Color(0xFF8FA0B8),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
        actions: [
          // Like / Heart icon in #EF4444
          ScaleTransition(
            scale: _heartAnimController,
            child: IconButton(
              icon: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                color: const Color(0xFFEF4444),
                size: 24,
              ),
              tooltip: _isLiked ? 'Unlike photo' : 'Like photo',
              onPressed: _toggleLike,
            ),
          ),

          // Download / Save icon
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTokens.signalYellow,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Save to Downloads',
                  onPressed: _downloadImage,
                ),

          // Share / Copy icon
          IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: Colors.white,
              size: 22,
            ),
            tooltip: 'Share photo details',
            onPressed: _shareImageDetails,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Center Interactive Image Viewer with double-tap zoom & hero transition
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (details) => _doubleTapDetails = details,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 4.5,
                boundaryMargin: const EdgeInsets.all(32),
                child: Center(
                  child: Hero(
                    tag: 'chat_img_${widget.message.messageId}',
                    child: file.existsSync()
                        ? Image.file(
                            file,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => _buildFallbackError(),
                          )
                        : _buildFallbackError(),
                  ),
                ),
              ),
            ),
          ),

          // Bottom banner showing sender name, delivery status, and image dimensions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1322).withValues(alpha: 0.94),
                    border: const Border(
                      top: BorderSide(color: Color(0xFF263754), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            AppTokens.signalYellow.withValues(alpha: 0.2),
                        child: Text(
                          widget.message.senderName.isNotEmpty
                              ? widget.message.senderName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppTokens.signalYellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.message.senderName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                widget.message.buildStatusWidget(context),
                                const SizedBox(width: 4),
                                Text(
                                  widget.message.status.label,
                                  style: const TextStyle(
                                    color: Color(0xFF8FA0B8),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_imageDimensions != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE)
                                .withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusSm),
                            border: Border.all(
                              color: const Color(0xFF22D3EE)
                                  .withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${_imageDimensions!.width.toInt()} × ${_imageDimensions!.height.toInt()} px',
                            style: const TextStyle(
                              color: Color(0xFF22D3EE),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1322),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: const Color(0xFF263754)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_rounded, size: 48, color: Color(0xFF8FA0B8)),
          SizedBox(height: 12),
          Text(
            'Photo unavailable in local storage',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
