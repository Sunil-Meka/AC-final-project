import 'package:final_project/register.dart';
import 'package:final_project/rsa_brain.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  final RSABrain rsaBrain;
  LoginScreen(this.rsaBrain);
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _email, _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  validator: (input) {
                    if (input == null || input.isEmpty) {
                      return 'Please enter an email';
                    }
                    return null;
                  },
                  onSaved: (input) => _email = input!,
                  decoration: InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                TextFormField(
                  obscureText: true,
                  validator: (input) {
                    if (input == null || input.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                  onSaved: (input) => _password = input!,
                  decoration: InputDecoration(
                    labelText: 'Password',
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      try {
                        UserCredential userCredential = await FirebaseAuth
                            .instance
                            .signInWithEmailAndPassword(
                          email: _email,
                          password: _password,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(widget.rsaBrain),
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'user-not-found') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('User not found')),
                          );
                        } else if (e.code == 'wrong-password') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Wrong password')),
                          );
                        }
                      }
                    }
                  },
                  child: Text('LOGIN'),
                ),
                SizedBox(height: 16),
                Text('Don\'t have an account?'),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterScreen(widget.rsaBrain),
                      ),
                    );
                  },
                  child: Text('REGISTER'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
