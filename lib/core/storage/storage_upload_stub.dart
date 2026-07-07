import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> uploadPickedFile({
  required SupabaseClient client,
  required String bucket,
  required String objectPath,
  required XFile file,
  required FileOptions fileOptions,
}) {
  throw UnsupportedError('File upload is not supported on this platform.');
}
