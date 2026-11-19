import 'package:flutter/material.dart';

/// Material icon for the API's category `icon` names.
IconData categoryIcon(String name) => switch (name) {
  'menu_book' => Icons.menu_book_rounded,
  'devices' => Icons.devices_rounded,
  'chair' => Icons.chair_rounded,
  'checkroom' => Icons.checkroom_rounded,
  'pedal_bike' => Icons.pedal_bike_rounded,
  'apartment' => Icons.apartment_rounded,
  'sports_esports' => Icons.sports_esports_rounded,
  'theaters' => Icons.theaters_rounded,
  'family_restroom' => Icons.family_restroom_rounded,
  _ => Icons.category_rounded,
};
