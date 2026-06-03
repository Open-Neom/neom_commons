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
  /// Parses the cumulative stream text to separate reasoning steps and final output.
  /// Captures anything inside `<think>...</think>` tags (or active unclosed `<think>` tags).
  static ThinkingParseResult parse(String fullStreamText) {
    if (fullStreamText.isEmpty) {
      return const ThinkingParseResult(
        thinkingContent: '',
        finalContent: '',
        isThinkingActive: false,
      );
    }

    final thinkRegExp = RegExp(r'<think>([\s\S]*?)(?:</think>|$)');
    final match = thinkRegExp.firstMatch(fullStreamText);

    if (match == null) {
      // No think tag present at all, everything is standard content.
      return ThinkingParseResult(
        thinkingContent: '',
        finalContent: fullStreamText,
        isThinkingActive: false,
      );
    }

    final thinking = match.group(1) ?? '';
    final hasClosedTag = fullStreamText.contains('</think>');
    final isThinkingActive = !hasClosedTag;

    // Remove the entire <think>...</think> block from the visible final output
    String finalContent = fullStreamText.replaceAll(thinkRegExp, '');

    return ThinkingParseResult(
      thinkingContent: thinking.trim(),
      finalContent: finalContent.trim(),
      isThinkingActive: isThinkingActive,
    );
  }
}
