import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebtService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addDebt({
    required String otherUserEmail,
    required double amount,
  }) async {
    final String uid = _auth.currentUser!.uid;

    final CollectionReference<Map<String, dynamic>> debts = _firestore
        .collection('users')
        .doc(uid)
        .collection('debts');

    await debts.add({
      'otherUserEmail': otherUserEmail,
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
