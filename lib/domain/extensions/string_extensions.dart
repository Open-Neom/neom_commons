extension SafeStringTruncation on String {
  /// Truncates a string safely without splitting UTF-16 surrogate pairs.
  String truncateSafe(int maxLength) {
    if (maxLength <= 0) return '';
    if (length <= maxLength) return this;

    int end = maxLength;
    // Rango High Surrogate: 0xD800 a 0xDBFF
    // If the unit at end-1 is a High Surrogate, then the character continues
    // to the next code unit (Low Surrogate). So we must step back by 1 to
    // keep the character complete before the cut.
    int lastCodeUnit = codeUnitAt(end - 1);
    if (lastCodeUnit >= 0xD800 && lastCodeUnit <= 0xDBFF) {
      end -= 1;
    }

    return substring(0, end);
  }
}
