import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/i18n/strings.dart';

/// A widget that wraps a child in default localizations.
class Testable extends StatelessWidget {
  final Widget _child;

  Testable(this._child) : assert(_child != null);

  @override
  Widget build(BuildContext context) {
    return Localizations(
      delegates: [
        StringsDelegate(),
        DefaultMaterialLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      locale: Locale("en", "CA"),
      child: _child,
    );
  }
}