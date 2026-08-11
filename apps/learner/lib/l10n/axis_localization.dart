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

String axisHelpOf(AxisKind axis, Strings s) => switch (axis) {
      AxisKind.authenticity => s.axisHelpAuthenticity,
      AxisKind.claimVeracity => s.axisHelpClaim,
      AxisKind.contextIntegrity => s.axisHelpContext,
    };
