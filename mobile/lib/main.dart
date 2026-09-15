import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // The Sprint 1 screens are drawn for a portrait handset (402x874 and
  // 412x892): a fixed header over a scrolling body with the primary action
  // pinned to the bottom. There is no landscape design, and in landscape the
  // header eats most of the viewport, so the app is locked upright.
  // Remove this once landscape layouts exist.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) => runApp(const JihudumieApp()));
}
