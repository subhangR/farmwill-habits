import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';

class UserDetailsInputPage extends StatelessWidget {
  final User user;
  final Function(FreeUser freeUser) onComplete;

  UserDetailsInputPage({super.key, required this.user, required this.onComplete});

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  Future<void> _saveUserInfo(User user) async {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final freeUser = FreeUser(
      uid: user.uid,
      email: user.email!,
      firstName: firstName,
      lastName: lastName,
    );
    GetIt.I.get<AuthService>().saveUser(freeUser);
    onComplete(freeUser);
  }


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Information'),
          backgroundColor: Colors.blueAccent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please enter your details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                ),
              ),
              const SizedBox(height: 20),

              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  final firstName = _firstNameController.text;
                  final lastName = _lastNameController.text;

                  if (firstName.isEmpty || lastName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all fields'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    await _saveUserInfo(user);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      );
    }
  }
