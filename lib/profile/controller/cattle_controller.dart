import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/cattle_model.dart';

class CattleController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Stream of cattle list for the current user
  Stream<List<CattleModel>> getCattleStream() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cattle')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CattleModel.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  // Add new cattle
  Future<void> addCattle({
    required String type,
    required String breed,
    required int age,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('cattle')
        .add({
      'cattle': type,
      'breed': breed,
      'age': age,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete cattle
  Future<void> deleteCattle(String cattleId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('cattle')
        .doc(cattleId)
        .delete();
  }
}
