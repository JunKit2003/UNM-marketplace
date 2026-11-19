import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/api/api_error.dart';
import '../core/api/models.dart';
import 'auth.dart';
import 'providers.dart';

/// Toggle save for [listing]. Signed-out visitors are sent to log in first.
/// Returns the new saved state, or null if nothing changed.
Future<bool?> toggleSave(
  BuildContext context,
  WidgetRef ref,
  Listing listing,
) async {
  if (ref.read(authProvider).value == null) {
    final here = GoRouterState.of(context).uri.toString();
    context.go('/login?from=${Uri.encodeComponent(here)}');
    return null;
  }
  final repo = ref.read(listingsRepositoryProvider);
  final next = !listing.isSaved;
  try {
    next ? await repo.save(listing.id) : await repo.unsave(listing.id);
    return next;
  } on ApiError catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
    return null;
  }
}
