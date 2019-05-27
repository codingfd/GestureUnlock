import 'package:flutter/material.dart';

import 'strings.dart';
import 'package:gesture_unlock/lock_pattern.dart';
import 'package:gesture_unlock/lock_pattern_indicator.dart';


class GestureCreatePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("创建手势"),
        ),
        body: GestureCreate());
  }
}

class GestureCreate extends StatefulWidget {
  @override
  GestureCreateState createState() {
    return GestureCreateState();
  }
}

class GestureCreateState extends State<GestureCreate> {
  var _status = GestureCreateStatus.Create;
  var _msg = "请绘制解锁手势";
  var _gesturePassword;
  LockPatternIndicator _indicator;
  LockPattern _lockPattern;

  @override
  Widget build(BuildContext context) {
    if (_indicator == null) {
      _indicator = LockPatternIndicator();
    }
    if (_lockPattern == null) {
      _lockPattern = LockPattern(
        type: LockPatternType.Hollow,
        padding: 30,
        onCompleted: _gestureComplete,
      );
    }
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: _indicator,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 12, bottom: 12),
            child: Center(
              child: Text(
                _msg,
                style: TextStyle(
                    color: (_status ==
                                GestureCreateStatus.Verify_Failed ||
                            _status == GestureCreateStatus.Create_Failed)
                        ? Colors.red
                        : Colors.black),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: _lockPattern,
            ),
          )
        ],
      ),
    );
  }

  _gestureComplete(List<int> selected, LockPatternStatus status) {
    setState(() {
      switch (_status) {
        case GestureCreateStatus.Create:
        case GestureCreateStatus.Create_Failed:
          if (selected.length < 4) {
           _msg = "连接数不能小于4个，请重新尝试";
           _status = GestureCreateStatus.Create_Failed;
            _lockPattern.updateStatus(LockPatternStatus.Failed);
          } else {
            _msg = "请再次验证手势";
            _gesturePassword = LockPattern.selectedToString(selected);
            _status = GestureCreateStatus.Verify;
            _lockPattern.updateStatus(LockPatternStatus.Success);
            _indicator.setSelectPoint(selected);
          }
          break;
        case GestureCreateStatus.Verify:
        case GestureCreateStatus.Verify_Failed:
          var password = LockPattern.selectedToString(selected);
          if (_gesturePassword == password) {
            _msg = "设置成功,手势密码为$password";
            Strings.gesturePassword=password;
            _lockPattern.updateStatus(LockPatternStatus.Success);
          } else {
            _msg = "验证失败，请重新尝试";
            _status = GestureCreateStatus.Verify_Failed;
            _lockPattern.updateStatus(LockPatternStatus.Failed);
          }
          break;
        case GestureCreateStatus.Verify_Failed_Count_Overflow:
          break;
      }
    });
  }
}

enum GestureCreateStatus {
  Create,
  Create_Failed,
  Verify,
  Verify_Failed,
  Verify_Failed_Count_Overflow
}
