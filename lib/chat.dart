import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'rsa_brain.dart';

class ChatScreen extends StatefulWidget {
  // this is the chat screen which will show all the messages between the current user and the opponent user
  final String opponentEmail;
  final String opponentPublicKey;
  final RSABrain rsaBrain;
  ChatScreen(
      {required this.opponentEmail,
      required this.opponentPublicKey,
      required this.rsaBrain});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
      TextEditingController(); // controller to get the message
  final ScrollController _scrollController = ScrollController();
  var _imageFile; // variable to store the image file

  // copy image from assets to application directory
  void _copyImageFromAsset(String imageName) async {
    Directory directory = await getApplicationDocumentsDirectory();
    ByteData data = await rootBundle.load("assets/" + imageName);
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    File(directory.path + "/" + imageName).writeAsBytes(bytes);
    setState(() {
      _imageFile = File(directory.path + "/" + imageName);
    });
  }

// upload image to firebase storage
  Future<String> uploadImage(File imageFile, String name) async {
    FirebaseStorage storage = FirebaseStorage.instance;

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = storage.ref().child("images/$fileName-$name");

    UploadTask uploadTask = reference.putFile(imageFile);
    TaskSnapshot taskSnapshot = await uploadTask;
    String imageUrl = await taskSnapshot.ref.getDownloadURL();

    return imageUrl;
  }

  @override
  void initState() {
    // copy image from assets to application directory
    // default.png is the default image which will be used to encode the cipher text
    _copyImageFromAsset("default.png");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // get the current user email
    String currentUserEmail =
        FirebaseAuth.instance.currentUser!.email as String;

    // generate chat id between two users
    String generateChatId(String sender, String receiver) {
      if (sender.compareTo(receiver) < 0) {
        return '$sender-$receiver';
      } else {
        return '$receiver-$sender';
      }
    }

    return Scaffold(
      appBar: AppBar(
        // show the opponent user's email as the title of the appbar
        title: Text(widget.opponentEmail),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              key: ValueKey(widget.opponentEmail),
              // fetch all the messages between the current user and the opponent user using the chat id as the channel
              // snapshot is used to get the real time data from firestore
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .where('channel',
                      isEqualTo: generateChatId(
                          currentUserEmail, widget.opponentEmail))
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // data is still loading
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // error in loading data
                  return Center(child: Text(snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  // no data found
                  return Text("No Messages Found");
                }
                // data loaded successfully
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final data = snapshot.data!.docs[index].data();
                    Message message =
                        Message.fromJson(data as Map<String, dynamic>);
                    // decrypt the message and arrange them left and right according to the sender and receiver
                    return FutureBuilder<String>(
                      future: message.sender == currentUserEmail
                          ? widget.rsaBrain.decrypt(message.sender_message_url)
                          : widget.rsaBrain
                              .decrypt(message.receiver_message_url),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          // data is still loading
                          return Container(
                            padding: EdgeInsets.all(8),
                            height: 50,
                            width: double.infinity,
                            alignment: message.sender == currentUserEmail
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          // error in loading data
                          return Container(
                            padding: EdgeInsets.all(8),
                            height: 50,
                            width: double.infinity,
                            alignment: message.sender == currentUserEmail
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Text(snapshot.error.toString()),
                          );
                        }
                        // data loaded successfully
                        String decodedMsg = snapshot.data!;
                        return Container(
                          padding: EdgeInsets.all(8),
                          height: 50,
                          width: double.infinity,
                          // arrange the messages according to the sender and receiver as left and rights
                          alignment: message.sender == currentUserEmail
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Text(decodedMsg),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    // send message to the opponent user
                    // this is the main function which will encrypt the message and send it to the opponent user
                    String message = _messageController.text.trim();

                    if (message.isNotEmpty) {
                      // ensure that the message is not empty
                      _messageController.clear();
                      _scrollController.animateTo(
                          _scrollController.position.minScrollExtent,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                      //* this is for the receiver user *//

                      // setting the opponent user's public key to encrypt the message
                      widget.rsaBrain
                          .setReceiverPublicKey(widget.opponentPublicKey);
                      // encrypt the message with the opponent user's public key using RSA
                      // text variable contains the encrypted message(cipher text)
                      var text =
                          widget.rsaBrain.encryptTheSetterMessage(message);
                      print("text rsa success, $text");
                      // the encrypted message is encoded in image using steganography
                      // img variable contains the image file where the cipher text is encoded
                      File img =
                          await widget.rsaBrain.encrypt(_imageFile, text!);
                      print("image rsa success");
                      // upload the image to firebase storage
                      String url = await uploadImage(img, widget.opponentEmail);

                      //* this is for the sender user *//
                      // setting the sender user's public key to encrypt the message which later will be used to decrypt the message to display as sent msg in chat
                      widget.rsaBrain.setReceiverPublicKey(
                          widget.rsaBrain.getOwnPublicKey().toString());
                      // encrypt the message with the sender user's public key using RSA
                      // text1 variable contains the encrypted message(cipher text)
                      var text1 =
                          widget.rsaBrain.encryptTheSetterMessage(message);

                      print("text1 rsa success");
                      // the encrypted message is encoded in image using steganography
                      File img1 =
                          await widget.rsaBrain.encrypt(_imageFile, text1!);
                      print("image1 rsa success");
                      // upload the image to firebase storage
                      String url1 = await uploadImage(img1, currentUserEmail);
                      // save the message details to firestore(we are only saving the cipher-text-encoded-image url and not the message)
                      FirebaseFirestore.instance.collection('messages').add({
                        'sender_message_url': url1,
                        "receiver_message_url": url,
                        'sender': currentUserEmail,
                        'receiver': widget.opponentEmail,
                        'createdAt': DateTime.now().toIso8601String(),
                        // generate chat id between two users which will be used to fetch the messages between the two users
                        'channel': generateChatId(
                            currentUserEmail, widget.opponentEmail),
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// this is the message model which will be used to save the message details to firestore
class Message {
  final String sender_message_url; // cipher-text-encoded-image url for sender
  final String
      receiver_message_url; // cipher-text-encoded-image url for receiver
  final String sender; // sender email
  final String receiver; // receiver email
  final String createdAt; // message sent time
  final String channel; // chat id between two users

  Message({
    required this.sender_message_url,
    required this.receiver_message_url,
    required this.sender,
    required this.receiver,
    required this.createdAt,
    required this.channel,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      sender_message_url: map['sender_message_url'],
      receiver_message_url: map['receiver_message_url'],
      sender: map['sender'],
      receiver: map['receiver'],
      createdAt: map['createdAt'],
      channel: map['channel'],
    );
  }
  static Message fromJson(Map<String, dynamic> json) {
    return Message(
      sender_message_url: json['sender_message_url'],
      receiver_message_url: json['receiver_message_url'],
      sender: json['sender'],
      receiver: json['receiver'],
      createdAt: json['createdAt'],
      channel: json['channel'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_message_url': sender_message_url,
      'receiver_message_url': receiver_message_url,
      'sender': sender,
      'receiver': receiver,
      'createdAt': createdAt,
      'channel': channel,
    };
  }
}
