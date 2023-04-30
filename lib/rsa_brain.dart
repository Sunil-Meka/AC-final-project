import 'dart:io';
import 'package:flutter_stegify/flutter_stegify.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypton/crypton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:http/http.dart' as http;

class RSABrain {
  // this is the RSA brain which will handle all the RSA and Steganography related operations

  RSABrain() {
    // initialize the RSA key pair
    _myRsaKeypair = RSAKeypair.fromRandom();
  }

  late RSAKeypair _myRsaKeypair; // variable to store the user's key pair
  RSAPublicKey? _receiverRsaPublicKey; // variable to store the receiver's key

  // function to set the receiver's public key
  void setReceiverPublicKey(String pubKey) {
    try {
      _receiverRsaPublicKey = RSAPublicKey.fromString(pubKey);
    } catch (error) {
      _receiverRsaPublicKey = null;
    }
  }

// function to get the user's public key
  String getOwnPublicKey() {
    return _myRsaKeypair.publicKey.toString();
  }

// function to get the user's private key
  String getOwnPrivateKey() {
    return _myRsaKeypair.privateKey.toString();
  }

// function to encrypt the message using RSA
  String? encryptTheSetterMessage(String message) {
    try {
      var encrypted_msg =
          _receiverRsaPublicKey!.encrypt(message); //null check: !
      return encrypted_msg;
    } catch (error) {
      return null;
    }
  }

// function to decrypt the message using RSA
  String? decryptTheGetterMessage(String message) {
    try {
      var decrypted_msg = _myRsaKeypair.privateKey.decrypt(message);
      return decrypted_msg;
    } catch (error) {
      return null;
    }
  }

// this encrypts the message using RSA and then encodes the ciphertext in the image and returns the image file
  Future encrypt(File _imageFile, String text) async {
    try {
      if (_imageFile == null) return;
      // creating a new file in temporary directory with the name sender_enc_txt_${DateTime.now().toIso8601String()}.txt
      final Directory directory = await getTemporaryDirectory();
      final File file = File(
          '${directory.path}/sender_enc_txt_${DateTime.now().toIso8601String()}.txt');
      await file.writeAsString(text);
      var encryptedText;
      var path = directory.path +
          "/sender_enc_img_${DateTime.now().toIso8601String()}";
      await Stegify.encode(_imageFile.path, file.path, path);
      print("encrypt done");
      return File('${path}.png');
    } catch (e) {
      print("error: ${e}");
    }
  }

// function to get the image file from the url and returns the image file
  Future<File?> getImageFileFromUrl(String url) async {
    try {
      var response = await http.get(Uri.parse(url));
      final documentDirectory = await getTemporaryDirectory();
      // creating a new file in temporary directory with the name storage_image_${DateTime.now().toIso8601String()}.png
      final file = File(
          '${documentDirectory.path}/storage_image_${DateTime.now().toIso8601String()}.png');
      // writing the image file
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      print(e);
      return null;
    }
  }

// this decodes the ciphertext from image and then decrypts the message using RSA and returns the message
  Future<String> decrypt(String url) async {
    try {
      print("url: ${url}");
      File? _imageFile = await getImageFileFromUrl(url);
      if (_imageFile == null) return "image error";
      final Directory directory = await getTemporaryDirectory();
      // creating a new file in temporary directory with the name receiver_dec_txt_${DateTime.now().toIso8601String()}.txt
      final File file = File(
          '${directory.path}/receiver_dec_txt_${DateTime.now().toIso8601String()}.txt');
      var text;
      // decoding the ciphertext from image and writing it to the file
      await Stegify.decode(_imageFile.path, file.path);
      text = await file.readAsString();
      // text varaible contains the ciphertext
      print(text);
      // decrypting the ciphertext using RSA
      var finalText = decryptTheGetterMessage(text);
      print("decoded text: ${finalText}");
      return finalText ?? "decode error";
    } catch (e) {
      print("error: ${e}");
      return "decode error";
    }
  }
}
