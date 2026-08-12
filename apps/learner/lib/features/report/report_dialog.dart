import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/strings.dart';

/// Report harmful or incorrect content.
///
/// `danger` is the one place in the product that colour is allowed to mean
/// alarm — this is a safety affordance, not a learning verdict.
///
/// The dialog acknowledges without exposing moderation state (the API
/// answers `202`, never "we removed it"), matching `ABUSE_MODERATION.md`:
/// a reporter must not be able to probe what the moderation queue did.
Future<void> showReportDialog({
  required BuildContext context,
  required String missionId,
  required bool isDemo,
  required Future<void> Function(String reason, String? detail) onSubmit,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        _ReportDialog(missionId: missionId, isDemo: isDemo, onSubmit: onSubmit),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.missionId,
    required this.isDemo,
    required this.onSubmit,
  });

  final String missionId;

  /// In demo mode nothing leaves the device, so the confirmation must not
  /// claim a reviewer will see it.
  final bool isDemo;
  final Future<void> Function(String reason, String? detail) onSubmit;

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _detailController = TextEditingController();
  String? _reason;
  bool _sending = false;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null || _sending) return;
    setState(() => _sending = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final s = Strings.of(context);
    final confirmation = widget.isDemo ? s.reportSentDemo : s.reportSent;
    final failure = s.reportFailed;

    try {
      await widget.onSubmit(
        _reason!,
        _detailController.text.trim().isEmpty ? null : _detailController.text.trim(),
      );
    } catch (_) {
      // A failed send must not be confirmed as received. Keep the dialog
      // open with its content intact so the report isn't silently lost.
      if (mounted) setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(content: Text(failure)));
      return;
    }

    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(confirmation)));
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    final reasons = <String, String>{
      'incorrect': s.reportIncorrect,
      'harmful': s.reportHarmful,
      'outdated': s.reportOutdated,
      'copyright': s.reportCopyright,
      'accessibility': s.reportAccessibility,
      'other': s.reportOther,
    };

    return AlertDialog(
      icon: Icon(Icons.flag_outlined, color: tokens.danger),
      title: Text(s.reportTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.reportReason, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(height: tokens.space(1)),
            // RadioGroup owns the selection; per-tile groupValue/onChanged
            // were deprecated after 3.32. The ancestor also gives the set
            // proper radio-group semantics for a screen reader.
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in reasons.entries)
                    RadioListTile<String>(
                      value: entry.key,
                      title: Text(entry.value),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
            SizedBox(height: tokens.space(1)),
            TextField(
              controller: _detailController,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: s.reportDetail,
                border: const OutlineInputBorder(),
              ),
            ),
            Text(s.reportPrivacy, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        ElevatedButton(
          onPressed: _reason == null || _sending ? null : _submit,
          child: Text(s.send),
        ),
      ],
    );
  }
}
