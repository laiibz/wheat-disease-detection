import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as img;

class StorageService {
  // Since Firebase Storage is blocked for you, we are using BASE64 Database Storage.
  // This is FREE and allows Admin and Community to see all pictures!

  Future<String> uploadImage(File file, String folder) async {
    try {
      if (!await file.exists()) return "";

      // 1. Load the image
      final bytes = await file.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) return "";

      // 2. Shrink it (Resize to max 400px width for efficiency)
      img.Image resizedImage = img.copyResize(originalImage, width: 400);

      // 3. Compress it heavily to fit in the database (JPEG quality 60)
      final compressedBytes = img.encodeJpg(resizedImage, quality: 60);

      // 4. Convert to Text (Base64)
      String base64String = base64Encode(compressedBytes);
      
      print("Image converted to Base64 (Length: ${base64String.length})");
      return "data:image/jpeg;base64,$base64String"; // Return as a format the UI can read
    } catch (e) {
      print("Conversion Error: $e");
      return "";
    }
  }

  // Keep compatibility
  Future<String> saveImageLocally(File file) async {
    return await uploadImage(file, "scans");
  }
}
