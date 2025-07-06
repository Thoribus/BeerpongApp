import 'package:beerpongapp/models/tournament.dart';
import 'package:flutter/material.dart';
import 'tournament_overview_screen.dart';
import 'tournament_standings.dart';

class TournamentPageView extends StatefulWidget {
  final String tournamentId;
  final Tournament initialTournament;

  const TournamentPageView({
    super.key,
    required this.tournamentId,
    required this.initialTournament,
  });

  @override
  State<TournamentPageView> createState() => _TournamentPageViewState();
}

class _TournamentPageViewState extends State<TournamentPageView> {
  late PageController _pageController;
  late Tournament _tournament;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tournament = widget.initialTournament;
  }

  // Optionally, you can expose this to children to reload tournament data
  void updateTournament(Tournament newTournament) {
    setState(() {
      _tournament = newTournament;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament.name),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: 'Standings',
            onPressed: () => _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Overview',
            onPressed: () => _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: [
          TournamentOverviewScreen(
            tournamentId: widget.tournamentId,
            tournament: _tournament,
            onTournamentUpdated: updateTournament,
          ),
          TournamentStandingsScreen(
            tournament: _tournament,
          ),
        ],
      ),
    );
  }
}
