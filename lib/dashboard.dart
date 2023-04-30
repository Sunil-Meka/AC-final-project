import 'package:final_project/login.dart';
import 'package:final_project/rsa_brain.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat.dart';

class HomeScreen extends StatelessWidget {
  // this is the dashboard screen which will show all the users as the chat cards
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
            // navigate to login screen as user is logged out
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
        // get all the users except the current user
        stream: FirebaseFirestore.instance
            .collection('users')
            .where(
              "email",
              isNotEqualTo: FirebaseAuth.instance.currentUser!.email,
            )
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            // show loading if data is not available
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.length == 0) {
            // show no users found if there are no users
            return Center(child: Text('No users found'));
          }
          // show all the users as chat cards
          return ListView(
            children: snapshot.data!.docs.map((document) {
              // return a chat card for each user with name and email
              return Card(
                child: ListTile(
                  title: Text(document['displayName']),
                  subtitle: Text(document['email']),
                  onTap: () {
                    // Navigate to chat details screen between current user and the selected user
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
