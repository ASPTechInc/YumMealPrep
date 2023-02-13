import 'dart:typed_data';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:yummealprep/models/meal_item_model.dart';
import 'package:yummealprep/themes/colours.dart';
import 'package:yummealprep/utils/constants.dart';

class ShareMealItemScreen extends StatefulWidget {
  final MealItemModel? item;

  const ShareMealItemScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  ShareMealItemScreenState createState() => ShareMealItemScreenState();
}

class ShareMealItemScreenState extends State<ShareMealItemScreen> {
  dynamic nutritionFactsImage;
  Uint8List? bytesImage;

  pw.Column itemDescriptionSection() {
    return pw.Column(mainAxisSize: pw.MainAxisSize.min, children: <pw.Widget>[
      pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12.0),
            child: pw.Text(
              'Description',
              style: pw.TextStyle(
                  fontSize: 20.0,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey),
            )),
      ),
      pw.SizedBox(
        height: 10.0,
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 15, right: 15),
        child: pw.Text(
          widget.item!.description!,
          textAlign: pw.TextAlign.justify,
          style: const pw.TextStyle(fontSize: 14.0),
        ),
      )
    ]);
  }

  Future<void> getItemImage(image) async {
    final itemImage = await networkImage(image);
    setState(() {
      nutritionFactsImage = itemImage;
    });
  }

  pw.Padding expandedSection(itemList) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 10),
      child: pw.SizedBox(
        height: 300,
        child: pw.ListView.separated(
          direction: pw.Axis.horizontal,
          separatorBuilder: (context, index) => pw.SizedBox(
            width: 10.0,
          ),
          itemCount: widget.item!.nutritionFacts!.length,
          itemBuilder: (pw.Context context, int index) {
            getItemImage(widget.item!.nutritionFacts![index]);
            return pw.Image(nutritionFactsImage, width: 250, height: 250);
          },
        ),
      ),
    );
  }

  pw.Column nutritionFactsSection() {
    return pw.Column(mainAxisSize: pw.MainAxisSize.min, children: <pw.Widget>[
      pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12.0),
            child: pw.Text(
              'Nutrition Facts',
              style: pw.TextStyle(
                  fontSize: 20.0,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey),
            )),
      ),
      expandedSection(widget.item!.nutritionFacts!),
    ]);
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final font = await PdfGoogleFonts.nunitoExtraBold();
    final itemImage = await networkImage(widget.item!.image!);
    final appLogo = await networkImage(dotenv.env['APPLOGO1']!);
    final companyLogo = await networkImage(dotenv.env['COMPANYLOGO']!);
    final pdf = pw.Document(
        version: PdfVersion.pdf_1_5,
        compress: true,
        title: 'Meal Details',
        author: Constants.appName,
        creator: Constants.appName,
        subject: 'Meal Details PDF File',
        producer: dotenv.env['COMPANYNAMEALIAS']!);

    // Add pdf page
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        orientation: pw.PageOrientation.portrait,
        build: (context) {
          return pw.Stack(
            children: [
              // Header
              pw.Positioned(
                right: 30.0,
                child: pw.Flexible(
                    child: pw.Image(itemImage, height: 100, width: 100)),
              ),
              pw.Positioned(
                top: 30,
                right: 15,
                child: pw.Header(
                    title: 'Meal Details',
                    child: pw.Flexible(
                        child: pw.Image(appLogo, height: 40, width: 40))),
              ),
              // Body
              pw.SizedBox(
                height: 1500,
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: <pw.Widget>[
                    pw.SizedBox(height: 10.0),
                    pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(
                          left: 10.0,
                        ),
                        child: pw.Text(
                          widget.item!.name!,
                          maxLines: 5,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              font: font,
                              fontSize: 20.0,
                              color: PdfColors.black),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5.0),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 15.0),
                            child: pw.Text('${widget.item!.type!} Meal',
                                style: pw.TextStyle(
                                    color: PdfColors.grey600,
                                    fontSize: 15,
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: <pw.Widget>[
                        pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: <pw.Widget>[
                            pw.Text(
                              'Drink',
                              style: pw.TextStyle(
                                  color: PdfColors.grey700,
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Align(
                                alignment: pw.Alignment.centerLeft,
                                child: pw.Text(
                                  widget.item!.drink!,
                                  style: pw.TextStyle(
                                      fontSize: 15.0,
                                      color: PdfColors.grey700,
                                      fontWeight: pw.FontWeight.bold),
                                )),
                          ],
                        ),
                        pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: <pw.Widget>[
                            pw.Text(
                              'Side dish',
                              style: pw.TextStyle(
                                  color: PdfColors.grey700,
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              widget.item!.sideDish!,
                              style: pw.TextStyle(
                                  fontSize: 15.0,
                                  color: PdfColors.grey700,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 25.0),
                    itemDescriptionSection(),
                    pw.Divider(color: PdfColors.grey700),
                    pw.SizedBox(height: 5.0),
                    nutritionFactsSection(),
                  ],
                ),
              ),
              // Footer
              pw.Positioned(
                bottom: 10,
                child: pw.Footer(
                  title: pw.Text(
                      'Copyright \u00a9 2022 ${dotenv.env['COMPANYNAME']!}. All rights reserved.',
                      style: const pw.TextStyle(fontSize: 11)),
                  trailing: pw.SizedBox(
                    height: 25.0,
                    width: 25.0,
                    child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 5),
                        child: pw.Image(companyLogo)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Flushbar showFlushBar(context, String value) {
    return Flushbar(
      backgroundColor: AppColours.dark,
      messageText: Text(value,
          textAlign: TextAlign.center,
          style: GoogleFonts.workSans(
            color: Colors.white,
            fontSize: 16.0,
          )),
      icon: Icon(
          value.contains('Meal item printed') ||
                  value.contains('Meal item shared')
              ? Icons.check_box
              : Icons.close,
          size: 28.0,
          color: value.contains('Meal item printed') ||
                  value.contains('Meal item shared')
              ? Colors.green[300]
              : Colors.red[500]),
      leftBarIndicatorColor: value.contains('Meal item printed') ||
              value.contains('Meal item shared')
          ? Colors.green[300]
          : Colors.red[500],
      duration: const Duration(seconds: 3),
      onStatusChanged: (status) {
        // if (status == FlushbarStatus.SHOWING && value != 'Meal added') {
        //   Future.delayed(const Duration(seconds: 3), () {
        //     Navigator.of(context).pushNamed(Constants.editProfileScreen);
        //   });
        // }
      },
    )..show(this.context);
  }

  @override
  Widget build(BuildContext context) {
    String? filename = widget.item!.name!.toLowerCase().split(' ').join('_');

    return PdfPreview(
      pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: Colors.black)),
      pdfFileName: '${filename}_meal_${Constants.appName.toLowerCase}.pdf',
      build: (format) => _generatePdf(format, Constants.appName),
      onError: ((context, error) => Center(
            child: Text(
              'Error: $error',
              maxLines: 3,
              style: const TextStyle(color: Colors.black),
            ),
          )),
      loadingWidget: Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColours.primaryColour),
      )),
      onPrinted: (context) => showFlushBar(context, 'Meal item printed!'),
      onShared: (context) => showFlushBar(context, 'Meal item shared!'),
    );
  }
}
