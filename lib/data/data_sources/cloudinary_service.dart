import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  Future<String?> uploadImage(String imagePath) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

    if (cloudName == null || uploadPreset == null) {
      throw Exception('Cloudinary credentials not found in .env file');
    }

    final cloudinary = CloudinaryPublic(cloudName, uploadPreset, cache: false);

    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imagePath,
          resourceType: CloudinaryResourceType.Image,
          folder: 'ecomap/bins',
        ),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      debugPrint(e.message);
      debugPrint(
        e.request.toString(),
      ); // Convert request to string for debugPrint
      return null;
    }
  }
}
