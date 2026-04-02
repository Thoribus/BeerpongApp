// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Beerpong Companion';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnSave => 'Save';

  @override
  String get btnSaving => 'Saving…';

  @override
  String get btnAdd => 'Add';

  @override
  String get btnClose => 'Close';

  @override
  String get btnOk => 'OK';

  @override
  String get btnSignInGoogle => 'Sign in with Google';

  @override
  String get labelTeamBlue => 'Team Blue';

  @override
  String get labelTeamRed => 'Team Red';

  @override
  String get labelVs => 'VS';

  @override
  String get labelRules => 'Rules';

  @override
  String get labelPlayers => 'Players';

  @override
  String get labelTeams => 'Teams';

  @override
  String get labelTournament => 'Tournament';

  @override
  String labelLevelShort(int level) {
    return 'Lv $level';
  }

  @override
  String get loginTagline => 'Track your game. Rule the table.';

  @override
  String get loginToggleSignIn => 'Sign In';

  @override
  String get loginToggleRegister => 'Register';

  @override
  String get loginFieldUsername => 'Username';

  @override
  String get loginFieldEmail => 'Email';

  @override
  String get loginFieldPassword => 'Password';

  @override
  String get loginValidateUsername => 'Enter a username';

  @override
  String get loginValidateEmail => 'Enter a valid email';

  @override
  String get loginValidatePassword => 'Minimum 6 characters';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginBtnSignIn => 'Sign In';

  @override
  String get loginBtnCreateAccount => 'Create Account';

  @override
  String get loginOrContinueWith => 'or continue with';

  @override
  String get loginContinueGoogle => 'Continue with Google';

  @override
  String get loginContinueApple => 'Continue with Apple';

  @override
  String get loginErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get loginErrorGoogle => 'Google sign-in failed. Please try again.';

  @override
  String get loginErrorApple => 'Apple sign-in failed. Please try again.';

  @override
  String get loginErrorEmailFirst => 'Enter your email address first.';

  @override
  String get loginResetEmailSent => 'Password reset email sent!';

  @override
  String get loginErrorResetFailed =>
      'Could not send reset email. Check the address.';

  @override
  String get loginErrUserNotFound => 'No account found with this email.';

  @override
  String get loginErrWrongPassword => 'Incorrect email or password.';

  @override
  String get loginErrEmailInUse => 'An account with this email already exists.';

  @override
  String get loginErrWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get loginErrInvalidEmail => 'Please enter a valid email address.';

  @override
  String get loginErrTooManyRequests =>
      'Too many attempts. Please try again later.';

  @override
  String get loginErrAuthFailed => 'Authentication failed. Please try again.';

  @override
  String get homeLetsPlay => 'Let\'s play!';

  @override
  String get homeBeerPong => 'Beer Pong';

  @override
  String get homeBtnNewGame => 'New Game';

  @override
  String get homeResumeTitle => 'Resume Game';

  @override
  String get homeResumeSubtitle => 'Continue your last game';

  @override
  String homePendingInvitations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count pending invitations',
      one: 'You have 1 pending invitation',
    );
    return '$_temp0';
  }

  @override
  String get homeRulebookTitle => 'Rulebook';

  @override
  String get homeRulebookSubtitle => 'Learn how every special rule works';

  @override
  String get homeNewGameDialogTitle => 'New Game';

  @override
  String get homeNewGameDialogContent =>
      'Starting a new game will delete the current game. Do you want to continue?';

  @override
  String get homeNewGameDialogConfirm => 'Start New Game';

  @override
  String get homeGameModeTitle => 'Play Beerpong';

  @override
  String get homeGameModeSubtitle => 'Quick, fun rounds';

  @override
  String get homeTournamentTitle => 'Tournament';

  @override
  String get homeTournamentSubtitle => 'Bracket-style play';

  @override
  String get gameModeRuleAirballs => 'Airballs';

  @override
  String get gameModeRuleBounce => 'Bounce';

  @override
  String get gameModeRulePutback => 'Putback';

  @override
  String get gameModeRuleIsland => 'Island';

  @override
  String get gameModeRuleDeathcup => 'Deathcup';

  @override
  String get gameModeRuleRearrange => 'Rearrange';

  @override
  String get gameModeNoUser => 'No user logged in!';

  @override
  String get gameModeNoFriends => 'No friends found!';

  @override
  String gameModeInvited(String username) {
    return 'Invited $username';
  }

  @override
  String get gameModeInvitationDeclined => 'Invitation declined';

  @override
  String get gameModeBtnStartGame => 'Start Game';

  @override
  String get gameModeBtnStartTournament => 'Start Tournament';

  @override
  String get gameModeDialogSelectPlayer => 'Select a Player';

  @override
  String get gameModeYourself => 'Yourself';

  @override
  String get gameModeFriends => 'Friends';

  @override
  String get gameModeWhoStarts => 'Who starts?';

  @override
  String get gameModeWhichTeamStarts => 'Which team should start?';

  @override
  String get gameModeTeamBlueStarts => 'Team Blue starts';

  @override
  String get gameModeTeamRedStarts => 'Team Red starts';

  @override
  String get gameModeToggleSingleGame => 'Single Game';

  @override
  String get gameModeLabelBlue => 'BLUE';

  @override
  String get gameModeLabelRed => 'RED';

  @override
  String get gameModeLabelPlayersUpper => 'PLAYERS';

  @override
  String get gameModeAddPlayer => 'Add Player';

  @override
  String gameModePlayerN(int number) {
    return 'Player $number';
  }

  @override
  String get gameLoadingTitle => 'Game';

  @override
  String get gameTapCupSank => 'Tap the cup you sank';

  @override
  String gameTeamTurn(String teamName) {
    return '$teamName\'s Turn';
  }

  @override
  String get gameNavTable => 'Table';

  @override
  String get gameNavStats => 'Stats';

  @override
  String get gameVs => 'vs';

  @override
  String get gameMissZone => 'Miss Zone — tap to log airball';

  @override
  String get gameTeamStatistics => 'Team Statistics';

  @override
  String get gameStatsPlayer => 'Player';

  @override
  String get gameStatsScore => 'Score';

  @override
  String get gameStatsThrows => 'Throws';

  @override
  String get gameStatsMisses => 'Misses';

  @override
  String get gameStatsAirballs => 'Airballs';

  @override
  String get gameUndoLabel => 'Undo';

  @override
  String get gameCupsLabel => 'Cups';

  @override
  String get gameMoreLabel => 'More';

  @override
  String get gameEndTurnLabel => 'End Turn';

  @override
  String get gameDeathCupLabel => 'Death Cup';

  @override
  String get gameIslandShotLabel => 'Island Shot';

  @override
  String get gameBounceShotLabel => 'Bounce Shot';

  @override
  String get gameRearrangeCupsLabel => 'Rearrange Cups';

  @override
  String get gameSelectPlayer => 'Select Player';

  @override
  String get gameWhoMadeIslandShot => 'Who made the island shot?';

  @override
  String get gameBounceSelectThrower => 'Bounce Shot — Select Thrower';

  @override
  String get gameEnemyLastTurn => 'Enemy Team\'s Last Turn';

  @override
  String get gameBonusCupTitle => 'Choose your free bonus cup';

  @override
  String get gameBonusCupSubtitle =>
      'Island shot reward — pick any remaining cup';

  @override
  String get gameBonusCupSkip => 'Skip bonus';

  @override
  String get gameLeaveTitle => 'Leave Game?';

  @override
  String get gameLeaveContent =>
      'Your game is saved automatically. You can resume it from the home screen.';

  @override
  String get gameLeaveStay => 'Stay';

  @override
  String get gameLeaveLeave => 'Leave';

  @override
  String get dialogSelectPlayerBody => 'Select the player for the cup action:';

  @override
  String get dialogRearrangeErrorTitle => 'Rearrange Error!';

  @override
  String get dialogRearrangeErrorBody =>
      'You can only rearrange if you have 6 or fewer cups!';

  @override
  String get dialogEndTurnTitle => 'End your turn!';

  @override
  String get dialogEndTurnBody => 'Confirm that all cup actions were selected!';

  @override
  String get dialogEndTurnConfirm => 'End Turn';

  @override
  String get dialogAirballTitle => 'Airball Milestone';

  @override
  String get dialogAirballBody => 'All players need to drink a shot!';

  @override
  String dialogAirballCount(int count) {
    return 'Total airballs: $count';
  }

  @override
  String get dialogBallsBackTitle => 'Balls Back!';

  @override
  String get dialogBallsBackBody => 'All players hit this round!';

  @override
  String get dialogOnFireTitle => 'On Fire!';

  @override
  String get dialogOnFireBody => 'Three consecutive hits!';

  @override
  String get dialogBitchCupTitle => 'Bitch Cup!';

  @override
  String get dialogBitchCupBody => 'Drop your pants!';

  @override
  String get dialogGameOverTitle => 'Game Over';

  @override
  String get dialogGameOverGoStats => 'Go to Stats';

  @override
  String get dialogGameOverGoHome => 'Go to Home';

  @override
  String get rulebookSpecialBadge => 'SPECIAL';

  @override
  String get rulebookHowToActivate => 'How to activate';

  @override
  String get rulebookAirballsTagline =>
      'Miss out loud — your team pays the price.';

  @override
  String get rulebookAirballsDescription =>
      'An airball is a throw that misses every cup without touching anything. When a team accumulates 3 airballs in total, all players must take a penalty sip. The counter resets and keeps climbing.';

  @override
  String get rulebookAirballsStep1 => 'Enable \"Airballs\" in game setup.';

  @override
  String get rulebookAirballsStep2 =>
      'When a shot misses completely, tap the orange miss zone below the cups.';

  @override
  String get rulebookAirballsStep3 =>
      'At every 3rd airball, a dialog prompts the penalty.';

  @override
  String get rulebookAirballsTip =>
      'The miss zone only appears when the Airballs rule is active — remember to tap it on every complete miss.';

  @override
  String get rulebookBounceTagline =>
      'One ball, two cups — but the defense can swat it.';

  @override
  String get rulebookBounceDescription =>
      'A bounce shot is a throw where the ball bounces off the table before landing in a cup. It rewards risk: a successful bounce removes the hit cup plus one additional random cup. However, the defending team is allowed to swat the ball away after the first bounce, so it can be blocked.';

  @override
  String get rulebookBounceStep1 => 'Enable \"Bounce\" in game setup.';

  @override
  String get rulebookBounceStep2 =>
      'During your turn, open the action menu (⋯) and tap \"Bounce Shot\".';

  @override
  String get rulebookBounceStep3 =>
      'Select who made the bounce, then tap the cup they sank.';

  @override
  String get rulebookBounceTip =>
      'Bounce shots are high-risk, high-reward. Save them for when you need to close a gap quickly.';

  @override
  String get rulebookPutbackTagline =>
      'The game isn\'t over until the last redemption throw lands.';

  @override
  String get rulebookPutbackDescription =>
      'When a team sinks the opponent\'s final cup, the losing side earns one redemption throw per player. If any throw lands, the last cup is restored and the game continues into overtime. Every player must attempt their throw before the result is decided.';

  @override
  String get rulebookPutbackStep1 => 'Enable \"Putback\" in game setup.';

  @override
  String get rulebookPutbackStep2 =>
      'When the last cup is sunk, the redemption dialog appears automatically.';

  @override
  String get rulebookPutbackStep3 =>
      'Each losing-team player takes one shot. A hit keeps the game alive.';

  @override
  String get rulebookPutbackTip =>
      'If multiple redemption throws land, only one cup is restored — aim carefully.';

  @override
  String get rulebookIslandTagline => 'An isolated cup means a free bonus cup.';

  @override
  String get rulebookIslandDescription =>
      'An island cup is one with no neighbours — completely surrounded by empty space. A designated shooter can call an island shot on it. If they sink it, they win that cup plus a bonus cup of their choice. A miss scores nothing and the attempt is used up.';

  @override
  String get rulebookIslandStep1 => 'Enable \"Island\" in game setup.';

  @override
  String get rulebookIslandStep2 =>
      'Tap \"Island Shot\" in the action menu and select the shooter.';

  @override
  String get rulebookIslandStep3 =>
      'Island cups glow yellow. Tap one to take the shot.';

  @override
  String get rulebookIslandStep4 =>
      'On success, pick your free bonus cup from the bottom sheet.';

  @override
  String get rulebookIslandTip =>
      'If only one island cup exists, the shot triggers automatically after selecting the shooter — no extra tap needed.';

  @override
  String get rulebookDeathcupTagline =>
      'Sink the cup being drunk and the game ends instantly.';

  @override
  String get rulebookDeathcupDescription =>
      'When the Deathcup rule is active, each cup that has been sunk but not yet fully drunk is a live deathcup. If a player lands a ball in it while an opponent is still drinking, that team immediately loses — all remaining cups are cleared.';

  @override
  String get rulebookDeathcupStep1 => 'Enable \"Deathcup\" in game setup.';

  @override
  String get rulebookDeathcupStep2 =>
      'When a deathcup is sunk, open the action menu (⋯) and tap \"Deathcup\".';

  @override
  String get rulebookDeathcupStep3 =>
      'Select the player who made the shot to trigger the instant win.';

  @override
  String get rulebookDeathcupTip =>
      'Keep track of which cups opponents are currently drinking — they\'re your highest-value targets.';

  @override
  String get rulebookRearrangeTagline =>
      'Regroup scattered cups into a tighter formation.';

  @override
  String get rulebookRearrangeDescription =>
      'Once per game, when 6 or fewer cups remain on your side, you can call a re-rack. Cups are rearranged into a standard triangle formation, closing the gaps that make individual cups harder to hit. The re-rack can only be used once and only within the 6-cup limit.';

  @override
  String get rulebookRearrangeStep1 => 'Enable \"Rearrange\" in game setup.';

  @override
  String get rulebookRearrangeStep2 =>
      'When 6 or fewer cups remain, tap the re-rack button in the bottom dock bar.';

  @override
  String get rulebookRearrangeStep3 =>
      'Cups immediately shift into a compact triangle.';

  @override
  String get rulebookRearrangeTip =>
      'Save your re-rack for when cups are most scattered — a tight triangle is significantly easier to aim at.';

  @override
  String get statsTabStats => 'Stats';

  @override
  String get statsTabPerformance => 'Performance';

  @override
  String get statsTabProgress => 'Progress';

  @override
  String get statsTabBreakdown => 'Breakdown';

  @override
  String get statsTabHistory => 'History';

  @override
  String get statsSignInPrompt => 'Sign in to view your statistics';

  @override
  String get statsFailedToLoad => 'Failed to load games';

  @override
  String get statsNoGamesYet => 'No games recorded yet.';

  @override
  String get statsLiveView => 'Live view';

  @override
  String get statsGameStatistics => 'Game Statistics';

  @override
  String get statsViewTeam => 'View Team';

  @override
  String get statsViewGameStats => 'View Game Stats';

  @override
  String get statsViewTable => 'View Table';

  @override
  String get statsColumnPlayer => 'Player';

  @override
  String get statsColumnScore => 'Score';

  @override
  String get statsColumnThrows => 'Throws';

  @override
  String get statsColumnMiss => 'Miss';

  @override
  String get statsColumnHitRate => 'Hit%';

  @override
  String get statsColumnBounce => 'Bounce';

  @override
  String get statsColumnDef => 'Def';

  @override
  String get statsAchievements => 'Achievements';

  @override
  String get statsTeamStatistics => 'Team Statistics';

  @override
  String get statsMvp => 'MVP';

  @override
  String get statsAirballer => 'Airballer';

  @override
  String get statsMissManiac => 'Miss Maniac';

  @override
  String get statsSniper => 'Sniper';

  @override
  String get statsTierRoadmap => 'Tier Roadmap';

  @override
  String get statsAchievementProgress => 'Achievement Progress';

  @override
  String get statsUnlockedTitles => 'Unlocked Titles';

  @override
  String get statsAlmostThere => 'Almost There';

  @override
  String statsMaxLevelReached(int xp) {
    return 'Max level reached — $xp XP total';
  }

  @override
  String statsReachLevelUnlock(int level, String title) {
    return 'Reach Level $level to unlock $title';
  }

  @override
  String get perfSummaryTitle => 'Performance Summary';

  @override
  String get perfHeatMapTitle => 'Cups Hit Heat Map';

  @override
  String get perfRowAccuracyTitle => 'Row Accuracy';

  @override
  String get perfFilterAll => 'All';

  @override
  String get perfFilterLast10 => 'Last 10';

  @override
  String get perfFilterLast5 => 'Last 5';

  @override
  String get perfFilterLast3 => 'Last 3';

  @override
  String get perfNoData => 'No data yet.';

  @override
  String get perfRowFront => 'Front';

  @override
  String get perfRowMid => 'Mid';

  @override
  String get perfRowBack => 'Back';

  @override
  String get perfRowApex => 'Apex';

  @override
  String get statTotalScore => 'Total Score';

  @override
  String get statTotalMisses => 'Total Misses';

  @override
  String get statTotalAirballs => 'Total Airballs';

  @override
  String get statCupsHit => 'Cups Hit';

  @override
  String get statHitRate => 'Hit Rate';

  @override
  String get statWinRate => 'Win Rate';

  @override
  String get statBounceRate => 'Bounce Rate';

  @override
  String get statIslandConv => 'Island Conv.';

  @override
  String get statDefended => 'Defended';

  @override
  String get statOnFire => 'On Fire';

  @override
  String get statHeatingUp => 'Heating Up';

  @override
  String get friendsTabFriendlist => 'Friendlist';

  @override
  String get friendsTabLeaderboard => 'Leaderboard';

  @override
  String get friendsTabSocials => 'Socials';

  @override
  String get friendsSignInPrompt => 'Sign in to view your friends';

  @override
  String get friendsMustSignIn => 'You must be signed in to add friends.';

  @override
  String get friendsNoFriends =>
      'No friends yet. Add one using the + button above.';

  @override
  String get friendsNoActivity => 'Add friends to see activity here.';

  @override
  String get friendsNoRecentActivity => 'No recent activity yet.';

  @override
  String get friendsNoFriendsFound => 'No friends found.';

  @override
  String get friendsRemoveTitle => 'Remove Friend';

  @override
  String friendsRemoveBody(String username) {
    return 'Remove $username from your friends?';
  }

  @override
  String get friendsRemoveConfirm => 'Remove';

  @override
  String get friendsAddTitle => 'Add a Friend';

  @override
  String get friendsSearchHint => 'Search by username…';

  @override
  String get friendsNoUsersFound => 'No users found.';

  @override
  String get friendsAddBtn => 'Add';

  @override
  String get friendsShareQr => 'Share / Scan QR';

  @override
  String get friendsIdCopied => 'ID copied to clipboard';

  @override
  String get friendsScanQrBtn => 'Scan QR Code';

  @override
  String get friendsWatchBtn => 'Watch';

  @override
  String get shopTabAvatar => 'Avatar';

  @override
  String get shopTabUserCard => 'User Card';

  @override
  String get shopTabInGame => 'In Game';

  @override
  String get shopSignInEarnStars => 'Sign in to earn Stars';

  @override
  String get shopGetStars => 'Get Stars';

  @override
  String get shopEarnStarsHint => 'Earn ⭐ stars to spend in the shop.';

  @override
  String get shopSupporterTitle => 'Thank you! ⭐';

  @override
  String get shopSupporterBody =>
      'You\'re now a Supporter! Your Supporter badge is live on your profile, and you\'re helping keep the app running. Thank you!';

  @override
  String get shopSupporterBtn => 'Awesome!';

  @override
  String shopStarsAwarded(int count) {
    return 'You got $count ⭐!';
  }

  @override
  String shopPurchaseFailed(String message) {
    return 'Purchase failed: $message';
  }

  @override
  String get shopNoAdAvailable => 'No ad available right now. Try again later.';

  @override
  String get shopEarned50Stars => 'You earned 50 ⭐!';

  @override
  String get shopEarnFreeStars => 'Earn stars for free by playing games!';

  @override
  String get shopRestorePurchases => 'Restore Purchases';

  @override
  String get shopWatchVideo => 'Watch a short video';

  @override
  String get shopDailyLimitReached =>
      'Daily limit reached — come back tomorrow';

  @override
  String get shopSupporterBadge => 'You\'re a Supporter ✓';

  @override
  String get shopBuyBtn => 'Buy';

  @override
  String get shopComingSoon => 'Coming soon';

  @override
  String get accountProfile => 'Profile';

  @override
  String get accountSupporter => 'Supporter';

  @override
  String get accountFeedbackTooltip => 'Send feedback';

  @override
  String get accountSignOutTooltip => 'Sign out';

  @override
  String get accountSignOutTitle => 'Sign out?';

  @override
  String get accountSignOutBody =>
      'You will be returned to the sign-in screen.';

  @override
  String get accountSignOutConfirm => 'Sign out';

  @override
  String get achievementStagesBronze => 'Bronze';

  @override
  String get achievementStagesSilver => 'Silver';

  @override
  String get achievementStagesGold => 'Gold';

  @override
  String get achievementStagesDiamond => 'Diamond';

  @override
  String get achievementMaxed => 'Maxed!';

  @override
  String get achievementFullyMastered => 'Fully mastered!';

  @override
  String achievementProgress(int current, int next) {
    return 'Progress: $current / $next';
  }

  @override
  String achievementUnlocksTitle(String title) {
    return 'Unlocks title: \"$title\"';
  }

  @override
  String get profileSectionUsername => 'Username';

  @override
  String get profileSectionAvatar => 'Avatar';

  @override
  String get profileSectionBackground => 'Background';

  @override
  String get profileSectionTitle => 'Title';

  @override
  String get profileUsernamePlaceholder => 'Choose a username';

  @override
  String get profileUsernameChecking => 'Checking…';

  @override
  String get profileUsernameAvailable => 'Available';

  @override
  String get profileUsernameTaken => 'Already taken';

  @override
  String get profileUsernameInvalid =>
      '3–20 chars, letters/numbers/underscores/spaces, no consecutive __ or spaces';

  @override
  String get profileUpdated => 'Profile updated!';

  @override
  String profileSaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String profileLevelRequired(int level) {
    return 'Lv $level';
  }

  @override
  String dialogGameOverWinners(String winners) {
    return '$winners have won the game!';
  }

  @override
  String get achievementsMaxLevel => 'Max level reached';

  @override
  String achievementsXpProgress(int xp, int toNext, int nextLevel) {
    return '$xp XP · $toNext XP to Level $nextLevel';
  }

  @override
  String get achievementsBestStreak => 'Best Streak';

  @override
  String get shopSignInBrowse => 'Sign in to browse the shop';

  @override
  String get shopSectionProfilePictures => 'Profile Pictures';

  @override
  String get shopSectionAvatarBorders => 'Avatar Borders';

  @override
  String get shopSectionEmblemsAndMedals => 'Emblems & Medals';

  @override
  String get shopSectionCupSkins => 'Cup Skins';

  @override
  String get shopSectionTableThemes => 'Table Themes';

  @override
  String get shopSectionTitles => 'Titles';

  @override
  String get shopSectionCardBackgrounds => 'Card Backgrounds';

  @override
  String get shopCardBackgroundsNote =>
      'Card backgrounds are unlocked for free by levelling up. Manage them in your profile.';

  @override
  String get shopEquip => 'Equip';

  @override
  String get shopUnequip => 'Unequip';

  @override
  String get shopYourBalance => 'Your balance';

  @override
  String get shopCost => 'Cost';

  @override
  String shopBuyForStars(int price) {
    return 'Buy for ⭐ $price';
  }

  @override
  String shopNeedMoreStars(int count) {
    return 'You need $count more ⭐ to buy this.';
  }

  @override
  String get shopGetMoreStars => 'Get More Stars';

  @override
  String shopItemPurchased(String name) {
    return '$name purchased! ⭐';
  }

  @override
  String get shopNotEnoughStars => 'Not enough stars!';

  @override
  String get navShop => 'Shop';

  @override
  String get navFriends => 'Friends';

  @override
  String get navHome => 'Home';

  @override
  String get navGames => 'Games';

  @override
  String get navProfile => 'Profile';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsPrivacy => 'Privacy Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get feedbackSheetTitle => 'Send Feedback';

  @override
  String get feedbackHint => 'Describe the issue or idea…';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackSuccess => 'Thanks for your feedback!';

  @override
  String get feedbackError => 'Could not send feedback. Try again.';

  @override
  String get feedbackCategoryBug => 'Bug';

  @override
  String get feedbackCategorySuggestion => 'Suggestion';

  @override
  String get feedbackCategoryOther => 'Other';

  @override
  String get invitationsTitle => 'Invitations';

  @override
  String get invitationsNotSignedIn => 'Not signed in';

  @override
  String get invitationsNoPending => 'No pending invitations';

  @override
  String get invitationsDeclined => 'Invitation declined';

  @override
  String get invitationsDeclineBtn => 'Decline';

  @override
  String get invitationsAcceptBtn => 'Accept';

  @override
  String get invitationsFromPlayer => 'A player';

  @override
  String get invitationsInvitedToGame => 'Invited you to a Game';

  @override
  String get invitationsInvitedToTournament => 'Invited you to a Tournament';

  @override
  String get waitingTitle => 'Waiting…';

  @override
  String waitingForGame(String host) {
    return 'Waiting for $host to start the game…';
  }

  @override
  String waitingForTournament(String host) {
    return 'Waiting for $host to start the tournament…';
  }

  @override
  String get liveGameTitle => 'Live Game';

  @override
  String get liveGameSummary => 'Game Summary';

  @override
  String get liveTabTable => 'Table';

  @override
  String get liveTabStats => 'Stats';

  @override
  String get liveTabTimeline => 'Timeline';

  @override
  String get liveGameNotFound => 'Game not found.';

  @override
  String get liveGameError => 'Something went wrong';

  @override
  String get liveBadgeLive => 'LIVE';

  @override
  String get liveBadgeFinal => 'FINAL';

  @override
  String get liveStatsAccuracy => 'Accuracy %';

  @override
  String get liveTimelineNoEvents => 'No events yet';

  @override
  String liveTimelineRound(int number) {
    return 'Round $number';
  }

  @override
  String liveTimelineEndOfTurn(String time) {
    return 'End of turn · $time';
  }

  @override
  String get liveEventHit => 'Hit';

  @override
  String get liveEventBounce => 'Bounce';

  @override
  String get liveEventIsland => 'Island';

  @override
  String get liveEventDeathCup => 'Death Cup';

  @override
  String get liveEventAirball => 'Airball';

  @override
  String get liveEventBitchCup => 'Bitch Cup';

  @override
  String get liveEventOnFire => 'On Fire';

  @override
  String get spectatelobbyTitle => 'Lobby';

  @override
  String get spectateLobbyGameTitle => 'Game Lobby';

  @override
  String get spectateLobbyError => 'Error loading game.';

  @override
  String get spectateLobbyNoPlayers => 'No players yet';

  @override
  String get spectateLobbyGameSettings => 'Game Settings';

  @override
  String get spectateLobbyMode => 'Mode';

  @override
  String get spectateLobbyStartingTeam => 'Starting Team';

  @override
  String get spectateLobbyWaiting => 'Waiting for the host to start the game…';

  @override
  String get btnLeave => 'Leave';

  @override
  String liveCupsLeft(int count) {
    return '$count cups left';
  }

  @override
  String get liveStatScore => 'Score';

  @override
  String get liveStatThrows => 'Throws';

  @override
  String get liveStatAirballs => 'Airballs';

  @override
  String get liveStatMisses => 'Misses';

  @override
  String get liveStatCupsHit => 'Cups Hit';

  @override
  String gameModeTeamStarts(String team) {
    return '$team starts';
  }

  @override
  String get tournamentCompleteTitle => 'Tournament Complete!';

  @override
  String get tournamentCompleteBody =>
      'All matches have been played.\nCheck out the standings!';

  @override
  String get labelPlayer => 'Player';

  @override
  String get compareTitle => 'Comparison';

  @override
  String get compareOverview => 'OVERVIEW';

  @override
  String get compareStatComparison => 'STAT COMPARISON';

  @override
  String get compareBouncePercent => 'Bounce %';

  @override
  String get compareIslandPercent => 'Island %';

  @override
  String get compareTotalWins => 'Total Wins';

  @override
  String get compareOnFire => 'On Fire';

  @override
  String get breakdownShotDistribution => 'Shot Distribution';

  @override
  String get breakdownSpecialShots => 'Special Shots';

  @override
  String get breakdownWinContext => 'Win Context';

  @override
  String get breakdownHeadToHead => 'Head to Head';

  @override
  String get breakdownThrowsLabel => 'throws';

  @override
  String get breakdownHits => 'Hits';

  @override
  String get breakdownBounceShot => 'Bounce Shot';

  @override
  String get breakdownIslandShot => 'Island Shot';

  @override
  String get breakdownWinMarginTitle => 'Win Margin Distribution';

  @override
  String get breakdownDominant => 'Dominant (5+ cups)';

  @override
  String get breakdownComfortable => 'Comfortable (3–4)';

  @override
  String get breakdownClose => 'Close (1–2)';

  @override
  String get breakdownClutchRate => 'Clutch Rate';

  @override
  String get breakdownClutchDesc => 'Hit the last cup to win';

  @override
  String get breakdownNoGames => 'No games recorded yet.';

  @override
  String get breakdownNoOpponents => 'No opponents found.';

  @override
  String get breakdownNoThrows => 'No throws recorded yet.';

  @override
  String get statsViewAllAchievements => 'View all achievements';

  @override
  String get statsColAbbrevScore => 'S';

  @override
  String get statsColAbbrevMisses => 'M';

  @override
  String get statsColAbbrevThrows => 'T';

  @override
  String get statsColAbbrevAirballs => 'A';

  @override
  String get statsColAbbrevHitRate => 'HR';

  @override
  String get statsCareerHighlights => 'CAREER HIGHLIGHTS';

  @override
  String get statsBestStreak => 'Best Streak';

  @override
  String get statsBestHitRate => 'Best Hit Rate';

  @override
  String get statsMostCups => 'Most Cups';

  @override
  String get statsRecentForm => 'Recent Form';

  @override
  String get statsWins => 'Wins';

  @override
  String get statsLosses => 'Losses';

  @override
  String get statsWinRate => 'Win Rate';

  @override
  String get statsHitRate => 'Hit Rate';

  @override
  String get statsOnFire => 'On Fire';

  @override
  String get statsBouncePercent => 'Bounce%';

  @override
  String get statsIslands => 'Islands';

  @override
  String get statsDefended => 'Defended';

  @override
  String get statsHeatingUp => 'Heating Up';

  @override
  String get statsLastCup => 'Last Cup';

  @override
  String get statsAvgPerGame => 'Avg/Game';

  @override
  String get statsNightGames => 'Night Games';

  @override
  String get statsCupsPerGame => 'cups/game';

  @override
  String get statsThrowsPerGame => 'throws/game';

  @override
  String statsStreakChip(int count, String type) {
    return '$count-game $type streak';
  }

  @override
  String statsCurrentStreak(String label) {
    return 'Current streak: $label';
  }

  @override
  String statsLast10Record(int count, int wins, int losses) {
    return 'Last $count:  ${wins}W  ${losses}L';
  }

  @override
  String statsXpProgress(int xp, int toNext, int level) {
    return '$xp XP · $toNext XP to Level $level';
  }

  @override
  String get compareWinRate => 'Win Rate';

  @override
  String get compareHitRate => 'Hit Rate';

  @override
  String get shopStarterPackTitle => 'Starter Pack  ·  €1.99';

  @override
  String get shopStarterPackSubtitle => '200 ⭐';

  @override
  String get shopPopularPackTitle => 'Popular Pack  ·  €4.99';

  @override
  String get shopPopularPackSubtitle => '600 ⭐  ·  Best value';

  @override
  String get shopMegaPackTitle => 'Mega Pack  ·  €9.99';

  @override
  String get shopMegaPackSubtitle => '1 500 ⭐';

  @override
  String get shopSupporterPackFull => 'Supporter Pack  ·  €2.99';

  @override
  String get shopSupporterPackFullSubtitle =>
      '300 ⭐  ·  Supporter badge on your profile';

  @override
  String shopWatchesRemaining(int remaining, int total) {
    return '+50 ⭐  ·  $remaining of $total watches remaining today';
  }

  @override
  String socialBeatFriend(String username) {
    return 'Beat $username';
  }

  @override
  String socialLostToFriend(String username) {
    return 'Lost to $username';
  }

  @override
  String socialSharedGameResult(int myScore, int oppScore, int hitPct) {
    return '$myScore–$oppScore · $hitPct% hit rate';
  }

  @override
  String socialWinStreak(int count) {
    return '🔥 $count-game win streak!';
  }

  @override
  String get socialWinStreakSubtitle =>
      'You\'re on fire — keep the momentum going.';

  @override
  String socialFriendReachedWins(String username, int count) {
    return '🏆 $username reached $count wins';
  }

  @override
  String get socialFriendLegendSubtitle => 'A true beer pong legend.';

  @override
  String socialFriendOnFire(String username, int count) {
    return '🔥 $username went on fire $count+ times';
  }

  @override
  String get socialSeriousHeatSubtitle => 'Serious heat.';

  @override
  String socialFriendIsActive(String username) {
    return '$username is active';
  }

  @override
  String socialFriendActiveSubtitle(String timeAgo, int totalGames) {
    return 'Played $timeAgo · $totalGames total games';
  }

  @override
  String get leaderboardTotalScore => 'Total Score';

  @override
  String get leaderboardGames => 'Games';
}
