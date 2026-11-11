/// Cloudinary settings for incident photo uploads.
///
/// These values are safe to ship in the app. Uploads use an unsigned preset,
/// so no API secret is needed. Never put the Cloudinary API secret here.
class CloudinaryConfig {
  static const String cloudName = 'dasumvwgg';
  static const String uploadPreset = 'tatua_reports';

  static Uri get uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
}
