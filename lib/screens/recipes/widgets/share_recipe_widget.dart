import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:yummealprep/models/custom_bullet_list_model.dart';
import 'package:yummealprep/models/recipe_model.dart';
import 'package:yummealprep/screens/recipes/widgets/custom_bullet_list_widget.dart';
import 'package:yummealprep/themes/colours.dart';
import 'package:yummealprep/utils/constants.dart';

class ShareRecipe extends StatefulWidget {
  final RecipeModel item;

  const ShareRecipe({Key? key, required this.item}) : super(key: key);
  @override
  State<StatefulWidget> createState() => ShareRecipeState();
}

class ShareRecipeState extends State<ShareRecipe> {
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
          widget.item.description!,
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

  pw.Padding expandedSection(field, itemList) {
    CustomBulletListModel instructionsCustomBulletList = CustomBulletListModel(
        listItems: widget.item.instructions!,
        listOrder: CustomListOrder.ordered,
        bulletType: CustomBulletType.numbered);

    CustomBulletListModel ingredientsCustomBulletList = CustomBulletListModel(
      listItems: widget.item.ingredients!,
      listOrder: CustomListOrder.ordered,
    );

    return pw.Padding(
      padding:
          const pw.EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 10),
      child: pw.SizedBox(
        height: 300,
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10.0),
                child: field == 'Instructions'
                    ? CustomBulletList(
                        list: instructionsCustomBulletList,
                      )
                    : CustomBulletList(
                        list: ingredientsCustomBulletList,
                      ))
          ],
        ),
      ),
    );
  }

  pw.Padding instructionsExpandedSection(itemList) {
    CustomBulletListModel instructionsCustomBulletList = CustomBulletListModel(
        listItems: widget.item.instructions!,
        listOrder: CustomListOrder.ordered,
        bulletType: CustomBulletType.numbered);

    return pw.Padding(
      padding:
          const pw.EdgeInsets.only(top: 0, left: 10, right: 10, bottom: 10),
      child: pw.SizedBox(
        height: 300,
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10.0),
                child: CustomBulletList(
                  list: instructionsCustomBulletList,
                ))
          ],
        ),
      ),
    );
  }

  pw.Column itemIngredientsSection() {
    return pw.Column(mainAxisSize: pw.MainAxisSize.min, children: <pw.Widget>[
      pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12.0),
            child: pw.Text(
              'Ingredients',
              style: pw.TextStyle(
                  fontSize: 20.0,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey),
            )),
      ),
      pw.SizedBox(
        height: 10.0,
      ),
      expandedSection('Ingredients', widget.item.ingredients!),
      pw.SizedBox(
        height: 10.0,
      ),
    ]);
  }

  pw.Column instructionsSection() {
    return pw.Column(mainAxisSize: pw.MainAxisSize.min, children: <pw.Widget>[
      pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12.0),
            child: pw.Text(
              'Instructions',
              style: pw.TextStyle(
                  fontSize: 20.0,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey),
            )),
      ),
      pw.SizedBox(
        height: 10.0,
      ),
      instructionsExpandedSection(widget.item.instructions!),
      pw.SizedBox(
        height: 10.0,
      ),
    ]);
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final font = await PdfGoogleFonts.nunitoExtraBold();
    final itemImage = await networkImage(widget.item.image!);
    final appLogo = await networkImage(dotenv.env['APPLOGO1']!);
    final companyLogo = await networkImage(dotenv.env['COMPANYLOGO']!);
    final pdf = pw.Document(
        version: PdfVersion.pdf_1_5,
        compress: true,
        title: 'Recipe Details',
        author: Constants.appName,
        creator: Constants.appName,
        subject: 'Recipe Details PDF File',
        producer: dotenv.env['COMPANYNAMEALIAS']!);

    // Add pdf page # 1
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
                    title: 'Recipe Details',
                    child: pw.Flexible(
                        child: pw.Image(appLogo, height: 40, width: 40))),
              ),
              // Body
              pw.SizedBox(
                height: 2000,
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
                          widget.item.name!,
                          maxLines: 5,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            font: font,
                            fontSize: 20.0,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5.0),
                    pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 12.0),
                        child: pw.Text(
                          '${widget.item.type!} Recipe',
                          style: pw.TextStyle(
                              color: PdfColors.grey600,
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: <pw.Widget>[
                        pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: <pw.Widget>[
                            pw.Text(
                              'Servings',
                              style: pw.TextStyle(
                                  color: PdfColors.grey700,
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Align(
                                alignment: pw.Alignment.centerLeft,
                                child: pw.Text(
                                  widget.item.servingSize!,
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
                              'Preparation time',
                              style: pw.TextStyle(
                                  color: PdfColors.grey700,
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              widget.item.preparationTime!,
                              style: pw.TextStyle(
                                  fontSize: 15.0,
                                  color: PdfColors.grey700,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                        pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: <pw.Widget>[
                            pw.Text(
                              'Cooking time',
                              style: pw.TextStyle(
                                  color: PdfColors.grey700,
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              widget.item.cookingTime!,
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
                    itemIngredientsSection(),
                    pw.Divider(color: PdfColors.grey700),
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

    // Add pdf page #2
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
                    title: 'Recipe Details',
                    child: pw.Flexible(
                        child: pw.Image(appLogo, height: 40, width: 40))),
              ),
              // Body
              pw.SizedBox(
                height: 2000,
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: <pw.Widget>[
                    pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(
                          left: 10.0,
                        ),
                        child: pw.Text(
                          widget.item.name!,
                          maxLines: 5,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 20.0,
                            color: PdfColors.black,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 5.0),
                    pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 12.0),
                        child: pw.Text(
                          '${widget.item.type!} Recipe',
                          style: pw.TextStyle(
                              color: PdfColors.grey600,
                              fontSize: 15,
                              fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 30.0),
                    instructionsSection(),
                    pw.SizedBox(height: 10.0),
                  ],
                ),
              ),
              // Footer
              pw.Positioned(
                bottom: 10,
                child: pw.Footer(
                  title: pw.Text(
                      'Copyright \u00a9 2021 ${dotenv.env['COMPANYNAME']!}. All rights reserved.',
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
          value.contains('Recipe printed') || value.contains('Recipe shared')
              ? Icons.check_box
              : Icons.close,
          size: 28.0,
          color: value.contains('Recipe printed') ||
                  value.contains('Recipe shared')
              ? Colors.green[300]
              : Colors.red[500]),
      leftBarIndicatorColor:
          value.contains('Recipe printed') || value.contains('Recipe shared')
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? filename = widget.item.name!.toLowerCase().split(' ').join('_');
    return PdfPreview(
      pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white, border: Border.all(color: Colors.black)),
      pdfFileName: '${filename}_recipe_${Constants.appName.toLowerCase}.pdf',
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
      onPrinted: (context) => showFlushBar(context, 'Recipe printed!'),
      onShared: (context) => showFlushBar(context, 'Recipe item shared!'),
    );
  }
}
