import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  late final FirebaseFirestore firestore;
  late final FirebaseStorage storage;

  FirebaseService({FirebaseFirestore? firestore, FirebaseStorage? storage}) {
    if (firestore != null) {
      this.firestore = firestore;
    } else {
      try {
        this.firestore = FirebaseFirestore.instance;
        this.firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (_) {
        // Ignored if in test or already initialized
      }
    }

    if (storage != null) {
      this.storage = storage;
    } else {
      try {
        this.storage = FirebaseStorage.instance;
      } catch (_) {
        // Ignored if in test
      }
    }
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
