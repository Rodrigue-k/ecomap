import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestPhotosPermission() async {
    if (await Permission.photos.request().isGranted) {
      return true;
    }
    return false;
  }

  static Future<bool> checkAndRequestPhotosPermission() async {
    if (await Permission.photos.isGranted) {
      return true;
    }
    return await requestPhotosPermission();
  }

  static Future<bool> checkAndRequestCameraPermission() async {
    if (await Permission.camera.isGranted) {
      return true;
    }
    return await requestCameraPermission();
  }

  static Future<bool> checkAndRequestMediaPermissions() async {
    final cameraStatus = await checkAndRequestCameraPermission();
    final photosStatus = await checkAndRequestPhotosPermission();
    return cameraStatus && photosStatus;
  }
}
