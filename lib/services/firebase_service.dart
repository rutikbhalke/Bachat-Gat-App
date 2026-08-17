import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  FirebaseService() {
    try {
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (_) {
      // Ignored if settings already set
    }
  }

  /// Ensures that there is an active authenticated Firebase user session.
  Future<User?> ensureAuthenticatedSession() async {
    User? user = auth.currentUser;
    if (user == null) {
      try {
        final credential = await auth.signInAnonymously();
        user = credential.user;
      } catch (e) {
        // In local/test environments or when offline, fallback gracefully
      }
    }
    return user;
  }

  // Collection References
  CollectionReference get groups => firestore.collection('groups');

  // Helper to get group-specific sub-collections
  CollectionReference members(String groupId) => 
      groups.doc(groupId).collection('members');
  
  CollectionReference monthlyContributions(String groupId) => 
      groups.doc(groupId).collection('monthly_contributions');

  // Alias for backward compatibility
  CollectionReference savings(String groupId) => monthlyContributions(groupId);
  
  CollectionReference loans(String groupId) => 
      groups.doc(groupId).collection('loans');
  
  CollectionReference loanRepayments(String groupId) => 
      groups.doc(groupId).collection('loan_repayments');

  // Alias for backward compatibility
  CollectionReference repayments(String groupId) => loanRepayments(groupId);
  
  CollectionReference activities(String groupId) => 
      groups.doc(groupId).collection('activities');
}
