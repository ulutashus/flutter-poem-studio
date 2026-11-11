import 'dart:async';

import 'package:flutter/material.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (details.direction != AxisDirection.down &&
        details.direction != AxisDirection.up) {
      return super.buildScrollbar(context, child, details);
    }
    final controller = details.controller;
    if (controller == null) return child;
    return _FixedThumbScrollbar(controller: controller, child: child);
  }
}

class _FixedThumbScrollbar extends StatefulWidget {
  const _FixedThumbScrollbar({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  State<_FixedThumbScrollbar> createState() => _FixedThumbScrollbarState();
}

class _FixedThumbScrollbarState extends State<_FixedThumbScrollbar> {
  static const double _thickness = 8;
  static const double _thumbHeight = 56;
  static const double _rightInset = 6;
  static const Duration _hideDelay = Duration(milliseconds: 900);

  Timer? _hideTimer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _FixedThumbScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  ScrollPosition? get _position {
    final positions = widget.controller.positions;
    return positions.isEmpty ? null : positions.last;
  }

  void _onScroll() {
    if (!_visible) setState(() => _visible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final color = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: 0.4);

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          bottom: 0,
          right: _rightInset,
          width: _thickness,
          child: IgnorePointer(
            ignoring: !_visible,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) => LayoutBuilder(
                  builder: (context, constraints) {
                    final track = constraints.maxHeight;
                    final travel = track - _thumbHeight;
                    final position = _position;
                    final maxScroll = position?.maxScrollExtent ?? 0.0;
                    if (travel <= 0 || maxScroll <= 0) {
                      return const SizedBox.shrink();
                    }

                    final offset = position!.pixels.clamp(0.0, maxScroll);
                    return Stack(
                      children: [
                        Positioned(
                          top: travel * offset / maxScroll,
                          left: 0,
                          right: 0,
                          height: _thumbHeight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragStart: (_) => _hideTimer?.cancel(),
                            onVerticalDragUpdate: (details) {
                              final position = _position;
                              if (position == null) return;
                              final scrollPerPixel =
                                  position.maxScrollExtent / travel;
                              position.jumpTo(
                                (position.pixels +
                                        details.delta.dy * scrollPerPixel)
                                    .clamp(0.0, position.maxScrollExtent),
                              );
                            },
                            onVerticalDragEnd: (_) => _onScroll(),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(_thickness),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
