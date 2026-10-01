import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth_sync/hearth_sync.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/providers/sync_providers.dart';
import '../data/household_sync.dart';

/// Same-Wi-Fi sync can run in this build (not in a browser).
const wifiSyncAvailable = true;

/// What the QR code carries: an app link the phone's own camera can open,
/// straight into "Type a code" with the code filled in (no in-app scanner;
/// hearthSync ADR 0014).
String wifiSyncLink(String code) => 'lullaby://sync/settings/sync/wifi?code=$code';

/// The "Sync on this Wi-Fi" block on the sync screen, while sync is on.
class WifiSyncSection extends StatelessWidget {
  const WifiSyncSection({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Sync on this Wi-Fi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Both phones on the same Wi-Fi: one shows a code, the other types it. '
          'No relay needed.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          key: const Key('wifi-show'),
          onPressed: enabled ? () => context.push('/settings/sync/wifi?mode=show') : null,
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Show a code'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('wifi-type'),
          onPressed: enabled ? () => context.push('/settings/sync/wifi') : null,
          icon: const Icon(Icons.keyboard),
          label: const Text('Type a code'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }
}

/// Words for a same-Wi-Fi sync that did not happen.
String wifiProblem(Object e, {required bool showing}) {
  if (e is LanException) {
    switch (e.code) {
      case 'bad_code':
        return 'That code has a typo. Check it against the other phone.';
      case 'unreachable':
        return showing
            ? 'This phone isn’t on a Wi-Fi network. Join the same Wi-Fi as the other phone.'
            : 'Couldn’t reach the other phone. Check that both are on the same Wi-Fi '
                'and the code is still showing.';
      case 'timeout':
        return 'The other phone stopped answering. Try again with a new code.';
      case 'expired':
        return 'Nobody used the code in time. Show a new one.';
      case 'refused':
        return showing
            ? 'A phone that isn’t in this household tried the code. Nothing was shared. Show a new code.'
            : 'The other phone isn’t in this household, or the code was already used.';
      case 'used':
        return 'That code was already used or has expired. Show a new one on the other phone.';
    }
  }
  if (e is StateError) return 'Turn sync on first.';
  return ohFriendlyErrorMessage(e);
}

/// Settings → Sync with another phone → Show a code / Type a code.
class WifiSyncScreen extends ConsumerStatefulWidget {
  const WifiSyncScreen({super.key, required this.show, this.code});

  /// Show a code (this phone listens); otherwise type one.
  final bool show;

  /// A code from the QR link, filled in.
  final String? code;

  @override
  ConsumerState<WifiSyncScreen> createState() => _WifiSyncScreenState();
}

enum _Stage { idle, waiting, syncing, done, failed }

class _WifiSyncScreenState extends ConsumerState<WifiSyncScreen> {
  late final _code = TextEditingController(text: widget.code ?? '');
  _Stage _stage = _Stage.idle;
  String? _problem;
  LanCode? _shown;

  late final HouseholdSync _sync;

  @override
  void initState() {
    super.initState();
    _sync = ref.read(householdSyncProvider);
    if (widget.show) _listen();
  }

  @override
  void dispose() {
    // Leaving the screen takes the code away.
    if (widget.show && _stage == _Stage.waiting) unawaited(_sync.stopWifi());
    _code.dispose();
    super.dispose();
  }

  void _fail(Object e) {
    developer.log('Wi-Fi sync failed', name: 'lullaby.sync', error: e);
    if (!mounted) return;
    setState(() {
      _stage = _Stage.failed;
      _problem = wifiProblem(e, showing: widget.show);
    });
  }

  Future<void> _listen() async {
    setState(() {
      _stage = _Stage.syncing;
      _problem = null;
    });
    try {
      final listener = await _sync.listenOnWifi();
      if (!mounted) return;
      setState(() {
        _shown = listener.code;
        _stage = _Stage.waiting;
      });
      await listener.done;
      if (mounted) setState(() => _stage = _Stage.done);
    } on Object catch (e) {
      _fail(e);
    }
  }

  Future<void> _join() async {
    if (LanCode.tryParse(_code.text) == null) {
      setState(() {
        _stage = _Stage.failed;
        _problem = wifiProblem(const LanException('bad_code'), showing: false);
      });
      return;
    }
    setState(() {
      _stage = _Stage.syncing;
      _problem = null;
    });
    try {
      await _sync.syncOnWifi(LanCode.tryParse(_code.text)!);
      if (mounted) setState(() => _stage = _Stage.done);
    } on Object catch (e) {
      _fail(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Opened from the QR link, this screen is the only page: there is
    // nothing to pop, so Back (arrow or gesture) leads to Sync with another
    // phone instead of leaving the app.
    final router = GoRouter.maybeOf(context);
    final linked = router != null && !Navigator.of(context).canPop();
    void toSync() => router!.go('/settings/sync');
    return PopScope(
      canPop: !linked,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && linked) toSync();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: linked ? BackButton(onPressed: toSync) : null,
          title: Text(widget.show ? 'Show a code' : 'Type a code'),
        ),
        body: OhPage(
          padding: EdgeInsets.zero,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: widget.show ? _showView(context) : _typeView(context),
          ),
        ),
      ),
    );
  }

  Widget _doneView(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('wifi-done'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle_outline, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text('Synced with the other phone.',
            textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.pop(),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _problemText(BuildContext context) => Text(
        _problem ?? '',
        key: const Key('wifi-problem'),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      );

  List<Widget> _showView(BuildContext context) {
    final theme = Theme.of(context);
    final code = _shown;
    return switch (_stage) {
      _Stage.done => [_doneView(context)],
      _Stage.failed => [
          _problemText(context),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _listen,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Show a new code'),
          ),
        ],
      _Stage.waiting when code != null => [
          Text(
            'On the other phone, open Settings, then Sync with another phone, then Type '
            'a code, and type this. Or point its camera at the square.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: QrImageView(
                data: wifiSyncLink(code.text),
                size: 200,
                backgroundColor: Colors.white,
                semanticsLabel: 'The code as a square for the other phone’s camera',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SelectableText(
              code.text,
              key: const Key('wifi-code'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Waiting for the other phone. The code works once, for 10 minutes.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Cancel'),
          ),
        ],
      _ => [
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          const Text('Getting a code…', textAlign: TextAlign.center),
        ],
    };
  }

  List<Widget> _typeView(BuildContext context) {
    final theme = Theme.of(context);
    if (_stage == _Stage.done) return [_doneView(context)];
    final busy = _stage == _Stage.syncing;
    return [
      Text(
        'On the other phone, choose Show a code. Then type it here. Both phones '
        'need to be on the same Wi-Fi.',
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: 16),
      TextField(
        key: const Key('wifi-code-field'),
        controller: _code,
        enabled: !busy,
        autofocus: widget.code == null,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z\- ]'))],
        style: theme.textTheme.titleLarge?.copyWith(fontFamily: 'monospace', letterSpacing: 1.5),
        decoration: const InputDecoration(
          labelText: 'Code from the other phone',
          hintText: 'XXXXXX-XXXXXX-XXXXXX',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => busy ? null : _join(),
      ),
      const SizedBox(height: 16),
      if (_stage == _Stage.failed) ...[_problemText(context), const SizedBox(height: 16)],
      FilledButton.icon(
        key: const Key('wifi-sync'),
        onPressed: busy ? null : _join,
        icon: busy
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.sync),
        label: Text(busy ? 'Syncing…' : 'Sync'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    ];
  }
}
