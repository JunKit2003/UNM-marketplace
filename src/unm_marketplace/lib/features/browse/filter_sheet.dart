import 'package:flutter/material.dart';

import '../../core/api/models.dart';
import '../../core/repositories/listings_repository.dart';

/// Bottom sheet for condition and price range. Returns the new filters, or null if dismissed.
Future<BrowseFilters?> showFilterSheet(
  BuildContext context,
  BrowseFilters current,
) {
  return showModalBottomSheet<BrowseFilters>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    builder: (_) => _FilterSheet(current: current),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current});
  final BrowseFilters current;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _condition = widget.current.condition;
  late final _min = TextEditingController(
    text: widget.current.min?.toString() ?? '',
  );
  late final _max = TextEditingController(
    text: widget.current.max?.toString() ?? '',
  );

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: t.headlineSmall),
          const SizedBox(height: 20),
          Text('Condition', style: t.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in conditions)
                ChoiceChip(
                  label: Text(c),
                  selected: _condition == c,
                  onSelected: (on) =>
                      setState(() => _condition = on ? c : null),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Price (RM)', style: t.titleSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min'),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('to'),
              ),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  widget.current.copyWith(
                    condition: null,
                    min: null,
                    max: null,
                  ),
                ),
                child: const Text('Clear'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  widget.current.copyWith(
                    condition: _condition,
                    min: num.tryParse(_min.text.trim()),
                    max: num.tryParse(_max.text.trim()),
                  ),
                ),
                child: const Text('Show results'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
