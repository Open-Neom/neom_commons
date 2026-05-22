// Tests for `CollectionUtilities`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/utils/collection_utilities.dart';

void main() {
  group('CollectionUtilities.mapKeysEquals', () {
    test('mapas idénticos son iguales', () {
      expect(
        CollectionUtilities.mapKeysEquals({'a': 1, 'b': 2}, {'a': 1, 'b': 2}),
        isTrue,
      );
    });

    test('mapas vacíos son iguales', () {
      expect(CollectionUtilities.mapKeysEquals({}, {}), isTrue);
    });

    test('longitudes distintas son distintos', () {
      expect(
        CollectionUtilities.mapKeysEquals({'a': 1}, {'a': 1, 'b': 2}),
        isFalse,
      );
    });

    test('mismas llaves pero valores distintos son distintos', () {
      expect(
        CollectionUtilities.mapKeysEquals({'a': 1}, {'a': 2}),
        isFalse,
      );
    });

    test('llaves distintas son distintos', () {
      expect(
        CollectionUtilities.mapKeysEquals({'a': 1}, {'b': 1}),
        isFalse,
      );
    });

    test('orden de llaves no importa', () {
      expect(
        CollectionUtilities.mapKeysEquals(
          {'a': 1, 'b': 2, 'c': 3},
          {'c': 3, 'b': 2, 'a': 1},
        ),
        isTrue,
      );
    });
  });
}
