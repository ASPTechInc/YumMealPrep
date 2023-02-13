import 'package:flutter/material.dart';
import 'package:yummealprep/themes/colours.dart';
import 'package:yummealprep/utils/constants.dart';

class ZoomClipNetworkImage extends StatelessWidget {
  final double? zoom;
  final double? height;
  final double? width;
  final String? imageNetwork;

  const ZoomClipNetworkImage(
      {Key? key,
      required this.zoom,
      this.height,
      this.width,
      required this.imageNetwork})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // var isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: OverflowBox(
          maxHeight: height! * zoom!,
          maxWidth: width! * zoom!,
          child: Image.network(
            imageNetwork!,
            fit: BoxFit.fill,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              return Center(
                  child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    // isDarkTheme ? Colors.blue : AppColours.primaryColour),
                    AppColours.primaryColour),
              ));
            },
            errorBuilder: (context, error, stackTrace) => Center(
              child: Image.asset(
                Constants.errorImage,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
