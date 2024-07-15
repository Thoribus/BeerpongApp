import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:provider/provider.dart';

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
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    user = userProvider.user;

    if (user != null) {
      selectedIcon = user!.icon;
      selectedColor = user!.iconColor;
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: user == null
            ? ElevatedButton(
                onPressed: () async {
                  userProvider.signIn();
                },
                child: const Text('Sign in with Google'),
              )
            : Column(
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
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user!.username,
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
                          _buildDataRow('Total Score', '${user!.totalScore}'),
                          _buildDataRow('Total Misses', '${user!.totalMisses}'),
                          _buildDataRow(
                              'Total Airballs', '${user!.totalAirballs}'),
                          _buildDataRow('Cups Hit', '${user!.cupsHit}'),
                          _buildDataRow('Wins', '${user!.wins}'),
                          _buildDataRow('Losses', '${user!.losses}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      userProvider.signOut();
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
                          final userProvider =
                              Provider.of<UserProvider>(context, listen: false);
                          userProvider.updateUser(user!.copyWith(icon: icon));
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
                          final userProvider =
                              Provider.of<UserProvider>(context, listen: false);
                          userProvider
                              .updateUser(user!.copyWith(iconColor: color));
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
    BeerpongIcons.bunny_avatar,
    BeerpongIcons.cat_avatar,
    BeerpongIcons.dog_avatar,
    BeerpongIcons.racoon_avatar,
    BeerpongIcons.eagle_avatar,
    BeerpongIcons.frog_avatar,
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
