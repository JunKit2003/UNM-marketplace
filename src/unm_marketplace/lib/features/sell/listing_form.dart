import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/models.dart';
import '../../state/providers.dart';
import 'validators.dart';

/// Controllers for the listing fields, shared by create and edit.
class ListingFormData {
  final title = TextEditingController();
  final price = TextEditingController();
  final description = TextEditingController();
  String? categorySlug;
  String condition = 'Like new';
  Map<String, String> serverErrors = {};

  void fillFrom(Listing l) {
    title.text = l.title;
    price.text = l.price == l.price.roundToDouble() ? l.price.toInt().toString() : l.price.toString();
    description.text = l.description;
    categorySlug = l.category.slug;
    condition = l.condition;
  }

  void dispose() {
    title.dispose();
    price.dispose();
    description.dispose();
  }
}

class ListingForm extends ConsumerStatefulWidget {
  const ListingForm({super.key, required this.data, required this.formKey, this.onChanged});
  final ListingFormData data;
  final GlobalKey<FormState> formKey;
  final VoidCallback? onChanged;

  @override
  ConsumerState<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends ConsumerState<ListingForm> {
  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final cats = ref.watch(categoriesProvider).value ?? const [];
    final t = Theme.of(context).textTheme;
    String? server(String f) => d.serverErrors[f];

    return Form(
      key: widget.formKey,
      onChanged: widget.onChanged,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextFormField(
          key: const Key('field-title'),
          controller: d.title,
          maxLength: 80,
          decoration: InputDecoration(labelText: 'Title', hintText: 'e.g. LED desk lamp with USB charging', errorText: server('title')),
          validator: validateTitle,
        ),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextFormField(
              key: const Key('field-price'),
              controller: d.price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Price', prefixText: 'RM ', errorText: server('price'), errorMaxLines: 3),
              validator: validatePrice,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              key: const Key('field-category'),
              initialValue: d.categorySlug,
              isExpanded: true,
              decoration: InputDecoration(labelText: 'Category', errorText: server('categorySlug')),
              items: [for (final c in cats) DropdownMenuItem(value: c.slug, child: Text(c.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() {
                d.categorySlug = v;
                widget.onChanged?.call();
              }),
              validator: (v) => v == null ? 'Pick a category.' : null,
            ),
          ),
        ]),
        const SizedBox(height: 18),
        Text('Condition', style: t.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in conditions)
            ChoiceChip(
              label: Text(c),
              selected: d.condition == c,
              onSelected: (_) => setState(() {
                d.condition = c;
                widget.onChanged?.call();
              }),
            ),
        ]),
        const SizedBox(height: 18),
        TextFormField(
          key: const Key('field-description'),
          controller: d.description,
          minLines: 4,
          maxLines: 10,
          maxLength: 2000,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Condition details, what is included, where to meet…',
            alignLabelWithHint: true,
            errorText: server('description'),
          ),
          validator: validateDescription,
        ),
      ]),
    );
  }
}
