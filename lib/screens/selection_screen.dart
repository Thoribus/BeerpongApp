import 'package:flutter/material.dart';
import 'package:beerpongapp/screens/game_screen.dart';
import 'package:beerpongapp/widgets/new_game_dialog.dart';
import '../models/player.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  _SelectionScreenState createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  List<Player> players1 = [];
  List<Player> players2 = [];
  String selectedGameMode = 'Single Game';
  List<String> gameModes = ['Single Game', 'Tournament'];
  Map<String, bool> selectedRulesMap = {
    'Deathcup': false,
    'Island': false,
    'Rearrange': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Game Setup',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber.withOpacity(0.75),
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlayersSelection(),
              const SizedBox(height: 20),
              _buildGameModeSelection(),
              const SizedBox(height: 20),
              _buildSpecialRulesSelection(),
              const SizedBox(height: 20),
              _buildStartGameButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Players',
          style: TextStyle(
            fontSize: 18,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 1),
        const Divider(
          color: Colors.amber,
          thickness: 1,
        ),
        const SizedBox(height: 10),
        (players1.isEmpty && players2.isEmpty)
            ? Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
            : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTeamColumn(players1, 'Team Blue:'),
                      _buildTeamColumn(players2, 'Team Red:'),
                    ],
                  ),
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
                        padding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      ),
                      child: const Text('Edit Players',
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 20),
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
          Text(teamName,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          ...players.map((player) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(player.name, style: const TextStyle(color: Colors.white)),
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
      builder: (context) =>
          NewGameDialog(team: team, initialNames: initialNames),
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        const Divider(
          color: Colors.amber,
          thickness: 1,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(8.0),
            selectedColor: Colors.black,
            fillColor: Colors.amber,
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
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        const Divider(
          color: Colors.amber,
          thickness: 1,
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
                activeColor: Colors.amber,
                inactiveThumbColor: Colors.black,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStartGameButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GameScreen(
                title: 'Beer Pong',
                players1: players1,
                players2: players2,
                selectedRules: selectedRulesMap,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
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
