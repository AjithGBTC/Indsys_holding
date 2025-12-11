import 'package:flutter/material.dart';

class BlueClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);

    var firstControl = Offset(size.width / 2, size.height);
    var firstEnd = Offset(size.width, size.height - 80);

    path.quadraticBezierTo(
        firstControl.dx, firstControl.dy, firstEnd.dx, firstEnd.dy);

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}