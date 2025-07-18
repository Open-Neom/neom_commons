
import 'package:flutter/cupertino.dart';
import '../text_utilities.dart';

class AppLocaleConstants {

  static final List<String> supportedLanguages = ['english', 'spanish', 'french', 'deutsch'];

  static const Map<String, Locale> supportedLocales = {
    'english': Locale('en', 'US'),
    'spanish': Locale('es', 'MX'),
    'french': Locale('fr', 'FR'),
    'deutsch': Locale('de', 'DE')
  };

  static const String es = 'es';

// Listas de países por idioma (normalizadas y en minúsculas)
  static List<String> spanishCountries = [
    'mexico', 'spain', 'argentina', 'colombia', 'peru', 'venezuela',
    'chile', 'ecuador', 'guatemala', 'cuba', 'bolivia', 'honduras',
    'paraguay', 'el salvador', 'nicaragua', 'costa rica', 'puerto rico',
    'uruguay', 'panama', 'dominican republic', 'equatorial guinea'
  ].map((country) => TextUtilities.normalizeString(country).toLowerCase()).toList(); // Aplicar normalización y minúsculas

  static List<String> frenchCountries =  [
    'france', 'belgium', 'switzerland', 'senegal', 'ivory coast',
    'cameroon', 'burkina faso', 'niger', 'mali', 'haiti', 'chad',
    'guinea', 'rwanda', 'burundi', 'benin', 'togo', 'central african republic',
    'republic of the congo', 'gabon', 'djibouti', 'comoros', 'luxembourg',
    'monaco', 'seychelles', 'vanuatu'
  ].map((country) => TextUtilities.normalizeString(country).toLowerCase()).toList(); // Aplicar normalización y minúsculas

  static List<String> germanCountries = [
    'germany', 'austria', 'switzerland', 'luxembourg', 'belgium', 'liechtenstein'
  ].map((country) => TextUtilities.normalizeString(country).toLowerCase()).toList();


}
