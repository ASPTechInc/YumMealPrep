import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:yummealprep/models/custom_bullet_list_model.dart';

class CustomBulletList extends pw.StatelessWidget {
  final CustomBulletListModel? list;
  CustomBulletList({Key? key, this.list});

  @override
  pw.Widget build(pw.Context context) {
    pw.Widget bullet(pw.Context context) {
      return list!.bullet ??
          pw.Container(
            height: 10,
            width: 10,
            decoration: pw.BoxDecoration(
              color: list!.bulletColor,
              shape: list!.boxShape,
            ),
          );
    }

    pw.Widget numberedBullet(dynamic item) {
      final int number = 1 + list!.listItems.indexWhere((e) => e == item);
      if (number < 1) {
        return bullet(context);
      }
      final double boxSize = 10 + (1.0 * list!.listItems.length);
      return pw.Container(
        alignment: pw.Alignment.center,
        height: boxSize,
        width: boxSize,
        decoration: pw.BoxDecoration(
          color: list!.bulletColor,
          shape: list!.boxShape,
        ),
        child: pw.Text(
          number.toString(),
          style: pw.TextStyle.defaultStyle().copyWith(
              fontSize: 10,
              color: list!.numberColor,
              fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      );
    }

    if (list!.listOrder == CustomListOrder.ordered &&
        list!.listItems is List<String>) {
      list!.listItems.sort((a, b) => a.compareTo(b));
    }

    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: list!.crossAxisAlignment,
        children: [
          pw.ListView.separated(
              separatorBuilder: (context, index) => pw.SizedBox(height: 5),
              itemCount: list!.listItems.length,
              itemBuilder: (context, index) {
                return pw.Row(children: [
                  list!.bulletType == CustomBulletType.conventional
                      ? bullet(context)
                      : numberedBullet(list!.listItems[index]),
                  pw.SizedBox(width: 10),
                  list!.listItems[index] == null
                      ? pw.Text(
                          '',
                          style: const pw.TextStyle(
                              color: PdfColors.black, fontSize: 14),
                        )
                      : list!.listItems[index] is String
                          ? pw.Text(list!.listItems[index],
                              style: const pw.TextStyle(
                                  color: PdfColors.black, fontSize: 14))
                          : list!.listItems[index] is pw.Widget
                              ? list!.listItems[index]
                              : pw.Text(
                                  'Error: Only Widget/String allowed:\n${list!.listItems[index]}',
                                ),
                ]);
              }),
        ],
      ),
    );
  }
}
