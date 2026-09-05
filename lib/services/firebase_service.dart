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

  // ---------------------------------------------------------------------------
  // ROOT COLLECTIONS (Exact Web Database Structure)
  // ---------------------------------------------------------------------------
  CollectionReference get groups => firestore.collection('groups');
  CollectionReference get users => firestore.collection('users');
  CollectionReference get monthlyContributions => firestore.collection('monthlyContributions');
  CollectionReference get loans => firestore.collection('loans');
  CollectionReference get repayments => firestore.collection('repayments');
  CollectionReference get transactions => firestore.collection('transactions');

  // ---------------------------------------------------------------------------
  // DOCUMENT REFERENCES
  // ---------------------------------------------------------------------------
  DocumentReference groupDoc(String groupId) => groups.doc(groupId);
  DocumentReference userDoc(String uid) => users.doc(uid);
  DocumentReference contributionDoc(String id) => monthlyContributions.doc(id);
  DocumentReference loanDoc(String id) => loans.doc(id);
  DocumentReference repaymentDoc(String id) => repayments.doc(id);
  DocumentReference transactionDoc(String id) => transactions.doc(id);

  // ---------------------------------------------------------------------------
  // GROUP-SCOPED QUERY HELPERS
  // ---------------------------------------------------------------------------
  Query members(String groupId) =>
      users.where('groupId', isEqualTo: groupId);

  Query monthlyContributionsByGroup(String groupId) =>
      monthlyContributions.where('groupId', isEqualTo: groupId);

  Query loansByGroup(String groupId) =>
      loans.where('groupId', isEqualTo: groupId);

  Query repaymentsByGroup(String groupId) =>
      repayments.where('groupId', isEqualTo: groupId);

  Query activities(String groupId) =>
      transactions.where('groupId', isEqualTo: groupId);

  // Compatibility aliases
  Query loanRepayments(String groupId) => repaymentsByGroup(groupId);
  Query savings(String groupId) => monthlyContributionsByGroup(groupId);
}

