import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _username;
  String? _existingUsername;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _existingUsername = prefs.getString('username');
    });
  }

  void _createAccount() async {
    final prefs = await SharedPreferences.getInstance();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Here you would typically send the data to your backend or save it locally
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created for $_username')),
      );
      await prefs.setString("username", _username!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: _existingUsername == null
              ? <Widget>[
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Username'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _username = value;
                          },
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _createAccount,
                          child: Text('Create Account'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ]
              : <Widget>[
                  Text('Welcome, $_existingUsername!'),
                  SizedBox(height: 20),
                  Text(
                    'Your Stats',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  // Here you would typically fetch and display the user's stats
                  // For now, just showing a placeholder
                  Text('Games Played: 10'),
                  Text('Games Won: 5'),
                  Text('Total Points: 50'),
                ],
        ),
      ),
    );
  }
}
