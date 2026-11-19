import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../../core/api/models.dart';
import '../../theme/tokens.dart';

/// Picked photos as reorderable tiles, plus an "Add photos" tile that also accepts drag-and-drop.
class PhotoPickerGrid extends StatefulWidget {
  const PhotoPickerGrid({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onDropped,
    required this.onRemove,
    required this.onReorder,
    this.max = 6,
  });

  final List<PickedPhoto> photos;
  final VoidCallback onAdd;
  final ValueChanged<List<PickedPhoto>> onDropped;
  final ValueChanged<int> onRemove;
  final void Function(int from, int to) onReorder;
  final int max;

  @override
  State<PhotoPickerGrid> createState() => _PhotoPickerGridState();
}

class _PhotoPickerGridState extends State<PhotoPickerGrid> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final full = widget.photos.length >= widget.max;
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (detail) async {
        setState(() => _dragging = false);
        final dropped = <PickedPhoto>[];
        for (final f in detail.files) {
          dropped.add(PickedPhoto(bytes: await f.readAsBytes(), name: f.name, mimeType: f.mimeType));
        }
        widget.onDropped(dropped);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: _dragging ? AppTokens.cyan : scheme.outline, width: _dragging ? 2 : 1),
          color: _dragging ? AppTokens.cyan.withValues(alpha: 0.08) : Colors.transparent,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            height: 150,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: widget.photos.length,
              onReorderItem: widget.onReorder,
              footer: full ? null : _AddTile(onTap: widget.onAdd),
              itemBuilder: (context, i) => Padding(
                key: ValueKey(widget.photos[i]),
                padding: const EdgeInsets.only(right: 12),
                child: ReorderableDragStartListener(
                  index: i,
                  child: _PhotoTile(photo: widget.photos[i], cover: i == 0, onRemove: () => widget.onRemove(i)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Up to ${widget.max} photos. Drag to reorder; the first one is the cover. You can also drop files here.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.cover, required this.onRemove});
  final PickedPhoto photo;
  final bool cover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 150,
          height: 150,
          child: Stack(fit: StackFit.expand, children: [
            Image.memory(photo.bytes, fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black26)),
            if (cover)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(gradient: AppTokens.accent, borderRadius: BorderRadius.circular(99)),
                  child: const Text('Cover', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filled(
                tooltip: 'Remove photo',
                style: IconButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white, minimumSize: const Size(32, 32)),
                iconSize: 18,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ]),
        ),
      );
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        key: const Key('add-photos'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: [AppTokens.violet.withValues(alpha: 0.18), AppTokens.cyan.withValues(alpha: 0.12)]),
            border: Border.all(color: AppTokens.violet.withValues(alpha: 0.5)),
          ),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_photo_alternate_rounded, size: 34),
            SizedBox(height: 8),
            Text('Add photos', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
