import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<FreeUser?> fetchUser(String uid) async {
    print("Fetching User: $uid");
    FreeUser user;
    DocumentSnapshot documentSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (documentSnapshot.exists) {
      user = FreeUser.fromJson(uid, documentSnapshot.data() as Map<String, dynamic>);
      return user;
    }
    return null;

  }

  Future<void> saveUser(FreeUser freeUser) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(freeUser.uid)
        .set(freeUser.toJson());
  }


  Future<bool> setHunterName(String uid, String hunterName) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final userRef = _firestore.collection('users').doc(uid);
    final hunterRef = _firestore.collection('hunters').doc(hunterName);

    try {
      bool success = await _firestore.runTransaction((transaction) async {
        final hunterDoc = await transaction.get(hunterRef);

        if (hunterDoc.exists) {
          // Document with hunterName already exists
          Map<String, dynamic> data = hunterDoc.data() as Map<String, dynamic>;
          if (data['uid'] == uid) {
            return true;
          } else {
            return false;
          }
        } else {
          transaction.set(hunterRef, {
            'uid': uid,
            'hunterId': hunterName,
          });
          transaction.set(userRef, {
            'hunter': hunterName,
          }, SetOptions(merge: true));
          return true;
        }
      });

      return success;
    } catch (e) {
      print('Error setting hunter name: $e');
      return false;
    }
  }


  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}