// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Beerpong Companion';

  @override
  String get btnCancel => 'Abbrechen';

  @override
  String get btnSave => 'Speichern';

  @override
  String get btnSaving => 'Speichern…';

  @override
  String get btnAdd => 'Hinzufügen';

  @override
  String get btnClose => 'Schließen';

  @override
  String get btnOk => 'OK';

  @override
  String get btnSignInGoogle => 'Mit Google anmelden';

  @override
  String get labelTeamBlue => 'Team Blau';

  @override
  String get labelTeamRed => 'Team Rot';

  @override
  String get labelVs => 'VS';

  @override
  String get labelRules => 'Regeln';

  @override
  String get labelPlayers => 'Spieler';

  @override
  String get labelTeams => 'Teams';

  @override
  String get labelTournament => 'Turnier';

  @override
  String labelLevelShort(int level) {
    return 'Lv $level';
  }

  @override
  String get loginTagline => 'Tracke dein Spiel. Beherrsche den Tisch.';

  @override
  String get loginToggleSignIn => 'Anmelden';

  @override
  String get loginToggleRegister => 'Registrieren';

  @override
  String get loginFieldUsername => 'Benutzername';

  @override
  String get loginFieldEmail => 'E-Mail';

  @override
  String get loginFieldPassword => 'Passwort';

  @override
  String get loginValidateUsername => 'Benutzernamen eingeben';

  @override
  String get loginValidateEmail => 'Gültige E-Mail eingeben';

  @override
  String get loginValidatePassword => 'Mindestens 6 Zeichen';

  @override
  String get loginForgotPassword => 'Passwort vergessen?';

  @override
  String get loginBtnSignIn => 'Anmelden';

  @override
  String get loginBtnCreateAccount => 'Konto erstellen';

  @override
  String get loginOrContinueWith => 'oder weiter mit';

  @override
  String get loginContinueGoogle => 'Weiter mit Google';

  @override
  String get loginContinueApple => 'Weiter mit Apple';

  @override
  String get loginErrorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get loginErrorGoogle =>
      'Google-Anmeldung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get loginErrorApple =>
      'Apple-Anmeldung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get loginErrorEmailFirst => 'Gib zuerst deine E-Mail-Adresse ein.';

  @override
  String get loginResetEmailSent =>
      'E-Mail zum Zurücksetzen des Passworts gesendet!';

  @override
  String get loginErrorResetFailed =>
      'E-Mail konnte nicht gesendet werden. Überprüfe die Adresse.';

  @override
  String get loginErrUserNotFound => 'Kein Konto mit dieser E-Mail gefunden.';

  @override
  String get loginErrWrongPassword => 'Falsche E-Mail oder falsches Passwort.';

  @override
  String get loginErrEmailInUse =>
      'Ein Konto mit dieser E-Mail existiert bereits.';

  @override
  String get loginErrWeakPassword =>
      'Das Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get loginErrInvalidEmail =>
      'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get loginErrTooManyRequests =>
      'Zu viele Versuche. Bitte versuche es später erneut.';

  @override
  String get loginErrAuthFailed =>
      'Authentifizierung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get homeLetsPlay => 'Los geht\'s!';

  @override
  String get homeBeerPong => 'Beer Pong';

  @override
  String get homeBtnNewGame => 'Neues Spiel';

  @override
  String get homeResumeTitle => 'Spiel fortsetzen';

  @override
  String get homeResumeSubtitle => 'Setze dein letztes Spiel fort';

  @override
  String homePendingInvitations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Du hast $count ausstehende Einladungen',
      one: 'Du hast 1 ausstehende Einladung',
    );
    return '$_temp0';
  }

  @override
  String get homeRulebookTitle => 'Regelbuch';

  @override
  String get homeRulebookSubtitle =>
      'Erfahre, wie jede Sonderregel funktioniert';

  @override
  String get homeNewGameDialogTitle => 'Neues Spiel';

  @override
  String get homeNewGameDialogContent =>
      'Ein neues Spiel zu starten löscht das aktuelle Spiel. Möchtest du fortfahren?';

  @override
  String get homeNewGameDialogConfirm => 'Neues Spiel starten';

  @override
  String get homeGameModeTitle => 'Beerpong spielen';

  @override
  String get homeGameModeSubtitle => 'Schnelle, spaßige Runden';

  @override
  String get homeTournamentTitle => 'Turnier';

  @override
  String get homeTournamentSubtitle => 'Turniermodus mit Bracket';

  @override
  String get gameModeRuleAirballs => 'Airballs';

  @override
  String get gameModeRuleBounce => 'Bounce';

  @override
  String get gameModeRulePutback => 'Nachwurf';

  @override
  String get gameModeRuleIsland => 'Island';

  @override
  String get gameModeRuleDeathcup => 'Deathcup';

  @override
  String get gameModeRuleRearrange => 'Umstellen';

  @override
  String get gameModeNoUser => 'Kein Benutzer angemeldet!';

  @override
  String get gameModeNoFriends => 'Keine Freunde gefunden!';

  @override
  String gameModeInvited(String username) {
    return '$username eingeladen';
  }

  @override
  String get gameModeInvitationDeclined => 'Einladung abgelehnt';

  @override
  String get gameModeBtnStartGame => 'Spiel starten';

  @override
  String get gameModeBtnStartTournament => 'Turnier starten';

  @override
  String get gameModeDialogSelectPlayer => 'Spieler auswählen';

  @override
  String get gameModeYourself => 'Du selbst';

  @override
  String get gameModeFriends => 'Freunde';

  @override
  String get gameModeWhoStarts => 'Wer fängt an?';

  @override
  String get gameModeWhichTeamStarts => 'Welches Team soll anfangen?';

  @override
  String get gameModeTeamBlueStarts => 'Team Blau fängt an';

  @override
  String get gameModeTeamRedStarts => 'Team Rot fängt an';

  @override
  String get gameModeToggleSingleGame => 'Einzelspiel';

  @override
  String get gameModeLabelBlue => 'BLAU';

  @override
  String get gameModeLabelRed => 'ROT';

  @override
  String get gameModeLabelPlayersUpper => 'SPIELER';

  @override
  String get gameModeAddPlayer => 'Spieler hinzufügen';

  @override
  String gameModePlayerN(int number) {
    return 'Spieler $number';
  }

  @override
  String get gameLoadingTitle => 'Spiel';

  @override
  String get gameTapCupSank => 'Tippe auf den getroffenen Becher';

  @override
  String gameTeamTurn(String teamName) {
    return '$teamName ist dran';
  }

  @override
  String get gameNavTable => 'Tisch';

  @override
  String get gameNavStats => 'Statistik';

  @override
  String get gameVs => 'vs';

  @override
  String get gameMissZone => 'Fehlzone — tippen für Airball';

  @override
  String get gameTeamStatistics => 'Teamstatistiken';

  @override
  String get gameStatsPlayer => 'Spieler';

  @override
  String get gameStatsScore => 'Punkte';

  @override
  String get gameStatsThrows => 'Würfe';

  @override
  String get gameStatsMisses => 'Fehlwürfe';

  @override
  String get gameStatsAirballs => 'Airballs';

  @override
  String get gameUndoLabel => 'Rückgängig';

  @override
  String get gameCupsLabel => 'Becher';

  @override
  String get gameMoreLabel => 'Mehr';

  @override
  String get gameEndTurnLabel => 'Zug beenden';

  @override
  String get gameDeathCupLabel => 'Deathcup';

  @override
  String get gameIslandShotLabel => 'Island Shot';

  @override
  String get gameBounceShotLabel => 'Bounce Shot';

  @override
  String get gameRearrangeCupsLabel => 'Becher umstellen';

  @override
  String get gameSelectPlayer => 'Spieler auswählen';

  @override
  String get gameWhoMadeIslandShot => 'Wer hat den Island Shot gemacht?';

  @override
  String get gameBounceSelectThrower => 'Bounce Shot — Werfer auswählen';

  @override
  String get gameEnemyLastTurn => 'Letzter Zug des Gegnerteams';

  @override
  String get gameBonusCupTitle => 'Wähle deinen Gratisbecher';

  @override
  String get gameBonusCupSubtitle =>
      'Island-Shot-Belohnung — wähle einen beliebigen Becher';

  @override
  String get gameBonusCupSkip => 'Bonus überspringen';

  @override
  String get gameLeaveTitle => 'Spiel verlassen?';

  @override
  String get gameLeaveContent =>
      'Dein Spiel wird automatisch gespeichert. Du kannst es vom Startbildschirm aus fortsetzen.';

  @override
  String get gameLeaveStay => 'Bleiben';

  @override
  String get gameLeaveLeave => 'Verlassen';

  @override
  String get dialogSelectPlayerBody =>
      'Wähle den Spieler für die Becheraktion:';

  @override
  String get dialogRearrangeErrorTitle => 'Umstellungsfehler!';

  @override
  String get dialogRearrangeErrorBody =>
      'Du kannst nur umstellen, wenn du 6 oder weniger Becher hast!';

  @override
  String get dialogEndTurnTitle => 'Zug beenden!';

  @override
  String get dialogEndTurnBody =>
      'Bestätige, dass alle Becheraktionen ausgewählt wurden!';

  @override
  String get dialogEndTurnConfirm => 'Zug beenden';

  @override
  String get dialogAirballTitle => 'Airball-Meilenstein';

  @override
  String get dialogAirballBody => 'Alle Spieler müssen einen Shot trinken!';

  @override
  String dialogAirballCount(int count) {
    return 'Airballs insgesamt: $count';
  }

  @override
  String get dialogBallsBackTitle => 'Balls Back!';

  @override
  String get dialogBallsBackBody => 'Alle Spieler haben getroffen!';

  @override
  String get dialogOnFireTitle => 'On Fire!';

  @override
  String get dialogOnFireBody => 'Drei Treffer in Folge!';

  @override
  String get dialogBitchCupTitle => 'Bitch Cup!';

  @override
  String get dialogBitchCupBody => 'Hose runter!';

  @override
  String get dialogGameOverTitle => 'Spiel vorbei';

  @override
  String get dialogGameOverGoStats => 'Zu den Statistiken';

  @override
  String get dialogGameOverGoHome => 'Zum Startbildschirm';

  @override
  String get rulebookSpecialBadge => 'SPEZIAL';

  @override
  String get rulebookHowToActivate => 'So aktivierst du es';

  @override
  String get rulebookAirballsTagline =>
      'Komplett daneben — dein Team zahlt den Preis.';

  @override
  String get rulebookAirballsDescription =>
      'Ein Airball ist ein Wurf, der keinen Becher berührt. Wenn ein Team insgesamt 3 Airballs ansammelt, müssen alle Spieler einen Strafschluck trinken. Der Zähler wird zurückgesetzt und zählt weiter.';

  @override
  String get rulebookAirballsStep1 =>
      'Aktiviere \"Airballs\" in den Spieleinstellungen.';

  @override
  String get rulebookAirballsStep2 =>
      'Wenn ein Wurf komplett daneben geht, tippe auf die orangene Fehlzone unter den Bechern.';

  @override
  String get rulebookAirballsStep3 =>
      'Bei jedem 3. Airball erscheint ein Dialog für die Strafe.';

  @override
  String get rulebookAirballsTip =>
      'Die Fehlzone erscheint nur, wenn die Airball-Regel aktiv ist — denk daran, bei jedem kompletten Fehlwurf darauf zu tippen.';

  @override
  String get rulebookBounceTagline =>
      'Ein Ball, zwei Becher — aber die Verteidigung kann abwehren.';

  @override
  String get rulebookBounceDescription =>
      'Ein Bounce Shot ist ein Wurf, bei dem der Ball vom Tisch abprallt, bevor er in einem Becher landet. Es belohnt Risiko: Ein erfolgreicher Bounce entfernt den getroffenen Becher plus einen zusätzlichen zufälligen Becher. Allerdings darf das verteidigende Team den Ball nach dem ersten Aufprall wegschlagen.';

  @override
  String get rulebookBounceStep1 =>
      'Aktiviere \"Bounce\" in den Spieleinstellungen.';

  @override
  String get rulebookBounceStep2 =>
      'Öffne während deines Zuges das Aktionsmenü (⋯) und tippe auf \"Bounce Shot\".';

  @override
  String get rulebookBounceStep3 =>
      'Wähle, wer den Bounce gemacht hat, und tippe dann auf den getroffenen Becher.';

  @override
  String get rulebookBounceTip =>
      'Bounce Shots sind risikoreich, aber lohnenswert. Hebe sie für Situationen auf, in denen du schnell aufholen musst.';

  @override
  String get rulebookPutbackTagline =>
      'Das Spiel ist nicht vorbei, bis der letzte Nachwurf gelandet ist.';

  @override
  String get rulebookPutbackDescription =>
      'Wenn ein Team den letzten Becher des Gegners trifft, bekommt das verlierende Team einen Nachwurf pro Spieler. Wenn ein Wurf trifft, wird der letzte Becher wiederhergestellt und das Spiel geht in die Verlängerung. Jeder Spieler muss seinen Wurf versuchen, bevor das Ergebnis feststeht.';

  @override
  String get rulebookPutbackStep1 =>
      'Aktiviere \"Nachwurf\" in den Spieleinstellungen.';

  @override
  String get rulebookPutbackStep2 =>
      'Wenn der letzte Becher getroffen wird, erscheint der Nachwurf-Dialog automatisch.';

  @override
  String get rulebookPutbackStep3 =>
      'Jeder Spieler des verlierenden Teams wirft einmal. Ein Treffer hält das Spiel am Leben.';

  @override
  String get rulebookPutbackTip =>
      'Wenn mehrere Nachwürfe treffen, wird trotzdem nur ein Becher wiederhergestellt — ziele sorgfältig.';

  @override
  String get rulebookIslandTagline =>
      'Ein isolierter Becher bedeutet einen Gratisbecher.';

  @override
  String get rulebookIslandDescription =>
      'Ein Island-Becher ist einer ohne Nachbarn — komplett von leeren Plätzen umgeben. Ein bestimmter Werfer kann einen Island Shot darauf ansagen. Trifft er, gewinnt er diesen Becher plus einen Bonusbecher seiner Wahl. Ein Fehlwurf bringt nichts und der Versuch ist verbraucht.';

  @override
  String get rulebookIslandStep1 =>
      'Aktiviere \"Island\" in den Spieleinstellungen.';

  @override
  String get rulebookIslandStep2 =>
      'Tippe im Aktionsmenü auf \"Island Shot\" und wähle den Werfer.';

  @override
  String get rulebookIslandStep3 =>
      'Island-Becher leuchten gelb. Tippe auf einen, um den Wurf zu machen.';

  @override
  String get rulebookIslandStep4 =>
      'Bei Erfolg wähle deinen Gratisbecher im Auswahlmenü.';

  @override
  String get rulebookIslandTip =>
      'Wenn nur ein Island-Becher existiert, wird der Wurf automatisch ausgelöst, nachdem der Werfer ausgewählt wurde — kein extra Tippen nötig.';

  @override
  String get rulebookDeathcupTagline =>
      'Triff den Becher, der gerade getrunken wird, und das Spiel endet sofort.';

  @override
  String get rulebookDeathcupDescription =>
      'Wenn die Deathcup-Regel aktiv ist, ist jeder getroffene, aber noch nicht ausgetrunkene Becher ein aktiver Deathcup. Wenn ein Spieler den Ball hineinwirft, während ein Gegner noch trinkt, verliert dieses Team sofort — alle verbleibenden Becher werden abgeräumt.';

  @override
  String get rulebookDeathcupStep1 =>
      'Aktiviere \"Deathcup\" in den Spieleinstellungen.';

  @override
  String get rulebookDeathcupStep2 =>
      'Wenn ein Deathcup getroffen wird, öffne das Aktionsmenü (⋯) und tippe auf \"Deathcup\".';

  @override
  String get rulebookDeathcupStep3 =>
      'Wähle den Spieler, der den Wurf gemacht hat, um den Sofortsieg auszulösen.';

  @override
  String get rulebookDeathcupTip =>
      'Behalte im Auge, welche Becher die Gegner gerade trinken — das sind deine wertvollsten Ziele.';

  @override
  String get rulebookRearrangeTagline =>
      'Verstreute Becher in eine engere Formation bringen.';

  @override
  String get rulebookRearrangeDescription =>
      'Einmal pro Spiel, wenn 6 oder weniger Becher auf deiner Seite übrig sind, kannst du ein Re-Rack ansagen. Die Becher werden in eine Standard-Dreiecksformation umgestellt, die Lücken schließt. Das Re-Rack kann nur einmal und nur innerhalb des 6-Becher-Limits verwendet werden.';

  @override
  String get rulebookRearrangeStep1 =>
      'Aktiviere \"Umstellen\" in den Spieleinstellungen.';

  @override
  String get rulebookRearrangeStep2 =>
      'Wenn 6 oder weniger Becher übrig sind, tippe auf den Umstell-Button in der unteren Leiste.';

  @override
  String get rulebookRearrangeStep3 =>
      'Die Becher werden sofort in ein kompaktes Dreieck verschoben.';

  @override
  String get rulebookRearrangeTip =>
      'Spare dein Re-Rack für den Moment, wenn die Becher am meisten verstreut sind — ein enges Dreieck ist deutlich leichter zu treffen.';

  @override
  String get statsTabStats => 'Statistik';

  @override
  String get statsTabPerformance => 'Leistung';

  @override
  String get statsTabProgress => 'Fortschritt';

  @override
  String get statsTabBreakdown => 'Aufschlüsselung';

  @override
  String get statsTabHistory => 'Verlauf';

  @override
  String get statsSignInPrompt =>
      'Melde dich an, um deine Statistiken zu sehen';

  @override
  String get statsFailedToLoad => 'Spiele konnten nicht geladen werden';

  @override
  String get statsNoGamesYet => 'Noch keine Spiele aufgezeichnet.';

  @override
  String get statsLiveView => 'Live-Ansicht';

  @override
  String get statsGameStatistics => 'Spielstatistiken';

  @override
  String get statsViewTeam => 'Team anzeigen';

  @override
  String get statsViewGameStats => 'Spielstatistiken anzeigen';

  @override
  String get statsViewTable => 'Tisch anzeigen';

  @override
  String get statsColumnPlayer => 'Spieler';

  @override
  String get statsColumnScore => 'Punkte';

  @override
  String get statsColumnThrows => 'Würfe';

  @override
  String get statsColumnMiss => 'Fehl';

  @override
  String get statsColumnHitRate => 'Treff%';

  @override
  String get statsColumnBounce => 'Bounce';

  @override
  String get statsColumnDef => 'Vert.';

  @override
  String get statsAchievements => 'Erfolge';

  @override
  String get statsTeamStatistics => 'Teamstatistiken';

  @override
  String get statsMvp => 'MVP';

  @override
  String get statsAirballer => 'Airballer';

  @override
  String get statsMissManiac => 'Fehlwurf-Maniac';

  @override
  String get statsSniper => 'Scharfschütze';

  @override
  String get statsTierRoadmap => 'Stufen-Roadmap';

  @override
  String get statsAchievementProgress => 'Erfolgsfortschritt';

  @override
  String get statsUnlockedTitles => 'Freigeschaltete Titel';

  @override
  String get statsAlmostThere => 'Fast geschafft';

  @override
  String statsMaxLevelReached(int xp) {
    return 'Maximallevel erreicht — $xp XP insgesamt';
  }

  @override
  String statsReachLevelUnlock(int level, String title) {
    return 'Erreiche Level $level, um $title freizuschalten';
  }

  @override
  String get perfSummaryTitle => 'Leistungsübersicht';

  @override
  String get perfHeatMapTitle => 'Becher-Treffer-Heatmap';

  @override
  String get perfRowAccuracyTitle => 'Reihen-Genauigkeit';

  @override
  String get perfFilterAll => 'Alle';

  @override
  String get perfFilterLast10 => 'Letzte 10';

  @override
  String get perfFilterLast5 => 'Letzte 5';

  @override
  String get perfFilterLast3 => 'Letzte 3';

  @override
  String get perfNoData => 'Noch keine Daten.';

  @override
  String get perfRowFront => 'Vorne';

  @override
  String get perfRowMid => 'Mitte';

  @override
  String get perfRowBack => 'Hinten';

  @override
  String get perfRowApex => 'Spitze';

  @override
  String get statTotalScore => 'Gesamtpunktzahl';

  @override
  String get statTotalMisses => 'Fehlwürfe gesamt';

  @override
  String get statTotalAirballs => 'Airballs gesamt';

  @override
  String get statCupsHit => 'Becher getroffen';

  @override
  String get statHitRate => 'Trefferquote';

  @override
  String get statWinRate => 'Siegquote';

  @override
  String get statBounceRate => 'Bounce-Quote';

  @override
  String get statIslandConv => 'Island-Konv.';

  @override
  String get statDefended => 'Verteidigt';

  @override
  String get statOnFire => 'On Fire';

  @override
  String get statHeatingUp => 'Heating Up';

  @override
  String get friendsTabFriendlist => 'Freundesliste';

  @override
  String get friendsTabLeaderboard => 'Rangliste';

  @override
  String get friendsTabSocials => 'Soziales';

  @override
  String get friendsSignInPrompt => 'Melde dich an, um deine Freunde zu sehen';

  @override
  String get friendsMustSignIn =>
      'Du musst angemeldet sein, um Freunde hinzuzufügen.';

  @override
  String get friendsNoFriends =>
      'Noch keine Freunde. Füge einen über den + Button oben hinzu.';

  @override
  String get friendsNoActivity =>
      'Füge Freunde hinzu, um hier Aktivitäten zu sehen.';

  @override
  String get friendsNoRecentActivity => 'Noch keine Aktivitäten.';

  @override
  String get friendsNoFriendsFound => 'Keine Freunde gefunden.';

  @override
  String get friendsRemoveTitle => 'Freund entfernen';

  @override
  String friendsRemoveBody(String username) {
    return '$username aus deiner Freundesliste entfernen?';
  }

  @override
  String get friendsRemoveConfirm => 'Entfernen';

  @override
  String get friendsAddTitle => 'Freund hinzufügen';

  @override
  String get friendsSearchHint => 'Nach Benutzernamen suchen…';

  @override
  String get friendsNoUsersFound => 'Keine Benutzer gefunden.';

  @override
  String get friendsAddBtn => 'Hinzufügen';

  @override
  String get friendsShareQr => 'Teilen / QR scannen';

  @override
  String get friendsIdCopied => 'ID in Zwischenablage kopiert';

  @override
  String get friendsScanQrBtn => 'QR-Code scannen';

  @override
  String get friendsWatchBtn => 'Zuschauen';

  @override
  String get shopTabAvatar => 'Avatar';

  @override
  String get shopTabUserCard => 'Benutzerkarte';

  @override
  String get shopTabInGame => 'Im Spiel';

  @override
  String get shopSignInEarnStars => 'Melde dich an, um Sterne zu verdienen';

  @override
  String get shopGetStars => 'Sterne holen';

  @override
  String get shopEarnStarsHint => 'Verdiene ⭐ Sterne zum Ausgeben im Shop.';

  @override
  String get shopSupporterTitle => 'Danke! ⭐';

  @override
  String get shopSupporterBody =>
      'Du bist jetzt Supporter! Dein Supporter-Abzeichen ist auf deinem Profil aktiv und du hilfst, die App am Laufen zu halten. Danke!';

  @override
  String get shopSupporterBtn => 'Super!';

  @override
  String shopStarsAwarded(int count) {
    return 'Du hast $count ⭐ erhalten!';
  }

  @override
  String shopPurchaseFailed(String message) {
    return 'Kauf fehlgeschlagen: $message';
  }

  @override
  String get shopNoAdAvailable =>
      'Gerade keine Werbung verfügbar. Versuche es später erneut.';

  @override
  String get shopEarned50Stars => 'Du hast 50 ⭐ verdient!';

  @override
  String get shopEarnFreeStars => 'Verdiene Sterne kostenlos durch Spielen!';

  @override
  String get shopRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get shopWatchVideo => 'Ein kurzes Video schauen';

  @override
  String get shopDailyLimitReached =>
      'Tageslimit erreicht — komm morgen wieder';

  @override
  String get shopSupporterBadge => 'Du bist Supporter ✓';

  @override
  String get shopBuyBtn => 'Kaufen';

  @override
  String get shopComingSoon => 'Kommt bald';

  @override
  String get accountProfile => 'Profil';

  @override
  String get accountSupporter => 'Supporter';

  @override
  String get accountFeedbackTooltip => 'Feedback senden';

  @override
  String get accountSignOutTooltip => 'Abmelden';

  @override
  String get accountSignOutTitle => 'Abmelden?';

  @override
  String get accountSignOutBody =>
      'Du wirst zum Anmeldebildschirm zurückgeleitet.';

  @override
  String get accountSignOutConfirm => 'Abmelden';

  @override
  String get achievementStagesBronze => 'Bronze';

  @override
  String get achievementStagesSilver => 'Silber';

  @override
  String get achievementStagesGold => 'Gold';

  @override
  String get achievementStagesDiamond => 'Diamant';

  @override
  String get achievementMaxed => 'Maximal!';

  @override
  String get achievementFullyMastered => 'Vollständig gemeistert!';

  @override
  String achievementProgress(int current, int next) {
    return 'Fortschritt: $current / $next';
  }

  @override
  String achievementUnlocksTitle(String title) {
    return 'Schaltet Titel frei: \"$title\"';
  }

  @override
  String get profileSectionUsername => 'Benutzername';

  @override
  String get profileSectionAvatar => 'Avatar';

  @override
  String get profileSectionBackground => 'Hintergrund';

  @override
  String get profileSectionTitle => 'Titel';

  @override
  String get profileUsernamePlaceholder => 'Wähle einen Benutzernamen';

  @override
  String get profileUsernameChecking => 'Prüfe…';

  @override
  String get profileUsernameAvailable => 'Verfügbar';

  @override
  String get profileUsernameTaken => 'Bereits vergeben';

  @override
  String get profileUsernameInvalid =>
      '3–20 Zeichen, Buchstaben/Zahlen/Unterstriche/Leerzeichen, keine aufeinanderfolgenden __ oder Leerzeichen';

  @override
  String get profileUpdated => 'Profil aktualisiert!';

  @override
  String profileSaveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String profileLevelRequired(int level) {
    return 'Lv $level';
  }

  @override
  String dialogGameOverWinners(String winners) {
    return '$winners haben das Spiel gewonnen!';
  }

  @override
  String get achievementsMaxLevel => 'Maximallevel erreicht';

  @override
  String achievementsXpProgress(int xp, int toNext, int nextLevel) {
    return '$xp XP · $toNext XP bis Level $nextLevel';
  }

  @override
  String get achievementsBestStreak => 'Beste Serie';

  @override
  String get shopSignInBrowse => 'Melde dich an, um den Shop zu durchstöbern';

  @override
  String get shopSectionProfilePictures => 'Profilbilder';

  @override
  String get shopSectionAvatarBorders => 'Avatar-Rahmen';

  @override
  String get shopSectionEmblemsAndMedals => 'Embleme & Medaillen';

  @override
  String get shopSectionCupSkins => 'Becher-Skins';

  @override
  String get shopSectionTableThemes => 'Tisch-Designs';

  @override
  String get shopSectionTitles => 'Titel';

  @override
  String get shopSectionCardBackgrounds => 'Karten-Hintergründe';

  @override
  String get shopCardBackgroundsNote =>
      'Karten-Hintergründe werden kostenlos durch Levelaufstiege freigeschaltet. Verwalte sie in deinem Profil.';

  @override
  String get shopEquip => 'Ausrüsten';

  @override
  String get shopUnequip => 'Ablegen';

  @override
  String get shopYourBalance => 'Dein Guthaben';

  @override
  String get shopCost => 'Kosten';

  @override
  String shopBuyForStars(int price) {
    return 'Kaufen für ⭐ $price';
  }

  @override
  String shopNeedMoreStars(int count) {
    return 'Du brauchst noch $count ⭐ um das zu kaufen.';
  }

  @override
  String get shopGetMoreStars => 'Mehr Sterne holen';

  @override
  String shopItemPurchased(String name) {
    return '$name gekauft! ⭐';
  }

  @override
  String get shopNotEnoughStars => 'Nicht genug Sterne!';

  @override
  String get navShop => 'Shop';

  @override
  String get navFriends => 'Freunde';

  @override
  String get navHome => 'Home';

  @override
  String get navGames => 'Spiele';

  @override
  String get navProfile => 'Profil';

  @override
  String get settingsDarkMode => 'Dunkelmodus';

  @override
  String get settingsPrivacy => 'Datenschutzeinstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get feedbackSheetTitle => 'Feedback senden';

  @override
  String get feedbackHint => 'Beschreibe das Problem oder die Idee…';

  @override
  String get feedbackSend => 'Senden';

  @override
  String get feedbackSuccess => 'Danke für dein Feedback!';

  @override
  String get feedbackError =>
      'Feedback konnte nicht gesendet werden. Versuche es erneut.';

  @override
  String get feedbackCategoryBug => 'Fehler';

  @override
  String get feedbackCategorySuggestion => 'Vorschlag';

  @override
  String get feedbackCategoryOther => 'Sonstiges';

  @override
  String get invitationsTitle => 'Einladungen';

  @override
  String get invitationsNotSignedIn => 'Nicht angemeldet';

  @override
  String get invitationsNoPending => 'Keine ausstehenden Einladungen';

  @override
  String get invitationsDeclined => 'Einladung abgelehnt';

  @override
  String get invitationsDeclineBtn => 'Ablehnen';

  @override
  String get invitationsAcceptBtn => 'Annehmen';

  @override
  String get invitationsFromPlayer => 'Ein Spieler';

  @override
  String get invitationsInvitedToGame => 'Hat dich zu einem Spiel eingeladen';

  @override
  String get invitationsInvitedToTournament =>
      'Hat dich zu einem Turnier eingeladen';

  @override
  String get waitingTitle => 'Warte…';

  @override
  String waitingForGame(String host) {
    return 'Warte darauf, dass $host das Spiel startet…';
  }

  @override
  String waitingForTournament(String host) {
    return 'Warte darauf, dass $host das Turnier startet…';
  }

  @override
  String get liveGameTitle => 'Live-Spiel';

  @override
  String get liveGameSummary => 'Spielzusammenfassung';

  @override
  String get liveTabTable => 'Tisch';

  @override
  String get liveTabStats => 'Statistik';

  @override
  String get liveTabTimeline => 'Zeitverlauf';

  @override
  String get liveGameNotFound => 'Spiel nicht gefunden.';

  @override
  String get liveGameError => 'Etwas ist schiefgelaufen';

  @override
  String get liveBadgeLive => 'LIVE';

  @override
  String get liveBadgeFinal => 'ENDE';

  @override
  String get liveStatsAccuracy => 'Genauigkeit %';

  @override
  String get liveTimelineNoEvents => 'Noch keine Ereignisse';

  @override
  String liveTimelineRound(int number) {
    return 'Runde $number';
  }

  @override
  String liveTimelineEndOfTurn(String time) {
    return 'Zugende · $time';
  }

  @override
  String get liveEventHit => 'Treffer';

  @override
  String get liveEventBounce => 'Bounce';

  @override
  String get liveEventIsland => 'Island';

  @override
  String get liveEventDeathCup => 'Deathcup';

  @override
  String get liveEventAirball => 'Airball';

  @override
  String get liveEventBitchCup => 'Bitch Cup';

  @override
  String get liveEventOnFire => 'On Fire';

  @override
  String get spectatelobbyTitle => 'Lobby';

  @override
  String get spectateLobbyGameTitle => 'Spiel-Lobby';

  @override
  String get spectateLobbyError => 'Fehler beim Laden des Spiels.';

  @override
  String get spectateLobbyNoPlayers => 'Noch keine Spieler';

  @override
  String get spectateLobbyGameSettings => 'Spieleinstellungen';

  @override
  String get spectateLobbyMode => 'Modus';

  @override
  String get spectateLobbyStartingTeam => 'Startteam';

  @override
  String get spectateLobbyWaiting =>
      'Warte darauf, dass der Host das Spiel startet…';

  @override
  String get btnLeave => 'Verlassen';

  @override
  String liveCupsLeft(int count) {
    return '$count Becher übrig';
  }

  @override
  String get liveStatScore => 'Punkte';

  @override
  String get liveStatThrows => 'Würfe';

  @override
  String get liveStatAirballs => 'Airballs';

  @override
  String get liveStatMisses => 'Fehlwürfe';

  @override
  String get liveStatCupsHit => 'Becher getroffen';

  @override
  String gameModeTeamStarts(String team) {
    return '$team fängt an';
  }

  @override
  String get tournamentCompleteTitle => 'Turnier abgeschlossen!';

  @override
  String get tournamentCompleteBody =>
      'Alle Spiele wurden gespielt.\nSchau dir die Platzierungen an!';

  @override
  String get labelPlayer => 'Spieler';

  @override
  String get compareTitle => 'Vergleich';

  @override
  String get compareOverview => 'ÜBERSICHT';

  @override
  String get compareStatComparison => 'STATISTIKVERGLEICH';

  @override
  String get compareBouncePercent => 'Bounce %';

  @override
  String get compareIslandPercent => 'Island %';

  @override
  String get compareTotalWins => 'Siege gesamt';

  @override
  String get compareOnFire => 'On Fire';

  @override
  String get breakdownShotDistribution => 'Wurfverteilung';

  @override
  String get breakdownSpecialShots => 'Spezialwürfe';

  @override
  String get breakdownWinContext => 'Sieg-Kontext';

  @override
  String get breakdownHeadToHead => 'Direktvergleich';

  @override
  String get breakdownThrowsLabel => 'Würfe';

  @override
  String get breakdownHits => 'Treffer';

  @override
  String get breakdownBounceShot => 'Bounce Shot';

  @override
  String get breakdownIslandShot => 'Island Shot';

  @override
  String get breakdownWinMarginTitle => 'Siegabstand-Verteilung';

  @override
  String get breakdownDominant => 'Dominant (5+ Becher)';

  @override
  String get breakdownComfortable => 'Komfortabel (3–4)';

  @override
  String get breakdownClose => 'Knapp (1–2)';

  @override
  String get breakdownClutchRate => 'Clutch-Rate';

  @override
  String get breakdownClutchDesc => 'Letzten Becher zum Sieg getroffen';

  @override
  String get breakdownNoGames => 'Noch keine Spiele aufgezeichnet.';

  @override
  String get breakdownNoOpponents => 'Keine Gegner gefunden.';

  @override
  String get breakdownNoThrows => 'Noch keine Würfe aufgezeichnet.';

  @override
  String get statsViewAllAchievements => 'Alle Erfolge anzeigen';

  @override
  String get statsColAbbrevScore => 'P';

  @override
  String get statsColAbbrevMisses => 'F';

  @override
  String get statsColAbbrevThrows => 'W';

  @override
  String get statsColAbbrevAirballs => 'A';

  @override
  String get statsColAbbrevHitRate => 'TQ';

  @override
  String get statsCareerHighlights => 'KARRIERE-HIGHLIGHTS';

  @override
  String get statsBestStreak => 'Beste Serie';

  @override
  String get statsBestHitRate => 'Beste Trefferquote';

  @override
  String get statsMostCups => 'Meiste Becher';

  @override
  String get statsRecentForm => 'Aktuelle Form';

  @override
  String get statsWins => 'Siege';

  @override
  String get statsLosses => 'Niederlagen';

  @override
  String get statsWinRate => 'Siegquote';

  @override
  String get statsHitRate => 'Trefferquote';

  @override
  String get statsOnFire => 'On Fire';

  @override
  String get statsBouncePercent => 'Bounce%';

  @override
  String get statsIslands => 'Islands';

  @override
  String get statsDefended => 'Verteidigt';

  @override
  String get statsHeatingUp => 'Heating Up';

  @override
  String get statsLastCup => 'Letzter Becher';

  @override
  String get statsAvgPerGame => 'Ø/Spiel';

  @override
  String get statsNightGames => 'Nachtspiele';

  @override
  String get statsCupsPerGame => 'Becher/Spiel';

  @override
  String get statsThrowsPerGame => 'Würfe/Spiel';

  @override
  String statsStreakChip(int count, String type) {
    return '$count-Spiele $type-Serie';
  }

  @override
  String statsCurrentStreak(String label) {
    return 'Aktuelle Serie: $label';
  }

  @override
  String statsLast10Record(int count, int wins, int losses) {
    return 'Letzte $count:  ${wins}S  ${losses}N';
  }

  @override
  String statsXpProgress(int xp, int toNext, int level) {
    return '$xp XP · $toNext XP bis Level $level';
  }

  @override
  String get compareWinRate => 'Siegquote';

  @override
  String get compareHitRate => 'Trefferquote';

  @override
  String get shopStarterPackTitle => 'Starterpaket  ·  1,99 €';

  @override
  String get shopStarterPackSubtitle => '200 ⭐';

  @override
  String get shopPopularPackTitle => 'Beliebtes Paket  ·  4,99 €';

  @override
  String get shopPopularPackSubtitle => '600 ⭐  ·  Bestes Angebot';

  @override
  String get shopMegaPackTitle => 'Mega-Paket  ·  9,99 €';

  @override
  String get shopMegaPackSubtitle => '1 500 ⭐';

  @override
  String get shopSupporterPackFull => 'Supporter-Paket  ·  2,99 €';

  @override
  String get shopSupporterPackFullSubtitle =>
      '300 ⭐  ·  Supporter-Abzeichen auf deinem Profil';

  @override
  String shopWatchesRemaining(int remaining, int total) {
    return '+50 ⭐  ·  $remaining von $total Videos heute übrig';
  }

  @override
  String socialBeatFriend(String username) {
    return '$username besiegt';
  }

  @override
  String socialLostToFriend(String username) {
    return 'Gegen $username verloren';
  }

  @override
  String socialSharedGameResult(int myScore, int oppScore, int hitPct) {
    return '$myScore–$oppScore · $hitPct% Trefferquote';
  }

  @override
  String socialWinStreak(int count) {
    return '🔥 $count-Spiele Siegesserie!';
  }

  @override
  String get socialWinStreakSubtitle => 'Du bist on fire — bleib dran.';

  @override
  String socialFriendReachedWins(String username, int count) {
    return '🏆 $username hat $count Siege erreicht';
  }

  @override
  String get socialFriendLegendSubtitle => 'Eine wahre Beer-Pong-Legende.';

  @override
  String socialFriendOnFire(String username, int count) {
    return '🔥 $username war $count+ Mal on fire';
  }

  @override
  String get socialSeriousHeatSubtitle => 'Ernsthaft heiß.';

  @override
  String socialFriendIsActive(String username) {
    return '$username ist aktiv';
  }

  @override
  String socialFriendActiveSubtitle(String timeAgo, int totalGames) {
    return 'Gespielt $timeAgo · $totalGames Spiele insgesamt';
  }

  @override
  String get leaderboardTotalScore => 'Gesamtpunktzahl';

  @override
  String get leaderboardGames => 'Spiele';
}
