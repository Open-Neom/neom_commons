import 'package:flutter/material.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

import '../../utils/constants/translations/common_translation_constants.dart';

/// Shared model for a literary game card, used by both
/// the timeline spotlight cards and the web sidebar games widget.
class LiteraryGameInfo {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final Color color;
  final String route;

  const LiteraryGameInfo({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.color,
    required this.route,
  });

  /// All available literary games.
  static const List<LiteraryGameInfo> allGames = [
    // 1. Libroverso (FindYourBook)
    LiteraryGameInfo(
      titleKey: CommonTranslationConstants.bookverse,
      descriptionKey: CommonTranslationConstants.bookverseDesc,
      icon: Icons.explore,
      color: Colors.indigoAccent,
      route: AppRouteConstants.gamesFindYourBook,
    ),
    // 2. Frasedrez (LiteraryChess)
    LiteraryGameInfo(
      titleKey: CommonTranslationConstants.literaryChess,
      descriptionKey: CommonTranslationConstants.literaryChessDesc,
      icon: Icons.castle,
      color: Colors.deepOrangeAccent,
      route: AppRouteConstants.gamesLiteraryChess,
    ),
    // 3. Librinder
    LiteraryGameInfo(
      titleKey: CommonTranslationConstants.librinder,
      descriptionKey: CommonTranslationConstants.librinderDesc,
      icon: Icons.favorite,
      color: Color(0xFFE94057),
      route: AppRouteConstants.gamesLibrinder,
    ),
    // 4. Fábrica de Cuentos (StoryBuilder)
    LiteraryGameInfo(
      titleKey: CommonTranslationConstants.storyBuilder,
      descriptionKey: CommonTranslationConstants.storyBuilderDesc,
      icon: Icons.auto_stories,
      color: Colors.tealAccent,
      route: AppRouteConstants.gamesStoryBuilder,
    ),
    // 5. Versos Revueltos (VerseScramble)
    LiteraryGameInfo(
      titleKey: CommonTranslationConstants.verseScramble,
      descriptionKey: CommonTranslationConstants.verseScrambleDesc,
      icon: Icons.text_rotation_none,
      color: Colors.cyanAccent,
      route: AppRouteConstants.gamesVerseScramble,
    ),
    // 6. Duelo de Plumas (QuoteQuest)
    LiteraryGameInfo(
      titleKey: CommonTranslationConstants.quoteQuest,
      descriptionKey: CommonTranslationConstants.quoteQuestDesc,
      icon: Icons.format_quote,
      color: Colors.purpleAccent,
      route: AppRouteConstants.gamesQuoteQuest,
    ),
    // 7. Cadena de Palabras (WordChain)
    LiteraryGameInfo(
      titleKey: CommonTranslationConstants.wordChain,
      descriptionKey: CommonTranslationConstants.wordChainDesc,
      icon: Icons.link,
      color: Colors.amber,
      route: AppRouteConstants.gamesWordChain,
    ),
  ];
}
