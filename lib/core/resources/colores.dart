import 'package:flutter/material.dart';

abstract class ColorsManager {
  // Base Colors
  static const Color background = Color(0xFF111827); // Background
  static const Color primary = Color(0xFF1F2937); // Primary
  static const Color lightPrimary = Color(0xFF7F8CF8); // Primary
  static const Color darkPrimary = Color(0xFF121F2F); // Darker variant

  //dark mode colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkAppbarColor = Color(0xFF1F1F1F);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  

  // UI Colors
  static const Color headerText = Color(0xFF7F8CF8); // Header Text
  static const Color button = Color(0xFF4F46E5); // Button Color
  static const Color buttonText = Color(0xFFFFFFFF); // Text on buttons
  static const Color chipColor = Colors.amberAccent; // Text on buttons
  static Color greenWithShade = const Color.fromARGB(255, 25, 70, 27); // Text on buttons
  static Color green = Colors.greenAccent; // Text on buttons
  static Color readWithShade = Colors.red.shade100; // Text on buttons

  // Common Colors
  static const Color white = Color(0xFFF5F5F5);
  static const Color black = Color(0xFF1A1A1A);
  static const Color shadow1 = Colors.black26;

  // Optional – you may keep grey variants if needed
  static const Color grey = Color(0xFF737477);
  static const Color darkGrey = Color(0xFF525252);
  static const Color lightGrey = Color(0x4D9E9E9E); // Colors.grey.withOpacity(.3)
  static const Color grey1 = Color(0xFF707070);
  static const Color grey2 = Color(0xFF797979);

  // Error Color
  static const Color red = Color(0xFFE61F34);
 

  static const btnsColor =  Colors.cyan;
  static const backgroundColor = Color.fromARGB(255, 255, 250, 250);
  static const backgroundColor2 =  Color.fromARGB(255, 198, 248, 255);
  static const appbarColor =  Color.fromARGB(255, 185, 218, 255);
  static const signupbtnColor =   Color.fromARGB(255, 0, 225, 255);
  
  
  // Light mode colors (original)
  static Color periwinkleBlue = Color(0xFFB4C4FE);
  static Color softYellow = Color(0xFFFFF580);
  static Color mintGreen = Color(0xFFD0F4EA);
  static Color pinkBlush = Color(0xFFFFC0F5);
  static Color iceBlue = Color(0xFFF4F7FF);
  static Color royalBlue = Color(0xFF3B6BB9);
  static Color snowWhite = Color(0xFFFAFCFC);
  static Color stoneGrey = Color(0xFF91949B);
  static Color transparent = Color(0x00000000);

  // Dark mode alternatives
  static Color periwinkleBlueDark = Color(0xFF4A5B8C);        // Darker, muted periwinkle
  static Color softYellowDark = Color(0xFF8A8A3D);            // Darker, warmer yellow
  static Color mintGreenDark = Color(0xFF3A6B5C);             // Deep forest green
  static Color pinkBlushDark = Color(0xFF8A4D7A);             // Darker rose/magenta
  static Color iceBlueDark = Color(0xFF2C3340);               // Dark blue-grey
  static Color royalBlueDark = Color(0xFF5B7AC7);             // Lighter royal blue for contrast
  static Color snowWhiteDark = Color(0xFF1E2125);             // Very dark grey (almost black)
  static Color stoneGreyDark = Color(0xFF6B6E75);    
}
