import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'photo_service.dart';

/// The only file that imports `image_picker` -- same rule as
/// `JhGeoLocationService` for `geolocator`/`geocoding`.
class JhImagePickerPhotoService implements JhPhotoService {
  // Lazy, like `Geocoding()` in the location service: constructing the
  // plugin eagerly is what made a bare `JhAppState()` throw in `flutter test`
  // before that was fixed there, so this waits until a pick is actually
  // requested, which tests never do.
  late final ImagePicker _picker = ImagePicker();

  @override
  Future<Uint8List?> pickFromCamera() => _pick(ImageSource.camera);

  @override
  Future<Uint8List?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<Uint8List?> _pick(ImageSource source) async {
    // Capped so a phone-camera photo doesn't sit multiple megabytes deep in
    // memory for the rest of the wizard -- there is nowhere to upload it to
    // yet, so it lives as bytes on the draft until the order commits.
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }
}
