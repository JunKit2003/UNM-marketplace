import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/models.dart';

typedef PhotoPicker = Future<List<PickedPhoto>> Function();

/// Opens the browser's file chooser for images. Overridden in tests.
final photoPickerProvider = Provider<PhotoPicker>((ref) => () async {
      final files = await ImagePicker().pickMultiImage(limit: 6);
      return [
        for (final f in files) PickedPhoto(bytes: await f.readAsBytes(), name: f.name, mimeType: f.mimeType),
      ];
    });
