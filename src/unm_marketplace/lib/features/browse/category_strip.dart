import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../theme/tokens.dart';
import '../../widgets/category_icon.dart';

/// Horizontal category chips with live counts. Tapping the selected one clears it.
class CategoryStrip extends ConsumerWidget {
  const CategoryStrip({super.key, required this.selected, required this.onSelect});
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoriesProvider).value ?? const [];
    Widget chip({required Key key, required String label, required IconData icon, required bool on, required VoidCallback onTap, int? count}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          key: key,
          selected: on,
          showCheckmark: false,
          onSelected: (_) => onTap(),
          avatar: Icon(icon, size: 18, color: on ? AppTokens.cyan : null),
          label: Text(count == null ? label : '$label  $count'),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        chip(key: const Key('category-all'), label: 'All', icon: Icons.apps_rounded, on: selected == null, onTap: () => onSelect(null)),
        for (final c in cats)
          chip(
            key: Key('category-${c.slug}'),
            label: c.name,
            icon: categoryIcon(c.icon),
            count: c.count,
            on: selected == c.slug,
            onTap: () => onSelect(selected == c.slug ? null : c.slug),
          ),
      ]),
    );
  }
}
