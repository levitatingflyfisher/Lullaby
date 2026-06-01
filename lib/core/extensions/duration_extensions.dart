extension DurationExtensions on Duration {
  String toHoursMinutes() {
    final h = inHours;
    final m = inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  String toTimerDisplay() {
    final h = inHours.toString().padLeft(2, '0');
    final m = inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
