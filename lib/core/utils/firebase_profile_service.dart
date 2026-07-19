import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:tictactoe/core/utils/progression_service.dart';

class FirebaseProfileService {
  static final FirebaseProfileService _instance = FirebaseProfileService._internal();

  factory FirebaseProfileService() => _instance;
  FirebaseProfileService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  // Use a generic placeholder since we don't have FirebaseAuth yet.
  String get _uid => 'anonymous_user'; 

  Future<void> syncProfileToFirebase() async {
    try {
      final profile = ProgressionService().profile;
      await _db.ref('users/$_uid/profile').set(profile.toJson());
    } catch (e) {
      debugPrint('[FirebaseProfileService] sync failed: $e');
    }
  }

  Future<void> loadProfileFromFirebase() async {
    try {
      final snapshot = await _db.ref('users/$_uid/profile').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        // Profile loaded — could merge into ProgressionService here
        debugPrint('[FirebaseProfileService] loaded profile: $data');
      }
    } catch (e) {
      debugPrint('[FirebaseProfileService] load failed: $e');
    }
  }
}
