import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hearth_sync/hearth_sync.dart' show HouseholdDevice;
import 'package:openhearth_design/openhearth_design.dart';
import 'package:sanctuary_auth_core/sanctuary_auth_core.dart';
import 'package:sanctuary_backup_ui/sanctuary_backup_ui.dart';

import '../../../core/providers/sync_providers.dart';
import '../data/household_sync.dart';
import '../data/sync_settings_store.dart';
import 'sync_words.dart';
import 'wifi_sync.dart';

/// The relay a household can choose. The project relay is an opt-in option
/// households may use but never need (fleet sync decision 4); it is not
/// running yet, so it is shown and disabled.
enum RelayChoice { none, household, project }

String _normalise(String words) =>
    words.trim().toLowerCase().split(RegExp(r'\s+')).join(' ');

/// Settings → Sync with another phone. Opens into what a parent came to do:
/// start, join, or see whether it is working.
class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _label = TextEditingController();
  final _relay = TextEditingController();
  RelayChoice _choice = RelayChoice.household;
  String? _relayError, _labelError;
  bool _busy = false;
  bool _edited = false;

  HouseholdSync get _sync => ref.read(householdSyncProvider);

  @override
  void initState() {
    super.initState();
    _sync.boot().then((_) {
      if (!mounted) return;
      _fillFrom(_sync.snapshot.value);
      _sync.syncNow();
    });
  }

  void _fillFrom(SyncSnapshot s) {
    if (_edited) return;
    setState(() {
      final label = s.settings.label;
      _label.text = label == 'This phone' ? '' : label;
      _relay.text = s.settings.relay?.toString() ?? '';
      _choice = s.mode != SyncMode.off && s.settings.relay == null
          ? RelayChoice.none
          : RelayChoice.household;
    });
  }

  @override
  void dispose() {
    _label.dispose();
    _relay.dispose();
    super.dispose();
  }

  Uri? _validRelay() {
    if (_choice != RelayChoice.household) return null;
    final problem = relayAddressProblem(_relay.text);
    setState(() => _relayError = problem);
    return problem == null ? relayUri(_relay.text) : null;
  }

  String? _validLabel() {
    final t = _label.text.trim();
    setState(() => _labelError = t.isEmpty ? 'Give this phone a name, like “Phone 2”.' : null);
    return t.isEmpty ? null : t;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e, st) {
      developer.log('sync action failed', name: 'lullaby.sync', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ohFriendlyErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "Start syncing from this phone": uses the words already here, or sets
  /// them up first.
  Future<void> _start() async {
    final label = _validLabel();
    if (label == null) return;
    final relay = _validRelay();
    if (_choice == RelayChoice.household && relay == null) return;
    await _run(() async {
      final store = ref.read(secureKeyStoreProvider);
      if (await store.readMnemonic() == null) {
        if (!mounted) return;
        await const BackupFlow().runSeedSetup(context, ref);
        if (await store.readMnemonic() == null) return;
      }
      await _sync.turnOn(label: label, relay: relay);
    });
  }

  /// "Join a phone that already syncs": type the same 12 words here.
  Future<void> _join() async {
    final label = _validLabel();
    if (label == null) return;
    final relay = _validRelay();
    if (_choice == RelayChoice.household && relay == null) return;
    final words = await PhraseEntryDialog.show(
      context,
      title: 'Enter the 12 recovery words',
      body: 'Type the recovery words of the phone that already syncs. '
          'The same words on both phones make them one household.',
      confirmLabel: 'Join',
    );
    if (words == null || !mounted) return;
    if (!OpenHearthMnemonic.validate(_normalise(words))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Those aren’t 12 recovery words. Check each word and try again.')));
      return;
    }
    final store = ref.read(secureKeyStoreProvider);
    final mine = await store.readMnemonic();
    if (mine != null && _normalise(mine) != _normalise(words)) {
      if (!mounted) return;
      final ok = await showOhConfirm(
        context,
        title: 'Use the other phone’s words here?',
        message: 'This phone has its own recovery words. Joining replaces them. '
            'Backups made on this phone with its old words open only with '
            'those old words, so keep them if you have such backups.',
        confirmLabel: 'Replace words and join',
      );
      if (!ok) return;
    }
    await _run(() async {
      await store.writeMnemonic(_normalise(words));
      // Typed in full, so they are evidently written down somewhere.
      await store.writeSeedAcknowledged();
      ref.invalidate(authNotifierProvider);
      await _sync.turnOn(label: label, relay: relay);
    });
  }

  Future<void> _saveRelay() async {
    final relay = _validRelay();
    if (_choice == RelayChoice.household && relay == null) return;
    await _run(() => _sync.setRelay(relay));
  }

  /// The words, typed again, gate both Forgets (fleet sync decision 2).
  Future<bool> _wordsMatch(String why) async {
    final typed = await PhraseEntryDialog.show(
      context,
      title: 'Enter the 12 recovery words',
      body: why,
      confirmLabel: 'Continue',
    );
    if (typed == null || !mounted) return false;
    final stored = await ref.read(secureKeyStoreProvider).readMnemonic();
    final ok = stored != null && _normalise(stored) == _normalise(typed);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Those words don’t match this household’s. Nothing was changed.')));
    }
    return ok;
  }

  Future<void> _forgetThis() async {
    final ok = await _wordsMatch(
        'Forgetting this phone stops it syncing and removes the recovery words '
        'from it. Its records stay on it. Type the words to confirm.');
    if (!ok || !mounted) return;
    final sure = await showOhConfirm(
      context,
      title: 'Forget this phone?',
      message: 'It stops syncing with the household and its recovery words are '
          'removed from it. The records on it stay. To sync again, join with '
          'the words.',
      confirmLabel: 'Forget this phone',
      destructive: true,
    );
    if (!sure) return;
    await _run(() async {
      await _sync.forgetThisDevice();
      ref.invalidate(authNotifierProvider);
    });
  }

  Future<void> _forgetOther(HouseholdDevice d) async {
    final ok = await _wordsMatch(
        'Forgetting “${d.label}” stops the household taking its changes. '
        'It is wiped when it next connects. Type the words to confirm.');
    if (!ok || !mounted) return;
    final sure = await showOhConfirm(
      context,
      title: 'Forget “${d.label}”?',
      message: 'Its later changes stop counting on every phone. What it already '
          'has stays on it. A phone forgotten by mistake can join again.',
      confirmLabel: 'Forget ${d.label}',
      destructive: true,
    );
    if (!sure) return;
    await _run(() => _sync.forgetDevice(d.device));
  }

  Future<void> _typeWordsAgain() async {
    final words = await PhraseEntryDialog.show(
      context,
      title: 'Enter the 12 recovery words',
      body: 'Sync was on, but this phone no longer has its recovery words. '
          'Type them to carry on.',
      confirmLabel: 'Continue',
    );
    if (words == null || !mounted) return;
    if (!OpenHearthMnemonic.validate(_normalise(words))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Those aren’t 12 recovery words. Check each word and try again.')));
      return;
    }
    await _run(() async {
      final store = ref.read(secureKeyStoreProvider);
      await store.writeMnemonic(_normalise(words));
      await store.writeSeedAcknowledged();
      ref.invalidate(authNotifierProvider);
      await _sync.resume();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(householdSyncProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sync with another phone')),
      body: OhPage(
        padding: EdgeInsets.zero,
        child: ValueListenableBuilder<SyncSnapshot>(
          valueListenable: sync.snapshot,
          builder: (context, s, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: switch (s.mode) {
              SyncMode.off => _offView(context, s),
              SyncMode.starting => [const _Busy()],
              SyncMode.needsWords => _needsWordsView(context, s),
              SyncMode.failed => _failedView(context, s),
              SyncMode.on => _onView(context, s),
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _offView(BuildContext context, SyncSnapshot s) {
    final theme = Theme.of(context);
    return [
      if (s.forgotten)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'This phone was removed from the household’s sync. Its records '
              'stay here. Join again with the 12 words to sync once more.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      Text(
        wifiSyncAvailable
            ? 'Share this baby’s record with your partner’s phone. Changes travel '
                'sealed with your 12 recovery words: straight to the other phone '
                'on the same Wi-Fi, or through a relay that passes them on and '
                'cannot read them.'
            : 'Share this baby’s record with your partner’s phone. Changes travel '
                'sealed with your 12 recovery words, through a relay that passes them '
                'on and cannot read them.',
        style: theme.textTheme.bodyLarge,
      ),
      const SizedBox(height: 16),
      _labelField(),
      const SizedBox(height: 16),
      ..._relayChoice(context, includeNone: wifiSyncAvailable, starting: true),
      const SizedBox(height: 24),
      FilledButton.icon(
        key: const Key('sync-start'),
        onPressed: _busy ? null : _start,
        icon: const Icon(Icons.sync),
        label: const Text('Start syncing from this phone'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const Key('sync-join'),
        onPressed: _busy ? null : _join,
        icon: const Icon(Icons.phonelink),
        label: const Text('Join a phone that already syncs'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      const SizedBox(height: 16),
      Text(
        wifiSyncAvailable
            ? 'Joining: on the second phone, choose Join and type the same 12 words. '
                'With no relay, then use Sync on this Wi-Fi.'
            : 'Joining: on the second phone, choose Join and type the same 12 words.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    ];
  }

  Widget _labelField() => TextField(
        key: const Key('sync-label'),
        controller: _label,
        onChanged: (_) => _edited = true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'This phone’s name',
          hintText: 'Phone 2',
          helperText: 'Shown on notes and in the other phone’s list. The relay sees it too.',
          helperMaxLines: 2,
          errorText: _labelError,
          border: const OutlineInputBorder(),
        ),
      );

  List<Widget> _relayChoice(BuildContext context,
      {required bool includeNone, bool starting = false}) {
    final theme = Theme.of(context);
    return [
      Text('Relay', style: theme.textTheme.titleMedium),
      RadioGroup<RelayChoice>(
        groupValue: _choice,
        onChanged: (v) => setState(() {
          _edited = true;
          if (v != null) _choice = v;
        }),
        child: Column(
          children: [
            if (includeNone)
              RadioListTile<RelayChoice>(
                value: RelayChoice.none,
                title: const Text('None'),
                subtitle: Text(starting
                    ? 'Sync only with a phone on the same Wi-Fi.'
                    : wifiSyncAvailable
                        ? 'Same-Wi-Fi sync still works; nothing goes to a relay.'
                        : 'Pause: changes wait on this phone.'),
              ),
            const RadioListTile<RelayChoice>(
              value: RelayChoice.household,
              title: Text('A household relay'),
              subtitle: Text('One you or someone you trust runs.'),
            ),
            const RadioListTile<RelayChoice>(
              value: RelayChoice.project,
              enabled: false,
              title: Text('OpenHearth relay'),
              subtitle: Text('Not available yet.'),
            ),
          ],
        ),
      ),
      if (_choice == RelayChoice.household)
        TextField(
          key: const Key('sync-relay'),
          controller: _relay,
          onChanged: (_) => _edited = true,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Relay address',
            hintText: 'https://relay.example.org/',
            errorText: _relayError,
            border: const OutlineInputBorder(),
          ),
        ),
    ];
  }

  List<Widget> _needsWordsView(BuildContext context, SyncSnapshot s) => [
        Text(syncHeadline(s, DateTime.now()), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('Records you log meanwhile stay on this phone and join the '
            'household’s record once the words are back.'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _typeWordsAgain,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Type the 12 words'),
        ),
      ];

  List<Widget> _failedView(BuildContext context, SyncSnapshot s) => [
        Text(syncHeadline(s, DateTime.now()), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : () => _run(_sync.resume),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Try again'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy ? null : () => _run(_sync.startOver),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('Stop syncing on this phone'),
        ),
      ];

  List<Widget> _onView(BuildContext context, SyncSnapshot s) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return [
      Card(
        key: const Key('sync-status'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Syncing as ${s.settings.label}', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(syncHeadline(s, now), style: theme.textTheme.bodyLarge),
              if (syncWaitingLine(s) case final w?)
                Text(w, style: theme.textTheme.bodyMedium),
              if (s.settings.relay != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('sync-now'),
                  onPressed: _busy ? null : () => _run(() async => _sync.syncNow()),
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync now'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ],
          ),
        ),
      ),
      if (s.review.isNotEmpty)
        ListTile(
          key: const Key('sync-review'),
          leading: const Icon(Icons.rule),
          title: Text(s.review.length == 1
              ? '1 change to look over'
              : '${s.review.length} changes to look over'),
          subtitle: const Text('Edits a merge set aside'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/sync/review'),
        ),
      const SizedBox(height: 16),
      WifiSyncSection(enabled: !_busy),
      const SizedBox(height: 24),
      ..._relayChoice(context, includeNone: true),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _busy ? null : _saveRelay,
          child: const Text('Save relay'),
        ),
      ),
      const Divider(height: 32),
      Text('Phones in this household', style: theme.textTheme.titleMedium),
      for (final d in s.devices)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(d.forgotten ? Icons.phonelink_erase : Icons.smartphone),
          title: Text(d.label),
          subtitle: Text(d.me ? 'This phone' : d.forgotten ? 'Forgotten' : 'Syncing'),
          trailing: d.me || d.forgotten
              ? null
              : TextButton(
                  onPressed: _busy ? null : () => _forgetOther(d),
                  child: const Text('Forget'),
                ),
        ),
      const Divider(height: 32),
      Text(
        'While sync is on, restoring a backup file is turned off: it would '
        'replace both phones’ records at once.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        key: const Key('sync-forget-self'),
        onPressed: _busy ? null : _forgetThis,
        icon: const Icon(Icons.phonelink_erase),
        label: const Text('Forget this phone'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: theme.colorScheme.error,
        ),
      ),
    ];
  }
}

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Opening the household’s record…'),
          ],
        ),
      );
}
