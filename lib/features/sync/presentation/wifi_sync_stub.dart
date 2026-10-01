import 'package:flutter/material.dart';

/// Same-Wi-Fi sync can run in this build (not in a browser).
const wifiSyncAvailable = false;

/// Unused in a browser.
String wifiSyncLink(String code) => code;

/// In a browser: the page cannot listen for another phone, so it syncs
/// through a relay (hearthSync ADR 0014).
class WifiSyncSection extends StatelessWidget {
  const WifiSyncSection({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) => Text(
        'In a browser, sync goes through a relay: a web page can’t reach another '
        'phone on the Wi-Fi directly.',
        style: Theme.of(context).textTheme.bodySmall,
      );
}

/// The same words as a page, if a Wi-Fi link is opened in a browser.
class WifiSyncScreen extends StatelessWidget {
  const WifiSyncScreen({super.key, required this.show, this.code});

  final bool show;
  final String? code;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sync on this Wi-Fi')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: WifiSyncSection(),
        ),
      );
}
