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
  RSABrain() {
    _myRsaKeypair = RSAKeypair.fromRandom();
  }

  late RSAKeypair _myRsaKeypair;
  RSAPublicKey? _receiverRsaPublicKey;
  String _message = '';
  void setReceiverPublicKey(String pubKey) {
    try {
      _receiverRsaPublicKey = RSAPublicKey.fromString(pubKey);
    } catch (error) {
      _receiverRsaPublicKey = null;
    }
  }

  String getOwnPublicKey() {
    return _myRsaKeypair.publicKey.toString();
  }

  String getOwnPrivateKey() {
    return _myRsaKeypair.privateKey.toString();
  }

  String? encryptTheSetterMessage(String message) {
    try {
      var encrypted_msg =
          _receiverRsaPublicKey!.encrypt(message); //null check: !
      return encrypted_msg;
    } catch (error) {
      return null;
    }
  }

  String? decryptTheGetterMessage(String message) {
    try {
      var decrypted_msg = _myRsaKeypair.privateKey.decrypt(message);
      return decrypted_msg;
    } catch (error) {
      return null;
    }
  }

  Future encrypt(File _imageFile, String text) async {
    try {
      if (_imageFile == null) return;
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

  Future<File?> getImageFileFromUrl(String url) async {
    try {
      var response = await http.get(Uri.parse(url));
      final documentDirectory = await getTemporaryDirectory();
      final file = File(
          '${documentDirectory.path}/storage_image_${DateTime.now().toIso8601String()}.png');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<String> decrypt(String url) async {
    try {
      print("url: ${url}");
      File? _imageFile = await getImageFileFromUrl(url);
      if (_imageFile == null) return "image error";
      final Directory directory = await getTemporaryDirectory();
      final File file = File(
          '${directory.path}/receiver_dec_txt_${DateTime.now().toIso8601String()}.txt');
      var text;
      await Stegify.decode(_imageFile.path, file.path);
      text = await file.readAsString();
      print(text);
      var finalText = decryptTheGetterMessage(text);

      print("decoded text: ${finalText}");
      return finalText ?? "decode error";
    } catch (e) {
      print("error: ${e}");
      return "decode error";
    }
  }
}
