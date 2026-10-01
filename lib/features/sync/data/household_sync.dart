import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:hearth_sync/hearth_sync.dart';

import '../../../services/database/database.dart';
import 'lullaby_records.dart';
import 'record_projection.dart';
import 'record_writer.dart';
import 'sync_settings_store.dart';

/// Where this phone's sync stands, for the Settings screen.
enum SyncMode {
  /// Sync is off: records stay on this phone and the kernel is not loaded.
  off,

  /// Opening the household's log.
  starting,

  /// Writes go through the household's log.
  on,

  /// Sync was on, but this phone has no recovery words any more. Records stay
  /// on the phone until the words are typed again.
  needsWords,

  /// The log could not be opened (see [SyncSnapshot.problem]).
  failed,
}

/// How this phone last synced.
enum SyncPath {
  /// A round with the household relay.
  relay,

  /// Phone to phone on the same Wi-Fi (hearthSync ADR 0014).
  wifi,
}

/// One look at the sync state; everything the Settings screen shows.
@immutable
class SyncSnapshot {
  const SyncSnapshot({
    this.mode = SyncMode.off,
    this.settings = const SyncSettings(),
    this.lastSynced,
    this.lastPath,
    this.lastError,
    this.retryIn,
    this.waiting = 0,
    this.review = const [],
    this.devices = const [],
    this.problem,
    this.forgotten = false,
  });

  final SyncMode mode;
  final SyncSettings settings;

  /// When a sync (relay round or Wi-Fi) last finished cleanly.
  final DateTime? lastSynced;

  /// Which path that was.
  final SyncPath? lastPath;

  /// Why the last round stopped, if it did.
  final Object? lastError;

  /// When the loop tries again after [lastError].
  final Duration? retryIn;

  /// Changes made here that the relay is not known to hold yet.
  final int waiting;

  /// Edits a merge set aside, for the review list.
  final List<ReviewItem> review;

  /// Every phone ever joined to the household.
  final List<HouseholdDevice> devices;

  /// Why the log could not be opened ([SyncMode.failed]).
  final String? problem;

  /// This phone was just removed from the household (by itself or another).
  final bool forgotten;

  SyncSnapshot copyWith({
    SyncMode? mode,
    SyncSettings? settings,
    DateTime? Function()? lastSynced,
    SyncPath? Function()? lastPath,
    Object? Function()? lastError,
    Duration? Function()? retryIn,
    int? waiting,
    List<ReviewItem>? review,
    List<HouseholdDevice>? devices,
    String? Function()? problem,
    bool? forgotten,
  }) =>
      SyncSnapshot(
        mode: mode ?? this.mode,
        settings: settings ?? this.settings,
        lastSynced: lastSynced != null ? lastSynced() : this.lastSynced,
        lastPath: lastPath != null ? lastPath() : this.lastPath,
        lastError: lastError != null ? lastError() : this.lastError,
        retryIn: retryIn != null ? retryIn() : this.retryIn,
        waiting: waiting ?? this.waiting,
        review: review ?? this.review,
        devices: devices ?? this.devices,
        problem: problem != null ? problem() : this.problem,
        forgotten: forgotten ?? this.forgotten,
      );
}

/// Turning sync on needs the 12 words.
class NoRecoveryWordsException implements Exception {
  @override
  String toString() => 'NoRecoveryWordsException';
}

/// Lullaby's side of the household sync (ADR-0007): opens the kernel over the
/// app's own Drift database when sync is on, hands repositories the right
/// [RecordWriter], runs the relay loop, and handles Forget.
///
/// With sync off it never loads the bridge and never makes an HTTP client:
/// [initBridge] and [relayClient] are only called once a parent turns sync on.
class HouseholdSync {
  HouseholdSync({
    required this.db,
    required this.settingsStore,
    required this.readWords,
    required this.deriveSeed,
    required this.signer,
    required this.initBridge,
    required this.forgetWords,
    RelayClient Function(Uri relay)? relayClient,
    SyncLoop Function(HearthSync hs, RelayClient relay)? loop,
    Clock clock = DateTime.now,
  })  : projection = RecordProjection(db),
        _relayClient = relayClient ?? RelayClient.new,
        _makeLoop = loop ?? ((hs, relay) => SyncLoop(hs, relay)),
        _clock = clock;

  final AppDatabase db;
  final SyncSettingsStore settingsStore;

  /// The household's 12 words as this phone stores them, or null.
  final Future<String?> Function() readWords;

  /// The 64-byte BIP39 seed from the words.
  final Future<Uint8List> Function(String words) deriveSeed;

  /// This phone's device key (never derived from the words).
  final Signer Function() signer;

  /// Loads the kernel (the .so, or the .wasm on the web).
  final Future<void> Function() initBridge;

  /// Deletes the words from this phone (a forgotten phone keeps none).
  final Future<void> Function() forgetWords;

  final RelayClient Function(Uri relay) _relayClient;
  final SyncLoop Function(HearthSync hs, RelayClient relay) _makeLoop;
  final Clock _clock;
  final RecordProjection projection;

  late final DriftPersist persist = DriftPersist(
    db,
    applyTables: (batch) => projection.apply(batch.changes),
  );

  HearthSync? _hs;
  SyncLoop? _loop;
  RelayClient? _relay;
  Signer? _signer;
  StreamSubscription<Changes>? _changesSub;
  StreamSubscription<SyncStatus>? _statusSub;
  Future<void>? _booted;

  /// The current state; listen for changes.
  final ValueNotifier<SyncSnapshot> snapshot = ValueNotifier(const SyncSnapshot());

  /// The open replica, when sync is on.
  HearthSync? get hearth => _hs;

  void _set(SyncSnapshot s) => snapshot.value = s;

  /// Read the settings and, if sync was on, open the log. Runs once; every
  /// write waits for it, so no write can slip past the log at launch.
  Future<void> boot() => _booted ??= _boot();

  Future<void> _boot() async {
    // Sync is on exactly when this phone holds a household log. Deciding that
    // from the database, not the settings, keeps the off path free of any
    // platform call: a phone that never turned sync on reads one table name.
    if (!await _hasLog()) return;
    SyncSettings settings;
    try {
      settings = await settingsStore.read();
    } on Object catch (e, st) {
      developer.log('sync settings unreadable', name: 'lullaby.sync', error: e, stackTrace: st);
      settings = const SyncSettings();
    }
    settings = settings.copyWith(on: true);
    _set(snapshot.value.copyWith(settings: settings));
    await _open(settings);
  }

  Future<bool> _hasLog() async {
    final table = await db
        .customSelect("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'hearth_records'")
        .get();
    if (table.isEmpty) return false;
    return (await db.customSelect('SELECT 1 FROM hearth_records LIMIT 1').get()).isNotEmpty;
  }

  /// Whether this phone holds a household log (sync on, paused, or waiting
  /// for its words).
  Future<bool> isOn() async {
    await boot();
    return snapshot.value.mode != SyncMode.off;
  }

  /// Try again to open the log: after the words were typed again
  /// ([SyncMode.needsWords]) or a failure.
  Future<void> resume() async {
    await boot();
    if (_hs != null) return;
    await _open(snapshot.value.settings);
  }

  /// Give up on a log this phone cannot open ([SyncMode.failed], e.g. its
  /// device key is gone): clear it and turn sync off. Records stay here.
  Future<void> startOver() async {
    await close();
    await persist.clear();
    await _turnedOff();
  }

  /// The writer for the next write: through the log when sync is on.
  Future<RecordWriter> writer() async {
    await boot();
    final hs = _hs;
    final label = snapshot.value.settings.label;
    if (hs != null && !hs.isWiped) {
      return HearthRecordWriter(projection, hs, author: label);
    }
    final on = snapshot.value.settings.on;
    return DirectRecordWriter(projection, author: on ? label : null, inGap: on);
  }

  Future<void> _open(SyncSettings settings) async {
    _set(snapshot.value.copyWith(mode: SyncMode.starting, problem: () => null));
    final words = await readWords();
    if (words == null) {
      _set(snapshot.value.copyWith(mode: SyncMode.needsWords));
      return;
    }
    try {
      await initBridge();
      final stored = await HearthSync.storedDevice(persist);
      if (stored?.wiped ?? false) {
        // Forgotten earlier: hand nothing on (the round at Forget did), clear.
        await persist.clear();
        await _turnedOff(forgotten: true);
        return;
      }
      _signer ??= signer();
      final hs = await HearthSync.open(
        app: lullabySyncApp,
        schema: lullabySyncSchema,
        persist: persist,
        signer: _signer!,
        seed: await deriveSeed(words),
        label: settings.label,
        clock: _clock,
      );
      _hs = hs;
      _changesSub = hs.changes.listen(_onChanges);
      await _importLocal(hs);
      _set(snapshot.value.copyWith(mode: SyncMode.on));
      await _refresh();
      _startLoop(settings.relay);
    } on DeviceWipedException {
      await persist.clear();
      await _turnedOff(forgotten: true);
    } on Object catch (e, st) {
      developer.log('could not open the sync log', name: 'lullaby.sync', error: e, stackTrace: st);
      _set(snapshot.value.copyWith(
        mode: SyncMode.failed,
        problem: () => e is HearthSyncException && e.code == 'wrong_device'
            ? 'This phone’s sync key is missing, so it can’t continue the household’s record. Forget this phone and join again.'
            : 'Sync couldn’t start on this phone. Your records are safe here.',
      ));
    }
  }

  /// Put every local row the log does not hold yet (or holds differently),
  /// and every local handoff note: what this phone logged while sync was off.
  Future<void> _importLocal(HearthSync hs) async {
    // Deletes made while the log could not be opened go first; otherwise the
    // record would live on in the household and come back.
    final gone = await projection.gapDeletes();
    if (gone.isNotEmpty) {
      final inLog = {for (final r in hs.view().rows) '${r.table}/${r.row}'};
      for (final (table, id) in gone) {
        if (inLog.contains('${table.name}/$id')) await hs.delete(table.name, id);
        await projection.clearGapDelete(table, id);
      }
    }
    final view = <String, Map<String, Object?>>{
      for (final r in hs.view().rows) '${r.table}/${r.row}': r.fields,
    };
    for (final table in recordTables) {
      final rows = await projection.readAll(table);
      for (final e in rows.entries) {
        final inLog = view['${table.name}/${e.key}'];
        final changed = inLog == null
            ? e.value
            : {
                for (final f in e.value.entries)
                  if (inLog[f.key] != f.value) f.key: f.value,
              };
        if (changed.isNotEmpty) await hs.put(table.name, e.key, changed);
      }
    }
    final notes = await db.select(db.handoffNotes).get();
    final writer = HearthRecordWriter(projection, hs, author: snapshot.value.settings.label);
    for (final n in notes) {
      if (_isLogId(n.id)) continue;
      await writer.addHandoffNote(babyId: n.babyId, text: n.body, at: n.writtenAt);
      await (db.delete(db.handoffNotes)..where((t) => t.id.equals(n.id))).go();
    }
  }

  static bool _isLogId(String id) => RegExp(r'^[0-9a-f]{64}$').hasMatch(id);

  void _startLoop(Uri? relay) {
    final hs = _hs;
    if (hs == null || relay == null) return;
    _relay = _relayClient(relay);
    final loop = _makeLoop(hs, _relay!);
    _loop = loop;
    _statusSub = loop.status.listen(_onStatus);
    loop.start();
  }

  Future<void> _stopLoop() async {
    await _loop?.stop();
    await _statusSub?.cancel();
    _statusSub = null;
    _loop = null;
    _relay = null;
  }

  void _onChanges(Changes c) {
    if (c.wiped) return; // handled when the round or the Forget ends
    if (c.outgoing.isNotEmpty || c.reviewAdded.isNotEmpty || c.delivered.isNotEmpty) {
      unawaited(_refresh());
    }
  }

  Future<void> _onStatus(SyncStatus s) async {
    if (_hs?.isWiped ?? false) {
      await _wiped();
      return;
    }
    _set(snapshot.value.copyWith(
      lastSynced: s.ok ? () => s.at : null,
      lastPath: s.ok ? () => SyncPath.relay : null,
      lastError: () => s.error,
      retryIn: () => s.retryIn,
    ));
    await _refresh();
  }

  Future<void> _refresh() async {
    final hs = _hs;
    if (hs == null || hs.isWiped) return;
    try {
      final waiting = (await hs.relayOutbox()).length;
      _set(snapshot.value.copyWith(
        waiting: waiting,
        review: hs.review(),
        devices: hs.devices(),
      ));
    } on Object catch (e) {
      developer.log('sync status unreadable', name: 'lullaby.sync', error: e);
    }
  }

  /// Turn sync on with the words already on this phone (after setup, or after
  /// a parent typed them to join), as [label], through [relay] (or none).
  Future<void> turnOn({required String label, Uri? relay}) async {
    await boot();
    if (_hs != null) return;
    if (await readWords() == null) throw NoRecoveryWordsException();
    final settings = SyncSettings(on: true, relay: relay, label: label);
    await settingsStore.write(settings);
    _set(snapshot.value.copyWith(settings: settings, forgotten: false));
    await _open(settings);
  }

  /// Use [relay] from now on, or none (sync pauses; writes still go through
  /// the log, so nothing is lost when a relay is chosen again).
  Future<void> setRelay(Uri? relay) async {
    final settings = snapshot.value.settings.copyWith(relay: () => relay);
    await settingsStore.write(settings);
    _set(snapshot.value.copyWith(settings: settings, lastError: () => null));
    await _stopLoop();
    _startLoop(relay);
  }

  /// A round now (on opening Settings, or a parent's "Sync now").
  Future<SyncStatus?> syncNow() async {
    final loop = _loop;
    if (loop == null) return null;
    return loop.syncNow();
  }

  // ---------------------------------------------------------------- same Wi-Fi

  LanListener? _listener;

  Future<Uint8List> _seed() async {
    final words = await readWords();
    if (words == null) throw NoRecoveryWordsException();
    return deriveSeed(words);
  }

  HearthSync _openLog() {
    final hs = _hs;
    if (hs == null || hs.isWiped) {
      throw StateError('same-Wi-Fi sync needs sync on');
    }
    return hs;
  }

  /// Show a code another phone of the household can type: this phone listens
  /// on the Wi-Fi until that phone has synced, the code expires, or
  /// [stopWifi]. Only one code at a time. [advertise] overrides the address
  /// in the code (tests). Throws `LanException('unreachable')` off Wi-Fi.
  Future<LanListener> listenOnWifi({String? advertise}) async {
    // A QR link can cold-start the app straight into this: wait for the
    // launch's open of the log.
    await boot();
    final hs = _openLog();
    await stopWifi();
    final listener = await LanListener.start(hs, await _seed(), advertise: advertise);
    _listener = listener;
    unawaited(listener.done.then((_) => _wifiSynced(), onError: (Object e) {
      developer.log('Wi-Fi code ended', name: 'lullaby.sync', error: e);
    }).whenComplete(() {
      if (identical(_listener, listener)) _listener = null;
    }));
    return listener;
  }

  /// Sync with the phone showing [code] on this Wi-Fi (the screen reads the
  /// typed code with `LanCode.tryParse`, which catches a typo first).
  Future<void> syncOnWifi(LanCode code) async {
    await boot();
    final hs = _openLog();
    await syncOverLan(hs, await _seed(), code);
    await _wifiSynced();
  }

  /// Stop showing a code (it stops working).
  Future<void> stopWifi() async {
    final l = _listener;
    _listener = null;
    await l?.stop();
  }

  Future<void> _wifiSynced() async {
    if (_hs?.isWiped ?? false) {
      await _wiped();
      return;
    }
    _set(snapshot.value.copyWith(
      lastSynced: () => _clock(),
      lastPath: () => SyncPath.wifi,
    ));
    await _refresh();
  }

  /// Keep this phone's value for a review item the merge replaced.
  Future<void> keepMine(ReviewItem item) async {
    final hs = _hs;
    if (hs == null) return;
    if (item.kind == 'field' && item.table != null && item.row != null && item.field != null) {
      await hs.put(item.table!, item.row!, {item.field!: item.mine});
    }
    await hs.dismissReview(item.key);
    await _refresh();
  }

  /// Leave the merge's choice and take the item off the list.
  Future<void> dismiss(ReviewItem item) async {
    await _hs?.dismissReview(item.key);
    await _refresh();
  }

  /// Forget another phone: its later changes stop counting everywhere.
  Future<void> forgetDevice(Uint8List device) async {
    final hs = _hs;
    if (hs == null) return;
    await hs.forgetDevice(device);
    await _refresh();
    unawaited(syncNow());
  }

  /// "Forget this device": hands what this phone owes to the relay, then
  /// destroys its key and deletes the words here. The records stay on this
  /// phone; sync is off afterwards.
  Future<void> forgetThisDevice() async {
    final hs = _hs;
    if (hs == null) return;
    final relay = _relay;
    await _stopLoop();
    try {
      await hs.forgetSelf(relay: relay);
    } on RelayHandoverException catch (e) {
      // The wipe happened; the relay just did not hear about it.
      developer.log('forget handover did not reach the relay', name: 'lullaby.sync', error: e.cause);
    }
    await _wiped();
  }

  Future<void> _wiped() async {
    final hs = _hs;
    _hs = null;
    await stopWifi();
    await _stopLoop();
    await _changesSub?.cancel();
    _changesSub = null;
    if (hs != null) await hs.close();
    _signer = null;
    await persist.clear();
    await forgetWords();
    await _turnedOff(forgotten: true);
  }

  Future<void> _turnedOff({bool forgotten = false}) async {
    // No log is owed anything any more: a later join must not replay these.
    await projection.clearGapDeletes();
    final settings = snapshot.value.settings.copyWith(on: false, relay: () => null);
    await settingsStore.write(settings);
    _set(SyncSnapshot(settings: settings, forgotten: forgotten));
  }

  /// Stop the loop and release the kernel (the records stay).
  Future<void> close() async {
    await stopWifi();
    await _stopLoop();
    await _changesSub?.cancel();
    await _hs?.close();
    _hs = null;
  }
}

/// The writer repositories hold: each write asks [HouseholdSync] which path
/// is live right now (direct with sync off, the log with it on), after the
/// boot that decides it.
class HouseholdRecordWriter extends RecordWriter {
  HouseholdRecordWriter(this.sync) : super(sync.projection);

  final HouseholdSync sync;

  @override
  Future<void> put(RecordTable table, String id, Map<String, Object?> fields) async =>
      (await sync.writer()).put(table, id, fields);

  @override
  Future<void> update(RecordTable table, String id, Map<String, Object?> fields) async =>
      (await sync.writer()).update(table, id, fields);

  @override
  Future<void> send(RecordTable table, String id, Map<String, Object?> fields) async =>
      (await sync.writer()).send(table, id, fields);

  @override
  Future<void> delete(RecordTable table, String id) async =>
      (await sync.writer()).delete(table, id);

  @override
  Future<void> restore(RecordTable table, String id, Map<String, Object?> fields) async =>
      (await sync.writer()).restore(table, id, fields);

  @override
  Future<void> addHandoffNote({
    required String babyId,
    required String text,
    required DateTime at,
  }) async =>
      (await sync.writer()).addHandoffNote(babyId: babyId, text: text, at: at);
}
