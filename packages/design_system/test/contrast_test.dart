import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x relative luminance.
double _luminance(Color c) {
  double channel(double v) {
    final s = v; // already 0..1 in Flutter's component accessors
    return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio, 1:1 to 21:1.
double _ratio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const t = EvidenceGymTokens.standard;

  // Every pair below actually occurs in the UI. Checking pairs that are
  // never rendered together would give false confidence; missing a pair
  // that is rendered gives false safety. This list is the audit.
  final normalText = <String, (Color, Color)>{
    'textPrimary on surface': (t.textPrimary, t.surface),
    'textPrimary on surfaceRaised': (t.textPrimary, t.surfaceRaised),
    'textMuted on surface': (t.textMuted, t.surface),
    'textMuted on surfaceRaised': (t.textMuted, t.surfaceRaised),
    'white on action': (Colors.white, t.action),
    'white on evidencePrimary': (Colors.white, t.evidencePrimary),
    'action on surfaceRaised': (t.action, t.surfaceRaised),
    'supported on surfaceRaised': (t.supported, t.surfaceRaised),
    'contradicted on surfaceRaised': (t.contradicted, t.surfaceRaised),
    'unknown on surfaceRaised': (t.unknown, t.surfaceRaised),
    'danger on surfaceRaised': (t.danger, t.surfaceRaised),
  };

  // Icons, borders and the focus ring only need 3:1 under WCAG 1.4.11.
  final nonText = <String, (Color, Color)>{
    'focus ring on surface': (t.focus, t.surface),
    'evidenceSecondary border on surfaceRaised': (t.evidenceSecondary, t.surfaceRaised),
    'misleading border on surfaceRaised': (t.misleading, t.surfaceRaised),
  };

  group('WCAG 2.2 AA contrast', () {
    normalText.forEach((name, pair) {
      test('$name meets 4.5:1 for body text', () {
        final ratio = _ratio(pair.$1, pair.$2);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$name is ${ratio.toStringAsFixed(2)}:1, needs 4.5:1',
        );
      });
    });

    nonText.forEach((name, pair) {
      test('$name meets 3:1 for a non-text indicator', () {
        final ratio = _ratio(pair.$1, pair.$2);
        expect(
          ratio,
          greaterThanOrEqualTo(3.0),
          reason: '$name is ${ratio.toStringAsFixed(2)}:1, needs 3:1',
        );
      });
    });
  });

  test('no status colour is a conventional green or red', () {
    // The product argues against binary true/false verdicts, so its
    // status palette must not quietly reintroduce one. Guarding this in
    // a test means a future colour tweak cannot undo the argument.
    for (final entry in {
      'supported': t.supported,
      'contradicted': t.contradicted,
      'misleading': t.misleading,
      'unknown': t.unknown,
    }.entries) {
      final c = entry.value;
      final pureGreen = c.g > c.r * 1.6 && c.g > c.b * 1.6;
      final pureRed = c.r > c.g * 1.9 && c.r > c.b * 1.9;
      expect(pureGreen, isFalse, reason: '${entry.key} reads as success green');
      expect(pureRed, isFalse, reason: '${entry.key} reads as error red');
    }
  });
}
