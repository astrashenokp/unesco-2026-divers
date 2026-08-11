import 'package:flutter/widgets.dart';

/// Layout sizes. Mobile is primary; wider layouts add a secondary pane
/// but never change reading/focus order (`SCREEN_INVENTORY.md`).
enum FormFactor { phone, tablet, desktop }

extension FormFactorX on FormFactor {
  bool get isPhone => this == FormFactor.phone;

  /// Tablet and desktop both get the two-pane treatment and a rail
  /// instead of a bottom bar.
  bool get isWide => this != FormFactor.phone;
}

/// Breakpoints follow Material's window size classes (compact / medium /
/// expanded) so behaviour matches what platform users already expect.
FormFactor formFactorOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return FormFactor.phone;
  if (width < 1024) return FormFactor.tablet;
  return FormFactor.desktop;
}

/// Caps line length on wide screens. Long measures are a readability
/// problem for exactly the low-confidence readers this product serves.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
