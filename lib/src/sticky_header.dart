// Copyright (c) 2022, crasowas.
//
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:easy_sticky_header/src/sticky_footer_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'sticky_header_controller.dart';
import 'sticky_header_widget.dart';

typedef FooterWidgetBuilder = Widget? Function(BuildContext context, int afterIndex);

/// Sticky Header.
///
/// Wraps a [ListView], [GridView], [CustomScrollView], [SingleChildScrollView]
/// or similar with this widget. Usually, as long as the wrapped widget is a
/// scrolling widget, it can be used normally.
///
/// {@tool snippet}
///
/// This example shows how to easily create a [ListView] with a sticky header.
/// For more usage details, please refer to the example project.
///
/// ```dart
/// StickyHeader(
///   child: ListView.builder(
///     itemCount: 100,
///     itemBuilder: (context, index) {
///       // Custom header widget.
///       if (index % 3 == 0) {
///         return StickyContainerWidget(
///           index: index,
///           child: Container(
///             color: Color.fromRGBO(Random().nextInt(256),
///                 Random().nextInt(256), Random().nextInt(256), 1),
///             padding: const EdgeInsets.only(left: 16.0),
///             alignment: Alignment.centerLeft,
///             width: double.infinity,
///             height: 50,
///             child: Text(
///               'Header #$index',
///               style: const TextStyle(
///                 color: Colors.white,
///                 fontSize: 16,
///               ),
///             ),
///           ),
///         );
///       }
///       // Custom item widget.
///       return Container(
///         width: double.infinity,
///         height: 80,
///         color: Colors.white,
///       );
///     },
///   ),
/// );
/// ```
/// {@end-tool}
class StickyHeader extends StatefulWidget {
  /// Optional [StickyHeaderController].
  ///
  /// One controller will be maintained by default,
  /// if no other features are required, then there is no need to create
  /// a new controller.
  final StickyHeaderController? controller;

  /// This property must be set if the value of the [reverse] property
  /// needs to be changed dynamically. Usually set to null by default.
  final bool? reverse;

  /// Spacing between sticky header and start position.
  final double spacing;

  /// Widget that support scrolling.
  final Widget child;

  /// Whether to also show the next stickyHeader as a footer.
  final bool showFooter;

  /// Decoration to apply to the footer
  final BoxDecoration? footerDecoration;

  /// Builder for the Footer if it has not yet built in the scrollable child
  final FooterWidgetBuilder? footerBuilder;

  const StickyHeader({
    Key? key,
    this.controller,
    this.reverse,
    this.spacing = 0.0,
    this.showFooter = false,
    this.footerDecoration =
        const BoxDecoration(boxShadow: [BoxShadow(color: Colors.grey, spreadRadius: 5, blurRadius: 5)]),
    this.footerBuilder,
    required this.child,
  }) : super(key: key);

  @override
  State<StickyHeader> createState() => _StickyHeaderState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('reverse', reverse, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('spacing', spacing, defaultValue: 0.0));
  }

  static StickyHeaderController? of(BuildContext? context) =>
      context?.dependOnInheritedWidgetOfExactType<_StickyHeaderControllerWidget>()?.controller;
}

class _StickyHeaderState extends State<StickyHeader> {
  StickyHeaderController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? StickyHeaderController();
  }

  @override
  void didUpdateWidget(covariant StickyHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller && widget.controller != null) {
      _controller?.dispose();
      _controller = widget.controller;
    } else if (widget.reverse != null && widget.reverse != _controller?.isReverse) {
      _controller?.clearStickyHeaderInfo();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _controller?.scrollListener();
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var controller = _controller;
    if (controller != null) {
      return _StickyHeaderControllerWidget(
        controller: controller,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                // Abort if jumping to the header widget at the specified index
                // is in progress.
                controller.isJumping = false;
                return false;
              },
              child: widget.child,
            ),
            StickyHeaderWidget(
              controller: controller,
              spacing: widget.spacing,
            ),
            if (widget.showFooter)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: StickyFooterWidget(
                  controller: controller,
                  spacing: widget.spacing,
                  footerBuilder: widget.footerBuilder,
                  footerDecoration: widget.footerDecoration,
                ),
              )
          ],
        ),
      );
    } else {
      // Ignore this return, this line of code will not be executed.
      return const _NullWidget();
    }
  }
}

/// Sticky Header Controller Widget.
///
/// This is an [InheritedWidget], which is convenient for
/// [StickyContainerWidget] to get the controller.
class _StickyHeaderControllerWidget extends InheritedWidget {
  const _StickyHeaderControllerWidget({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  final StickyHeaderController controller;

  @override
  bool updateShouldNotify(_StickyHeaderControllerWidget oldWidget) => controller != oldWidget.controller;
}

class _NullWidget extends Widget {
  const _NullWidget();

  @override
  Element createElement() => throw UnimplementedError();
}
