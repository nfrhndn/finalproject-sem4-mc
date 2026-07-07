import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> uploadPickedFile({
  required SupabaseClient client,
  required String bucket,
  required String objectPath,
  required XFile file,
  required FileOptions fileOptions,
}) {
  return client.storage
      .from(bucket)
      .upload(objectPath, File(file.path), fileOptions: fileOptions);
}
