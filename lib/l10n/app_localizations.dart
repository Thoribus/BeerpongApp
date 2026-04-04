import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de')
  ];

  /// App name shown in title bar
  ///
  /// In en, this message translates to:
  /// **'Beerpong Companion'**
  String get appTitle;

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// Generic save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get btnSave;

  /// Save button label while in progress
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get btnSaving;

  /// Generic add button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get btnAdd;

  /// Generic close button
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get btnClose;

  /// Generic OK button
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get btnOk;

  /// Generic sign-in with Google button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get btnSignInGoogle;

  /// Blue team display name
  ///
  /// In en, this message translates to:
  /// **'Team Blue'**
  String get labelTeamBlue;

  /// Red team display name
  ///
  /// In en, this message translates to:
  /// **'Team Red'**
  String get labelTeamRed;

  /// Versus divider between two teams
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get labelVs;

  /// Section header for game rules
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get labelRules;

  /// Section header or label for players
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get labelPlayers;

  /// Section header for teams
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get labelTeams;

  /// Tournament mode label
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get labelTournament;

  /// Short level badge, e.g. Lv 5
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String labelLevelShort(int level);

  /// App tagline shown on login screen
  ///
  /// In en, this message translates to:
  /// **'Track your game. Rule the table.'**
  String get loginTagline;

  /// Sign-in tab label on login toggle
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginToggleSignIn;

  /// Register tab label on login toggle
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get loginToggleRegister;

  /// Username input field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginFieldUsername;

  /// Email input field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginFieldEmail;

  /// Password input field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginFieldPassword;

  /// Validation error when username is empty
  ///
  /// In en, this message translates to:
  /// **'Enter a username'**
  String get loginValidateUsername;

  /// Validation error for invalid email
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get loginValidateEmail;

  /// Validation error when password is too short
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get loginValidatePassword;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// Sign-in submit button label
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginBtnSignIn;

  /// Register submit button label
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginBtnCreateAccount;

  /// Divider text between email form and social logins
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get loginOrContinueWith;

  /// Google sign-in button label
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginContinueGoogle;

  /// Apple sign-in button label
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get loginContinueApple;

  /// Generic error during email sign-in
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get loginErrorGeneric;

  /// Error during Google sign-in
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get loginErrorGoogle;

  /// Error during Apple sign-in
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed. Please try again.'**
  String get loginErrorApple;

  /// Error shown when forgot-password tapped without email
  ///
  /// In en, this message translates to:
  /// **'Enter your email address first.'**
  String get loginErrorEmailFirst;

  /// Snackbar after password reset email sent
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent!'**
  String get loginResetEmailSent;

  /// Error when reset email fails to send
  ///
  /// In en, this message translates to:
  /// **'Could not send reset email. Check the address.'**
  String get loginErrorResetFailed;

  /// Firebase: user-not-found
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get loginErrUserNotFound;

  /// Firebase: wrong-password / invalid-credential
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get loginErrWrongPassword;

  /// Firebase: email-already-in-use
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get loginErrEmailInUse;

  /// Firebase: weak-password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get loginErrWeakPassword;

  /// Firebase: invalid-email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get loginErrInvalidEmail;

  /// Firebase: too-many-requests
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get loginErrTooManyRequests;

  /// Firebase: catch-all auth error
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get loginErrAuthFailed;

  /// Subtitle on hero card
  ///
  /// In en, this message translates to:
  /// **'Let\'s play!'**
  String get homeLetsPlay;

  /// Title on hero card
  ///
  /// In en, this message translates to:
  /// **'Beer Pong'**
  String get homeBeerPong;

  /// New Game button on hero card
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get homeBtnNewGame;

  /// Resume game card title
  ///
  /// In en, this message translates to:
  /// **'Resume Game'**
  String get homeResumeTitle;

  /// Resume game card subtitle
  ///
  /// In en, this message translates to:
  /// **'Continue your last game'**
  String get homeResumeSubtitle;

  /// Badge showing number of pending game invitations
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have 1 pending invitation} other{You have {count} pending invitations}}'**
  String homePendingInvitations(int count);

  /// Rulebook banner title
  ///
  /// In en, this message translates to:
  /// **'Rulebook'**
  String get homeRulebookTitle;

  /// Rulebook banner subtitle
  ///
  /// In en, this message translates to:
  /// **'Learn how every special rule works'**
  String get homeRulebookSubtitle;

  /// Title of confirmation dialog when starting a new game
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get homeNewGameDialogTitle;

  /// Body of new-game confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Starting a new game will delete the current game. Do you want to continue?'**
  String get homeNewGameDialogContent;

  /// Confirm button in new-game dialog
  ///
  /// In en, this message translates to:
  /// **'Start New Game'**
  String get homeNewGameDialogConfirm;

  /// Game mode screen title for single game
  ///
  /// In en, this message translates to:
  /// **'Play Beerpong'**
  String get homeGameModeTitle;

  /// Game mode screen subtitle for single game
  ///
  /// In en, this message translates to:
  /// **'Quick, fun rounds'**
  String get homeGameModeSubtitle;

  /// Game mode screen title for tournament
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get homeTournamentTitle;

  /// Game mode screen subtitle for tournament
  ///
  /// In en, this message translates to:
  /// **'Bracket-style play'**
  String get homeTournamentSubtitle;

  /// Airballs rule name on game setup screen
  ///
  /// In en, this message translates to:
  /// **'Airballs'**
  String get gameModeRuleAirballs;

  /// Bounce rule name on game setup screen
  ///
  /// In en, this message translates to:
  /// **'Bounce'**
  String get gameModeRuleBounce;

  /// Putback rule name on game setup screen
  ///
  /// In en, this message translates to:
  /// **'Putback'**
  String get gameModeRulePutback;

  /// Island rule name on game setup screen
  ///
  /// In en, this message translates to:
  /// **'Island'**
  String get gameModeRuleIsland;

  /// Deathcup rule name on game setup screen
  ///
  /// In en, this message translates to:
  /// **'Deathcup'**
  String get gameModeRuleDeathcup;

  /// Rearrange rule name on game setup screen
  ///
  /// In en, this message translates to:
  /// **'Rearrange'**
  String get gameModeRuleRearrange;

  /// Error when no user is logged in during player pick
  ///
  /// In en, this message translates to:
  /// **'No user logged in!'**
  String get gameModeNoUser;

  /// Error when friend list is empty
  ///
  /// In en, this message translates to:
  /// **'No friends found!'**
  String get gameModeNoFriends;

  /// Snackbar confirmation after sending a game invitation
  ///
  /// In en, this message translates to:
  /// **'Invited {username}'**
  String gameModeInvited(String username);

  /// Snackbar when an invitation is declined
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get gameModeInvitationDeclined;

  /// Start game button label
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get gameModeBtnStartGame;

  /// Start tournament button label
  ///
  /// In en, this message translates to:
  /// **'Start Tournament'**
  String get gameModeBtnStartTournament;

  /// Title of player-picker dialog on game setup
  ///
  /// In en, this message translates to:
  /// **'Select a Player'**
  String get gameModeDialogSelectPlayer;

  /// Option to add yourself as a player
  ///
  /// In en, this message translates to:
  /// **'Yourself'**
  String get gameModeYourself;

  /// Section header in player-picker for friends
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get gameModeFriends;

  /// Title of starting-team dialog
  ///
  /// In en, this message translates to:
  /// **'Who starts?'**
  String get gameModeWhoStarts;

  /// Body of starting-team dialog
  ///
  /// In en, this message translates to:
  /// **'Which team should start?'**
  String get gameModeWhichTeamStarts;

  /// Button to choose blue team as starting team
  ///
  /// In en, this message translates to:
  /// **'Team Blue starts'**
  String get gameModeTeamBlueStarts;

  /// Button to choose red team as starting team
  ///
  /// In en, this message translates to:
  /// **'Team Red starts'**
  String get gameModeTeamRedStarts;

  /// Mode toggle option for single game
  ///
  /// In en, this message translates to:
  /// **'Single Game'**
  String get gameModeToggleSingleGame;

  /// Blue team panel header label
  ///
  /// In en, this message translates to:
  /// **'BLUE'**
  String get gameModeLabelBlue;

  /// Red team panel header label
  ///
  /// In en, this message translates to:
  /// **'RED'**
  String get gameModeLabelRed;

  /// Tournament players panel header label
  ///
  /// In en, this message translates to:
  /// **'PLAYERS'**
  String get gameModeLabelPlayersUpper;

  /// Add player button in tournament lobby
  ///
  /// In en, this message translates to:
  /// **'Add Player'**
  String get gameModeAddPlayer;

  /// Placeholder text for an unnamed player slot
  ///
  /// In en, this message translates to:
  /// **'Player {number}'**
  String gameModePlayerN(int number);

  /// AppBar title while game is loading
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get gameLoadingTitle;

  /// AppBar instruction during active bounce shot
  ///
  /// In en, this message translates to:
  /// **'Tap the cup you sank'**
  String get gameTapCupSank;

  /// AppBar title showing whose turn it is
  ///
  /// In en, this message translates to:
  /// **'{teamName}\'s Turn'**
  String gameTeamTurn(String teamName);

  /// Nav pill label for the game table page
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get gameNavTable;

  /// Nav pill label for the in-game stats page
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get gameNavStats;

  /// Versus separator in score strip
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get gameVs;

  /// Label on the airball miss zone tap area
  ///
  /// In en, this message translates to:
  /// **'Miss Zone — tap to log airball'**
  String get gameMissZone;

  /// Header on the in-game stats page
  ///
  /// In en, this message translates to:
  /// **'Team Statistics'**
  String get gameTeamStatistics;

  /// Column header: player name
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get gameStatsPlayer;

  /// Column header: score
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get gameStatsScore;

  /// Column header: throw count
  ///
  /// In en, this message translates to:
  /// **'Throws'**
  String get gameStatsThrows;

  /// Column header: miss count
  ///
  /// In en, this message translates to:
  /// **'Misses'**
  String get gameStatsMisses;

  /// Column header: airball count
  ///
  /// In en, this message translates to:
  /// **'Airballs'**
  String get gameStatsAirballs;

  /// Bottom bar: undo last action
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get gameUndoLabel;

  /// Bottom bar: toggle re-rack
  ///
  /// In en, this message translates to:
  /// **'Cups'**
  String get gameCupsLabel;

  /// Bottom bar: open actions sheet
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get gameMoreLabel;

  /// Bottom bar: end current turn
  ///
  /// In en, this message translates to:
  /// **'End Turn'**
  String get gameEndTurnLabel;

  /// Actions sheet: death cup entry
  ///
  /// In en, this message translates to:
  /// **'Death Cup'**
  String get gameDeathCupLabel;

  /// Actions sheet: island shot entry
  ///
  /// In en, this message translates to:
  /// **'Island Shot'**
  String get gameIslandShotLabel;

  /// Actions sheet: bounce shot entry
  ///
  /// In en, this message translates to:
  /// **'Bounce Shot'**
  String get gameBounceShotLabel;

  /// Actions sheet: rearrange cups entry
  ///
  /// In en, this message translates to:
  /// **'Rearrange Cups'**
  String get gameRearrangeCupsLabel;

  /// Dialog title for in-game player selection
  ///
  /// In en, this message translates to:
  /// **'Select Player'**
  String get gameSelectPlayer;

  /// Dialog title for island shot player selection
  ///
  /// In en, this message translates to:
  /// **'Who made the island shot?'**
  String get gameWhoMadeIslandShot;

  /// Dialog title for bounce shot player selection
  ///
  /// In en, this message translates to:
  /// **'Bounce Shot — Select Thrower'**
  String get gameBounceSelectThrower;

  /// Dialog title for putback (nachwurf) player selection
  ///
  /// In en, this message translates to:
  /// **'Enemy Team\'s Last Turn'**
  String get gameEnemyLastTurn;

  /// Bottom sheet title for island shot bonus cup picker
  ///
  /// In en, this message translates to:
  /// **'Choose your free bonus cup'**
  String get gameBonusCupTitle;

  /// Bottom sheet subtitle for bonus cup picker
  ///
  /// In en, this message translates to:
  /// **'Island shot reward — pick any remaining cup'**
  String get gameBonusCupSubtitle;

  /// Button to skip the island shot bonus cup
  ///
  /// In en, this message translates to:
  /// **'Skip bonus'**
  String get gameBonusCupSkip;

  /// Dialog title when trying to leave mid-game
  ///
  /// In en, this message translates to:
  /// **'Leave Game?'**
  String get gameLeaveTitle;

  /// Dialog body explaining auto-save before leaving
  ///
  /// In en, this message translates to:
  /// **'Your game is saved automatically. You can resume it from the home screen.'**
  String get gameLeaveContent;

  /// Cancel button in leave-game dialog
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get gameLeaveStay;

  /// Confirm button in leave-game dialog
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get gameLeaveLeave;

  /// Body text in the generic player selection dialog
  ///
  /// In en, this message translates to:
  /// **'Select the player for the cup action:'**
  String get dialogSelectPlayerBody;

  /// Title of rearrange rule error dialog
  ///
  /// In en, this message translates to:
  /// **'Rearrange Error!'**
  String get dialogRearrangeErrorTitle;

  /// Body of rearrange rule error dialog
  ///
  /// In en, this message translates to:
  /// **'You can only rearrange if you have 6 or fewer cups!'**
  String get dialogRearrangeErrorBody;

  /// Title of end-turn confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'End your turn!'**
  String get dialogEndTurnTitle;

  /// Body of end-turn confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm that all cup actions were selected!'**
  String get dialogEndTurnBody;

  /// Confirm button in end-turn dialog
  ///
  /// In en, this message translates to:
  /// **'End Turn'**
  String get dialogEndTurnConfirm;

  /// Title of airball milestone dialog
  ///
  /// In en, this message translates to:
  /// **'Airball Milestone'**
  String get dialogAirballTitle;

  /// Body of airball milestone dialog
  ///
  /// In en, this message translates to:
  /// **'All players need to drink a shot!'**
  String get dialogAirballBody;

  /// Running airball counter shown in milestone dialog
  ///
  /// In en, this message translates to:
  /// **'Total airballs: {count}'**
  String dialogAirballCount(int count);

  /// Title of balls-back notification dialog
  ///
  /// In en, this message translates to:
  /// **'Balls Back!'**
  String get dialogBallsBackTitle;

  /// Body of balls-back notification dialog
  ///
  /// In en, this message translates to:
  /// **'All players hit this round!'**
  String get dialogBallsBackBody;

  /// Title of on-fire streak notification dialog
  ///
  /// In en, this message translates to:
  /// **'On Fire!'**
  String get dialogOnFireTitle;

  /// Body of on-fire streak notification dialog
  ///
  /// In en, this message translates to:
  /// **'Three consecutive hits!'**
  String get dialogOnFireBody;

  /// Title of bitch-cup notification dialog
  ///
  /// In en, this message translates to:
  /// **'Bitch Cup!'**
  String get dialogBitchCupTitle;

  /// Body of bitch-cup notification dialog
  ///
  /// In en, this message translates to:
  /// **'Drop your pants!'**
  String get dialogBitchCupBody;

  /// Title of game-over dialog
  ///
  /// In en, this message translates to:
  /// **'Game Over'**
  String get dialogGameOverTitle;

  /// Game-over dialog button to navigate to stats
  ///
  /// In en, this message translates to:
  /// **'Go to Stats'**
  String get dialogGameOverGoStats;

  /// Game-over dialog button to navigate home
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get dialogGameOverGoHome;

  /// Badge label on each rule card in the rulebook
  ///
  /// In en, this message translates to:
  /// **'SPECIAL'**
  String get rulebookSpecialBadge;

  /// Section label above activation steps in a rule card
  ///
  /// In en, this message translates to:
  /// **'How to activate'**
  String get rulebookHowToActivate;

  /// Tagline for the Airballs rule card
  ///
  /// In en, this message translates to:
  /// **'Miss out loud — your team pays the price.'**
  String get rulebookAirballsTagline;

  /// Full description for the Airballs rule
  ///
  /// In en, this message translates to:
  /// **'An airball is a throw that misses every cup without touching anything. When a team accumulates 3 airballs in total, all players must take a penalty sip. The counter resets and keeps climbing.'**
  String get rulebookAirballsDescription;

  /// Airballs activation step 1
  ///
  /// In en, this message translates to:
  /// **'Enable \"Airballs\" in game setup.'**
  String get rulebookAirballsStep1;

  /// Airballs activation step 2
  ///
  /// In en, this message translates to:
  /// **'When a shot misses completely, tap the orange miss zone below the cups.'**
  String get rulebookAirballsStep2;

  /// Airballs activation step 3
  ///
  /// In en, this message translates to:
  /// **'At every 3rd airball, a dialog prompts the penalty.'**
  String get rulebookAirballsStep3;

  /// Tip for the Airballs rule
  ///
  /// In en, this message translates to:
  /// **'The miss zone only appears when the Airballs rule is active — remember to tap it on every complete miss.'**
  String get rulebookAirballsTip;

  /// Tagline for the Bounce rule card
  ///
  /// In en, this message translates to:
  /// **'One ball, two cups — but the defense can swat it.'**
  String get rulebookBounceTagline;

  /// Full description for the Bounce rule
  ///
  /// In en, this message translates to:
  /// **'A bounce shot is a throw where the ball bounces off the table before landing in a cup. It rewards risk: a successful bounce removes the hit cup plus one additional random cup. However, the defending team is allowed to swat the ball away after the first bounce, so it can be blocked.'**
  String get rulebookBounceDescription;

  /// Bounce activation step 1
  ///
  /// In en, this message translates to:
  /// **'Enable \"Bounce\" in game setup.'**
  String get rulebookBounceStep1;

  /// Bounce activation step 2
  ///
  /// In en, this message translates to:
  /// **'During your turn, open the action menu (⋯) and tap \"Bounce Shot\".'**
  String get rulebookBounceStep2;

  /// Bounce activation step 3
  ///
  /// In en, this message translates to:
  /// **'Select who made the bounce, then tap the cup they sank.'**
  String get rulebookBounceStep3;

  /// Tip for the Bounce rule
  ///
  /// In en, this message translates to:
  /// **'Bounce shots are high-risk, high-reward. Save them for when you need to close a gap quickly.'**
  String get rulebookBounceTip;

  /// Tagline for the Putback rule card
  ///
  /// In en, this message translates to:
  /// **'The game isn\'t over until the last redemption throw lands.'**
  String get rulebookPutbackTagline;

  /// Full description for the Putback rule
  ///
  /// In en, this message translates to:
  /// **'When a team sinks the opponent\'s final cup, the losing side earns one redemption throw per player. If any throw lands, the last cup is restored and the game continues into overtime. Every player must attempt their throw before the result is decided.'**
  String get rulebookPutbackDescription;

  /// Putback activation step 1
  ///
  /// In en, this message translates to:
  /// **'Enable \"Putback\" in game setup.'**
  String get rulebookPutbackStep1;

  /// Putback activation step 2
  ///
  /// In en, this message translates to:
  /// **'When the last cup is sunk, the redemption dialog appears automatically.'**
  String get rulebookPutbackStep2;

  /// Putback activation step 3
  ///
  /// In en, this message translates to:
  /// **'Each losing-team player takes one shot. A hit keeps the game alive.'**
  String get rulebookPutbackStep3;

  /// Tip for the Putback rule
  ///
  /// In en, this message translates to:
  /// **'If multiple redemption throws land, only one cup is restored — aim carefully.'**
  String get rulebookPutbackTip;

  /// Tagline for the Island rule card
  ///
  /// In en, this message translates to:
  /// **'An isolated cup means a free bonus cup.'**
  String get rulebookIslandTagline;

  /// Full description for the Island rule
  ///
  /// In en, this message translates to:
  /// **'An island cup is one with no neighbours — completely surrounded by empty space. A designated shooter can call an island shot on it. If they sink it, they win that cup plus a bonus cup of their choice. A miss scores nothing and the attempt is used up.'**
  String get rulebookIslandDescription;

  /// Island activation step 1
  ///
  /// In en, this message translates to:
  /// **'Enable \"Island\" in game setup.'**
  String get rulebookIslandStep1;

  /// Island activation step 2
  ///
  /// In en, this message translates to:
  /// **'Tap \"Island Shot\" in the action menu and select the shooter.'**
  String get rulebookIslandStep2;

  /// Island activation step 3
  ///
  /// In en, this message translates to:
  /// **'Island cups glow yellow. Tap one to take the shot.'**
  String get rulebookIslandStep3;

  /// Island activation step 4
  ///
  /// In en, this message translates to:
  /// **'On success, pick your free bonus cup from the bottom sheet.'**
  String get rulebookIslandStep4;

  /// Tip for the Island rule
  ///
  /// In en, this message translates to:
  /// **'If only one island cup exists, the shot triggers automatically after selecting the shooter — no extra tap needed.'**
  String get rulebookIslandTip;

  /// Tagline for the Deathcup rule card
  ///
  /// In en, this message translates to:
  /// **'Sink the cup being drunk and the game ends instantly.'**
  String get rulebookDeathcupTagline;

  /// Full description for the Deathcup rule
  ///
  /// In en, this message translates to:
  /// **'When the Deathcup rule is active, each cup that has been sunk but not yet fully drunk is a live deathcup. If a player lands a ball in it while an opponent is still drinking, that team immediately loses — all remaining cups are cleared.'**
  String get rulebookDeathcupDescription;

  /// Deathcup activation step 1
  ///
  /// In en, this message translates to:
  /// **'Enable \"Deathcup\" in game setup.'**
  String get rulebookDeathcupStep1;

  /// Deathcup activation step 2
  ///
  /// In en, this message translates to:
  /// **'When a deathcup is sunk, open the action menu (⋯) and tap \"Deathcup\".'**
  String get rulebookDeathcupStep2;

  /// Deathcup activation step 3
  ///
  /// In en, this message translates to:
  /// **'Select the player who made the shot to trigger the instant win.'**
  String get rulebookDeathcupStep3;

  /// Tip for the Deathcup rule
  ///
  /// In en, this message translates to:
  /// **'Keep track of which cups opponents are currently drinking — they\'re your highest-value targets.'**
  String get rulebookDeathcupTip;

  /// Tagline for the Rearrange rule card
  ///
  /// In en, this message translates to:
  /// **'Regroup scattered cups into a tighter formation.'**
  String get rulebookRearrangeTagline;

  /// Full description for the Rearrange rule
  ///
  /// In en, this message translates to:
  /// **'Once per game, when 6 or fewer cups remain on your side, you can call a re-rack. Cups are rearranged into a standard triangle formation, closing the gaps that make individual cups harder to hit. The re-rack can only be used once and only within the 6-cup limit.'**
  String get rulebookRearrangeDescription;

  /// Rearrange activation step 1
  ///
  /// In en, this message translates to:
  /// **'Enable \"Rearrange\" in game setup.'**
  String get rulebookRearrangeStep1;

  /// Rearrange activation step 2
  ///
  /// In en, this message translates to:
  /// **'When 6 or fewer cups remain, tap the re-rack button in the bottom dock bar.'**
  String get rulebookRearrangeStep2;

  /// Rearrange activation step 3
  ///
  /// In en, this message translates to:
  /// **'Cups immediately shift into a compact triangle.'**
  String get rulebookRearrangeStep3;

  /// Tip for the Rearrange rule
  ///
  /// In en, this message translates to:
  /// **'Save your re-rack for when cups are most scattered — a tight triangle is significantly easier to aim at.'**
  String get rulebookRearrangeTip;

  /// Statistics screen tab: stats overview
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTabStats;

  /// Statistics screen tab: performance charts
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get statsTabPerformance;

  /// Statistics screen tab: level and achievement progress
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get statsTabProgress;

  /// Statistics screen tab: game breakdown
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get statsTabBreakdown;

  /// Statistics screen tab: game history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get statsTabHistory;

  /// Prompt shown when user is not signed in on stats screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your statistics'**
  String get statsSignInPrompt;

  /// Error message when game history fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load games'**
  String get statsFailedToLoad;

  /// Empty state when no game history exists
  ///
  /// In en, this message translates to:
  /// **'No games recorded yet.'**
  String get statsNoGamesYet;

  /// Tooltip for live game view button in history
  ///
  /// In en, this message translates to:
  /// **'Live view'**
  String get statsLiveView;

  /// Title of game statistics detail view
  ///
  /// In en, this message translates to:
  /// **'Game Statistics'**
  String get statsGameStatistics;

  /// Button to view team details in a game
  ///
  /// In en, this message translates to:
  /// **'View Team'**
  String get statsViewTeam;

  /// Button to view full game statistics
  ///
  /// In en, this message translates to:
  /// **'View Game Stats'**
  String get statsViewGameStats;

  /// Button to view cup table layout for a game
  ///
  /// In en, this message translates to:
  /// **'View Table'**
  String get statsViewTable;

  /// Table column header: player name
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get statsColumnPlayer;

  /// Table column header: score
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get statsColumnScore;

  /// Table column header: throw count
  ///
  /// In en, this message translates to:
  /// **'Throws'**
  String get statsColumnThrows;

  /// Table column header: miss count (short)
  ///
  /// In en, this message translates to:
  /// **'Miss'**
  String get statsColumnMiss;

  /// Table column header: hit rate percentage
  ///
  /// In en, this message translates to:
  /// **'Hit%'**
  String get statsColumnHitRate;

  /// Table column header: bounce rate
  ///
  /// In en, this message translates to:
  /// **'Bounce'**
  String get statsColumnBounce;

  /// Table column header: defended (putback)
  ///
  /// In en, this message translates to:
  /// **'Def'**
  String get statsColumnDef;

  /// Section header for achievements in game breakdown
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get statsAchievements;

  /// Section header for team stats in game breakdown
  ///
  /// In en, this message translates to:
  /// **'Team Statistics'**
  String get statsTeamStatistics;

  /// Achievement badge: most valuable player
  ///
  /// In en, this message translates to:
  /// **'MVP'**
  String get statsMvp;

  /// Achievement badge: most airballs
  ///
  /// In en, this message translates to:
  /// **'Airballer'**
  String get statsAirballer;

  /// Achievement badge: most misses
  ///
  /// In en, this message translates to:
  /// **'Miss Maniac'**
  String get statsMissManiac;

  /// Achievement badge: best accuracy
  ///
  /// In en, this message translates to:
  /// **'Sniper'**
  String get statsSniper;

  /// Section header for tier roadmap on progress tab
  ///
  /// In en, this message translates to:
  /// **'Tier Roadmap'**
  String get statsTierRoadmap;

  /// Section header for achievement progress on progress tab
  ///
  /// In en, this message translates to:
  /// **'Achievement Progress'**
  String get statsAchievementProgress;

  /// Section header for unlocked titles on progress tab
  ///
  /// In en, this message translates to:
  /// **'Unlocked Titles'**
  String get statsUnlockedTitles;

  /// Section header for near-completion achievements
  ///
  /// In en, this message translates to:
  /// **'Almost There'**
  String get statsAlmostThere;

  /// Label shown when user has reached max level
  ///
  /// In en, this message translates to:
  /// **'Max level reached — {xp} XP total'**
  String statsMaxLevelReached(int xp);

  /// Hint to reach a level to unlock a tier title
  ///
  /// In en, this message translates to:
  /// **'Reach Level {level} to unlock {title}'**
  String statsReachLevelUnlock(int level, String title);

  /// Section title on performance tab
  ///
  /// In en, this message translates to:
  /// **'Performance Summary'**
  String get perfSummaryTitle;

  /// Section title for cup heat map on performance tab
  ///
  /// In en, this message translates to:
  /// **'Cups Hit Heat Map'**
  String get perfHeatMapTitle;

  /// Section title for row accuracy chart on performance tab
  ///
  /// In en, this message translates to:
  /// **'Row Accuracy'**
  String get perfRowAccuracyTitle;

  /// Filter chip: all games
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get perfFilterAll;

  /// Filter chip: last 10 games
  ///
  /// In en, this message translates to:
  /// **'Last 10'**
  String get perfFilterLast10;

  /// Filter chip: last 5 games
  ///
  /// In en, this message translates to:
  /// **'Last 5'**
  String get perfFilterLast5;

  /// Filter chip: last 3 games
  ///
  /// In en, this message translates to:
  /// **'Last 3'**
  String get perfFilterLast3;

  /// Empty state on performance tab
  ///
  /// In en, this message translates to:
  /// **'No data yet.'**
  String get perfNoData;

  /// Row accuracy label: front row
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get perfRowFront;

  /// Row accuracy label: middle row
  ///
  /// In en, this message translates to:
  /// **'Mid'**
  String get perfRowMid;

  /// Row accuracy label: back row
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get perfRowBack;

  /// Row accuracy label: apex (back-most cup)
  ///
  /// In en, this message translates to:
  /// **'Apex'**
  String get perfRowApex;

  /// Stat row label: total score
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get statTotalScore;

  /// Stat row label: total misses
  ///
  /// In en, this message translates to:
  /// **'Total Misses'**
  String get statTotalMisses;

  /// Stat row label: total airballs
  ///
  /// In en, this message translates to:
  /// **'Total Airballs'**
  String get statTotalAirballs;

  /// Stat row label: cups hit
  ///
  /// In en, this message translates to:
  /// **'Cups Hit'**
  String get statCupsHit;

  /// Stat row label: hit rate
  ///
  /// In en, this message translates to:
  /// **'Hit Rate'**
  String get statHitRate;

  /// Stat row label: win rate
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get statWinRate;

  /// Stat row label: bounce rate
  ///
  /// In en, this message translates to:
  /// **'Bounce Rate'**
  String get statBounceRate;

  /// Stat row label: island conversion rate
  ///
  /// In en, this message translates to:
  /// **'Island Conv.'**
  String get statIslandConv;

  /// Stat row label: putback defends
  ///
  /// In en, this message translates to:
  /// **'Defended'**
  String get statDefended;

  /// Stat row label: on-fire count
  ///
  /// In en, this message translates to:
  /// **'On Fire'**
  String get statOnFire;

  /// Stat row label: heating up count
  ///
  /// In en, this message translates to:
  /// **'Heating Up'**
  String get statHeatingUp;

  /// Friends screen tab: friend list
  ///
  /// In en, this message translates to:
  /// **'Friendlist'**
  String get friendsTabFriendlist;

  /// Friends screen tab: leaderboard
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get friendsTabLeaderboard;

  /// Friends screen tab: social feed
  ///
  /// In en, this message translates to:
  /// **'Socials'**
  String get friendsTabSocials;

  /// Prompt shown when user is not signed in on friends screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your friends'**
  String get friendsSignInPrompt;

  /// Error snackbar when trying to add a friend while signed out
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to add friends.'**
  String get friendsMustSignIn;

  /// Empty state on friend list tab
  ///
  /// In en, this message translates to:
  /// **'No friends yet. Add one using the + button above.'**
  String get friendsNoFriends;

  /// Empty state on socials tab when no friends
  ///
  /// In en, this message translates to:
  /// **'Add friends to see activity here.'**
  String get friendsNoActivity;

  /// Empty state on socials tab when friends have no activity
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet.'**
  String get friendsNoRecentActivity;

  /// Empty state when friend search yields no results
  ///
  /// In en, this message translates to:
  /// **'No friends found.'**
  String get friendsNoFriendsFound;

  /// Title of remove-friend confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Remove Friend'**
  String get friendsRemoveTitle;

  /// Body of remove-friend confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Remove {username} from your friends?'**
  String friendsRemoveBody(String username);

  /// Confirm button in remove-friend dialog
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get friendsRemoveConfirm;

  /// Title of add-friend sheet
  ///
  /// In en, this message translates to:
  /// **'Add a Friend'**
  String get friendsAddTitle;

  /// Hint text in username search field
  ///
  /// In en, this message translates to:
  /// **'Search by username…'**
  String get friendsSearchHint;

  /// Empty state in user search
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get friendsNoUsersFound;

  /// Button to add a found user as friend
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get friendsAddBtn;

  /// Section title for QR code sharing in add-friend sheet
  ///
  /// In en, this message translates to:
  /// **'Share / Scan QR'**
  String get friendsShareQr;

  /// Snackbar after copying user ID to clipboard
  ///
  /// In en, this message translates to:
  /// **'ID copied to clipboard'**
  String get friendsIdCopied;

  /// Button to scan a QR code to add a friend
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get friendsScanQrBtn;

  /// Button to spectate a friend's live game
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get friendsWatchBtn;

  /// Shop screen tab: avatar items
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get shopTabAvatar;

  /// Shop screen tab: user card backgrounds
  ///
  /// In en, this message translates to:
  /// **'User Card'**
  String get shopTabUserCard;

  /// Shop screen tab: in-game cosmetics
  ///
  /// In en, this message translates to:
  /// **'In Game'**
  String get shopTabInGame;

  /// Prompt shown when user is not signed in on shop screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to earn Stars'**
  String get shopSignInEarnStars;

  /// Button / sheet title to acquire stars
  ///
  /// In en, this message translates to:
  /// **'Get Stars'**
  String get shopGetStars;

  /// Subtitle on the get-stars sheet
  ///
  /// In en, this message translates to:
  /// **'Earn ⭐ stars to spend in the shop.'**
  String get shopEarnStarsHint;

  /// Dialog title after supporter purchase
  ///
  /// In en, this message translates to:
  /// **'Thank you! ⭐'**
  String get shopSupporterTitle;

  /// Dialog body after supporter purchase
  ///
  /// In en, this message translates to:
  /// **'You\'re now a Supporter! Your Supporter badge is live on your profile, and you\'re helping keep the app running. Thank you!'**
  String get shopSupporterBody;

  /// Dismiss button on supporter thank-you dialog
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get shopSupporterBtn;

  /// Snackbar shown when stars are awarded after purchase
  ///
  /// In en, this message translates to:
  /// **'You got {count} ⭐!'**
  String shopStarsAwarded(int count);

  /// Snackbar when an in-app purchase fails
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {message}'**
  String shopPurchaseFailed(String message);

  /// Snackbar when no rewarded ad is available
  ///
  /// In en, this message translates to:
  /// **'No ad available right now. Try again later.'**
  String get shopNoAdAvailable;

  /// Snackbar after watching a rewarded ad
  ///
  /// In en, this message translates to:
  /// **'You earned 50 ⭐!'**
  String get shopEarned50Stars;

  /// Hint text at bottom of get-stars sheet
  ///
  /// In en, this message translates to:
  /// **'Earn stars for free by playing games!'**
  String get shopEarnFreeStars;

  /// Button to restore previous in-app purchases
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get shopRestorePurchases;

  /// Label on rewarded ad button
  ///
  /// In en, this message translates to:
  /// **'Watch a short video'**
  String get shopWatchVideo;

  /// Label on rewarded ad button when daily limit hit
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached — come back tomorrow'**
  String get shopDailyLimitReached;

  /// Badge label shown when user is already a supporter
  ///
  /// In en, this message translates to:
  /// **'You\'re a Supporter ✓'**
  String get shopSupporterBadge;

  /// Generic buy button in the shop
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get shopBuyBtn;

  /// Badge label on shop items not yet available
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get shopComingSoon;

  /// Account screen title / section header
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get accountProfile;

  /// Badge label shown next to username for supporters
  ///
  /// In en, this message translates to:
  /// **'Supporter'**
  String get accountSupporter;

  /// Tooltip on feedback icon button
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get accountFeedbackTooltip;

  /// Tooltip on sign-out icon button
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOutTooltip;

  /// Title of sign-out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get accountSignOutTitle;

  /// Body of sign-out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'You will be returned to the sign-in screen.'**
  String get accountSignOutBody;

  /// Confirm button in sign-out dialog
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOutConfirm;

  /// Achievement tier: Bronze
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get achievementStagesBronze;

  /// Achievement tier: Silver
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get achievementStagesSilver;

  /// Achievement tier: Gold
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get achievementStagesGold;

  /// Achievement tier: Diamond
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get achievementStagesDiamond;

  /// Label when all achievement stages are completed
  ///
  /// In en, this message translates to:
  /// **'Maxed!'**
  String get achievementMaxed;

  /// Label in achievement detail when fully mastered
  ///
  /// In en, this message translates to:
  /// **'Fully mastered!'**
  String get achievementFullyMastered;

  /// Progress indicator in achievement detail dialog
  ///
  /// In en, this message translates to:
  /// **'Progress: {current} / {next}'**
  String achievementProgress(int current, int next);

  /// Label showing which title an achievement stage unlocks
  ///
  /// In en, this message translates to:
  /// **'Unlocks title: \"{title}\"'**
  String achievementUnlocksTitle(String title);

  /// Section header for username on profile edit screen
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileSectionUsername;

  /// Section header for avatar selection
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get profileSectionAvatar;

  /// Section header for background selection
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get profileSectionBackground;

  /// Section header for title selection
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get profileSectionTitle;

  /// Hint text for username input field
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get profileUsernamePlaceholder;

  /// Username availability status: checking
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get profileUsernameChecking;

  /// Username availability status: available
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get profileUsernameAvailable;

  /// Username availability status: taken
  ///
  /// In en, this message translates to:
  /// **'Already taken'**
  String get profileUsernameTaken;

  /// Username validation hint when format is invalid
  ///
  /// In en, this message translates to:
  /// **'3–20 chars, letters/numbers/underscores/spaces, no consecutive __ or spaces'**
  String get profileUsernameInvalid;

  /// Snackbar after successfully saving profile
  ///
  /// In en, this message translates to:
  /// **'Profile updated!'**
  String get profileUpdated;

  /// Snackbar when profile save fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String profileSaveFailed(String error);

  /// Lock label showing required level for locked avatar/background
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String profileLevelRequired(int level);

  /// Game-over dialog body showing winner names
  ///
  /// In en, this message translates to:
  /// **'{winners} have won the game!'**
  String dialogGameOverWinners(String winners);

  /// Label in level card when user is at max level
  ///
  /// In en, this message translates to:
  /// **'Max level reached'**
  String get achievementsMaxLevel;

  /// XP progress line in level card
  ///
  /// In en, this message translates to:
  /// **'{xp} XP · {toNext} XP to Level {nextLevel}'**
  String achievementsXpProgress(int xp, int toNext, int nextLevel);

  /// Stat chip label for best win streak in achievements screen
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get achievementsBestStreak;

  /// Prompt shown when browsing shop while not signed in
  ///
  /// In en, this message translates to:
  /// **'Sign in to browse the shop'**
  String get shopSignInBrowse;

  /// Section header for profile-picture items in avatar shop
  ///
  /// In en, this message translates to:
  /// **'Profile Pictures'**
  String get shopSectionProfilePictures;

  /// Section header for border items in avatar shop
  ///
  /// In en, this message translates to:
  /// **'Avatar Borders'**
  String get shopSectionAvatarBorders;

  /// Section header for emblem items in avatar shop
  ///
  /// In en, this message translates to:
  /// **'Emblems & Medals'**
  String get shopSectionEmblemsAndMedals;

  /// Section header for cup skin items in in-game shop
  ///
  /// In en, this message translates to:
  /// **'Cup Skins'**
  String get shopSectionCupSkins;

  /// Section header for table theme items in in-game shop
  ///
  /// In en, this message translates to:
  /// **'Table Themes'**
  String get shopSectionTableThemes;

  /// Section header for title items in user card shop
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get shopSectionTitles;

  /// Section header for background items in user card shop
  ///
  /// In en, this message translates to:
  /// **'Card Backgrounds'**
  String get shopSectionCardBackgrounds;

  /// Info note explaining how card backgrounds are unlocked
  ///
  /// In en, this message translates to:
  /// **'Card backgrounds are unlocked for free by levelling up. Manage them in your profile.'**
  String get shopCardBackgroundsNote;

  /// Button to equip an owned in-game item
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get shopEquip;

  /// Button to unequip an equipped in-game item
  ///
  /// In en, this message translates to:
  /// **'Unequip'**
  String get shopUnequip;

  /// Label showing user's current star balance in purchase dialog
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get shopYourBalance;

  /// Label showing item cost in purchase dialog
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get shopCost;

  /// Buy button label in purchase dialog
  ///
  /// In en, this message translates to:
  /// **'Buy for ⭐ {price}'**
  String shopBuyForStars(int price);

  /// Message when user cannot afford an item
  ///
  /// In en, this message translates to:
  /// **'You need {count} more ⭐ to buy this.'**
  String shopNeedMoreStars(int count);

  /// Button to open the get-stars sheet from the purchase dialog
  ///
  /// In en, this message translates to:
  /// **'Get More Stars'**
  String get shopGetMoreStars;

  /// Snackbar shown after successfully buying a shop item
  ///
  /// In en, this message translates to:
  /// **'{name} purchased! ⭐'**
  String shopItemPurchased(String name);

  /// Snackbar shown when purchase fails due to insufficient stars
  ///
  /// In en, this message translates to:
  /// **'Not enough stars!'**
  String get shopNotEnoughStars;

  /// Bottom nav label: shop
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShop;

  /// Bottom nav label: friends
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get navFriends;

  /// Bottom nav label: home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav label: games
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get navGames;

  /// Bottom nav label: profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Setting toggle label for dark mode
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// Setting row label for privacy settings
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get settingsPrivacy;

  /// Setting row label for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Title of the feedback bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get feedbackSheetTitle;

  /// Hint text in feedback text field
  ///
  /// In en, this message translates to:
  /// **'Describe the issue or idea…'**
  String get feedbackHint;

  /// Send button on feedback sheet
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get feedbackSend;

  /// Snackbar after feedback is submitted
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get feedbackSuccess;

  /// Snackbar when feedback submission fails
  ///
  /// In en, this message translates to:
  /// **'Could not send feedback. Try again.'**
  String get feedbackError;

  /// Feedback category: bug report
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get feedbackCategoryBug;

  /// Feedback category: suggestion
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get feedbackCategorySuggestion;

  /// Feedback category: other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get feedbackCategoryOther;

  /// AppBar title on the invitation inbox screen
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitationsTitle;

  /// Message shown on invitation screen when not signed in
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get invitationsNotSignedIn;

  /// Empty state on invitation inbox screen
  ///
  /// In en, this message translates to:
  /// **'No pending invitations'**
  String get invitationsNoPending;

  /// Snackbar after declining an invitation
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get invitationsDeclined;

  /// Button to decline an invitation
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get invitationsDeclineBtn;

  /// Button to accept an invitation
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get invitationsAcceptBtn;

  /// Fallback sender name when username is missing
  ///
  /// In en, this message translates to:
  /// **'A player'**
  String get invitationsFromPlayer;

  /// Invitation card subtitle for a game invite
  ///
  /// In en, this message translates to:
  /// **'Invited you to a Game'**
  String get invitationsInvitedToGame;

  /// Invitation card subtitle for a tournament invite
  ///
  /// In en, this message translates to:
  /// **'Invited you to a Tournament'**
  String get invitationsInvitedToTournament;

  /// AppBar title on the waiting-for-game screen
  ///
  /// In en, this message translates to:
  /// **'Waiting…'**
  String get waitingTitle;

  /// Message shown while waiting for host to start a game
  ///
  /// In en, this message translates to:
  /// **'Waiting for {host} to start the game…'**
  String waitingForGame(String host);

  /// Message shown while waiting for host to start a tournament
  ///
  /// In en, this message translates to:
  /// **'Waiting for {host} to start the tournament…'**
  String waitingForTournament(String host);

  /// AppBar title when watching a live in-progress game
  ///
  /// In en, this message translates to:
  /// **'Live Game'**
  String get liveGameTitle;

  /// AppBar title when the game is over and showing summary
  ///
  /// In en, this message translates to:
  /// **'Game Summary'**
  String get liveGameSummary;

  /// Live-ticker tab: cup table
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get liveTabTable;

  /// Live-ticker tab: stats
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get liveTabStats;

  /// Live-ticker tab: event timeline
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get liveTabTimeline;

  /// Message shown when a live game cannot be found
  ///
  /// In en, this message translates to:
  /// **'Game not found.'**
  String get liveGameNotFound;

  /// Generic error message on live game screen
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get liveGameError;

  /// Badge label shown on an in-progress live game
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveBadgeLive;

  /// Badge label shown when a game is finished
  ///
  /// In en, this message translates to:
  /// **'FINAL'**
  String get liveBadgeFinal;

  /// Column header for accuracy percentage in live match stats
  ///
  /// In en, this message translates to:
  /// **'Accuracy %'**
  String get liveStatsAccuracy;

  /// Empty state on the timeline tab
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get liveTimelineNoEvents;

  /// Round header in the timeline tab
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String liveTimelineRound(int number);

  /// End-of-turn marker in the timeline tab
  ///
  /// In en, this message translates to:
  /// **'End of turn · {time}'**
  String liveTimelineEndOfTurn(String time);

  /// Timeline event label: normal hit
  ///
  /// In en, this message translates to:
  /// **'Hit'**
  String get liveEventHit;

  /// Timeline event label: bounce shot
  ///
  /// In en, this message translates to:
  /// **'Bounce'**
  String get liveEventBounce;

  /// Timeline event label: island shot
  ///
  /// In en, this message translates to:
  /// **'Island'**
  String get liveEventIsland;

  /// Timeline event label: death cup
  ///
  /// In en, this message translates to:
  /// **'Death Cup'**
  String get liveEventDeathCup;

  /// Timeline event label: airball
  ///
  /// In en, this message translates to:
  /// **'Airball'**
  String get liveEventAirball;

  /// Timeline event label: bitch cup
  ///
  /// In en, this message translates to:
  /// **'Bitch Cup'**
  String get liveEventBitchCup;

  /// Timeline event label: on fire
  ///
  /// In en, this message translates to:
  /// **'On Fire'**
  String get liveEventOnFire;

  /// AppBar title on spectate lobby screen
  ///
  /// In en, this message translates to:
  /// **'Lobby'**
  String get spectatelobbyTitle;

  /// AppBar title on spectate lobby screen once game loaded
  ///
  /// In en, this message translates to:
  /// **'Game Lobby'**
  String get spectateLobbyGameTitle;

  /// Error message when game data can't be loaded in spectate lobby
  ///
  /// In en, this message translates to:
  /// **'Error loading game.'**
  String get spectateLobbyError;

  /// Empty state when no players have joined yet in spectate lobby
  ///
  /// In en, this message translates to:
  /// **'No players yet'**
  String get spectateLobbyNoPlayers;

  /// Section header for game settings in spectate lobby
  ///
  /// In en, this message translates to:
  /// **'Game Settings'**
  String get spectateLobbyGameSettings;

  /// Settings row label for game mode in spectate lobby
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get spectateLobbyMode;

  /// Settings row label for starting team in spectate lobby
  ///
  /// In en, this message translates to:
  /// **'Starting Team'**
  String get spectateLobbyStartingTeam;

  /// Message shown while waiting for host to start in spectate lobby
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host to start the game…'**
  String get spectateLobbyWaiting;

  /// Button to leave / exit a lobby or screen
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get btnLeave;

  /// Cups remaining counter shown under team name in live game header
  ///
  /// In en, this message translates to:
  /// **'{count} cups left'**
  String liveCupsLeft(int count);

  /// Stat column/row label for score in live match stats
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get liveStatScore;

  /// Stat column/row label for throws in live match stats
  ///
  /// In en, this message translates to:
  /// **'Throws'**
  String get liveStatThrows;

  /// Stat column/row label for airballs in live match stats
  ///
  /// In en, this message translates to:
  /// **'Airballs'**
  String get liveStatAirballs;

  /// Stat column/row label for misses in live match stats
  ///
  /// In en, this message translates to:
  /// **'Misses'**
  String get liveStatMisses;

  /// Stat column/row label for cups hit in live cup layout tab
  ///
  /// In en, this message translates to:
  /// **'Cups Hit'**
  String get liveStatCupsHit;

  /// Button label indicating which team starts the game
  ///
  /// In en, this message translates to:
  /// **'{team} starts'**
  String gameModeTeamStarts(String team);

  /// Dialog title when all tournament matches have been played
  ///
  /// In en, this message translates to:
  /// **'Tournament Complete!'**
  String get tournamentCompleteTitle;

  /// Dialog body when tournament is complete
  ///
  /// In en, this message translates to:
  /// **'All matches have been played.\nCheck out the standings!'**
  String get tournamentCompleteBody;

  /// Singular label for a player (e.g. column header)
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get labelPlayer;

  /// Screen title for friend stat comparison screen
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get compareTitle;

  /// Section header for the radar overview in compare screen
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get compareOverview;

  /// Section header for stat comparison bars in compare screen
  ///
  /// In en, this message translates to:
  /// **'STAT COMPARISON'**
  String get compareStatComparison;

  /// Stat row label: bounce shot percentage
  ///
  /// In en, this message translates to:
  /// **'Bounce %'**
  String get compareBouncePercent;

  /// Stat row label: island shot percentage
  ///
  /// In en, this message translates to:
  /// **'Island %'**
  String get compareIslandPercent;

  /// Stat row label: total wins
  ///
  /// In en, this message translates to:
  /// **'Total Wins'**
  String get compareTotalWins;

  /// Stat row label: on-fire count
  ///
  /// In en, this message translates to:
  /// **'On Fire'**
  String get compareOnFire;

  /// Section title for shot distribution donut chart
  ///
  /// In en, this message translates to:
  /// **'Shot Distribution'**
  String get breakdownShotDistribution;

  /// Section title for special shots breakdown
  ///
  /// In en, this message translates to:
  /// **'Special Shots'**
  String get breakdownSpecialShots;

  /// Section title for win context (win margin, clutch) breakdown
  ///
  /// In en, this message translates to:
  /// **'Win Context'**
  String get breakdownWinContext;

  /// Section title for head-to-head opponent breakdown
  ///
  /// In en, this message translates to:
  /// **'Head to Head'**
  String get breakdownHeadToHead;

  /// Lowercase label shown beneath total throws count in donut chart
  ///
  /// In en, this message translates to:
  /// **'throws'**
  String get breakdownThrowsLabel;

  /// Legend label for hits in shot donut chart
  ///
  /// In en, this message translates to:
  /// **'Hits'**
  String get breakdownHits;

  /// Label for bounce shot card in special shots section
  ///
  /// In en, this message translates to:
  /// **'Bounce Shot'**
  String get breakdownBounceShot;

  /// Label for island shot card in special shots section
  ///
  /// In en, this message translates to:
  /// **'Island Shot'**
  String get breakdownIslandShot;

  /// Card title for win margin distribution bar chart
  ///
  /// In en, this message translates to:
  /// **'Win Margin Distribution'**
  String get breakdownWinMarginTitle;

  /// Win margin bucket: dominant win with 5+ cups remaining
  ///
  /// In en, this message translates to:
  /// **'Dominant (5+ cups)'**
  String get breakdownDominant;

  /// Win margin bucket: comfortable win with 3–4 cups remaining
  ///
  /// In en, this message translates to:
  /// **'Comfortable (3–4)'**
  String get breakdownComfortable;

  /// Win margin bucket: close win with 1–2 cups remaining
  ///
  /// In en, this message translates to:
  /// **'Close (1–2)'**
  String get breakdownClose;

  /// Card label for clutch rate metric
  ///
  /// In en, this message translates to:
  /// **'Clutch Rate'**
  String get breakdownClutchRate;

  /// Description below clutch rate label
  ///
  /// In en, this message translates to:
  /// **'Hit the last cup to win'**
  String get breakdownClutchDesc;

  /// Empty state when no games have been recorded
  ///
  /// In en, this message translates to:
  /// **'No games recorded yet.'**
  String get breakdownNoGames;

  /// Empty state when no head-to-head opponents found
  ///
  /// In en, this message translates to:
  /// **'No opponents found.'**
  String get breakdownNoOpponents;

  /// Empty state when no throws have been recorded
  ///
  /// In en, this message translates to:
  /// **'No throws recorded yet.'**
  String get breakdownNoThrows;

  /// Button label to navigate to the achievements screen
  ///
  /// In en, this message translates to:
  /// **'View all achievements'**
  String get statsViewAllAchievements;

  /// Abbreviated column header for Score in player stats table
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get statsColAbbrevScore;

  /// Abbreviated column header for Misses in player stats table
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get statsColAbbrevMisses;

  /// Abbreviated column header for Throws in player stats table
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get statsColAbbrevThrows;

  /// Abbreviated column header for Airballs in player stats table
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get statsColAbbrevAirballs;

  /// Abbreviated column header for Hit Rate in player stats table
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get statsColAbbrevHitRate;

  /// Section header for career highlights in personal stats
  ///
  /// In en, this message translates to:
  /// **'CAREER HIGHLIGHTS'**
  String get statsCareerHighlights;

  /// Career highlight card label for longest win streak
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get statsBestStreak;

  /// Career highlight card label for best single-game hit rate
  ///
  /// In en, this message translates to:
  /// **'Best Hit Rate'**
  String get statsBestHitRate;

  /// Career highlight card label for most cups in a single game
  ///
  /// In en, this message translates to:
  /// **'Most Cups'**
  String get statsMostCups;

  /// Section header for the recent form W/L strip
  ///
  /// In en, this message translates to:
  /// **'Recent Form'**
  String get statsRecentForm;

  /// Stat tile label for total wins
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get statsWins;

  /// Stat tile label for total losses
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get statsLosses;

  /// Stat tile / chip label for win rate percentage
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get statsWinRate;

  /// Stat tile / chip label for hit rate percentage
  ///
  /// In en, this message translates to:
  /// **'Hit Rate'**
  String get statsHitRate;

  /// Stat tile label for on-fire count
  ///
  /// In en, this message translates to:
  /// **'On Fire'**
  String get statsOnFire;

  /// Stat tile label for bounce shot conversion percentage
  ///
  /// In en, this message translates to:
  /// **'Bounce%'**
  String get statsBouncePercent;

  /// Stat tile label for island shot makes
  ///
  /// In en, this message translates to:
  /// **'Islands'**
  String get statsIslands;

  /// Stat tile / shot card label for defended shots
  ///
  /// In en, this message translates to:
  /// **'Defended'**
  String get statsDefended;

  /// Stat tile label for heating-up count
  ///
  /// In en, this message translates to:
  /// **'Heating Up'**
  String get statsHeatingUp;

  /// Stat tile label for last-cup (clutch) hits
  ///
  /// In en, this message translates to:
  /// **'Last Cup'**
  String get statsLastCup;

  /// Stat tile label for average cups per game
  ///
  /// In en, this message translates to:
  /// **'Avg/Game'**
  String get statsAvgPerGame;

  /// Stat tile label for night games played
  ///
  /// In en, this message translates to:
  /// **'Night Games'**
  String get statsNightGames;

  /// Label on the cups-per-game derived chip
  ///
  /// In en, this message translates to:
  /// **'cups/game'**
  String get statsCupsPerGame;

  /// Label on the throws-per-game derived chip
  ///
  /// In en, this message translates to:
  /// **'throws/game'**
  String get statsThrowsPerGame;

  /// Streak chip text, e.g. '3-game W streak'
  ///
  /// In en, this message translates to:
  /// **'{count}-game {type} streak'**
  String statsStreakChip(int count, String type);

  /// Current streak label in the stats screen, e.g. 'Current streak: 3W'
  ///
  /// In en, this message translates to:
  /// **'Current streak: {label}'**
  String statsCurrentStreak(String label);

  /// Recent record summary, e.g. 'Last 10:  7W  3L'
  ///
  /// In en, this message translates to:
  /// **'Last {count}:  {wins}W  {losses}L'**
  String statsLast10Record(int count, int wins, int losses);

  /// XP progress line below the level bar
  ///
  /// In en, this message translates to:
  /// **'{xp} XP · {toNext} XP to Level {level}'**
  String statsXpProgress(int xp, int toNext, int level);

  /// Radar chart axis label for win rate
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get compareWinRate;

  /// Radar chart axis label for hit rate
  ///
  /// In en, this message translates to:
  /// **'Hit Rate'**
  String get compareHitRate;

  /// Fallback IAP row title for the starter star pack
  ///
  /// In en, this message translates to:
  /// **'Starter Pack  ·  €1.99'**
  String get shopStarterPackTitle;

  /// Fallback IAP row subtitle for the starter star pack
  ///
  /// In en, this message translates to:
  /// **'200 ⭐'**
  String get shopStarterPackSubtitle;

  /// Fallback IAP row title for the popular star pack
  ///
  /// In en, this message translates to:
  /// **'Popular Pack  ·  €4.99'**
  String get shopPopularPackTitle;

  /// Fallback IAP row subtitle for the popular star pack
  ///
  /// In en, this message translates to:
  /// **'600 ⭐  ·  Best value'**
  String get shopPopularPackSubtitle;

  /// Fallback IAP row title for the mega star pack
  ///
  /// In en, this message translates to:
  /// **'Mega Pack  ·  €9.99'**
  String get shopMegaPackTitle;

  /// Fallback IAP row subtitle for the mega star pack
  ///
  /// In en, this message translates to:
  /// **'1 500 ⭐'**
  String get shopMegaPackSubtitle;

  /// Fallback IAP row title for the supporter pack
  ///
  /// In en, this message translates to:
  /// **'Supporter Pack  ·  €2.99'**
  String get shopSupporterPackFull;

  /// Fallback IAP row subtitle for the supporter pack
  ///
  /// In en, this message translates to:
  /// **'300 ⭐  ·  Supporter badge on your profile'**
  String get shopSupporterPackFullSubtitle;

  /// Subtitle on the watch-a-video row showing daily ad quota
  ///
  /// In en, this message translates to:
  /// **'+50 ⭐  ·  {remaining} of {total} watches remaining today'**
  String shopWatchesRemaining(int remaining, int total);

  /// Social feed event title when current user won against a friend
  ///
  /// In en, this message translates to:
  /// **'Beat {username}'**
  String socialBeatFriend(String username);

  /// Social feed event title when current user lost to a friend
  ///
  /// In en, this message translates to:
  /// **'Lost to {username}'**
  String socialLostToFriend(String username);

  /// Social feed shared game subtitle showing scores and hit rate
  ///
  /// In en, this message translates to:
  /// **'{myScore}–{oppScore} · {hitPct}% hit rate'**
  String socialSharedGameResult(int myScore, int oppScore, int hitPct);

  /// Social feed title for a current win streak
  ///
  /// In en, this message translates to:
  /// **'🔥 {count}-game win streak!'**
  String socialWinStreak(int count);

  /// Social feed subtitle below the win streak card
  ///
  /// In en, this message translates to:
  /// **'You\'re on fire — keep the momentum going.'**
  String get socialWinStreakSubtitle;

  /// Social feed achievement title when a friend hits a win milestone
  ///
  /// In en, this message translates to:
  /// **'🏆 {username} reached {count} wins'**
  String socialFriendReachedWins(String username, int count);

  /// Social feed subtitle below a friend's win milestone card
  ///
  /// In en, this message translates to:
  /// **'A true beer pong legend.'**
  String get socialFriendLegendSubtitle;

  /// Social feed achievement title when a friend hits an on-fire milestone
  ///
  /// In en, this message translates to:
  /// **'🔥 {username} went on fire {count}+ times'**
  String socialFriendOnFire(String username, int count);

  /// Social feed subtitle below a friend's on-fire milestone card
  ///
  /// In en, this message translates to:
  /// **'Serious heat.'**
  String get socialSeriousHeatSubtitle;

  /// Social feed title for a recently active friend
  ///
  /// In en, this message translates to:
  /// **'{username} is active'**
  String socialFriendIsActive(String username);

  /// Social feed subtitle for a recently active friend
  ///
  /// In en, this message translates to:
  /// **'Played {timeAgo} · {totalGames} total games'**
  String socialFriendActiveSubtitle(String timeAgo, int totalGames);

  /// Leaderboard sort chip label for total score
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get leaderboardTotalScore;

  /// Leaderboard sort chip label for games played
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get leaderboardGames;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
