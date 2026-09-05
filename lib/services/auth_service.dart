import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseService _firebaseService;

  AuthService({FirebaseAuth? auth, FirebaseService? firebaseService})
      : _auth = auth ?? FirebaseAuth.instance,
        _firebaseService = firebaseService ?? FirebaseService();

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Fetches the user profile document from root `users/{uid}`
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = currentUid;
    if (uid == null) return null;

    try {
      final doc = await _firebaseService.users.doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('[AUTH SERVICE] Error fetching user profile for $uid: $e');
    }
    return null;
  }

  /// Resolves the groupId from the authenticated user's profile in `users/{uid}`.
  /// Falls back gracefully to the provided default or first available group.
  Future<String> resolveGroupId({String fallbackGroupId = 'shivshahi_group_001'}) async {
    final profile = await getCurrentUserProfile();
    if (profile != null && profile['groupId'] != null) {
      final gid = profile['groupId'].toString().trim();
      if (gid.isNotEmpty) {
        return gid;
      }
    }

    // Check if any group exists in `groups` collection
    try {
      final groupsSnap = await _firebaseService.groups.limit(1).get();
      if (groupsSnap.docs.isNotEmpty) {
        return groupsSnap.docs.first.id;
      }
    } catch (e) {
      debugPrint('[AUTH SERVICE] Error resolving group from Firestore: $e');
    }

    return fallbackGroupId;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
