import 'package:flutter_test/flutter_test.dart';
import 'package:safe_spaces/features/spaces/domain/entities/citation.dart';
import 'package:safe_spaces/features/spaces/domain/entities/safe_space.dart';
import 'package:safe_spaces/features/spaces/domain/entities/safety_label.dart';
import 'package:safe_spaces/features/spaces/domain/usecases/discover_spaces.dart';

SafeSpace _space({
  required String id,
  required SafetyLabel label,
  int? distance,
}) {
  return SafeSpace(
    id: id,
    googlePlaceId: 'g_$id',
    name: 'Place $id',
    types: const [],
    lat: 0,
    lng: 0,
    googleRatingsTotal: 0,
    safetyScore: 50,
    safetyLabel: label,
    positiveSignals: const [],
    negativeSignals: const [],
    webCitations: const <Citation>[],
    reviews: const [],
    deepChecked: false,
    distanceMeters: distance,
  );
}

void main() {
  group('SafeSpace.distanceLabel', () {
    test('formats meters under 1 km', () {
      expect(_space(id: '1', label: SafetyLabel.safe, distance: 120).distanceLabel,
          '120 m');
    });

    test('formats kilometers with comma decimal', () {
      expect(_space(id: '2', label: SafetyLabel.safe, distance: 1400).distanceLabel,
          '1,4 km');
    });

    test('is null when distance is unknown', () {
      expect(_space(id: '3', label: SafetyLabel.safe).distanceLabel, isNull);
    });
  });

  group('SafetyFilter', () {
    final safe = _space(id: 'a', label: SafetyLabel.safe);
    final unsafe = _space(id: 'b', label: SafetyLabel.notSafe);

    test('all matches everything', () {
      expect(SafetyFilter.all.matches(safe), isTrue);
      expect(SafetyFilter.all.matches(unsafe), isTrue);
    });

    test('safe matches only safe spaces', () {
      expect(SafetyFilter.safe.matches(safe), isTrue);
      expect(SafetyFilter.safe.matches(unsafe), isFalse);
    });

    test('notSafe matches only unsafe spaces', () {
      expect(SafetyFilter.notSafe.matches(unsafe), isTrue);
      expect(SafetyFilter.notSafe.matches(safe), isFalse);
    });
  });

  group('SafetyLabel.fromApi', () {
    test('maps known values', () {
      expect(SafetyLabel.fromApi('safe'), SafetyLabel.safe);
      expect(SafetyLabel.fromApi('not_safe'), SafetyLabel.notSafe);
      expect(SafetyLabel.fromApi('neutral'), SafetyLabel.neutral);
    });

    test('falls back to neutral on unknown', () {
      expect(SafetyLabel.fromApi('???'), SafetyLabel.neutral);
      expect(SafetyLabel.fromApi(null), SafetyLabel.neutral);
    });
  });
}
