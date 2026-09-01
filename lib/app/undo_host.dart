import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// The one Undo offer for the whole app.
///
/// Deliberate deletes happen on edit forms that close straight after, so an
/// Undo bar placed on the form would vanish with it. The controller lives
/// for the app's lifetime and [UndoHost] shows its bar below every screen.
final undoControllerProvider = Provider<OhUndoController>((ref) {
  final controller = OhUndoController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Wraps the app's navigator (from `MaterialApp.builder`) and keeps the
/// pending Undo bar pinned under it until the person taps Undo, dismisses
/// it, or deletes something else. It never times out.
class UndoHost extends ConsumerStatefulWidget {
  const UndoHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UndoHost> createState() => _UndoHostState();
}

class _UndoHostState extends ConsumerState<UndoHost> {
  // The bar's buttons carry tooltips, which need an Overlay; the navigator's
  // own overlay sits below this widget, so the host brings one.
  late final OverlayEntry _entry = OverlayEntry(builder: _buildFrame);

  @override
  void didUpdateWidget(UndoHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) _entry.markNeedsBuild();
  }

  Widget _buildFrame(BuildContext context) {
    final controller = ref.read(undoControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final showing = controller.pending != null;
        return Column(
          children: [
            Expanded(
              // The bar takes the bottom safe area while it shows. The tree
              // shape stays the same either way so the navigator keeps its
              // state.
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: showing,
                child: widget.child,
              ),
            ),
            OhUndoBar(controller: controller, commitOnDispose: false),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }
}
