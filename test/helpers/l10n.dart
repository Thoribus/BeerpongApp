import 'package:flutter/material.dart';
import 'package:beerpongapp/l10n/app_localizations.dart';

/// Wraps [child] in a [MaterialApp] with the app's localization delegates
/// so that `context.loc.*` calls work in widget tests.
Widget wrapWithL10n(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

/// Same as [wrapWithL10n] but without an extra Scaffold.
Widget wrapWithL10nBare(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
