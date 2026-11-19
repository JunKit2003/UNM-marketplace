import '../../core/api/models.dart';

const photoError = 'Photos must be JPEG, PNG or WebP, up to 5 MB.';
const maxPhotos = 6;
const _maxBytes = 5 * 1024 * 1024;
final _priceRe = RegExp(r'^\d{1,7}(\.\d{1,2})?$');

/// Same rule as the API: 0 – 1,000,000, digits only, up to 2 decimals.
String? validatePrice(String? v) {
  final s = (v ?? '').trim();
  if (!_priceRe.hasMatch(s) || num.parse(s) > 1000000) {
    return 'Enter a price from 0 to 1,000,000 with up to 2 decimals, e.g. 45 or 12.50.';
  }
  return null;
}

String? validateTitle(String? v) {
  final s = (v ?? '').trim();
  if (s.length < 3) return 'Give it a title of at least 3 characters.';
  if (s.length > 80) return 'Keep the title under 80 characters.';
  return null;
}

String? validateDescription(String? v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Add a short description.';
  if (s.length > 2000) return 'Keep the description under 2,000 characters.';
  return null;
}

/// Quick client-side check; the server re-checks the actual bytes.
String? validatePhoto(PickedPhoto p) {
  final name = p.name.toLowerCase();
  final okType =
      ['.jpg', '.jpeg', '.png', '.webp'].any(name.endsWith) ||
      ['image/jpeg', 'image/png', 'image/webp'].contains(p.mimeType);
  if (!okType || p.bytes.length > _maxBytes) return photoError;
  return null;
}
