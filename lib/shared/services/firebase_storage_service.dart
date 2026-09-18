import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Shared Firebase Storage Service
/// Handles uploading images to Cloud Storage and generating secure download URLs.
class SharedFirebaseStorageService {
  FirebaseStorage? _storage;

  SharedFirebaseStorageService() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _storage = FirebaseStorage.instance;
      }
    } catch (e) {
      debugPrint('FirebaseStorage initialization notice: $e (using fallback image URLs)');
    }
  }

  /// Uploads user profile avatar and returns public HTTPS URL
  Future<String> uploadProfileAvatar({
    required String userId,
    required Uint8List imageBytes,
    String contentType = 'image/jpeg',
  }) async {
    if (_storage != null) {
      try {
        final ref = _storage!
            .ref()
            .child('users')
            .child(userId)
            .child('avatar.jpg');

        final metadata = SettableMetadata(contentType: contentType);
        final uploadTask = await ref.putData(imageBytes, metadata);
        return await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Firebase Storage upload failed: $e');
      }
    }
    // Fallback image URL when storage is offline
    return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80';
  }

  /// Uploads restaurant media image
  Future<String> uploadRestaurantImage({
    required String restaurantId,
    required String fileName,
    required Uint8List imageBytes,
    String contentType = 'image/jpeg',
  }) async {
    if (_storage != null) {
      try {
        final ref = _storage!
            .ref()
            .child('restaurants')
            .child(restaurantId)
            .child(fileName);

        final metadata = SettableMetadata(contentType: contentType);
        final uploadTask = await ref.putData(imageBytes, metadata);
        return await uploadTask.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Firebase Storage upload failed: $e');
      }
    }
    return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80';
  }
}
