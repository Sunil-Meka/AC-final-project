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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  var _imageFile;

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
    _copyImageFromAsset("default.png");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String currentUserEmail =
        FirebaseAuth.instance.currentUser!.email as String;
    String generateChatId(String sender, String receiver) {
      if (sender.compareTo(receiver) < 0) {
        return '$sender-$receiver';
      } else {
        return '$receiver-$sender';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.opponentEmail),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              key: ValueKey(widget.opponentEmail),
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
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  return Text("No Messages Found");
                }
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final data = snapshot.data!.docs[index].data();
                    Message message =
                        Message.fromJson(data as Map<String, dynamic>);

                    return FutureBuilder<String>(
                      future: message.sender == currentUserEmail
                          ? widget.rsaBrain.decrypt(message.sender_message_url)
                          : widget.rsaBrain
                              .decrypt(message.receiver_message_url),
                      // future: _myRsaBrain.decrypt(message.receiver_message_url),
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                        String decodedMsg = snapshot.data!;
                        return Container(
                          padding: EdgeInsets.all(8),
                          height: 50,
                          width: double.infinity,
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

          // Expanded(
          //   child: StreamBuilder<QuerySnapshot>(
          //     key: ValueKey(widget.opponentEmail),
          //     stream: FirebaseFirestore.instance
          //         .collection('messages')
          //         .where('channel',
          //             isEqualTo: generateChatId(
          //                 currentUserEmail, widget.opponentEmail))
          //         .orderBy('createdAt', descending: false)
          //         .snapshots(),
          //     builder: (BuildContext context,
          //         AsyncSnapshot<QuerySnapshot> snapshot) {
          //       if (snapshot.connectionState == ConnectionState.waiting) {
          //         return Center(child: CircularProgressIndicator());
          //       }
          //       if (snapshot.hasError) {
          //         return Center(child: Text(snapshot.error.toString()));
          //       }
          //       if (!snapshot.hasData) {
          //         return Text("No Messages Found");
          //       }
          //       return ListView(
          //         reverse: true,
          //         controller: _scrollController,
          //         children: snapshot.data!.docs.map((document) async {
          //           final data = document.data();
          //           Message message =
          //               Message.fromJson(data as Map<String, dynamic>);
          //           print(message.message);
          //           var imageUrl = message.message;
          //           var decodedMsg = await _myRsaBrain.decrypt(imageUrl);

          //           return Container(
          //             padding: EdgeInsets.all(8),
          //             height: 50,
          //             width: double.infinity,
          //             alignment: message.sender == currentUserEmail
          //                 ? Alignment.centerRight
          //                 : Alignment.centerLeft,
          //             child: Text(message.message),
          //           );
          //         }).toList(),
          //       );
          //     },
          //   ),
          // ),
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
                    String message = _messageController.text.trim();

                    if (message.isNotEmpty) {
                      _messageController.clear();
                      _scrollController.animateTo(
                          _scrollController.position.minScrollExtent,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                      widget.rsaBrain
                          .setReceiverPublicKey(widget.opponentPublicKey);
                      var text =
                          widget.rsaBrain.encryptTheSetterMessage(message);
                      print("text rsa success, $text");
                      File img =
                          await widget.rsaBrain.encrypt(_imageFile, text!);
                      print("image rsa success");
                      String url = await uploadImage(img, widget.opponentEmail);

                      widget.rsaBrain.setReceiverPublicKey(
                          widget.rsaBrain.getOwnPublicKey().toString());
                      var text1 =
                          widget.rsaBrain.encryptTheSetterMessage(message);
                      print("text1 rsa success");
                      File img1 =
                          await widget.rsaBrain.encrypt(_imageFile, text1!);
                      print("image1 rsa success");
                      String url1 = await uploadImage(img1, currentUserEmail);

                      FirebaseFirestore.instance.collection('messages').add({
                        'sender_message_url': url1,
                        "receiver_message_url": url,
                        'sender': currentUserEmail,
                        'receiver': widget.opponentEmail,
                        'createdAt': DateTime.now().toIso8601String(),
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

class Message {
  final String sender_message_url;
  final String receiver_message_url;
  final String sender;
  final String receiver;
  final String createdAt;
  final String channel;

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
