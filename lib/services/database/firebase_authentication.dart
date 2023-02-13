import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthentication {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void> signsUserInAnonymously() async {
    // Signs user in anonymously
    await _auth.signInAnonymously();
  }
}
