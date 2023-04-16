import 'package:final_project/login.dart';
import 'package:final_project/rsa_brain.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat.dart';

class HomeScreen extends StatelessWidget {
  final RSABrain rsaBrain;
  HomeScreen(this.rsaBrain);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users'), actions: [
        IconButton(
          alignment: Alignment.topRight,
          icon: Icon(Icons.logout),
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoginScreen(rsaBrain),
              ),
            );
          },
        ),
      ]),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where(
              "email",
              isNotEqualTo: FirebaseAuth.instance.currentUser!.email,
            )
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.length == 0) {
            return Center(child: Text('No users found'));
          }
          return ListView(
            children: snapshot.data!.docs.map((document) {
              return Card(
                child: ListTile(
                  title: Text(document['displayName']),
                  subtitle: Text(document['email']),
                  onTap: () {
                    // Navigate to user details screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                            opponentEmail: document['email'],
                            opponentPublicKey: document['publickey'],
                            rsaBrain: rsaBrain),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
