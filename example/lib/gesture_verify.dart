import 'package:flutter/material.dart';

import 'strings.dart';
import 'package:gesture_unlock/lock_pattern.dart';

class GestureVerifyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("验证收拾"),
        ),
        body: GestureVerify());
  }
}

// ignore: must_be_immutable
class GestureVerify extends StatefulWidget {
  @override
  GestureVerifyState createState() {
    return GestureVerifyState();
  }
}

class GestureVerifyState extends State<GestureVerify> {
  var _status = GestureCreateStatus.Verify;
  var _msg = "请绘制解锁手势";
  var _failedCount = 0;
  LockPattern _lockPattern;

  @override
  Widget build(BuildContext context) {
    if (_lockPattern == null) {
      _lockPattern = LockPattern(
        padding: 30,
        onCompleted: _gestureComplete,
      );
    }
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 12, bottom: 12),
            child: Center(
              child: Text(
                _msg,
                style: TextStyle(
                    color: _status == GestureCreateStatus.Verify_Failed
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
        case GestureCreateStatus.Verify:
        case GestureCreateStatus.Verify_Failed:
          var password = LockPattern.selectedToString(selected);
          if (Strings.gesturePassword == password) {
            _msg = "解锁成功";
            _lockPattern.updateStatus(LockPatternStatus.Success);
          } else {

            _failedCount++;
            if (_failedCount >= 5) {
              _status = GestureCreateStatus.Verify_Failed_Count_Overflow;
              _lockPattern.updateStatus(LockPatternStatus.Disable);
              _msg = "多次验证失败，请5分钟后再次尝试";
            }else{
              _status = GestureCreateStatus.Verify_Failed;
              _lockPattern.updateStatus(LockPatternStatus.Failed);
              _msg = "验证失败，请重新尝试";
            }
          }
          break;
        case GestureCreateStatus.Verify_Failed_Count_Overflow:
          break;
        default:
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
