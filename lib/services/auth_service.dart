import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signIn({
    required String email,
    required String password
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password
    );
    await _updateUserData(cred.user);
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _updateUserData(User? user) async {
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'lastSignIn': DateTime.now()
      }, SetOptions(merge: true));
    }
  }
}
