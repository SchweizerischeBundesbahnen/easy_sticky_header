// Copyright (c) 2022, crasowas.
//
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'sticky_header_controller.dart';
import 'sticky_header_info.dart';

/// Sticky Header Widget.
///
/// Adjusts the position and visibility of the widget in real time according to
/// the scrolling changes, while covering the lower widget to achieve the effect
/// of sticky header.
class StickyFooterWidget extends StatefulWidget {
  final StickyHeaderController controller;

  final double spacing;

  final BoxDecoration? footerDecoration;

  const StickyFooterWidget({
    Key? key,
    required this.controller,
    required this.spacing,
    this.footerDecoration,
  }) : super(key: key);

  @override
  State<StickyFooterWidget> createState() => _StickyFooterWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<double>('pixels', controller.currentPixels, defaultValue: 0.0));
    properties.add(DiagnosticsProperty<Offset>('offset', controller.currentOffset, defaultValue: Offset.zero));
    properties.add(DiagnosticsProperty<StickyHeaderInfo>('stickyFooterInfo', controller.currentStickyFooterInfo,
        defaultValue: null));
  }
}

class _StickyFooterWidgetState extends State<StickyFooterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController.unbounded(vsync: this);
    _animationController.addListener(() {
      widget.controller.scrollPosition?.jumpTo(_animationController.value);
    });
    widget.controller.addListener(_update);
  }

  @override
  void didUpdateWidget(covariant StickyFooterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_update);
      widget.controller.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var stickyFooterInfo = widget.controller.currentStickyFooterInfo;
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Visibility(
        visible: stickyFooterInfo != null && stickyFooterInfo.visible,
        child: _buildStickyFooter(stickyFooterInfo),
      ),
    );
  }

  Widget _buildStickyFooter(StickyHeaderInfo? stickyFooterInfo) {
    if (stickyFooterInfo != null) {
      return Container(
          decoration: widget.footerDecoration,
          child: stickyFooterInfo.widget);
    }
    return Container();
  }

  void _update() {
    setState(() {});
  }

  /// The sticky header widget should be scrollable, and the scrolling widget
  /// scrolls in sync when the sticky header widget scrolls,
  /// it feels like part of the scrolling widget.
  void _onPanUpdate(DragUpdateDetails details) {
    widget.controller.scrollPosition?.jumpTo(widget.controller.currentPixels +
        (widget.controller.isReverse ? 1.0 : -1.0) * widget.controller.getComponent(details.delta));
  }

  /// After the user stops dragging the sticky footer widget, keep the same
  /// physics animation as the scrolling widget.
  void _onPanEnd(DragEndDetails details) {
    var scrollPosition = widget.controller.scrollPosition;
    if (scrollPosition != null) {
      // Velocity limit.
      var velocity = (widget.controller.isReverse ? 1.0 : -1.0) *
          widget.controller.getComponent(details.velocity.clampMagnitude(0, 1000).pixelsPerSecond);
      var simulation = scrollPosition.physics.createBallisticSimulation(scrollPosition, velocity);
      // In some cases, physical animation is not required, for example,
      // the velocity is already 0.0 at this time.
      if (simulation != null) {
        _animationController.animateWith(simulation);
      }
    }
  }
}
