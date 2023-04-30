import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/register.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'dashboard.dart';
import 'login.dart';
import 'rsa_brain.dart';

void main() async {
  // main function which will run at the start of the application
  // initialize firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  var _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // initailize RSA brain which will create a key pair for the user
    RSABrain _rsaBrain = RSABrain();
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData &&
              snapshot.data != null &&
              _currentUser != null) {
            // update the public key in firestore
            print("updating public key");
            FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .update({
              'publickey': _rsaBrain.getOwnPublicKey().toString(),
              "updated": DateTime.now().toIso8601String()
            });
            // navigate to dashboard as user is logged in
            return HomeScreen(_rsaBrain);
          } else {
            // navigate to login screen as user is not logged in
            return LoginScreen(_rsaBrain);
          }
        },
      ),
    );
  }
}
