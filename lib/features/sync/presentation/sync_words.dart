import 'package:hearth_sync/hearth_sync.dart';
import 'package:intl/intl.dart';

import '../data/household_sync.dart';
import '../data/lullaby_records.dart';

/// Plain-words status lines for the sync screen (no codes, no jargon).

String _at(DateTime at, DateTime now) {
  final sameDay = at.year == now.year && at.month == now.month && at.day == now.day;
  return sameDay
      ? DateFormat.jm().format(at)
      : '${DateFormat.MMMd().format(at)}, ${DateFormat.jm().format(at)}';
}

String _path(SyncPath? p) => switch (p) {
      SyncPath.wifi => ' on this Wi-Fi',
      SyncPath.relay => ' through the relay',
      null => '',
    };

/// The headline: is it working, when did it last work, and which way. [wifi]
/// is whether this build can sync on the same Wi-Fi (not in a browser).
String syncHeadline(SyncSnapshot s, DateTime now, {bool wifi = lanSupported}) {
  switch (s.mode) {
    case SyncMode.off:
      return 'Off. Everything stays on this phone.';
    case SyncMode.starting:
      return 'Starting…';
    case SyncMode.needsWords:
      return 'Waiting for your 12 recovery words.';
    case SyncMode.failed:
      return s.problem ?? 'Sync couldn’t start on this phone.';
    case SyncMode.on:
      break;
  }
  final last = s.lastSynced;
  if (s.settings.relay == null) {
    if (last != null) return 'Last synced ${_at(last, now)}${_path(s.lastPath)}.';
    return wifi
        ? 'No relay: sync with a phone on this Wi-Fi below.'
        : 'Paused: no relay chosen. Changes are kept and sent once you choose one.';
  }
  final e = s.lastError;
  if (e != null) {
    final retry = s.retryIn;
    final when = retry == null
        ? ''
        : retry.inMinutes >= 1
            ? ' Trying again in ${retry.inMinutes} min.'
            : ' Trying again in a moment.';
    final String relay;
    if (e is RelayException && e.code == 'network') {
      relay = 'Couldn’t reach the relay. Check the connection.$when';
    } else if (e is RelayException && e.retryable) {
      relay = 'The relay is busy.$when';
    } else {
      relay = 'The relay didn’t accept this phone’s changes. Check the relay address.';
    }
    // A sync on the Wi-Fi still happened: say so first, then the relay's trouble.
    if (last != null && s.lastPath == SyncPath.wifi) {
      return 'Last synced ${_at(last, now)}${_path(s.lastPath)}. $relay';
    }
    return relay;
  }
  return last == null ? 'Not synced yet.' : 'Last synced ${_at(last, now)}${_path(s.lastPath)}.';
}

/// What is still on its way to the relay, or null with no relay: what a
/// phone learned on the Wi-Fi waits for a relay that is not coming, so it is
/// not "waiting".
String? syncWaitingLine(SyncSnapshot s) => s.settings.relay == null
    ? null
    : switch (s.waiting) {
          0 => 'Everything from this phone has been sent.',
          1 => '1 change waiting to send.',
          final n => '$n changes waiting to send.',
        };

const _tableWords = {
  'babies': 'Baby',
  'feeding_logs': 'Feed',
  'sleep_logs': 'Sleep',
  'diaper_logs': 'Diaper',
  'growth_records': 'Growth',
  'medicine_logs': 'Medicine',
  'vaccine_records': 'Vaccine',
};

/// "Feed: amount ml".
String reviewTitle(ReviewItem i) {
  final what = _tableWords[i.table] ?? 'Record';
  final field = i.field?.replaceAll('_', ' ');
  return field == null ? what : '$what: $field';
}

/// A log value as a person reads it.
String reviewValue(String? table, String? field, Object? v) {
  if (v == null) return 'empty';
  final f = table == null || field == null ? null : recordTable(table)?.field(field);
  final d = f == null ? v : decodeValue(f.kind, v);
  if (d is DateTime) return DateFormat.yMMMd().add_jm().format(d);
  if (d is double) return d == d.roundToDouble() ? d.toStringAsFixed(0) : '$d';
  return '$d';
}

/// What happened, in a sentence.
String reviewBody(ReviewItem i) => switch (i.kind) {
      'field' =>
        'Your change (${reviewValue(i.table, i.field, i.mine)}) was replaced by '
            '${reviewValue(i.table, i.field, i.current)} from another phone.',
      'row_deleted' => 'You changed this record, but it had been deleted on another phone.',
      'op' => 'A change from this phone couldn’t be put back after a long time offline.',
      'foreign' => 'A change from another phone couldn’t be put back.',
      'lost' => 'A change was lost while this phone was offline for a long time.',
      _ => 'An old change was too old to check, so it was set aside.',
    };
