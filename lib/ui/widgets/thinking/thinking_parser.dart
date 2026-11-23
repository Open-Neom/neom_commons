class ThinkingParseResult {
  final String thinkingContent;
  final String finalContent;
  final bool isThinkingActive;

  const ThinkingParseResult({
    required this.thinkingContent,
    required this.finalContent,
    required this.isThinkingActive,
  });

  @override
  String toString() =>
      'ThinkingParseResult(thinkingContent: "$thinkingContent", finalContent: "$finalContent", isThinkingActive: $isThinkingActive)';
}

/// Result of [ThinkingParser.split].
class ThinkingSplit {
  /// The chain-of-thought / reasoning trace. Empty when the response had no
  /// thinking markers.
  final String thinking;

  /// The user-visible answer, with all thinking markers removed.
  final String content;

  const ThinkingSplit({required this.thinking, required this.content});

  bool get hasThinking => thinking.isNotEmpty;

  @override
  String toString() =>
      'ThinkingSplit(thinking: ${thinking.length} chars, content: ${content.length} chars)';
}

/// Unified reasoning-token parser shared across Open Neom UI widgets and AI
/// pipelines (Qwen3, DeepSeek-R1, QwQ, Gemma 4, gpt-oss, etc.).
///
/// Exposes both:
/// - [parse] → [ThinkingParseResult] for live streaming UI widgets (`isThinkingActive`)
/// - [split] / [stripThinking] / [hasThinking] → [ThinkingSplit] for post-processing
///   and agent pipelines (including closing-only template prefixes and bare
///   `Thought: … Answer: …` blocks).
class ThinkingParser {
  static final RegExp _closedThinkRegExp = RegExp(
    r'(?:<\s*think\b[^>]*>([\s\S]*?)<\s*/\s*think\s*>|<\|(?:channel|turn)\s*>\s*thought\b\s*([\s\S]*?)<(?:channel|turn)\s*\|>)',
    caseSensitive: false,
  );
  static final RegExp _openThinkTagRegExp = RegExp(
    r'(?:<\s*think\b[^>]*>|<\|(?:channel|turn)\s*>\s*thought\b\s*)',
    caseSensitive: false,
  );
  static final RegExp _orphanCloseThinkRegExp = RegExp(
    r'(?:<\s*/\s*think\s*>|<(?:channel|turn)\s*\|>|<\|tool_call\s*>[\s\S]*?(?:<tool_call\s*\|>|$)|<tool_call\s*\|>)',
    caseSensitive: false,
  );

  // Matches <think>…</think>, <thinking>…</thinking>, <thought>…</thought>, or
  // Gemma 4's <|channel>thought…<channel|> / <|turn>thought…<turn|>
  // (and <|channel|>thought…<|channel|>), case-insensitive, multi-line,
  // non-greedy (first closing tag wins).
  static final RegExp _tagRe = RegExp(
    r'(?:<(?:think(?:ing)?|thought)>([\s\S]*?)</(?:think(?:ing)?|thought)>|<\|(?:channel|turn)\|?>\s*thought\b([\s\S]*?)(?:<\|?(?:channel|turn)\|>|</(?:channel|turn)>))',
    caseSensitive: false,
  );

  // Matches an open `<think>`, `<thinking>`, `<thought>`, `<|channel>thought`,
  // or `<|turn>thought` that never closes (streaming / truncated).
  static final RegExp _openRe = RegExp(
    r'(?:<(?:think(?:ing)?|thought)>|<\|(?:channel|turn)\|?>\s*thought\b)([\s\S]*)$',
    caseSensitive: false,
  );

  static final RegExp _closeOnlyRe = RegExp(
    r'(?:</(?:think(?:ing)?|thought)>|<\|?channel\|>|</channel>)',
    caseSensitive: false,
  );

  static final RegExp _openMarkerRe = RegExp(
    r'(?:<(?:think(?:ing)?|thought)>|<\|(?:channel|turn)\|?>\s*thought\b)',
    caseSensitive: false,
  );

  static final RegExp _residualTagsRe = RegExp(
    r'(?:</?(?:think(?:ing)?|thought)>|<\|(?:channel|turn)\|?>\s*thought\b|<\|?channel\|>|</channel>|<\|?/?turn\|?>|<\|eot_id\|>|<(?:start|end)_of_turn>|<\|im_(?:start|end)\|>)',
    caseSensitive: false,
  );

  // Matches bare `Thought: …` / `Reasoning: …` blocks when no tags.
  static final RegExp _bareRe = RegExp(
    r'^\s*(?:Thought|Reasoning|Thinking)\s*:\s*([\s\S]*?)\n\s*(?:Answer|Response|Final)\s*:\s*([\s\S]+)$',
    caseSensitive: false,
  );

  /// Parses the cumulative stream text to separate reasoning steps and final output.
  /// Captures anything inside `<think>...</think>` or Gemma-4
  /// `<|channel>thought...<channel|>` / `<|turn>thought...<turn|>` blocks
  /// (including multiple blocks and active trailing unclosed thought tags).
  static ThinkingParseResult parse(String fullStreamText) {
    if (fullStreamText.isEmpty) {
      return const ThinkingParseResult(
        thinkingContent: '',
        finalContent: '',
        isThinkingActive: false,
      );
    }

    if (!fullStreamText.contains('<')) {
      return ThinkingParseResult(
        thinkingContent: '',
        finalContent: fullStreamText,
        isThinkingActive: false,
      );
    }

    final thinkingBlocks = <String>[];
    bool foundAnyThinkTag = false;

    String remaining = fullStreamText.replaceAllMapped(_closedThinkRegExp, (m) {
      foundAnyThinkTag = true;
      final inner = (m.group(1) ?? m.group(2) ?? '').trim();
      if (inner.isNotEmpty) {
        thinkingBlocks.add(inner);
      }
      return '';
    });

    final unclosedMatch = _openThinkTagRegExp.firstMatch(remaining);
    bool isThinkingActive = false;
    if (unclosedMatch != null) {
      foundAnyThinkTag = true;
      isThinkingActive = true;
      final trailing = remaining.substring(unclosedMatch.end).trim();
      if (trailing.isNotEmpty) {
        thinkingBlocks.add(trailing);
      }
      remaining = remaining.substring(0, unclosedMatch.start);
    }

    if (!foundAnyThinkTag) {
      return ThinkingParseResult(
        thinkingContent: '',
        finalContent: fullStreamText,
        isThinkingActive: false,
      );
    }

    final cleanFinal = remaining.replaceAll(_orphanCloseThinkRegExp, '').trim();
    return ThinkingParseResult(
      thinkingContent: thinkingBlocks.join('\n\n'),
      finalContent: cleanFinal,
      isThinkingActive: isThinkingActive,
    );
  }

  /// Splits [raw] into `(thinking, content)`. Either part may be empty.
  static ThinkingSplit split(String raw) {
    if (raw.isEmpty) return const ThinkingSplit(thinking: '', content: '');

    // Some chat templates end in `<think>` or `<|channel>thought`, so the model
    // emits only the closing delimiter; treat the prefix as reasoning.
    final close = _closeOnlyRe.firstMatch(raw);
    final firstOpen = _openMarkerRe.firstMatch(raw);
    if (close != null && (firstOpen == null || firstOpen.start > close.start)) {
      final prefix = raw.substring(0, close.start);
      final suffix = raw.substring(close.end);
      return split('<think>$prefix</think>$suffix');
    }

    String cleanTags(String text) =>
        text.replaceAll(_residualTagsRe, '').trim();

    final matches = _tagRe.allMatches(raw).toList();
    if (matches.isNotEmpty) {
      final thinkingParts = matches
          .map((m) => cleanTags(m.group(1) ?? m.group(2) ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
      final withoutClosed = raw.replaceAll(_tagRe, '');
      final trailingOpen = _openRe.firstMatch(withoutClosed);
      if (trailingOpen != null) {
        final trailingThink = cleanTags(trailingOpen.group(1) ?? '');
        if (trailingThink.isNotEmpty) {
          thinkingParts.add(trailingThink);
        }
        final visibleBeforeTrailing = cleanTags(
          withoutClosed.substring(0, trailingOpen.start),
        );
        return ThinkingSplit(
          thinking: thinkingParts.join('\n\n'),
          content: visibleBeforeTrailing,
        );
      }
      final content = cleanTags(withoutClosed);
      return ThinkingSplit(
        thinking: thinkingParts.join('\n\n'),
        content: content,
      );
    }

    final open = _openRe.firstMatch(raw);
    if (open != null) {
      final before = cleanTags(raw.substring(0, open.start));
      final thinking = cleanTags(open.group(1)!);
      return ThinkingSplit(thinking: thinking, content: before);
    }

    final bare = _bareRe.firstMatch(raw);
    if (bare != null) {
      return ThinkingSplit(
        thinking: cleanTags(bare.group(1)!),
        content: cleanTags(bare.group(2)!),
      );
    }

    return ThinkingSplit(thinking: '', content: cleanTags(raw));
  }

  /// Strips any thinking markers and returns just the user-visible content.
  static String stripThinking(String raw) => split(raw).content;

  /// Returns `true` if [raw] contains any recognised thinking marker.
  static bool hasThinking(String raw) =>
      _tagRe.hasMatch(raw) ||
      _openRe.hasMatch(raw) ||
      _bareRe.hasMatch(raw) ||
      _closeOnlyRe.hasMatch(raw);
}
