import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/mission_repository.dart';
import '../../data/models.dart';
import '../../l10n/strings.dart';
import '../common/failure_view.dart';
import '../receipt/receipt_screen.dart';

/// Who the learner is here, and what the app holds about them.
///
/// Two things this screen exists to say plainly: that a guest is not
/// tracked by name, and that everything held can be taken away. Both are
/// commitments from `PRIVACY.md`, and a privacy promise that lives only
/// in a policy document is not a promise a learner can act on.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.repository});

  final MissionRepository repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<({Progress progress, List<Receipt> receipts})> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _retry() => setState(() => _future = _load());

  Future<({Progress progress, List<Receipt> receipts})> _load() async {
    final progress = await widget.repository.getMyProgress();
    final receipts = await widget.repository.listReceipts();
    return (progress: progress, receipts: receipts);
  }

  Future<void> _export(Progress progress, List<Receipt> receipts) async {
    // Everything held, as readable text. Deliberately plain rather than
    // a download: it works identically on web and mobile, and the
    // learner can see exactly what they are taking before pasting it.
    final s = Strings.of(context);
    final buffer = StringBuffer()
      ..writeln('Evidence Gym — ${s.exportData}')
      ..writeln(DateTime.now().toIso8601String())
      ..writeln()
      ..writeln('XP: ${progress.totalXp}');

    for (final skill in progress.skills) {
      buffer.writeln('${skill.skill}: ${(skill.mastery * 100).round()}%');
    }
    buffer.writeln();
    for (final receipt in receipts) {
      buffer.writeln('${receipt.id}  ${receipt.createdAt.toIso8601String()}');
      for (final a in receipt.assessments) {
        buffer.writeln('  ${a.label} (${a.confidence}%)');
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s.exportCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final tokens = context.tokens;

    return FutureBuilder<({Progress progress, List<Receipt> receipts})>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Semantics(label: s.loading, child: const CircularProgressIndicator()),
          );
        }

        // Without this a failed load rendered as "Guest, 0 XP, no
        // receipts" — a network error presented as an empty account.
        if (snapshot.hasError) {
          return FailureView(
            error: snapshot.error,
            onRetry: _retry,
            isDemo: widget.repository.isDemo,
          );
        }

        final progress = snapshot.data!.progress;
        final receipts = snapshot.data!.receipts;

        return ReadableWidth(
          child: ListView(
            padding: EdgeInsets.all(tokens.space(2)),
            children: [
              Row(
                children: [
                  Lupa(mood: LupaMood.idle, size: 72, semanticLabel: s.lupaLabel('idle')),
                  SizedBox(width: tokens.space(2)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.youGuest,
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text(s.statXp(progress.totalXp),
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SectionRule(),
              Text(s.guestExplained, style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: tokens.space(3)),

              Text(s.historyTitle, style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: tokens.space(1)),
              if (receipts.isEmpty)
                Text(s.historyEmpty, style: Theme.of(context).textTheme.bodyMedium)
              else
                for (final (index, receipt) in receipts.indexed)
                  RevealOnScroll(
                    delayIndex: index,
                    child: Card(
                      // `onFocusChange: null` sat here with a comment
                      // claiming it made the tile announce as a button.
                      // It is the parameter's default and does nothing;
                      // ListTile's InkWell carries the tap action but
                      // never sets the button flag. This is the node that
                      // actually declares the role.
                      child: Builder(builder: (context) {
                        void open() => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReceiptScreen(
                                  repository: widget.repository,
                                  receiptId: receipt.id,
                                ),
                              ),
                            );
                        // The role and the action go on the same node.
                        // Declaring `button: true` here while the action
                        // lives on the ListTile's InkWell below leaves a
                        // node that announces as a button and does
                        // nothing when activated — the exact defect
                        // semantics_test.dart was written to catch.
                        return Semantics(
                          button: true,
                          onTap: open,
                          child: ListTile(
                            leading: Icon(Icons.receipt_long_outlined,
                                color: tokens.evidencePrimary),
                            title: Text(s.receiptNumbered(index + 1)),
                            subtitle: Text(
                              s.formatDateTime(receipt.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: open,
                          ),
                        );
                      }),
                    ),
                  ),
              SizedBox(height: tokens.space(3)),

              OutlinedButton.icon(
                onPressed: () => _export(progress, receipts),
                icon: const Icon(Icons.download_outlined),
                label: Text(s.exportData),
              ),
              SizedBox(height: tokens.space(0.5)),
              Text(s.exportExplained, style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: tokens.space(3)),
            ],
          ),
        );
      },
    );
  }
}
