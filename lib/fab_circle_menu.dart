import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;

typedef DisplayChange = void Function(bool isOpen);

/// Widget providing the circular FAB menu
/// both the invoke button and the circular menu
class FabCircularMenu extends StatefulWidget {
  /// List of the menu items in the circular menu
  final List<Widget> children;

  /// Alignment of the menu invoke button
  /// and also the ring of the circular menu items
  final Alignment alignment;

  /// Color of the circular menu items' ring background
  final Color? ringColor;

  /// Diameter of the circular menu items' ring
  final double? ringDiameter;

  /// Limit factor of the circular menu items' ring diameter
  final double ringDiameterLimitFactor;

  /// Width of the circular menu items' ring
  final double? ringWidth;

  /// Limit factor of the circular menu items' ring width
  final double ringWidthLimitFactor;

  /// Size of the FAB button
  final double fabSize;

  /// Elevation of the FAB button
  final double fabElevation;

  /// Color of the FAB button
  final Color? fabColor;

  /// Color of the FAB button when opening
  final Color? fabOpenColor;

  /// Color of the FAB button when closing
  final Color? fabCloseColor;

  /// Widget child of the FAB button (optional, for complete customization)
  final Widget? fabChild;

  /// Open icon of the FAB button
  final Widget fabOpenIcon;

  /// Close icon of the FAB button
  final Widget fabCloseIcon;

  /// Border shape of the FAB button icon
  final ShapeBorder? fabIconBorder;

  /// Margins of the FAB button
  final EdgeInsets fabMargin;

  /// FAB open / close animation duration
  final Duration animationDuration;

  /// FAB open / close animation curve
  final Curve animationCurve;

  /// Display change callback of FAB menu open / close
  final DisplayChange? onDisplayChange;

  final Function? onPressedWhenClose;

  FabCircularMenu(
      {Key? key,
      this.alignment = Alignment.bottomRight,
      this.ringColor,
      this.ringDiameter,
      this.ringDiameterLimitFactor = 1.5,
      this.ringWidth,
      this.ringWidthLimitFactor = 0.2,
      this.fabSize = 64.0,
      this.fabElevation = 8.0,
      this.fabColor,
      this.fabOpenColor,
      this.fabCloseColor,
      this.fabIconBorder,
      this.fabChild,
      this.fabOpenIcon = const Icon(Icons.menu),
      this.fabCloseIcon = const Icon(Icons.close),
      this.fabMargin = const EdgeInsets.all(16.0),
      this.animationDuration = const Duration(milliseconds: 800),
      this.animationCurve = Curves.easeInOutCirc,
      this.onDisplayChange,
      this.onPressedWhenClose,
      required this.children})
      : assert(children.isNotEmpty),
        super(key: key);

  @override
  FabCircularMenuState createState() => FabCircularMenuState();
}

class FabCircularMenuState extends State<FabCircularMenu>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late double _screenWidth;
  late double _screenHeight;
  late double _marginH;
  late double _marginV;
  late double _directionX;
  late double _directionY;
  late double _translationX;
  late double _translationY;

  Color? _ringColor;
  double? _ringDiameter;
  double? _ringWidth;
  Color? _fabColor;
  Color? _fabOpenColor;
  Color? _fabCloseColor;
  late ShapeBorder _fabIconBorder;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation _scaleCurve;
  late Animation<double> _rotateAnimation;
  late Animation _rotateCurve;
  Animation<Color?>? _colorAnimation;
  late Animation _colorCurve;

  bool _isOpen = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController =
        AnimationController(duration: widget.animationDuration, vsync: this);

    _scaleCurve = CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.4, curve: widget.animationCurve));
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(_scaleCurve as Animation<double>)
      ..addListener(() {
        setState(() {});
      });

    _rotateCurve = CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 1.0, curve: widget.animationCurve));
    _rotateAnimation = Tween<double>(begin: 0.5, end: 1.0)
        .animate(_rotateCurve as Animation<double>)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _calculateProps();
    if (isOpen) {
      close();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calculateProps();
  }

  @override
  Widget build(BuildContext context) {
    // This makes the widget able to correctly redraw on
    // hot reload while keeping performance in production
    if (!kReleaseMode) {
      _calculateProps();
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        return Stack(
          alignment: widget.alignment,
          children: <Widget>[
            // Ring
            OverflowBox(
              maxWidth: _ringDiameter,
              maxHeight: _ringDiameter,
              child: Transform(
                transform: Matrix4.translationValues(
                  _translationX,
                  _translationY,
                  0.0,
                )..scale(_scaleAnimation.value),
                alignment: FractionalOffset.center,
                child: SizedBox(
                  width: _ringDiameter,
                  height: _ringDiameter,
                  child: CustomPaint(
                    painter: _RingPainter(
                      width: _ringWidth,
                      color: _ringColor,
                    ),
                    child: _scaleAnimation.value == 1.0
                        ? Transform.rotate(
                            angle: (2 * pi) *
                                _rotateAnimation.value *
                                _directionX *
                                _directionY,
                            child: Stack(
                              alignment: Alignment.center,
                              children: widget.children
                                  .asMap()
                                  .map((index, child) => MapEntry(index,
                                      _applyTransformations(child, index)))
                                  .values
                                  .toList(),
                            ),
                          )
                        : Container(),
                  ),
                ),
              ),
            ),

            // FAB
            Container(
              width: widget.fabSize,
              height: widget.fabSize,
              margin: widget.fabMargin,
              child: RawMaterialButton(
                fillColor: _colorAnimation!.value,
                shape: _fabIconBorder,
                elevation: widget.fabElevation,
                onPressed: () {
                  if (_isAnimating) return;
                  if (_isOpen) {
                    close();
                  } else {
                    if(widget.onPressedWhenClose != null) {
                      widget.onPressedWhenClose!();
                    }
                  }
                },
                onLongPress: () {
                  if (_isAnimating) return;
                  if (!_isOpen) {
                    open();
                  }
                },
                child: Center(
                  child: widget.fabChild ??
                      (_scaleAnimation.value == 1.0
                          ? widget.fabCloseIcon
                          : widget.fabOpenIcon),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _applyTransformations(Widget child, int index) {
    double angleFix = 0.0;
    if (widget.alignment.x == 0) {
      angleFix = 45.0 * _directionY.abs();
    } else if (widget.alignment.y == 0) {
      angleFix = -45.0 * _directionX.abs();
    }

    final angle =
        vector.radians(90.0 / (widget.children.length - 1) * index + angleFix);

    return Transform(
        transform: Matrix4.translationValues(
            (-(_ringDiameter! / 2) * cos(angle) +
                    (_ringWidth! / 2 * cos(angle))) *
                _directionX,
            (-(_ringDiameter! / 2) * sin(angle) +
                    (_ringWidth! / 2 * sin(angle))) *
                _directionY,
            0.0),
        alignment: FractionalOffset.center,
        child: Material(
          color: Colors.transparent,
          child: child,
        ));
  }

  void _calculateProps() {
    _ringColor = widget.ringColor ?? Theme.of(context).secondaryHeaderColor;
    _fabColor = widget.fabColor ?? Theme.of(context).primaryColor;
    _fabOpenColor = widget.fabOpenColor ?? _fabColor;
    _fabCloseColor = widget.fabCloseColor ?? _fabColor;
    _fabIconBorder = widget.fabIconBorder ?? const CircleBorder();
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    _ringDiameter = widget.ringDiameter ??
        min(_screenWidth, _screenHeight) * widget.ringDiameterLimitFactor;
    _ringWidth =
        widget.ringWidth ?? _ringDiameter! * widget.ringWidthLimitFactor;
    _marginH = (widget.fabMargin.right + widget.fabMargin.left) / 2;
    _marginV = (widget.fabMargin.top + widget.fabMargin.bottom) / 2;
    _directionX = widget.alignment.x == 0 ? 1 : 1 * widget.alignment.x.sign;
    _directionY = widget.alignment.y == 0 ? 1 : 1 * widget.alignment.y.sign;
    _translationX =
        ((_screenWidth - widget.fabSize) / 2 - _marginH) * widget.alignment.x;
    _translationY =
        ((_screenHeight - widget.fabSize) / 2 - _marginV) * widget.alignment.y;

    if (_colorAnimation == null || !kReleaseMode) {
      _colorCurve = CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            0.0,
            0.4,
            curve: widget.animationCurve,
          ));
      _colorAnimation = ColorTween(begin: _fabCloseColor, end: _fabOpenColor)
          .animate(_colorCurve as Animation<double>)
        ..addListener(() {
          setState(() {});
        });
    }
  }

  void open() {
    _isAnimating = true;
    _animationController.forward().then((_) {
      _isAnimating = false;
      _isOpen = true;
      if (widget.onDisplayChange != null) {
        widget.onDisplayChange!(true);
      }
    });
  }

  void close() {
    _isAnimating = true;
    _animationController.reverse().then((_) {
      _isAnimating = false;
      _isOpen = false;
      if (widget.onDisplayChange != null) {
        widget.onDisplayChange!(false);
      }
    });
  }

  bool get isOpen => _isOpen;
}

class _RingPainter extends CustomPainter {
  final double? width;
  final Color? color;

  _RingPainter({required this.width, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width < width! ? size.width : width!;

    canvas.drawArc(
        Rect.fromLTWH(
            width! / 2, width! / 2, size.width - width!, size.height - width!),
        0.0,
        2 * pi,
        false,
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
