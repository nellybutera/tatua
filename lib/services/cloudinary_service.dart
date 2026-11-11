import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/cloudinary_config.dart';

/// Uploads incident photos to Cloudinary using an unsigned upload preset.
/// (Approved by the facilitator as the image store instead of Firebase Storage.)
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  // why Cloudinary? Firebase Storage wanted the paid plan, facilitator said Cloudinary is fine.
  // "unsigned preset" = no secret key inside the app. the preset decides what's allowed.
  static const maxBytes = 5 * 1024 * 1024; // 5 MB

  /// Returns the secure https URL of the uploaded image.
  Future<String> uploadImage(File file, {void Function(double progress)? onProgress}) async {
    final length = await file.length();
    // too big? stop right here, don't waste anyone's data
    if (length > maxBytes) {
      throw const CloudinaryException('Photo is larger than 5 MB. Please choose a smaller one.');
    }

    final request = http.MultipartRequest('POST', CloudinaryConfig.uploadUri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    onProgress?.call(0.1);
    final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();
    onProgress?.call(1);

    final json = jsonDecode(body) as Map<String, dynamic>;
    if (streamed.statusCode != 200 || json['secure_url'] == null) {
      final msg = (json['error'] as Map?)?['message'] ?? 'Upload failed (${streamed.statusCode})';
      throw CloudinaryException(msg.toString());
    }
    // we only keep the https link. Firestore stores the link, not the picture
    return json['secure_url'] as String;
  }
}

class CloudinaryException implements Exception {
  const CloudinaryException(this.message);
  final String message;
  @override
  String toString() => message;
}
