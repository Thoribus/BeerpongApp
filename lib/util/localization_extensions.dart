import 'package:flutter/widgets.dart';
import 'package:beerpongapp/l10n/app_localizations.dart';

export 'package:beerpongapp/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}
