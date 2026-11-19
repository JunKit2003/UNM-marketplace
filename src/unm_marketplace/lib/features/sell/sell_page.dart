import 'package:flutter/material.dart';

class SellPage extends StatelessWidget {
  const SellPage({super.key, this.editId});
  final int? editId;
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Sell')));
}
