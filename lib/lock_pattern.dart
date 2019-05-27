// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';


typedef GestureTapCallback = void Function();

class LockPattern extends StatefulWidget {
  //<editor-fold desc="属性">

  ///解锁类型（实心、空心）
  final LockPatternType type;

  ///与父布局的间距
  final double padding;

  ///圆之间的间距
  final double roundSpace;

  ///圆之间的间距比例(以圆半径作为基准)，[roundSpace]设置时无效
  final double roundSpaceRatio;

  ///默认颜色
  final Color defaultColor;

  ///验证失败颜色
  final Color failedColor;

  ///无法使用颜色
  final Color disableColor;

  ///线长度
  final double lineWidth;

  ///实心圆半径比例(以圆半径作为基准)
  final double solidRadiusRatio;

  ///触摸有效区半径比较(以圆半径作为基准)
  final double touchRadiusRatio;

  ///延迟显示时间
  final int delayTime;

  ///回调
  final Function(List<int>, LockPatternStatus) onCompleted;

  //</editor-fold>

  final _LockPatternState _state = _LockPatternState();

  LockPattern(
      {this.type = LockPatternType.Solid,
      this.padding = 10,
      this.roundSpace,
      this.roundSpaceRatio = 0.6,
      this.defaultColor = Colors.blue,
      this.failedColor = Colors.red,
      this.disableColor = Colors.grey,
      this.lineWidth = 2,
      this.solidRadiusRatio = 0.4,
      this.touchRadiusRatio = 0.6,
      this.delayTime = 1000,
      this.onCompleted});

  @override
  _LockPatternState createState() {
    return _state;
  }

  void updateStatus(LockPatternStatus status) {
    _state.updateStatus(status);
  }

  static String selectedToString(List<int> rounds) {
    var sb = StringBuffer();
    for (int i = 0; i < rounds.length; i++) {
      sb.write(rounds[i] + 1);
    }
    return sb.toString();
  }
}

class _LockPatternState extends State<LockPattern> {
  RenderBox _box;

  ///当前手势状态
  LockPatternStatus _status = LockPatternStatus.Default;

  ///九宫格圆
  List<Round> _rounds = List<Round>(9);

  ///选中圆位置
  List<int> _selected = [];

  ///最后触摸位置
  Offset _lastTouchPoint;
  double _radius;
  double _solidRadius;
  double _touchRadius;
  Timer _timer;

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
  void deactivate() {
    super.deactivate();
    if (_timer?.isActive == true) {
      _timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    var custom = CustomPaint(
        size: Size.infinite,
        painter: LockPatternPainter(
            widget.type,
            _status,
            _rounds,
            _selected,
            _lastTouchPoint,
            _radius,
            _solidRadius,
            widget.lineWidth,
            widget.defaultColor,
            widget.failedColor,
            widget.disableColor));
    var enableTouch = _status == LockPatternStatus.Default;
    return GestureDetector(
        child: custom,
        onPanStart: enableTouch ? _onPanStart : null,
        onPanEnd: enableTouch ? _onPanEnd : null,
        onPanUpdate: enableTouch ? _onPanUpdate : null);
  }

  void updateStatus(LockPatternStatus status) {
    _status = status;
    switch (status) {
      case LockPatternStatus.Default:
      case LockPatternStatus.Disable:
        _updateRoundStatus(status);
        _selected.clear();
        break;
      case LockPatternStatus.Failed:
        for (var round in _rounds) {
          if (round.status == LockPatternStatus.Success) {
            round.status = LockPatternStatus.Failed;
          }
        }
        _timer = Timer(Duration(milliseconds: widget.delayTime), () {
          updateStatus(LockPatternStatus.Default);
        });
        break;
      case LockPatternStatus.Success:
        _timer = Timer(Duration(milliseconds: widget.delayTime), () {
          updateStatus(LockPatternStatus.Default);
        });
        break;
    }
    setState(() {});
  }

  _updateRoundStatus(LockPatternStatus status) {
    for (Round round in _rounds) {
      round.status = status;
    }
  }

  _init(_) {
    _box = context.findRenderObject() as RenderBox;
    var size = context.size;
    if (size.width > size.height) {
      throw Exception("LockPattern width must <= height");
    }

    var width = size.width;
    var roundSpace = widget.roundSpace;
    if (roundSpace != null) {
      _radius = (width - widget.padding * 2 - roundSpace * 2) / 3 / 2;
    } else {
      _radius =
          (width - widget.padding * 2) / (3 + widget.roundSpaceRatio * 2) / 2;
      roundSpace = _radius * 2 * widget.roundSpaceRatio;
    }

    _solidRadius = _radius * widget.solidRadiusRatio;
    _touchRadius = _radius * widget.touchRadiusRatio;

    for (int i = 0; i < _rounds.length; i++) {
      var row = i ~/ 3;
      var column = i % 3;
      var dx = widget.padding + column * (_radius * 2 + roundSpace) + _radius;
      var dy = widget.padding + row * (_radius * 2 + roundSpace) + _radius;
      _rounds[i] = Round(dx, dy, LockPatternStatus.Default);
    }
    setState(() {});
  }

  //<editor-fold desc="触摸手势调用">
  _onPanStart(DragStartDetails detail) {
    setState(() {
      var position = _box.globalToLocal(detail.globalPosition);
      for (int i = 0; i < _rounds.length; i++) {
        var round = _rounds[i];
        if (round.status == LockPatternStatus.Default &&
            round.contains(position, _touchRadius)) {
          round.status = LockPatternStatus.Success;
          _selected.add(i);
          break;
        }
      }
    });
  }

  _onPanUpdate(DragUpdateDetails detail) {
    setState(() {
      var position = _box.globalToLocal(detail.globalPosition);
      for (int i = 0; i < _rounds.length; i++) {
        var round = _rounds[i];
        if (round.status == LockPatternStatus.Default &&
            round.contains(position, _touchRadius)) {
          round.status = LockPatternStatus.Success;
          _selected.add(i);
          break;
        }
      }

      ///判断触摸点是否超出widget大小
      double x = position.dx;
      double y = position.dy;
      if (x > context.size.width) {
        x = context.size.width;
      } else if (x < 0) {
        x = 0;
      }

      if (y > context.size.height) {
        y = context.size.height;
      } else if (y < 0) {
        y = 0;
      }

      _lastTouchPoint = Offset(x, y);
    });
  }

  _onPanEnd(DragEndDetails detail) {
    _lastTouchPoint = null;
    if (widget.onCompleted != null) {
      widget.onCompleted(_selected, _status);
    }
  }
//</editor-fold>
}

class LockPatternPainter extends CustomPainter {
  LockPatternType _type;
  LockPatternStatus _status;
  List<Round> _rounds;
  List<int> _selected;
  Offset _lastTouchPoint;
  double _radius;
  double _solidRadius;
  double _lineWidth;
  Color _defaultColor;
  Color _failedColor;
  Color _disableColor;

  LockPatternPainter(
      this._type,
      this._status,
      this._rounds,
      this._selected,
      this._lastTouchPoint,
      this._radius,
      this._solidRadius,
      this._lineWidth,
      this._defaultColor,
      this._failedColor,
      this._disableColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (_radius == null) return;
    var paint = Paint();

    if (_type == LockPatternType.Solid) {
      ///画圆
      _paintRound(canvas, paint);

      ///画线
      _paintLine(canvas, paint);
    } else {
      _paintRoundWithHollow(canvas, paint);
      _paintLineWithHollow(canvas, paint);
    }
  }

  _paintRoundWithHollow(Canvas canvas, Paint paint) {
    paint.strokeWidth = _lineWidth;
    for (Round round in _rounds) {
      switch (round.status) {
        case LockPatternStatus.Default:
          {
            paint.color = _defaultColor;
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(round.toOffset(), _radius, paint);
            break;
          }
        case LockPatternStatus.Success:
          {
            paint.style = PaintingStyle.fill;
            paint.color = _defaultColor;
            canvas.drawCircle(round.toOffset(), _solidRadius, paint);
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(round.toOffset(), _radius, paint);
            break;
          }
        case LockPatternStatus.Failed:
          {
            paint.style = PaintingStyle.fill;
            paint.color = _failedColor;
            canvas.drawCircle(round.toOffset(), _solidRadius, paint);
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(round.toOffset(), _radius, paint);
            break;
          }
        case LockPatternStatus.Disable:
          {
            paint.color = _disableColor;
            canvas.drawCircle(round.toOffset(), _solidRadius, paint);
            break;
          }
      }
    }
  }

  _paintLineWithHollow(Canvas canvas, Paint paint) {
    if (_selected.isNotEmpty) {
      paint.color =
          _status == LockPatternStatus.Failed ? _failedColor : _defaultColor;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = _lineWidth;
      var path = Path();

      ///画圆到圆的线
      for (int i = 1; i < _selected.length; i++) {
        var from = _rounds[_selected[i-1]].toOffset();
        var to = _rounds[_selected[i]].toOffset();
        _addPath(path, from, to, _radius,true);
      }

      ///画最后一个圆到触摸点的线
      var lastSelected = _rounds[_selected.last];
      if (_lastTouchPoint != null &&
          !lastSelected.contains(_lastTouchPoint, _radius)) {
        _addPath(path, lastSelected.toOffset() , _lastTouchPoint, _radius, false);
        path.lineTo(_lastTouchPoint.dx, _lastTouchPoint.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  _addPath(Path path, Offset from, Offset to, double radius, bool isLineTo) {
    var distance = sqrt(pow(to.dx - from.dx, 2) + pow(to.dy - from.dy, 2));
    var scale = radius / distance;
    var translateX = (to.dx - from.dx) * scale;
    var translateY = (to.dy - from.dy) * scale;
    var fromPoint = from.translate(translateX, translateY);
    var toPoint = to.translate(-translateX, -translateY);
    path.moveTo(fromPoint.dx, fromPoint.dy);
    if (isLineTo) {
      path.lineTo(toPoint.dx, toPoint.dy);
    }
  }

  _paintRound(Canvas canvas, Paint paint) {
    for (Round round in _rounds) {
      switch (round.status) {
        case LockPatternStatus.Default:
          {
            paint.color = _defaultColor;
            paint.style = PaintingStyle.fill;
            canvas.drawCircle(round.toOffset(), _solidRadius, paint);
            break;
          }
        case LockPatternStatus.Success:
          {
            paint.color = _defaultColor;
            canvas.drawCircle(round.toOffset(), _solidRadius, paint);
            paint.color = _defaultColor.withAlpha(20);
            canvas.drawCircle(round.toOffset(), _radius, paint);
            break;
          }
        case LockPatternStatus.Failed:
          {
            paint.color = _failedColor;
            canvas.drawCircle(round.toOffset(), _solidRadius, paint);
            paint.color = _failedColor.withAlpha(20);
            canvas.drawCircle(round.toOffset(), _radius, paint);
            break;
          }
        case LockPatternStatus.Disable:
          {
            paint.color = _disableColor;
            canvas.drawCircle(round.toOffset(), _solidRadius, paint);
            break;
          }
      }
    }
  }

  _paintLine(Canvas canvas, Paint paint) {
    if (_selected.isNotEmpty) {
      paint.color =
          _status == LockPatternStatus.Failed ? _failedColor : _defaultColor;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = _lineWidth;
      var path = Path();
      for (int i = 0; i < _selected.length; i++) {
        var index = _selected[i];
        if (i == 0) {
          path.moveTo(_rounds[index].x, _rounds[index].y);
        } else {
          path.lineTo(_rounds[index].x, _rounds[index].y);
        }
      }
      if (_lastTouchPoint != null) {
        path.lineTo(_lastTouchPoint.dx, _lastTouchPoint.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

enum LockPatternType { Solid, Hollow }

enum LockPatternStatus { Default, Success, Failed, Disable }

class Round {
  double x;
  double y;
  LockPatternStatus status;

  Round(this.x, this.y, this.status);

  Offset toOffset() {
    return Offset(x, y);
  }

  bool contains(Offset offset, radius) {
    return sqrt(pow(offset.dx - x, 2) + pow(offset.dy - y, 2)) < radius;
  }

  @override
  String toString() {
    return "($x,$y)";
  }
}
