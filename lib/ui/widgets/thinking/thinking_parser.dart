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

/// Helper utility to parse reasoning tokens from model stream output.
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
}
