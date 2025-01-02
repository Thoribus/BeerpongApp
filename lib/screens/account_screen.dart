import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:provider/provider.dart';
import 'achievements_screen.dart';
import 'personal_statistics_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  User? user;
  IconData? selectedIcon = Icons.person;
  Color? selectedColor = Colors.blue;
  String? selectedAvatar; // Holds the selected SVG asset path (null initially)
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      body: user == null
          ? Center(
              child: ElevatedButton(
                onPressed: () async {
                  userProvider.signIn();
                },
                child: const Text('Sign in with Google'),
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 20),
                _buildUserCard(),
                const SizedBox(height: 10),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      PersonalStatisticsScreen(user: user!),
                      AchievementsScreen(user: user!),
                      _buildActivityScreen(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserCard() {
    // Example of the current selected avatar, can be an icon or an SVG
    String? selectedAvatar =
        'assets/cat_avatar_profile.svg'; // Default to SVG for now

    return Card(
      color: Colors.transparent, // Transparent background
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            20), // More rounded corners for a credit card look
      ),
      elevation: 5.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image using slanted-gradient.svg
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/slanted-gradient.svg',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper part - Winner icons on the left
                  Row(
                    children: [
                      // Winner icons on the left (3 amber icons with circular background)
                      Row(
                        children: List.generate(3, (index) {
                          return Container(
                            margin: EdgeInsets.only(right: 8.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.star,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10), // Space to push content down
                  // Bottom part - User data on the left and CircleAvatar on the right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side - User text and username at the bottom-left
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'username',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.username ?? 'Username',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Right side - CircleAvatar with either icon or SVG background
                      GestureDetector(
                        onTap: _showIconPicker, // Trigger the icon picker
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Display an icon or SVG based on selectedAvatar
                            CircleAvatar(
                              radius: 50, // Increased size
                              backgroundColor: selectedColor,
                              child: selectedAvatar.isEmpty
                                  ? Icon(selectedIcon,
                                      size: 60, color: Colors.white)
                                  : SvgPicture.asset(
                                      selectedAvatar, // Use the SVG asset
                                      width: 60,
                                      height: 60,
                                    ),
                            ),
                            SvgPicture.asset(
                              'assets/avatar_border.svg',
                              width: 100,
                              height: 100,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.amber,
      labelColor: Colors.amber,
      unselectedLabelColor: Colors.white70,
      tabs: const [
        Tab(icon: Icon(Icons.pie_chart), text: "Stats"),
        Tab(icon: Icon(Icons.emoji_events), text: "Achievements"),
        Tab(icon: Icon(Icons.history), text: "Activity"),
      ],
    );
  }

  Widget _buildActivityScreen() {
    return Center(
      child: Text(
        'Activity Screen Placeholder',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  Widget _buildSignOutButton(UserProvider userProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: () async {
          userProvider.signOut();
          setState(() {}); // Refresh the UI after signing out
        },
        child: const Text(
          'Sign Out',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
                  'Select Icon and Avatar',
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
                  itemCount: _iconList.length +
                      _svgAssets.length, // Assuming you have a list of SVGs
                  itemBuilder: (BuildContext context, int index) {
                    if (index < _iconList.length) {
                      // Icon selection part
                      IconData icon = _iconList[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIcon = icon;
                            selectedAvatar = null; // Reset the selected SVG
                            final userProvider = Provider.of<UserProvider>(
                                context,
                                listen: false);
                            userProvider.updateUser(user!.copyWith(icon: icon));
                          });
                        },
                        child: CircleAvatar(
                          radius: 30, // Match the size of the avatar
                          backgroundColor:
                              selectedIcon == icon ? Colors.amber : Colors.grey,
                          child: Icon(icon, color: Colors.white),
                        ),
                      );
                    } else {
                      // SVG selection part
                      String svgAsset = _svgAssets[
                          index - _iconList.length]; // Adjust index for SVGs
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIcon = null; // Reset the selected icon
                            selectedAvatar = svgAsset; // Set the selected SVG
                            //final userProvider = Provider.of<UserProvider>(
                            //context,
                            //listen: false);
                            //userProvider
                            //.updateUser(user!.copyWith(avatar: svgAsset));
                          });
                        },
                        child: CircleAvatar(
                          radius: 30, // Same size for consistency
                          backgroundColor: Colors.transparent,
                          child: SvgPicture.asset(
                            svgAsset, // The selected SVG
                            width: 60,
                            height: 60,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _svgAssets = [
    'assets/cat_avatar_profile.svg'
    // Add more SVG asset paths here
  ];

  final List<IconData> _iconList = [
    BeerpongIcons.bunny_avatar,
    BeerpongIcons.cat_avatar,
    BeerpongIcons.dog_avatar,
    BeerpongIcons.racoon_avatar,
    BeerpongIcons.eagle_avatar,
    BeerpongIcons.frog_avatar,
  ];
}
