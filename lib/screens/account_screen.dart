import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/firestoreservice.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  User? user;
  IconData? selectedIcon = Icons.person;
  Color? selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirestoreService().getUser(currentUser.uid).then((value) {
        setState(() {
          user = value;
          selectedIcon = user?.icon ?? Icons.person;
          selectedColor = user?.iconColor ?? Colors.blue;
        });
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (user != null) FirestoreService().updateUser(user!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: StreamBuilder(
          stream: auth.FirebaseAuth.instance.authStateChanges(),
          builder: (BuildContext context, AsyncSnapshot<auth.User?> snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _showIconPicker,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: selectedColor,
                            child: Icon(
                              selectedIcon,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            snapshot.data?.displayName ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (user != null)
                      Expanded(
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 16,
                            headingRowHeight: 40,
                            dataRowMinHeight: 32,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Attribute',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Value',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            rows: [
                              _buildDataRow('User ID', user!.id),
                              _buildDataRow(
                                  'Total Score', '${user!.totalScore}'),
                              _buildDataRow(
                                  'Total Misses', '${user!.totalMisses}'),
                              _buildDataRow('Total Airballs',
                                  '${user!.totalAirballs}'),
                              _buildDataRow(
                                  'Cups Hit', '${user!.cupsHit}'),
                              _buildDataRow('Wins', '${user!.wins}'),
                              _buildDataRow('Losses', '${user!.losses}'),
                            ],
                          ),
                        ),
                      )
                    else
                      const Expanded(
                        child: Center(
                          child: Text(
                            'User data not available',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await GoogleSignIn().signOut();
                        auth.FirebaseAuth.instance.signOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Sign out',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                );
              } else {
                return ElevatedButton(
                  onPressed: () async {
                    auth.User? authUser =
                        await FirestoreService().signInWithGoogle();
                    final User user = User(
                      id: authUser!.uid,
                      username: authUser.displayName!,
                    );
                    if (await FirestoreService().getUser(user.id) == null) {
                      FirestoreService().addUser(user);
                    }
                  },
                  child: const Text('Sign in with Google'),
                );
              }
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }

  DataRow _buildDataRow(String attribute, String value) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            attribute,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        DataCell(
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Icon and Color',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _iconList.length,
                  itemBuilder: (BuildContext context, int index) {
                    IconData icon = _iconList[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIcon = icon;
                          user!.icon = icon;
                        });
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            selectedIcon == icon ? Colors.amber : Colors.grey,
                        child: Icon(icon, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Background Color',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _colorList.length,
                  itemBuilder: (BuildContext context, int index) {
                    Color color = _colorList[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                          user!.iconColor = color;
                        });
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            selectedColor == color ? Colors.amber : color,
                        child: selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  final List<IconData> _iconList = [
    Icons.person,
    Icons.favorite,
    Icons.star,
    Icons.directions_bike,
    Icons.ac_unit,
    Icons.airplanemode_active,
    Icons.access_alarm,
    Icons.book,
    Icons.brush,
    Icons.cake,
  ];

  final List<Color> _colorList = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.cyan,
  ];
}
