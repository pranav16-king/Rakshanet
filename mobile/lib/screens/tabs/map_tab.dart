import 'package:flutter/widgets.dart';

import '../tools/live_map_screen.dart';

/// Compatibility entry point for older routes.
///
/// The former tab drew hard-coded SOS and shelter markers. All map entry
/// points now use the GPS-backed live map, which shows only locally stored or
/// received coordinates.
class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) => const LiveMapScreen();
}
