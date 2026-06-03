abstract class IBloomFilter {
  /// Adds a packet unique key (e.g. "routeId-seqId") to the filter
  void add(String element);

  /// Checks if the element has likely been seen before (probabilistic check)
  bool contains(String element);

  /// Flushes all entries in the filter
  void clear();
}
