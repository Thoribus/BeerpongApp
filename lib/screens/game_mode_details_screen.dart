import 'package:beerpongapp/beerpong_icons_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GameModeDetailsScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String details;
  final String iconPath;
  final Color color;

  const GameModeDetailsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.iconPath,
    required this.color,
  });

  @override
  State<GameModeDetailsScreen> createState() => _GameModeDetailsScreenState();
}

class _GameModeDetailsScreenState extends State<GameModeDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final PageController _bottomPageController = PageController();
  int _bottomCurrentPage = 0;
  final Set<int> _selectedTiles = {};

  final List<String> infoPages = [
    'Fast-paced fun for everyone!',
    'Pick the rules you want to use!',
    'Invite your friends for a challenge!',
  ];

  final List<_InfoTileData> tiles = [
    _InfoTileData(BeerpongIcons.airball, 'Airballs'),
    _InfoTileData(Icons.roundabout_left, 'Bounce'),
    _InfoTileData(Icons.sports_basketball_outlined, 'Putback'),
    _InfoTileData(BeerpongIcons.palm_tree, 'Island'),
    _InfoTileData(BeerpongIcons.skull, 'Deathcup'),
    _InfoTileData(BeerpongIcons.umstellen, 'Rearrange'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.color,
      appBar: AppBar(
        backgroundColor: widget.color,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: infoPages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) => Column(
                      children: [
                        SvgPicture.asset(
                          widget.iconPath,
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          infoPages[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    infoPages.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180, // Adjust height as needed
                  child: PageView(
                    controller: _bottomPageController,
                    onPageChanged: (index) =>
                        setState(() => _bottomCurrentPage = index),
                    children: [
                      // Page 1: Rule tiles
                      Center(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: List.generate(
                            tiles.length,
                            (index) => _buildSelectableTile(index),
                          ),
                        ),
                      ),

                      // Page 2: Lobby mock-up
                      _buildLobbySection(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    2,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _bottomCurrentPage == index
                            ? Colors.white
                            : Colors.white30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additional Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Games are short and sweet. Perfect for quick breaks or warmups. Coming with a scoreboard and auto-ranking.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Start Game',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLobbySection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Lobby',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTeamBox('Team 1'),
            const SizedBox(width: 16),
            _buildTeamBox('Team 2'),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamBox(String title) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableTile(int index) {
    final isSelected = _selectedTiles.contains(index);
    final tile = tiles[index];

    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedTiles.remove(index);
        } else {
          _selectedTiles.add(index);
        }
      }),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[100] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tile.icon,
              color: isSelected ? Colors.amber[800] : Colors.grey,
            ),
            const SizedBox(height: 6),
            Text(
              tile.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.amber[800] : Colors.black87,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTileData {
  final IconData icon;
  final String text;

  _InfoTileData(this.icon, this.text);
}
