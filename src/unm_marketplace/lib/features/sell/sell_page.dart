import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/api/models.dart';
import '../../core/format.dart';
import '../../core/repositories/listings_repository.dart';
import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/net_image.dart';
import '../listing/listing_controller.dart';
import 'listing_form.dart';
import 'photo_picker.dart';
import 'photo_picker_grid.dart';
import 'validators.dart';

/// Create (three steps) or edit (one page) a listing.
class SellPage extends ConsumerWidget {
  const SellPage({super.key, this.editId});
  final int? editId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (editId == null) return const _CreateFlow();
    return ref
        .watch(listingProvider(editId!))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
            icon: Icons.search_off_rounded,
            title: ApiError.from(e).message,
          ),
          data: (l) => l.isOwner
              ? _EditListing(listing: l)
              : const EmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Only the seller can edit this listing.',
                ),
        );
  }
}

const _steps = ['Photos', 'Details', 'Review'];

class _CreateFlow extends ConsumerStatefulWidget {
  const _CreateFlow();

  @override
  ConsumerState<_CreateFlow> createState() => _CreateFlowState();
}

class _CreateFlowState extends ConsumerState<_CreateFlow> {
  int _step = 0;
  final _photos = <PickedPhoto>[];
  final _data = ListingFormData();
  final _formKey = GlobalKey<FormState>();
  String? _photoMessage;
  String? _error;
  bool _publishing = false;

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  void _addPhotos(List<PickedPhoto> picked) {
    String? problem;
    for (final p in picked) {
      final err = validatePhoto(p);
      if (err != null) {
        problem = err;
      } else if (_photos.length >= maxPhotos) {
        problem = 'A listing can have up to 6 photos.';
      } else {
        _photos.add(p);
      }
    }
    setState(() => _photoMessage = problem);
  }

  Future<void> _pick() async =>
      _addPhotos(await ref.read(photoPickerProvider)());

  void _next() {
    if (_step == 0 && _photos.isEmpty) {
      setState(() => _photoMessage = 'Add at least one photo.');
      return;
    }
    if (_step == 1) {
      _data.serverErrors = {};
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }
    setState(() => _step++);
  }

  Future<void> _publish() async {
    setState(() {
      _publishing = true;
      _error = null;
    });
    try {
      final l = await ref
          .read(listingsRepositoryProvider)
          .create(
            ListingDraft(
              title: _data.title.text.trim(),
              description: _data.description.text.trim(),
              price: _data.price.text.trim(),
              categorySlug: _data.categorySlug!,
              condition: _data.condition,
            ),
            _photos,
          );
      ref.read(listingsVersionProvider.notifier).bump();
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your listing is live.')));
      context.go('/listing/${l.id}');
    } on ApiError catch (e) {
      setState(() {
        _error = e.message;
        _data.serverErrors = e.fields;
        if (e.fields.keys.any((k) => k != 'photos')) _step = 1;
      });
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final t = Theme.of(context).textTheme;

    final stepBody = switch (_step) {
      0 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add photos', style: t.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Bright, clear photos sell faster. Natural light works best.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 18),
          PhotoPickerGrid(
            photos: _photos,
            onAdd: _pick,
            onDropped: _addPhotos,
            onRemove: (i) => setState(() => _photos.removeAt(i)),
            onReorder: (a, b) =>
                setState(() => _photos.insert(b, _photos.removeAt(a))),
          ),
        ],
      ),
      1 => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Describe it', style: t.headlineSmall),
          const SizedBox(height: 18),
          ListingForm(
            data: _data,
            formKey: _formKey,
            onChanged: () => setState(() {}),
          ),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review', style: t.headlineSmall),
          const SizedBox(height: 6),
          Text(
            "This is how buyers will see it. Happy? Publish it.",
            style: t.bodyMedium,
          ),
          if (!wide) ...[
            const SizedBox(height: 18),
            Center(
              child: SizedBox(
                width: 320,
                child: _PreviewCard(photos: _photos, data: _data),
              ),
            ),
          ],
        ],
      ),
    };

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeader(step: _step),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(a),
              child: c,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_step), child: stepBody),
        ),
        if (_photoMessage != null && _step == 0) ...[
          const SizedBox(height: 12),
          Text(
            _photoMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            if (_step > 0)
              OutlinedButton(
                onPressed: () => setState(() => _step--),
                child: const Text('Back'),
              ),
            const Spacer(),
            if (_step < 2)
              FilledButton(onPressed: _next, child: const Text('Next'))
            else
              FilledButton.icon(
                onPressed: _publishing ? null : _publish,
                icon: _publishing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rocket_launch_rounded),
                label: const Text('Publish'),
              ),
          ],
        ),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 16, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 48),
                    SizedBox(
                      width: 340,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live preview',
                            style: t.titleSmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PreviewCard(photos: _photos, data: _data),
                        ],
                      ),
                    ),
                  ],
                )
              : content,
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sell something', style: t.displaySmall),
        const SizedBox(height: 18),
        Row(
          children: [
            for (final (i, s) in _steps.indexed) ...[
              if (i > 0)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      gradient: i <= step ? AppTokens.accent : null,
                      color: i <= step
                          ? null
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: i <= step ? AppTokens.accent : null,
                  border: i <= step
                      ? null
                      : Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                ),
                child: Center(
                  child: i < step
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                s,
                style: t.labelLarge?.copyWith(
                  fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Mirrors ListingCard, using the local photo bytes.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.photos, required this.data});
  final List<PickedPhoto> photos;
  final ListingFormData data;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final price = num.tryParse(data.price.text.trim());
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photos.isEmpty)
                  ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: const Icon(
                      Icons.photo_camera_back_rounded,
                      size: 40,
                    ),
                  )
                else
                  Image.memory(
                    photos.first.bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: Colors.black26),
                  ),
                if (price != null)
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Text(
                      formatPrice(price),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: AppTokens.display,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        shadows: [Shadow(blurRadius: 8)],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title.text.isEmpty ? 'Your title here' : data.title.text,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ConditionPill(data.condition),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _EditListing extends ConsumerStatefulWidget {
  const _EditListing({required this.listing});
  final Listing listing;

  @override
  ConsumerState<_EditListing> createState() => _EditListingState();
}

class _EditListingState extends ConsumerState<_EditListing> {
  late final _data = ListingFormData()..fillFrom(widget.listing);
  final _formKey = GlobalKey<FormState>();
  late Listing _listing = widget.listing;
  bool _saving = false;
  String? _message;

  ListingsRepository get _repo => ref.read(listingsRepositoryProvider);

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Listing> Function() op) async {
    try {
      final l = await op();
      setState(() {
        _listing = l;
        _message = null;
      });
      ref.read(listingProvider(l.id).notifier).set(l);
      ref.read(listingsVersionProvider.notifier).bump();
    } on ApiError catch (e) {
      setState(() => _message = e.message);
    }
  }

  Future<void> _addPhotos() async {
    final picked = await ref.read(photoPickerProvider)();
    final ok = picked.where((p) => validatePhoto(p) == null).toList();
    if (ok.length < picked.length) setState(() => _message = photoError);
    if (ok.isNotEmpty) await _run(() => _repo.addImages(_listing.id, ok));
  }

  Future<void> _save() async {
    _data.serverErrors = {};
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final l = await _repo.update(_listing.id, {
        'title': _data.title.text.trim(),
        'price': _data.price.text.trim(),
        'description': _data.description.text.trim(),
        'categorySlug': _data.categorySlug,
        'condition': _data.condition,
      });
      ref.read(listingProvider(l.id).notifier).set(l);
      ref.read(listingsVersionProvider.notifier).bump();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Changes saved.')));
      context.go('/listing/${l.id}');
    } on ApiError catch (e) {
      setState(() {
        _message = e.message;
        _data.serverErrors = e.fields;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final images = _listing.images;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit listing', style: t.displaySmall),
              const SizedBox(height: 24),
              Text('Photos', style: t.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (i, img) in images.indexed)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            NetImage(img.url),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton.filled(
                                tooltip: 'Remove photo',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: images.length == 1
                                    ? null
                                    : () => _run(
                                        () => _repo.deleteImage(
                                          _listing.id,
                                          img.id,
                                        ),
                                      ),
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                            ),
                            Positioned(
                              left: 6,
                              bottom: 6,
                              child: i == 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppTokens.accent,
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: const Text(
                                        'Cover',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  : TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () => _run(
                                        () => _repo.reorderImages(_listing.id, [
                                          img.id,
                                          ...images
                                              .where((x) => x.id != img.id)
                                              .map((x) => x.id),
                                        ]),
                                      ),
                                      child: const Text('Make cover'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (images.length < maxPhotos)
                    OutlinedButton.icon(
                      onPressed: _addPhotos,
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                      label: const Text('Add photos'),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              ListingForm(data: _data, formKey: _formKey),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/listing/${_listing.id}'),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Save changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
