import 'package:beerpongapp/models/tournament.dart';
import 'package:beerpongapp/util/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'tournament_overview_screen.dart';
import 'tournament_standings.dart';
import 'tournament_analysis_screen.dart';
import '../../widgets/app_tab_bar.dart';

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
  final List<String> _tabs = ['Overview', 'Standings', 'Analysis'];

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
    return AppTabBar(
      tabs: _tabs,
      selectedIndex: _currentTabPage,
      onTabSelected: (index) {
        setState(() => _currentTabPage = index);
      },
      pageController: _pageController,
      backgroundColor: Colors.grey.shade700,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.labelTournament,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
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
