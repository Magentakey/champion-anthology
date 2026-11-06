import 'package:flutter/material.dart';

import '../shared/widgets/pixel_ui.dart';

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: PixelUi.night,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    // Pesan singkat (mis. "Segera hadir") ikut bergaya piksel: kotak gelap berbingkai krem, font piksel.
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: PixelUi.dark,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: PixelUi.cream, width: 2)),
      contentTextStyle: TextStyle(fontFamily: PixelUi.fontFamily, fontSize: 14, color: PixelUi.cream),
    ),
  );
}
