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

double _toLinear(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _toSrgb(double c) => (c <= 0.0031308
        ? 12.92 * c
        : 1.055 * math.pow(c, 1 / 2.4).toDouble() - 0.055)
    .clamp(0.0, 1.0);

/// CIELAB coordinates under a D65 white point.
(double, double, double) _lab(Color c) {
  final r = _toLinear(c.r);
  final g = _toLinear(c.g);
  final b = _toLinear(c.b);

  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;

  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;

  final fx = f(x), fy = f(y), fz = f(z);
  return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
}

/// Perceptual distance between two colours (CIE76).
///
/// Not a contrast ratio: contrast compares lightness only, so two
/// colours of equal lightness and opposite hue score as identical.
double _deltaE(Color a, Color b) {
  final (l1, a1, b1) = _lab(a);
  final (l2, a2, b2) = _lab(b);
  return math.sqrt(
      math.pow(l1 - l2, 2) + math.pow(a1 - a2, 2) + math.pow(b1 - b2, 2));
}

/// How a colour appears to someone with deuteranopia.
///
/// The standard Viénot–Brettel–Mollon reduction, applied in linear RGB
/// because the transform models cone response, not encoded values.
Color _deuteranopia(Color c) {
  final r = _toLinear(c.r);
  final g = _toLinear(c.g);
  final b = _toLinear(c.b);
  return Color.from(
    alpha: 1,
    red: _toSrgb(0.625 * r + 0.375 * g),
    green: _toSrgb(0.70 * r + 0.30 * g),
    blue: _toSrgb(0.30 * g + 0.70 * b),
  );
}

void main() {
  // Both themes face the same audit. A dark theme is where accessibility
  // usually slips: it gets added late, checked by eye, and ships with
  // accents that were only ever legible on white. Running one list over
  // both token sets means the dark palette cannot be held to a lower
  // standard than the light one.
  const themes = {
    'light': EvidenceGymTokens.standard,
    'dark': EvidenceGymTokens.dark,
  };

  themes.forEach((themeName, t) {
    // Every pair below actually occurs in the UI. Checking pairs that
    // are never rendered together would give false confidence; missing a
    // pair that is rendered gives false safety. This list is the audit.
    final normalText = <String, (Color, Color)>{
      'textPrimary on surface': (t.textPrimary, t.surface),
      'textPrimary on surfaceRaised': (t.textPrimary, t.surfaceRaised),
      'textMuted on surface': (t.textMuted, t.surface),
      'textMuted on surfaceRaised': (t.textMuted, t.surfaceRaised),
      // onAction rather than white: on the dark theme the action fill is
      // pale and takes a dark label instead.
      'onAction on action': (t.onAction, t.action),
      'onAction on evidencePrimary': (t.onAction, t.evidencePrimary),
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

    group('WCAG 2.2 AA contrast ($themeName)', () {
      normalText.forEach((name, pair) {
        test('$name meets 4.5:1 for body text', () {
          final ratio = _ratio(pair.$1, pair.$2);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$themeName: $name is ${ratio.toStringAsFixed(2)}:1, needs 4.5:1',
          );
        });
      });

      nonText.forEach((name, pair) {
        test('$name meets 3:1 for a non-text indicator', () {
          final ratio = _ratio(pair.$1, pair.$2);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason: '$themeName: $name is ${ratio.toStringAsFixed(2)}:1, needs 3:1',
          );
        });
      });
    });

    test('no $themeName status colour is a conventional green or red', () {
      // The product argues against binary true/false verdicts, so its
      // status palette must not quietly reintroduce one. Guarding this
      // in a test means a future colour tweak cannot undo the argument —
      // including a colour tweak made only to the dark theme.
      for (final entry in {
        'supported': t.supported,
        'contradicted': t.contradicted,
        'misleading': t.misleading,
        'unknown': t.unknown,
      }.entries) {
        final c = entry.value;
        final pureGreen = c.g > c.r * 1.6 && c.g > c.b * 1.6;
        final pureRed = c.r > c.g * 1.9 && c.r > c.b * 1.9;
        expect(pureGreen, isFalse,
            reason: '$themeName ${entry.key} reads as success green');
        expect(pureRed, isFalse,
            reason: '$themeName ${entry.key} reads as error red');
      }
    });

    test('$themeName relations stay apart, including for a red-green '
        'colour-blind learner', () {
      // Colour is never the only carrier of meaning here — every
      // relation is labelled in text — but two relations that look alike
      // still cost a sighted learner the at-a-glance reading the
      // evidence graph exists to give.
      //
      // Contrast ratio is the wrong tool for this and an earlier version
      // of this test used it: it only compares lightness, so teal and
      // magenta at the same lightness score ~1:1 while being obviously
      // different colours. This measures CIELAB ΔE instead, which is
      // what "look different" actually means.
      //
      // The second pass matters more than the first. Deuteranopia is the
      // most common colour vision deficiency, and it is the reason this
      // palette avoids green-versus-red in the first place: under it,
      // that pairing collapses. Simulating it here proves the
      // replacement palette survives what the conventional one does not.
      final relations = {
        'supported': t.supported,
        'contradicted': t.contradicted,
        'misleading': t.misleading,
        'unknown': t.unknown,
      };
      final names = relations.keys.toList();
      for (var i = 0; i < names.length; i++) {
        for (var j = i + 1; j < names.length; j++) {
          final a = relations[names[i]]!;
          final b = relations[names[j]]!;
          final pair = '$themeName: ${names[i]} vs ${names[j]}';

          // ΔE around 2.3 is the just-noticeable difference; 25 is
          // comfortably "a different colour" at a glance.
          final delta = _deltaE(a, b);
          expect(delta, greaterThanOrEqualTo(25.0),
              reason: '$pair is ΔE ${delta.toStringAsFixed(1)} — too similar');

          // Lower bar under simulation, because the simulation collapses
          // one axis by design. It still has to stay clearly readable.
          final blind = _deltaE(_deuteranopia(a), _deuteranopia(b));
          expect(blind, greaterThanOrEqualTo(12.0),
              reason: '$pair is ΔE ${blind.toStringAsFixed(1)} under '
                  'deuteranopia — a red-green colour-blind learner cannot '
                  'tell these two relations apart');
        }
      }
    });
  });
}
