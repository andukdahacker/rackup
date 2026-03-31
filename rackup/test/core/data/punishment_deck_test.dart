import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/data/punishment_deck.dart';

void main() {
  group('builtInPunishments', () {
    test('is non-empty', () {
      expect(builtInPunishments, isNotEmpty);
      expect(builtInPunishments.length, greaterThanOrEqualTo(30));
    });
  });

  group('randomPunishment', () {
    test('returns a valid string from the deck', () {
      final result = randomPunishment();
      expect(result, isA<String>());
      expect(result, isNotEmpty);
      expect(builtInPunishments, contains(result));
    });
  });
}
