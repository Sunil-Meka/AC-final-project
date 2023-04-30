import 'package:final_project/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'rsa_brain.dart';

class RegisterScreen extends StatefulWidget {
  // this is the register screen which will show the register form
  final RSABrain rsaBrain;
  RegisterScreen(this.rsaBrain);
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _email = ''; // variables to store email
  String _password = ''; // variables to store password
  String _displayName = ''; // variables to store display name
  bool _isLoading = false; // initial value of loading is false

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final newUser = await _auth.createUserWithEmailAndPassword(
          email: _email.trim(),
          password: _password,
        );
        if (newUser != null) {
          // Create a new user record in Firestore
          final userRef = _firestore.collection('users').doc(newUser.user!.uid);
          // creating a new user record in firestore with public key(getting from RSA brain which is already initilized at the application start), email, createdAt and display name
          userRef.set({
            'email': _email,
            'displayName': _displayName,
            'createdAt': FieldValue.serverTimestamp(),
            "publickey": widget.rsaBrain.getOwnPublicKey().toString()
          });
          // navigate to dashboard as user is logged in
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(widget.rsaBrain),
            ),
          );
        }
      } catch (e) {
        // show error message if registration fails
        setState(() {
          _isLoading = false;
        });
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Register'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                    key: _formKey,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // form to get email, password and display name
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(labelText: 'Email'),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Invalid email format';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _email = value.trim();
                              });
                            },
                          ),
                          SizedBox(height: 16.0),
                          TextFormField(
                            obscureText: true,
                            decoration: InputDecoration(labelText: 'Password'),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _password = value;
                              });
                            },
                          ),
                          SizedBox(height: 16.0),
                          TextFormField(
                            decoration:
                                InputDecoration(labelText: 'Display Name'),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Display Name is required';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _displayName = value;
                              });
                            },
                          ),
                          SizedBox(height: 32.0),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _register,
                              child: Text('Register'),
                            ),
                          ),
                        ]))));
  }
}
