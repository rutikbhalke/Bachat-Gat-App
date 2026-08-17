import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ConnectivityTestService {
  static Future<void> runTest() async {
    debugPrint('--- FIREBASE CONNECTIVITY TEST START ---');
    
    try {
      final firestore = FirebaseFirestore.instance;
      const collectionPath = 'firebase_connection_test';
      const docId = 'diagnostic_doc';
      final docRef = firestore.collection(collectionPath).doc(docId);
      
      final testData = {
        'test': true,
        'message': 'Firebase connection test',
        'status': 'connected',
        'timestamp': FieldValue.serverTimestamp(),
      };

      // 1. WRITE
      try {
        await docRef.set(testData);
        debugPrint('FIREBASE TEST: WRITE SUCCESS');
      } catch (e) {
        debugPrint('FIREBASE TEST: WRITE FAILED - $e');
        rethrow;
      }

      // 2. READ
      try {
        final snapshot = await docRef.get(const GetOptions(source: Source.server));
        if (snapshot.exists && snapshot.data() != null) {
          debugPrint('FIREBASE TEST: READ SUCCESS');
        } else {
          throw Exception('Document does not exist on server after write');
        }
      } catch (e) {
        debugPrint('FIREBASE TEST: READ FAILED - $e');
        rethrow;
      }

      // 3. UPDATE
      try {
        await docRef.update({
          'status': 'updated',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final updatedSnapshot = await docRef.get(const GetOptions(source: Source.server));
        if (updatedSnapshot.exists && updatedSnapshot.data()?['status'] == 'updated') {
          debugPrint('FIREBASE TEST: UPDATE SUCCESS');
        } else {
          throw Exception('Updated document did not match expected value');
        }
      } catch (e) {
        debugPrint('FIREBASE TEST: UPDATE FAILED - $e');
        rethrow;
      }

      // 4. DELETE
      try {
        await docRef.delete();
        final deletedSnapshot = await docRef.get(const GetOptions(source: Source.server));
        if (!deletedSnapshot.exists) {
          debugPrint('FIREBASE TEST: DELETE SUCCESS');
        } else {
          throw Exception('Document still exists after delete');
        }
      } catch (e) {
        debugPrint('FIREBASE TEST: DELETE FAILED - $e');
        rethrow;
      }

      debugPrint('--- FIREBASE CONNECTIVITY TEST COMPLETED SUCCESSFULLY ---');
    } catch (e) {
      debugPrint('FIREBASE CONNECTIVITY TEST: FAILED - $e');
    }
  }
}
