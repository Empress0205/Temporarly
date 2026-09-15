import 'dart:typed_data';

import 'package:jihudumie_app/orders/photo_service.dart';

/// Scriptable stand-in for [JhPhotoService] -- no real camera or file picker
/// touched in a test.
class FakePhotoService implements JhPhotoService {
  Uint8List? cameraResult;
  Uint8List? galleryResult;
  final List<String> calls = [];

  @override
  Future<Uint8List?> pickFromCamera() async {
    calls.add('camera');
    return cameraResult;
  }

  @override
  Future<Uint8List?> pickFromGallery() async {
    calls.add('gallery');
    return galleryResult;
  }
}
