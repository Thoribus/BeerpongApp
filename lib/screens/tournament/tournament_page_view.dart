import 'package:beerpongapp/models/tournament.dart';
import 'package:flutter/material.dart';
import 'tournament_overview_screen.dart';
import 'tournament_standings.dart';

// Placeholder for the new Analysis screen (replace with your real one)
class TournamentAnalysisScreen extends StatelessWidget {
  final Tournament tournament;

  const TournamentAnalysisScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Analysis Screen for ${tournament.name}',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

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
  int _currentTabPage = 0;

  // Added "Analysis" tab
  final List<String> _tabs = ["Overview", "Standings", "Analysis"];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tournament = widget.initialTournament;
  }

  void updateTournament(Tournament newTournament) {
    setState(() {
      _tournament = newTournament;
    });
  }

  Widget _buildTabPageSelector() {
    return Container(
      height: 48,
      width: double.infinity,
      color: Colors.grey.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = _currentTabPage == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() => _currentTabPage = index);
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.orange : Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tournament.name),
        backgroundColor: Colors.grey.shade700,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabPageSelector(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentTabPage = index;
          });
        },
        children: [
          TournamentOverviewScreen(
            tournamentId: widget.tournamentId,
            tournament: _tournament,
            onTournamentUpdated: updateTournament,
          ),
          TournamentStandingsScreen(
            tournament: _tournament,
          ),
          TournamentAnalysisScreen(
            tournament: _tournament,
          ),
        ],
      ),
    );
  }
}
