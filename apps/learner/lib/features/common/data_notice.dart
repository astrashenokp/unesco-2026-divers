import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// What this app records, shown before anyone starts.
///
/// `PRIVACY.md` requires "clear notice" and every line here is read off
/// its purpose matrix — nothing about data handling is invented in this
/// file, and nothing is promised that the engineering baseline does not
/// already commit to.
///
/// Deliberately **not** a consent gate. A checkbox reading "I agree"
/// over a wall of text is the pattern that trained a generation to click
/// past exactly this kind of notice, and a product teaching people to
/// check before they trust cannot open by asking them not to. It tells
/// the learner plainly and lets them proceed; the only thing that could
/// honestly be consented to — optional research use — is not collected
/// at all, so there is nothing here to tick.
///
/// The detail opens on demand rather than being hidden behind a link to
/// somewhere else. A notice a learner has to leave the app to read is a
/// notice written to be skipped.
class DataNotice extends StatefulWidget {
  const DataNotice({super.key, required this.isDemo});

  /// Demo mode runs entirely on a local pack, so the honest notice for
  /// it is much shorter — and saying so is more reassuring than
  /// repeating a general one that does not apply.
  final bool isDemo;

  @override
  State<DataNotice> createState() => _DataNoticeState();
}

class _DataNoticeState extends State<DataNotice> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.space(1.75)),
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.space(2)),
        border: Border.all(color: tokens.textMuted.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 18, color: tokens.evidencePrimary),
              SizedBox(width: tokens.space(1)),
              Expanded(
                child: Text(
                  widget.isDemo ? s.noticeDemoSummary : s.noticeSummary,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space(0.5)),
          // A plain button, not an ExpansionTile: the tile's own header
          // semantics fought the summary text above it, announcing the
          // whole block twice.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18),
              label: Text(_expanded ? s.noticeHide : s.noticeShow),
            ),
          ),
          if (_expanded) ...[
            // The detail arrives in response to a press elsewhere on the
            // card, so it announces itself rather than waiting to be
            // stumbled upon.
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in widget.isDemo
                      ? s.noticeDemoDetail
                      : s.noticeDetail)
                    Padding(
                      padding: EdgeInsets.only(bottom: tokens.space(0.75)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ',
                              style: Theme.of(context).textTheme.bodySmall),
                          Expanded(
                            child: Text(line,
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: tokens.space(0.5)),
                  Text(
                    s.noticeAgeDefault,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
