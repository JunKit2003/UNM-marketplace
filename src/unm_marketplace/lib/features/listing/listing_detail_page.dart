import 'package:flutter/material.dart';

class ListingDetailPage extends StatelessWidget {
  const ListingDetailPage({super.key, required this.id, this.openChat = false});
  final int id;
  final bool openChat;
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Listing')));
}
