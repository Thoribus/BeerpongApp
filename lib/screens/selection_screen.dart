import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:beerpongapp/screens/game_screen.dart';
import 'package:beerpongapp/widgets/new_game_dialog.dart';
import '../models/player.dart';

class SelectionScreen extends StatefulWidget {
  final VoidCallback onReturn;

  const SelectionScreen({super.key, required this.onReturn});

  @override
  SelectionScreenState createState() => SelectionScreenState();
}

class SelectionScreenState extends State<SelectionScreen> {
  List<Player> players1 = [];
  List<Player> players2 = [];
  int _numPlayers = 2; // Default number of players
  String selectedGameMode = 'Single Game';
  List<String> gameModes = ['Single Game', 'Tournament'];
  Map<String, bool> selectedRulesMap = {
    'Deathcup': false,
    'Island': false,
    'Nachwurf': false,
  };

  String startingTeam = 'Team Blue'; // Add this line
  String selectedSection = 'All'; // Default to 'All' when the screen is built

  bool get canStartGame {
    return players1.isNotEmpty &&
        players2.isNotEmpty &&
        players1.every((p) => p.name.isNotEmpty) &&
        players2.every((p) => p.name.isNotEmpty);
  }

  void _onPopInvoked(bool didPop) {
    // Call the callback function before popping the screen
    widget.onReturn();
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.amber,
          title: Text(
            'Select $title',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold, // Make the title text bold
            ),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Back'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Game Setup',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFFF0AE1D),
        ),
        body: Container(
          color: Colors.black,
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Customize your Game',
                    hintStyle: TextStyle(color: Colors.white, fontSize: 24),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const Text(
                  'Learn about different game modes, rules, and more!',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('All'),
                      _buildFilterButton('Players'),
                      _buildFilterButton('Game Mode'),
                      _buildFilterButton('Special Rules'),
                      _buildFilterButton('Starting Team'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (selectedSection == 'All' || selectedSection == 'Players')
                  _buildBracketSection(
                    title: 'Players',
                    imagePath: 'assets/two_cats.svg',
                    content: _buildPlayersSelection(),
                    infoMessage: 'Select the players for your game.\n\nAdd at least one player per team. You can add friends or custom players to each team.\n\nStatistics will only be saved when accounts are selected!',
                  ),
                if (selectedSection == 'All' || selectedSection == 'Game Mode')
                  _buildBracketSection(
                    title: 'Game Mode',
                    imagePath: 'assets/racoon_winner.svg',
                    content: _buildGameModeSelection(),
                    infoMessage: 'Choose the game mode you want to play.\n\nA single game creates a match between two players/teams.\n\nA tournament creates a  several matcheas between multiple players/teams.',
                  ),
                if (selectedSection == 'All' ||
                    selectedSection == 'Special Rules')
                  _buildBracketSection(
                    title: 'Special Rules',
                    imagePath: 'assets/frog_island.svg',
                    content: _buildSpecialRulesSelection(),
                    infoMessage: 'Select any special rules for your game.\n\nDEATHCUP.\nWhen a cup is hit and not cleared from the field or a cup that someone holding is hit, it is declared as a deathcup.\nThe team that hits the deathcup automatically wins!\n\nISLAND.\nA player can declare an island-shot (once per game) when a single cup has no surrounding cups.\nWhen an ISLAND is hit, an additional cup is cleared from the field!\n',
                  ),
                if (selectedSection == 'All' ||
                    selectedSection == 'Starting Team')
                  _buildBracketSection(
                    title: 'Starting Team',
                    imagePath: 'assets/cat_boxing.svg',
                    content: _buildStartingTeamSelection(),
                    infoMessage: 'Choose which team starts the game.',
                  ),
                const SizedBox(height: 20),
                _buildStartGameButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String section) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedSection = section;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color:
                  selectedSection == section ? const Color(0xFFF0AE1D) : Colors.grey,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            section,
            style: TextStyle(
              color:
                  selectedSection == section ? const Color(0xFFF0AE1D) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBracketSection({
    required String title,
    required String imagePath,
    required Widget content,
    required String infoMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF0AE1D),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _showInfoDialog(title, infoMessage);
              },
              child: Container(
                width: 15,
                height: 15,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF0AE1D),
                ),
                child: const Icon(
                  Icons.info,
                  color: Colors.black,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    imagePath,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: content),
                ],
              ),
              const SizedBox(height: 20),
              if (title == 'Players')
                _buildTeamsSection(), // Add this line to conditionally display the team columns under the "Players" section.
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPlayersSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Players:',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Slider(
                value: _numPlayers.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                activeColor: const Color(0xFFF0AE1D),
                label: '$_numPlayers',
                onChanged: (double value) {
                  setState(() {
                    _numPlayers = value.toInt();
                  });
                },
              ),
            ),
            Text(
              '$_numPlayers',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (players1.isEmpty && players2.isEmpty)
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.75),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              onPressed: () async {
                await _showTeamDialog(team: 1);
                await _showTeamDialog(team: 2);
              },
              icon: const Icon(Icons.add, size: 24, color: Colors.black),
              label: const Text('Add Players',
                  style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
          )
        else
          Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await _showTeamDialog(team: 1);
                    await _showTeamDialog(team: 2);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: const Text('Edit Players',
                      style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTeamsSection() {
    return Column(
      children: [
        if (players1.isNotEmpty || players2.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildTeamColumn(players1, 'Team Blue:'),
              ),
              const SizedBox(width: 10), // Small space between the columns
              Expanded(
                child: _buildTeamColumn(players2, 'Team Red:'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTeamColumn(List<Player> players, String teamName) {
    return Container(
      decoration: BoxDecoration(
        color: teamName.contains('Blue')
            ? Colors.blue.withOpacity(0.7)
            : Colors.red.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow:
                TextOverflow.ellipsis, // Ensures the text doesn't overflow
          ),
          const SizedBox(height: 8),
          ...players.map((player) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        player.name,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.white),
                        overflow: TextOverflow
                            .ellipsis, // Ensures the text doesn't overflow
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _showTeamDialog({required int team}) async {
    List<String> initialNames = [];
    if (team == 1) {
      initialNames = players1.map((player) => player.name).toList();
    } else if (team == 2) {
      initialNames = players2.map((player) => player.name).toList();
    }

    final teamResult = await showDialog<List<Player>>(
      context: context,
      builder: (context) => NewGameDialog(
          team: team, initialNames: initialNames, numPlayers: _numPlayers),
    );

    if (teamResult != null) {
      setState(() {
        if (team == 1) {
          players1 = teamResult;
        } else if (team == 2) {
          players2 = teamResult;
        }
      });
    }
  }

  Widget _buildGameModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Game Mode',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(8.0),
            selectedColor: Colors.black,
            fillColor: const Color(0xFFF0AE1D),
            onPressed: (int newIndex) {
              setState(() {
                selectedGameMode = gameModes[newIndex];
              });
            },
            isSelected:
                gameModes.map((mode) => mode == selectedGameMode).toList(),
            children:
                gameModes.map((mode) => _buildToggleButton(mode)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String mode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(mode, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildSpecialRulesSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Special Rules',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          itemCount: selectedRulesMap.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                selectedRulesMap.keys.elementAt(index),
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              trailing: Switch(
                value: selectedRulesMap.values.elementAt(index),
                onChanged: (bool value) {
                  setState(() {
                    selectedRulesMap[selectedRulesMap.keys.elementAt(index)] =
                        value;
                  });
                },
                activeColor: const Color(0xFFF0AE1D),
                inactiveThumbColor: Colors.black,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStartingTeamSelection() {
    List<String> teams = ['Team Blue', 'Team Red'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Starting Team',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(8.0),
            selectedColor: Colors.black,
            fillColor: startingTeam == 'Team Blue' ? Colors.blue : Colors.red,
            onPressed: (int newIndex) {
              setState(() {
                startingTeam = teams[newIndex];
              });
            },
            isSelected: teams.map((team) => team == startingTeam).toList(),
            children: teams.map((team) => _buildToggleButton(team)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStartGameButton() {
    return Center(
      child: ElevatedButton(
        onPressed: canStartGame
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      title: 'Beer Pong',
                      players1: players1,
                      players2: players2,
                      selectedRules: selectedRulesMap,
                      startingTeam: startingTeam == "Team Blue"
                          ? true
                          : false, // Pass starting team
                    ),
                  ),
                );
              }
            : () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: canStartGame ? const Color(0xFFF0AE1D) : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: const Text('Start Game',
            style: TextStyle(fontSize: 18, color: Colors.black)),
      ),
    );
  }
}
