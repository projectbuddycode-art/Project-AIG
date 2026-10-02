import 'dart:typed_data';

class StorageService {
  const StorageService();

  Future<String> uploadBytes({required String path, required Uint8List bytes, Map<String, String>? metadata}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return path;
  }

  Future<Uint8List?> downloadBytes({required String path}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return null;
  }

  Future<void> delete({required String path}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  Future<Map<String, String>> metadata({required String path}) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return <String, String>{};
  }
}
