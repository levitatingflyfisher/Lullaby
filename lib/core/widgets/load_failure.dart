import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// What a screen shows when its data did not load.
///
/// A thin layer over the fleet's [OhErrorState]: it names what failed
/// ("Couldn't load recent activity"), swaps the package's cloud glyph for a
/// plain one (Lullaby never touches a network, so a cloud would mislead), and
/// logs the raw error instead of printing it on the glass.
///
/// Use the default constructor where the failure replaces a whole screen body
/// and [LoadFailure.inline] where it sits inside a list, card or sheet, since
/// [OhErrorState] centres and scrolls itself and is too tall for a list row.
class LoadFailure extends StatefulWidget {
  const LoadFailure({
    super.key,
    required this.what,
    required this.error,
    this.stackTrace,
    this.onRetry,
  }) : inline = false;

  const LoadFailure.inline({
    super.key,
    required this.what,
    required this.error,
    this.stackTrace,
    this.onRetry,
  }) : inline = true;

  /// What did not load, in words that finish "Couldn't load …".
  final String what;
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final bool inline;

  String get title => 'Couldn’t load $what';

  @override
  State<LoadFailure> createState() => _LoadFailureState();
}

class _LoadFailureState extends State<LoadFailure> {
  @override
  void initState() {
    super.initState();
    _log();
  }

  @override
  void didUpdateWidget(LoadFailure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.error, widget.error)) _log();
  }

  void _log() => developer.log(
    widget.title,
    name: 'lullaby',
    error: widget.error,
    stackTrace: widget.stackTrace,
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.inline) {
      return OhErrorState.fromError(
        widget.error,
        stackTrace: widget.stackTrace,
        title: widget.title,
        onRetry: widget.onRetry,
        icon: Icons.error_outline,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.title}. ${ohFriendlyErrorMessage(widget.error)}',
                  ),
                ),
              ],
            ),
            if (widget.onRetry != null)
              TextButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
          ],
        ),
      ),
    );
  }
}
