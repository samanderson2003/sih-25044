import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/farm_plot_model.dart';

class FarmPlotController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save farm plot
  Future<Map<String, dynamic>> saveFarmPlot(FarmPlotModel farmPlot) async {
    try {
      print('💾 Saving farm plot to Firestore...');
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _firestore
          .collection('farmPlots')
          .doc(user.uid)
          .set(farmPlot.toJson(), SetOptions(merge: true));

      print('✅ Farm plot saved successfully');
      return {'success': true, 'message': 'Farm plot saved successfully'};
    } catch (e) {
      print('🔥 Error saving farm plot: $e');
      return {'success': false, 'message': 'Error saving farm plot: $e'};
    }
  }

  // Get farm plot
  Future<FarmPlotModel?> getFarmPlot() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('farmPlots').doc(user.uid).get();
      if (!doc.exists) return null;

      return FarmPlotModel.fromJson(doc.data()!);
    } catch (e) {
      print('Error fetching farm plot: $e');
      return null;
    }
  }

  // Get farm plot stream for real-time updates
  Stream<FarmPlotModel?> getFarmPlotStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('farmPlots').doc(user.uid).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return FarmPlotModel.fromJson(doc.data()!);
    });
  }

  // Delete farm plot
  Future<Map<String, dynamic>> deleteFarmPlot() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      await _firestore.collection('farmPlots').doc(user.uid).delete();

      return {'success': true, 'message': 'Farm plot deleted successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Error deleting farm plot: $e'};
    }
  }
}
