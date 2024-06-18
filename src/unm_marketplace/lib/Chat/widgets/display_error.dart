import 'package:flutter/material.dart';

class DisplayError extends StatelessWidget {
  const DisplayError({Key? key, this.error}) : super(key: key);

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Oh no, something went wrong. '
        'Please check your config. $error',
      ),
    );
  }
}