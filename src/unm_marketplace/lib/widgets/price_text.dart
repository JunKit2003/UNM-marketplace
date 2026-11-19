import 'package:flutter/material.dart';

import '../core/format.dart';

class PriceText extends StatelessWidget {
  const PriceText(this.price, {super.key, this.style});
  final num price;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
        formatPrice(price),
        style: style ?? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      );
}
