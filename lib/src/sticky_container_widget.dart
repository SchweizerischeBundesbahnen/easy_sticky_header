// Copyright (c) 2022, crasowas.
//
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'render_sticky_container.dart';
import 'sticky_header.dart';
import 'sticky_header_controller.dart';
import 'sticky_header_info.dart';

/// Building header widget by sticky amount.
///
/// The value of `stickyAmount` is in the range 0.0 to 1.0.
///
/// When the value of `stickyAmount` grows from 0.0 to 1.0, the header widget
/// is about to become a sticky header. When the value of `stickyAmount` value
/// is reduced from 1.0 to 0.0, the header widget is about to stop being a
/// sticky header. In other cases, the value of `stickyAmount` is 0.0.
typedef HeaderWidgetBuilder = Widget Function(
    BuildContext context, double stickyAmount);

/// Building scrollable header widget.
///
/// The header widget and the sticky header synchronize the scroll position
/// through [ScrollController].
typedef ScrollableHeaderWidgetBuilder = Widget Function(
    BuildContext context, ScrollController scrollController);

/// Parent header update callback.
///
/// Uses this callback when the content of the parent header widget changes. If
/// the callback result is true, call [ParentHeaderWidgetBuilder] to rebuild the
/// parent header widget.
///
/// This callback is used to reduce unnecessary rebuilds of the parent header
/// widget and optimize performance.
typedef ParentHeaderUpdateCallback = bool Function(
    StickyHeaderInfo? childStickyHeaderInfo);

/// Building header widget by group.
///
/// The widget created by this builder is the parent header widget, which is
/// used to provide content for the sticky header.
typedef ParentHeaderWidgetBuilder = Widget Function(
    BuildContext context, StickyHeaderInfo? childStickyHeaderInfo);

/// Sticky Container widget.
///
/// Wraps a header widget with this widget to make the sticky effect take effect.
class StickyContainerWidget extends SingleChildRenderObjectWidget {
  /// The index of the header widget, which requires a unique index and is
  /// sorted from small to large, can be discontinuous.
  ///
  /// It is recommended to use the index provided by the scroll widget.
  final int index;

  /// If [visible] is false, the header widget will not be visible
  /// when it is the current sticky header widget.
  ///
  /// The use of this property is that non-sticky header widgets
  /// can be inserted between header widgets.
  final bool visible;

  /// The exact pixels of the header widget.
  ///
  /// In the presence of exact pixels, setting this property can
  /// optimize performance.
  final double? pixels;

  /// In some special usage scenarios, the offset obtained through
  /// [getOffsetToReveal] has errors. If this property is set to false,
  /// the offset will be obtained in real time without caching.
  ///
  /// Note that if it is not necessary, please use the default value of true,
  /// otherwise the frame rate will be reduced. Also, if [pixels] is not null,
  /// this property has no effect.
  final bool performancePriority;

  /// If the [parentIndex] property is not null, the current header widget will
  /// be bound to the parent header widget, and the content of the sticky header
  /// will be provided by the bound parent header widget.
  ///
  /// Note that the value of [parentIndex] must be less than the value of
  /// [index], otherwise it is invalid.
  final int? parentIndex;

  /// The [overlapParent] property is used to determine how the sticky
  /// header is calculated when the header widgets are grouped.
  ///
  /// The default value of this property is false, which may be more in line
  /// with usage habits.
  final bool overlapParent;

  const StickyContainerWidget({
    Key? key,
    required this.index,
    this.visible = true,
    this.pixels,
    this.performancePriority = true,
    this.parentIndex,
    this.overlapParent = false,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderStickyContainer createRenderObject(BuildContext context) {
    return RenderStickyContainer(
      controller: _getController(context),
      index: index,
      visible: visible,
      pixels: pixels,
      performancePriority: performancePriority,
      parentIndex: parentIndex,
      overlapParent: overlapParent,
      widget: child ?? Container(),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderStickyContainer renderObject) {
    renderObject
      ..controller = _getController(context)
      ..index = index
      ..visible = visible
      ..pixels = pixels
      ..performancePriority = performancePriority
      ..parentIndex = parentIndex
      ..overlapParent = overlapParent
      ..widget = child ?? Container();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<int>('index', index, defaultValue: 0));
    properties
        .add(DiagnosticsProperty<bool>('visible', visible, defaultValue: true));
    properties
        .add(DiagnosticsProperty<double>('pixels', pixels, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>(
        'performancePriority', performancePriority,
        defaultValue: true));
    properties.add(DiagnosticsProperty<int>('parentIndex', parentIndex,
        defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('overlapParent', overlapParent,
        defaultValue: false));
  }

  StickyHeaderController? _getController(BuildContext context) {
    var controller = StickyHeader.of(context);
    assert(
        controller != null,
        'Sticky header controller instance must not be null, '
        'confirm whether to use [StickyHeader] to wrap the widget.');
    var scrollPosition = Scrollable.of(context).position;
    if (controller?.scrollPosition != scrollPosition) {
      controller?.scrollPosition = scrollPosition;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        controller?.scrollListener();
      });
    }
    return controller;
  }
}

/// Sticky Container Builder.
///
/// An extension of [StickyContainerWidget] that supports dynamically building
/// header widget by sticky amount.
///
/// If you find problems in use, please first confirm whether the
/// [addAutomaticKeepAlives] property of the scroll widget has been set to true.
class StickyContainerBuilder extends StatefulWidget {
  /// Mirror to [StickyContainerWidget.index]
  final int index;

  /// Mirror to [StickyContainerWidget.visible]
  final bool visible;

  /// Mirror to [StickyContainerWidget.pixels]
  final double? pixels;

  /// Mirror to [StickyContainerWidget.performancePriority]
  final bool performancePriority;

  /// Mirror to [StickyContainerWidget.parentIndex]
  final int? parentIndex;

  /// Mirror to [StickyContainerWidget.overlapParent]
  final bool overlapParent;

  /// The builder that creates a child to display in this widget, which will use
  /// the provided `stickyAmount` to build the header widget.
  final HeaderWidgetBuilder builder;

  const StickyContainerBuilder({
    Key? key,
    required this.index,
    this.visible = true,
    this.pixels,
    this.performancePriority = true,
    this.parentIndex,
    this.overlapParent = false,
    required this.builder,
  }) : super(key: key);

  @override
  State<StickyContainerBuilder> createState() => _StickyContainerBuilderState();
}

class _StickyContainerBuilderState extends State<StickyContainerBuilder>
    with AutomaticKeepAliveClientMixin {
  StickyHeaderController? _controller;
  double _stickyAmount = 0.0;

  @override
  void dispose() {
    _controller?.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var controller = StickyHeader.of(context);
    if (controller != null && _controller != controller) {
      controller.useStickyAmount = true;
      _controller?.removeListener(_update);
      _controller = controller;
      _controller?.addListener(_update);
    }
    return StickyContainerWidget(
      index: widget.index,
      visible: widget.visible,
      pixels: widget.pixels,
      performancePriority: widget.performancePriority,
      parentIndex: widget.parentIndex,
      overlapParent: widget.overlapParent,
      child: widget.builder(context, _stickyAmount),
    );
  }

  /// If there is too much spacing between the header widgets, the header widget
  /// may be disposed prematurely, making it impossible to rebuild the header
  /// widget with `stickyAmount`, so keep it active to avoid problems.
  @override
  bool get wantKeepAlive => true;

  void _update() {
    var stickyAmount =
        _controller?.getStickyHeaderInfo(widget.index)?.stickyAmount ?? 0.0;
    if (stickyAmount != _stickyAmount) {
      _stickyAmount = stickyAmount;
      setState(() {});
    }
  }
}

/// Sticky Container Scrollable Builder.
///
/// An extension of [StickyContainerWidget] that supports building scrollable
/// header widget.
///
/// If you find problems in use, please first confirm whether the
/// [addAutomaticKeepAlives] property of the scroll widget has been set to true.
class ScrollableStickyContainerBuilder extends StatefulWidget {
  /// Mirror to [StickyContainerWidget.index]
  final int index;

  /// Mirror to [StickyContainerWidget.visible]
  final bool visible;

  /// Mirror to [StickyContainerWidget.pixels]
  final double? pixels;

  /// Mirror to [StickyContainerWidget.performancePriority]
  final bool performancePriority;

  /// Mirror to [StickyContainerWidget.parentIndex]
  final int? parentIndex;

  /// Mirror to [StickyContainerWidget.overlapParent]
  final bool overlapParent;

  /// See also [ScrollController.initialScrollOffset].
  final double initialScrollOffset;

  /// See also [ScrollController.keepScrollOffset].
  final bool keepScrollOffset;

  /// See also [ScrollController.debugLabel].
  final String? debugLabel;

  /// See also [ScrollController.onAttach].
  final ScrollControllerCallback? onAttach;

  /// See also [ScrollController.onDetach].
  final ScrollControllerCallback? onDetach;

  /// The builder that creates a child to display in this widget, which will use
  /// the provided [ScrollController] to build the header widget.
  final ScrollableHeaderWidgetBuilder builder;

  const ScrollableStickyContainerBuilder({
    Key? key,
    required this.index,
    this.visible = true,
    this.pixels,
    this.performancePriority = true,
    this.parentIndex,
    this.overlapParent = false,
    this.initialScrollOffset = 0.0,
    this.keepScrollOffset = true,
    this.debugLabel,
    this.onAttach,
    this.onDetach,
    required this.builder,
  }) : super(key: key);

  @override
  State<ScrollableStickyContainerBuilder> createState() =>
      _ScrollableStickyContainerBuilderState();
}

class _ScrollableStickyContainerBuilderState
    extends State<ScrollableStickyContainerBuilder>
    with AutomaticKeepAliveClientMixin {
  bool _isSticking = false;
  late ScrollController _scrollController;

  Iterable<ScrollPosition> get _positions => _scrollController.positions;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialScrollOffset,
      keepScrollOffset: widget.keepScrollOffset,
      debugLabel: widget.debugLabel,
      onAttach: (position) {
        assert(_positions.length <= 3,
            'ScrollController attached to multiple scroll views.');
        _isSticking = _positions.length == 2;
        if (_isSticking) {
          position.correctPixels(_positions.first.pixels);
        }
        widget.onAttach?.call(position);
      },
      onDetach: (position) {
        if (_isSticking) {
          _positions.first.jumpTo(position.pixels);
        }
        _isSticking = false;
        widget.onDetach?.call(position);
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StickyContainerWidget(
      index: widget.index,
      visible: widget.visible,
      pixels: widget.pixels,
      performancePriority: widget.performancePriority,
      parentIndex: widget.parentIndex,
      overlapParent: widget.overlapParent,
      child: widget.builder(context, _scrollController),
    );
  }

  /// If there is too much spacing between the header widgets, the header widget
  /// may be disposed prematurely, resulting in failure to synchronize the scroll
  /// position, so keep it active to avoid problems.
  @override
  bool get wantKeepAlive => true;
}

/// Sticky Container Parent Builder.
///
/// An extension of [StickyContainerWidget] for building parent header widget.
///
/// [ParentStickyContainerBuilder] is not necessary to build the parent header
/// widget, [StickyContainerWidget] or [StickyContainerBuilder] are equally
/// fine. It's just that [ParentStickyContainerBuilder] can build a sticky
/// header based on the changes of the child header widgets.
///
/// If you find problems in use, please first confirm whether the
/// [addAutomaticKeepAlives] property of the scroll widget has been set to true.
class ParentStickyContainerBuilder extends StatefulWidget {
  /// Mirror to [StickyContainerWidget.index]
  final int index;

  /// Mirror to [StickyContainerWidget.visible]
  final bool visible;

  /// Mirror to [StickyContainerWidget.pixels]
  final double? pixels;

  /// Mirror to [StickyContainerWidget.performancePriority]
  final bool performancePriority;

  /// The callback should return false if the parent header widget does not
  /// need to be rebuild.
  final ParentHeaderUpdateCallback? onUpdate;

  /// The builder that creates a child to display in this widget, which will use
  /// the provided [StickyHeaderInfo] to build the parent header widget.
  final ParentHeaderWidgetBuilder builder;

  const ParentStickyContainerBuilder({
    Key? key,
    required this.index,
    this.visible = true,
    this.pixels,
    this.performancePriority = true,
    this.onUpdate,
    required this.builder,
  }) : super(key: key);

  @override
  State<ParentStickyContainerBuilder> createState() =>
      _ParentStickyContainerBuilderState();
}

class _ParentStickyContainerBuilderState
    extends State<ParentStickyContainerBuilder>
    with AutomaticKeepAliveClientMixin {
  StickyHeaderController? _controller;
  StickyHeaderInfo? _childStickyHeaderInfo;
  double _stickyAmount = 0.0;

  @override
  void dispose() {
    _controller?.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var controller = StickyHeader.of(context);
    if (controller != null && _controller != controller) {
      _controller?.removeListener(_update);
      _controller = controller;
      _controller?.addListener(_update);
    }
    return StickyContainerWidget(
      index: widget.index,
      visible: widget.visible,
      pixels: widget.pixels,
      performancePriority: widget.performancePriority,
      child: widget.builder(context, _childStickyHeaderInfo),
    );
  }

  /// If there is too much spacing between the parent header widget and the
  /// associated child header widget, the parent header widget may be disposed
  /// prematurely, so keep it alive to avoid problems.
  @override
  bool get wantKeepAlive => true;

  void _update() {
    var childStickyHeaderInfo = _controller?.currentChildStickyHeaderInfo;
    var needsUpdate = false;
    if (childStickyHeaderInfo == null) {
      if (_childStickyHeaderInfo != null) {
        _childStickyHeaderInfo = null;
        _stickyAmount = 0.0;
        needsUpdate = true;
      }
    } else {
      if (childStickyHeaderInfo.parentIndex == widget.index &&
          (childStickyHeaderInfo.index != _childStickyHeaderInfo?.index ||
              childStickyHeaderInfo.stickyAmount != _stickyAmount)) {
        _childStickyHeaderInfo = childStickyHeaderInfo;
        _stickyAmount = childStickyHeaderInfo.stickyAmount;
        needsUpdate = true;
      }
    }
    if (needsUpdate &&
        (widget.onUpdate?.call(_childStickyHeaderInfo) ?? true)) {
      setState(() {});
    }
  }
}
