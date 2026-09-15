import 'dart:typed_data';

/// Camera/gallery access for the Package step's optional photo. Mirrors
/// [JhLocationService]: an interface with no plugin import, so tests inject a
/// fake instead of touching a real camera or file picker.
abstract class JhPhotoService {
  /// Bytes of the photo taken, or null if the customer cancelled.
  Future<Uint8List?> pickFromCamera();

  /// Bytes of the photo chosen from the gallery, or null if cancelled.
  Future<Uint8List?> pickFromGallery();
}
