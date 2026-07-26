/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 *
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright (c) 2021-2026, Ankit Sangwan
 */

// Lightweight replacement for the discontinued `persistent_bottom_nav_bar`
// git fork. Provides per-tab navigation stacks (kept alive via IndexedStack),
// a bottom overlay widget (miniplayer + nav bar) and proper system-back
// handling through NavigatorPopHandler.

import 'package:flutter/material.dart';

class PersistentTabController extends ChangeNotifier {
  PersistentTabController({int initialIndex = 0}) : _index = initialIndex;

  int _index;

  int get index => _index;

  void jumpToTab(int value) {
    if (value != _index) {
      _index = value;
      notifyListeners();
    }
  }
}

class PersistentTabView extends StatefulWidget {
  const PersistentTabView(
    this.context, {
    super.key,
    required this.controller,
    required this.itemCount,
    required this.screens,
    required this.customWidget,
    this.navBarHeight = 60,
    this.onItemTapped,
    this.routes,
    this.onGenerateRoute,
  });

  final BuildContext context;
  final PersistentTabController controller;
  final int itemCount;
  final List<Widget> screens;

  /// Widget pinned above the bottom edge (miniplayer + bottom nav bar).
  final Widget customWidget;
  final double navBarHeight;
  final void Function(int)? onItemTapped;
  final Map<String, WidgetBuilder>? routes;
  final RouteFactory? onGenerateRoute;

  @override
  State<PersistentTabView> createState() => _PersistentTabViewState();
}

class _PersistentTabViewState extends State<PersistentTabView> {
  late final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(widget.itemCount, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) setState(() {});
  }

  Route<dynamic>? _generateRoute(RouteSettings settings, int tabIndex) {
    if (settings.name == Navigator.defaultRouteName) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => widget.screens[tabIndex],
      );
    }
    final WidgetBuilder? builder = widget.routes?[settings.name];
    if (builder != null) {
      return MaterialPageRoute(settings: settings, builder: builder);
    }
    return widget.onGenerateRoute?.call(settings);
  }

  @override
  Widget build(BuildContext context) {
    final int current = widget.controller.index;
    return NavigatorPopHandler(
      onPopWithResult: (result) {
        _navigatorKeys[current].currentState?.maybePop();
      },
      // Laid out in sequence rather than stacked: the pages used to fill the
      // whole area with the bar painted on top, so the last row of every list
      // sat behind the mini player and could not be scrolled to or tapped.
      // A column reserves exactly the height the bar needs, which changes as
      // the mini player appears and disappears.
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: current,
              children: List.generate(widget.itemCount, (i) {
                return Navigator(
                  key: _navigatorKeys[i],
                  onGenerateRoute: (settings) => _generateRoute(settings, i),
                );
              }),
            ),
          ),
          widget.customWidget,
        ],
      ),
    );
  }
}
