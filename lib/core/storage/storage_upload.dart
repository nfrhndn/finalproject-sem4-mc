import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_upload_stub.dart'
    if (dart.library.io) 'storage_upload_io.dart'
    if (dart.library.html) 'storage_upload_web.dart'
    as storage_upload;

Future<void> uploadPickedFile({
  required SupabaseClient client,
  required String bucket,
  required String objectPath,
  required XFile file,
  FileOptions fileOptions = const FileOptions(upsert: true),
}) {
  return storage_upload.uploadPickedFile(
    client: client,
    bucket: bucket,
    objectPath: objectPath,
    file: file,
    fileOptions: fileOptions,
  );
}

String pickedFileExtension(XFile file, {String fallback = 'jpg'}) {
  final name = file.name.isNotEmpty ? file.name : file.path;
  final extension = name.split('.').last.toLowerCase();
  if (extension == name || extension.isEmpty || extension.length > 5) {
    return fallback;
  }
  return extension;
}
