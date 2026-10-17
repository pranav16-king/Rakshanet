import 'package:flutter/material.dart';
import '../widgets/global_sos_overlay.dart';
import 'shell/main_shell.dart';

/// MainScreen: Root application container wrapping the primary navigation shell
/// with the GlobalSosOverlay so emergency distress alerts immediately surface
/// over all tabs (Chat, Map, SOS, Tools, AI).
class MainScreen extends StatelessWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 2});

  @override
  Widget build(BuildContext context) {
    return GlobalSosOverlay(
      child: MainShell(initialIndex: initialIndex),
    );
  }
}
