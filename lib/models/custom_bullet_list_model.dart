import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum CustomListOrder {
  unordered,
  ordered,
}

enum CustomBulletType {
  numbered,
  conventional,
}

class CustomBulletListModel {
  final List<dynamic> listItems;
  final pw.TextStyle? style;
  final pw.Widget? bullet;
  final CustomListOrder listOrder;

  /// Optional. Color for the default bullet. Ignored if [bullet] above is specified.
  final PdfColor bulletColor;
  final pw.CrossAxisAlignment crossAxisAlignment;
  final CustomBulletType bulletType;
  final PdfColor numberColor;
  final pw.BoxShape boxShape;

  const CustomBulletListModel({
    Key? key,
    required this.listItems,
    this.style,
    this.bullet,
    this.listOrder = CustomListOrder.unordered,
    this.bulletColor = PdfColors.blueGrey,
    this.crossAxisAlignment = pw.CrossAxisAlignment.center,
    this.bulletType = CustomBulletType.conventional,
    this.numberColor = PdfColors.white,
    this.boxShape = pw.BoxShape.circle,
  });
}
