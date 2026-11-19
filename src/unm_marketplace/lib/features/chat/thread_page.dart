import 'package:flutter/material.dart';

class ThreadPage extends StatelessWidget {
  const ThreadPage({super.key, required this.id});
  final int id;
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Thread')));
}
