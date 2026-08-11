import 'package:design_system/design_system.dart';

import 'strings.dart';

/// Joins the contract-stable axis vocabulary (owned by `design_system`)
/// with localized display text. The `code` travels to the API; the
/// `label` never does.
List<AxisOption> localizedAxisOptions(AxisKind axis, Strings s) => axisOptionCodes(axis)
    .map((o) => AxisOption(code: o.code, label: s.axisOptionLabel(o.code), tone: o.tone))
    .toList();

String axisNameOf(AxisKind axis, Strings s) => switch (axis) {
      AxisKind.authenticity => s.axisAuthenticity,
      AxisKind.claimVeracity => s.axisClaim,
      AxisKind.contextIntegrity => s.axisContext,
    };

/// Rebuilds a display option from the stable code stored on a receipt.
/// An unrecognised code (an older or newer content pack) is shown
/// verbatim with neutral styling rather than dropped — a receipt must
/// stay readable even when the client does not know the vocabulary.
AxisOption axisOptionFromCode(AxisKind axis, String code, Strings s) {
  for (final option in axisOptionCodes(axis)) {
    if (option.code == code) {
      return AxisOption(code: code, label: s.axisOptionLabel(code), tone: option.tone);
    }
  }
  return AxisOption(code: code, label: s.axisOptionLabel(code), tone: AxisTone.unknown);
}

String axisHelpOf(AxisKind axis, Strings s) => switch (axis) {
      AxisKind.authenticity => s.axisHelpAuthenticity,
      AxisKind.claimVeracity => s.axisHelpClaim,
      AxisKind.contextIntegrity => s.axisHelpContext,
    };
