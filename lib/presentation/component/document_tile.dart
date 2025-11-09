import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf_kit/core/models/file_model.dart';

class _Thumb {
  final Uint8List bytes;
  final int width;
  final int height;
  const _Thumb(this.bytes, this.width, this.height);
}

class DocEntryCard extends StatefulWidget {
  final FileInfo info;
  final VoidCallback? onOpen;
  final ValueChanged<String>? onMenu;

  const DocEntryCard({super.key, required this.info, this.onOpen, this.onMenu});

  @override
  State<DocEntryCard> createState() => _DocEntryCardState();
}

class _DocEntryCardState extends State<DocEntryCard> {
  static final Map<String, _Thumb> _cache = {};

  bool get _isPdf => widget.info.extension.toLowerCase() == 'pdf';
  bool get _isImage => const {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  }.contains(widget.info.extension.toLowerCase());

  Future<_Thumb?> _thumbnail() async {
    final key = widget.info.path;
    if (_cache.containsKey(key)) return _cache[key];

    if (_isPdf) {
      final doc = await PdfDocument.openFile(widget.info.path);
      final page = await doc.getPage(1);
      final w = page.width.round();
      final h = page.height.round();
      const scale = 2.0;
      final img = await page.render(
        width: (w * scale).toDouble(),
        height: (h * scale).toDouble(),
      );
      await page.close();
      await doc.close();
      if (img == null) return null;
      final t = _Thumb(img.bytes, w, h);
      _cache[key] = t;
      return t;
    }

    if (_isImage) {
      final bytes = await File(widget.info.path).readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final desc = await ui.ImageDescriptor.encoded(buffer);
      final t = _Thumb(bytes, desc.width, desc.height);
      desc.dispose();
      buffer.dispose();
      _cache[key] = t;
      return t;
    }

    return null;
  }

  String _recent() {
    final dt = widget.info.lastModified ?? DateTime.now();
    return DateFormat('MM/dd/yyyy  HH:mm').format(dt);
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(files: [XFile(widget.info.path)], text: widget.info.name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FutureBuilder<_Thumb?>(
                future: _thumbnail(),
                builder: (context, snap) {
                  Widget child;
                  if (snap.connectionState == ConnectionState.waiting) {
                    child = const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  } else if (snap.data != null) {
                    final t = snap.data!;
                    final fit = (t.height > t.width)
                        ? BoxFit.fitWidth
                        : BoxFit.fitHeight;
                    child = ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox.square(
                        dimension: 70,
                        child: Image.memory(
                          t.bytes,
                          fit: fit,
                          // Optional decode downscale for memory savings:
                          cacheWidth: 140,
                          cacheHeight: 140,
                        ),
                      ),
                    );
                  } else {
                    child = Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      width: 110,
                      height: 110,
                      child: Icon(
                        _isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                        size: 42,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: child,
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 110,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.info.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _recent(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(icon: const Icon(Icons.share), onPressed: _share),
              PopupMenuButton<String>(
                onSelected: widget.onMenu,
                itemBuilder: (c) => const [
                  PopupMenuItem(value: 'open', child: Text('Open')),
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
