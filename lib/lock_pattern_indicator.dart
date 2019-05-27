import 'package:flutter/material.dart';

import 'lock_pattern.dart';

class LockPatternIndicator extends StatefulWidget {
  final double roundSpace;
  final double roundSpaceRatio;
  final double strokeWidth;
  final Color color;
  final _LockPatternIndicatorState _state=_LockPatternIndicatorState();

  LockPatternIndicator(
      {this.roundSpace,
      this.roundSpaceRatio = 0.5,
      this.strokeWidth = 1,
      this.color = Colors.blue});

  void setSelectPoint(List<int> selected) {
    _state.setSelectPoint(selected);
  }

  @override
  _LockPatternIndicatorState createState() {
    return _state;
  }
}

class _LockPatternIndicatorState extends State<LockPatternIndicator> {
  List<Round> _rounds = List<Round>(9);
  double _radius;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_init);
  }

  @override
  void didUpdateWidget(StatefulWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(_init);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        size: Size.infinite,
        painter: LockPatternIndicatorPainter(
            _rounds, _radius, widget.strokeWidth, widget.color));
  }

  void setSelectPoint(List<int> selected) {
    for (int i = 0; i < _rounds.length; i++) {
      _rounds[i].status = selected.contains(i)
          ? LockPatternStatus.Success
          : LockPatternStatus.Default;
    }
  }

  _init(_) {
    if (context.size.width > context.size.height) {
      throw Exception("widget width must <= height");
    }
    var width = context.size.width;
    var roundSpace = widget.roundSpace;
    if (roundSpace != null) {
      _radius = (width - roundSpace * 2) / 3 / 2;
    } else {
      _radius = width / (3 + widget.roundSpaceRatio * 2) / 2;
      roundSpace = _radius * 2 * widget.roundSpaceRatio;
    }

    for (int i = 0; i < _rounds.length; i++) {
      var row = i ~/ 3;
      var column = i % 3;
      var dx = column * (_radius * 2 +roundSpace) + _radius;
      var dy = row * (_radius * 2 + roundSpace) + _radius;
      _rounds[i] = Round(dx, dy, LockPatternStatus.Default);
    }
    setState(() {});
  }
}

class LockPatternIndicatorPainter extends CustomPainter {
  List<Round> _rounds;
  double _radius;
  double _strokeWidth;
  Color _color;

  LockPatternIndicatorPainter(
      this._rounds, this._radius, this._strokeWidth, this._color);

  @override
  void paint(Canvas canvas, Size size) {
    if (_radius == null) return;

    var paint = Paint();
    paint.strokeWidth = _strokeWidth;
    paint.color = _color;

    for (var round in _rounds) {
      switch (round.status) {
        case LockPatternStatus.Default:
          paint.style = PaintingStyle.stroke;
          canvas.drawCircle(round.toOffset(), _radius, paint);
          break;
        case LockPatternStatus.Success:
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(round.toOffset(), _radius, paint);
          break;
        default:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
