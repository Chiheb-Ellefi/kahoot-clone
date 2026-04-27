import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../error/failures.dart';

/// Helper class for uploading files to Supabase Storage.
/// Uses [XFile] (from image_picker) instead of dart:io [File]
/// so it works on Flutter Web as well as mobile.
/// Each method returns a public download URL on success or throws [StorageFailure].
class SupabaseStorageHelper {
  SupabaseStorageHelper._();

  static SupabaseClient get _client => Supabase.instance.client;

  // ─── Upload quiz cover image ────────────────────────────────────────────
  static Future<String> uploadQuizCover(XFile file) async {
    return _upload(
      bucket: AppConstants.quizCoversBucket,
      file: file,
      folder: 'covers',
    );
  }

  // ─── Upload question image ──────────────────────────────────────────────
  static Future<String> uploadQuestionImage(XFile file) async {
    return _upload(
      bucket: AppConstants.questionImagesBucket,
      file: file,
      folder: 'questions',
    );
  }

  // ─── Upload user avatar ─────────────────────────────────────────────────
  static Future<String> uploadAvatar(XFile file) async {
    return _upload(
      bucket: AppConstants.avatarsBucket,
      file: file,
      folder: 'avatars',
    );
  }

  // ─── Upload document (PDF/PPTX) ──────────────────────────────────────────
  static Future<String> uploadDocument(PlatformFile file) async {
    try {
      final bytes = file.bytes;
      if (bytes == null) throw const StorageFailure('File bytes are null');

      final fileName = 'docs/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      await _client.storage.from(AppConstants.documentsBucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      return _client.storage
          .from(AppConstants.documentsBucket)
          .getPublicUrl(fileName);
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    } catch (e) {
      throw StorageFailure('Failed to upload document: $e');
    }
  }

  // ─── Internal helper ────────────────────────────────────────────────────
  static Future<String> _upload({
    required String bucket,
    required XFile file,
    required String folder,
  }) async {
    try {
      // Read bytes — works on both Web and mobile (no dart:io needed)
      final bytes = await file.readAsBytes();

      // Derive a safe filename from the original name or path
      final originalName = file.name.isNotEmpty
          ? file.name
          : file.path.split('/').last.split('\\').last;

      final fileName =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_$originalName';

      await _client.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _client.storage.from(bucket).getPublicUrl(fileName);
      return publicUrl;
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    } catch (e) {
      throw StorageFailure('Failed to upload file: $e');
    }
  }
}
